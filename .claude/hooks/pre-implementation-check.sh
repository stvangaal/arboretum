#!/usr/bin/env bash
# PreToolUse hook for Edit/Write: report file ownership before edits.
#
# Looks up the target file in REGISTER.md to show which spec owns it
# and that spec's current status. Warns if the file is unowned.
#
# Non-blocking: always exits 0. Output is informational context.
# Layer 1+ only — skip for Layer 0 projects.

set -euo pipefail

INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REGISTER="$PROJECT_DIR/docs/REGISTER.md"

# Layer 1+ only
LAYER=$(sed -n 's/^layer:[[:space:]]*\([0-9]\).*/\1/p' "$PROJECT_DIR/.arboretum.yml" 2>/dev/null)
LAYER="${LAYER:-0}"
[ "$LAYER" -lt 1 ] && exit 0

# Need a register to check ownership
[ ! -f "$REGISTER" ] && exit 0

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

# Make path relative to project directory
REL_PATH="${FILE_PATH#$PROJECT_DIR/}"

# Skip non-implementation files (governance docs, configs, etc.)
case "$REL_PATH" in
  src/*|tests/*|test/*|lib/*|bin/*|scripts/*) ;;
  *) exit 0 ;;
esac

# Look up ownership in register
# Register format: | spec.spec.md | status | owns | depends |
owner_spec=""
owner_status=""

while IFS='|' read -r _ spec status owns _; do
  spec=$(echo "$spec" | xargs)
  status=$(echo "$status" | xargs)
  owns=$(echo "$owns" | xargs)
  [ -z "$spec" ] || [ -z "$owns" ] && continue

  for pattern in $(echo "$owns" | tr ',' '\n'); do
    pattern=$(echo "$pattern" | xargs)
    [ -z "$pattern" ] && continue
    [ "$pattern" = "..." ] && continue

    if [[ "$pattern" == *"**"* ]]; then
      dir="${pattern%%\*\*}"
      if [[ "$REL_PATH" == "$dir"* ]]; then
        owner_spec="$spec"
        owner_status="$status"
        break 2
      fi
    elif [ "$REL_PATH" = "$pattern" ]; then
      owner_spec="$spec"
      owner_status="$status"
      break 2
    fi
  done
done < <(grep -E '^\|.*\.spec' "$REGISTER" 2>/dev/null || true)

if [ -n "$owner_spec" ]; then
  echo "[Ownership] ${REL_PATH} → ${owner_spec%.spec.md} (status: $owner_status)"
else
  echo "[Ownership] ${REL_PATH} is not owned by any spec."
  echo "  → Assign to a spec in REGISTER.md, or run /health-check to audit."
fi

exit 0
