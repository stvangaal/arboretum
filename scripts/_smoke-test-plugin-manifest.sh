#!/usr/bin/env bash
# owner: arboretum-as-plugin
#
# _smoke-test-plugin-manifest.sh — guards .claude-plugin/plugin.json against
# the manifest-validation rules Claude Code enforces at plugin install time.
#
# Regression guard for issue #268: the `hooks` path field shipped as
# "hooks/hooks.json" (no `./` prefix). Claude Code's manifest validator
# rejects bare relative paths ("Validation errors: hooks: Invalid input"),
# which made the published plugin un-installable. check-version-bump.sh only
# checks version fields, so the malformed path passed every gate.
#
# Asserts:
#   1. plugin.json and marketplace.json parse as JSON.
#   2. Every path-valued field (hooks, commands, agents, mcpServers,
#      lspServers, skills, outputStyles) that holds a string — or array of
#      strings — has each path starting with "./". Inline-object values
#      (valid for hooks/mcpServers/lspServers) carry no path and are skipped.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { echo "FAIL: $1" >&2; exit 1; }

PLUGIN_JSON="$ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$ROOT/.claude-plugin/marketplace.json"

for f in "$PLUGIN_JSON" "$MARKETPLACE_JSON"; do
  [ -f "$f" ] || fail "manifest not found: $f"
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" \
    || fail "invalid JSON: $f"
done

# Path-field check on plugin.json — names the offending field+value on failure.
python3 - "$PLUGIN_JSON" <<'PY' || fail "plugin.json has a path field not prefixed with './' (see above)"
import json, sys

manifest = json.load(open(sys.argv[1]))
PATH_FIELDS = ("hooks", "commands", "agents", "mcpServers",
               "lspServers", "skills", "outputStyles")

bad = []
for field in PATH_FIELDS:
    value = manifest.get(field)
    if isinstance(value, str):
        paths = [value]
    elif isinstance(value, list):
        paths = [p for p in value if isinstance(p, str)]
    else:
        paths = []  # absent, or inline object — nothing to validate
    for p in paths:
        if not p.startswith("./"):
            bad.append(f"{field}: {p!r}")

if bad:
    print("path fields must start with './':", file=sys.stderr)
    for b in bad:
        print(f"  {b}", file=sys.stderr)
    sys.exit(1)
PY

echo "PASS: plugin manifest — valid JSON; all path fields './'-prefixed"
