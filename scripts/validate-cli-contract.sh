#!/usr/bin/env bash
# owner: pipeline-contracts-template
# validate-cli-contract.sh — Validate a *.cli-contract.md file against the
# WS5 CLI-contract schema. Peer to WS4's validate-design-spec.sh,
# validate-build-exit.sh, etc.
#
# Usage: bash scripts/validate-cli-contract.sh <path-to-cli-contract.md>
#
# Output format (mirrors WS4):
#   Summary line: `CLI-CONTRACT-DRIFT: <N> issue(s) in <path>`
#   One indented line per issue: `  - <message>`
#
# Exit codes:
#   0 — valid
#   1 — one or more contract violations (issues printed to stderr)
#   2 — invocation problem (file missing, unreadable, etc.)

set -uo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 <path-to-cli-contract.md>" >&2; exit 2; }
contract="$1"
[ -f "$contract" ] || { echo "Not a file: $contract" >&2; exit 2; }

# All structural checks (frontmatter + body sections + test-surface bullet
# detection) run inside the embedded Python block below — PyYAML for YAML
# parsing, regex for section presence. The bash wrapper only handles arg
# parsing, file-existence, and dispatch. Matches WS4's
# validate-design-spec.sh precedent.

python3 - "$contract" <<'PYEOF'
import sys, re, yaml

path = sys.argv[1]
with open(path, 'r') as f:
    text = f.read()

issues = []

# Frontmatter delimiter check — file must start with --- and have a closing ---
parts = re.split(r'^---\s*$', text, maxsplit=2, flags=re.MULTILINE)
if len(parts) < 3 or parts[0].strip() != '':
    issues.append("missing or malformed frontmatter delimiters (file must start with --- and contain a closing ---)")
    fm_text = ''
    body = text
else:
    fm_text = parts[1]
    body = parts[2]

# Parse frontmatter as YAML
fm = {}
if fm_text:
    try:
        fm = yaml.safe_load(fm_text) or {}
        if not isinstance(fm, dict):
            issues.append(f"frontmatter must be a YAML mapping; got {type(fm).__name__}")
            fm = {}
    except yaml.YAMLError as e:
        issues.append(f"frontmatter is not valid YAML: {e}")

# Required frontmatter fields — present AND non-empty
for field in ('script', 'version', 'invokers', 'related-designs'):
    if field not in fm:
        issues.append(f"missing required frontmatter field: {field}")
    elif fm[field] in (None, '', [], {}):
        issues.append(f"frontmatter field '{field}' is empty (must have a non-empty value)")

# version must be semver-light (major.minor)
if 'version' in fm and fm['version'] not in (None, ''):
    vstr = str(fm['version'])
    if not re.fullmatch(r'\d+\.\d+', vstr):
        issues.append(f"version must be semver-light (major.minor); got '{vstr}'")

# invokers must be a list; every entry must be a mapping with 'type' in the closed enum
ALLOWED_TYPES = {'skill', 'script', 'hook', 'plugin', 'developer'}
if 'invokers' in fm and fm['invokers']:
    if not isinstance(fm['invokers'], list):
        issues.append(f"invokers: must be a YAML list; got {type(fm['invokers']).__name__}")
    else:
        for i, entry in enumerate(fm['invokers']):
            if not isinstance(entry, dict):
                issues.append(f"invokers[{i}]: must be a mapping with a 'type:' field; got {type(entry).__name__}")
                continue
            if 'type' not in entry:
                issues.append(f"invokers[{i}]: missing required 'type:' field")
                continue
            t = entry['type']
            if t not in ALLOWED_TYPES:
                issues.append(f"invokers[{i}]: type '{t}' not in closed enum (expected one of: {', '.join(sorted(ALLOWED_TYPES))})")

# Body section checks
required_sections = ('## Surface', '## Protocol', '## Test surface', '## Versioning')
for section in required_sections:
    if section not in body:
        issues.append(f"missing required body section: {section}")

required_subsections = ('### Arguments', '### Exit codes', '### Side effects')
for sub in required_subsections:
    if sub not in body:
        issues.append(f"missing required sub-section under ## Protocol: {sub}")

# Test surface must contain at least one bullet-list assertion
ts_match = re.search(r'^## Test surface\s*$(.*?)(?=^## |\Z)', body, re.MULTILINE | re.DOTALL)
if ts_match:
    if not re.search(r'^- ', ts_match.group(1), re.MULTILINE):
        issues.append("## Test surface has no bullet-list assertions")

# Report
if not issues:
    sys.exit(0)
print(f"CLI-CONTRACT-DRIFT: {len(issues)} issue(s) in {path}", file=sys.stderr)
for msg in issues:
    print(f"  - {msg}", file=sys.stderr)
sys.exit(1)
PYEOF
