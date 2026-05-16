#!/usr/bin/env bash
# owner: arboretum-as-plugin
#
# bump-version.sh — increment the arboretum plugin version across all three
# manifest occurrences: plugin.json `version`, marketplace.json `version`,
# and marketplace.json `plugins[0].version`.
#
# Usage: scripts/bump-version.sh <major|minor|patch>
#
# Honours REPO_ROOT (env) for testability; defaults to the repo containing
# this script.

set -euo pipefail

PART="${1:-}"
case "$PART" in
  major|minor|patch) ;;
  *)
    echo "Usage: $0 <major|minor|patch>" >&2
    exit 1
    ;;
esac

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

for f in "$PLUGIN_JSON" "$MARKETPLACE_JSON"; do
  if [ ! -f "$f" ]; then
    echo "bump-version: manifest not found: $f" >&2
    exit 1
  fi
done

python3 - "$PART" "$PLUGIN_JSON" "$MARKETPLACE_JSON" <<'PY'
import json
import sys

part, plugin_path, marketplace_path = sys.argv[1], sys.argv[2], sys.argv[3]


def load(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def dump(path, data):
    # ensure_ascii=False keeps non-ASCII characters (e.g. an em dash in a
    # description) literal rather than re-escaping them to \uXXXX, so the
    # bump produces a version-only diff.
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")


plugin = load(plugin_path)
marketplace = load(marketplace_path)

current = plugin["version"]
occurrences = {
    "plugin.json version": plugin["version"],
    "marketplace.json version": marketplace["version"],
    "marketplace.json plugins[0].version": marketplace["plugins"][0]["version"],
}
disagreeing = {k: v for k, v in occurrences.items() if v != current}
if disagreeing:
    sys.exit(f"bump-version: occurrences disagree before bump: {occurrences}")

try:
    major, minor, patch = (int(x) for x in current.split("."))
except ValueError:
    sys.exit(f"bump-version: version '{current}' is not MAJOR.MINOR.PATCH")

if part == "major":
    major, minor, patch = major + 1, 0, 0
elif part == "minor":
    minor, patch = minor + 1, 0
else:
    patch += 1
new = f"{major}.{minor}.{patch}"

plugin["version"] = new
marketplace["version"] = new
marketplace["plugins"][0]["version"] = new

dump(plugin_path, plugin)
dump(marketplace_path, marketplace)
print(f"{current} -> {new}")
PY
