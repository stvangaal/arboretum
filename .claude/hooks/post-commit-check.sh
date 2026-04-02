#!/usr/bin/env bash
# PostToolUse hook for Bash: detect governance drift after git commits.
#
# Fires after Bash commands containing "git commit". Checks the last
# commit for governance issues:
#   - Implementation files not owned by any spec
#   - Definition files changed without contracts.yaml update
#   - Spec files changed without REGISTER.md update
#
# Non-blocking: always exits 0. Output is informational context.
# Layer 2+ only — skip for Layer 0-1 projects.

set -euo pipefail

INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REGISTER="$PROJECT_DIR/docs/REGISTER.md"

# Layer 2+ only
LAYER=$(sed -n 's/^layer:[[:space:]]*\([0-9]\).*/\1/p' "$PROJECT_DIR/.arboretum.yml" 2>/dev/null)
LAYER="${LAYER:-0}"
[ "$LAYER" -lt 2 ] && exit 0

# Only fire on commands containing "git commit"
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Check the tool succeeded (commit actually happened)
STDOUT=$(echo "$INPUT" | jq -r '.tool_result.stdout // empty')
if ! echo "$STDOUT" | grep -qE '^\[|^create mode|file changed|files changed'; then
  exit 0
fi

# Get files from last commit
COMMITTED_FILES=$(git -C "$PROJECT_DIR" diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || true)
[ -z "$COMMITTED_FILES" ] && exit 0

output=""

# Categorize committed files
has_definitions=false
has_specs=false
has_contracts=false
has_register=false
unowned_impl=()

while IFS= read -r file; do
  case "$file" in
    docs/definitions/*) has_definitions=true ;;
    docs/specs/*) has_specs=true ;;
    contracts.yaml) has_contracts=true ;;
    docs/REGISTER.md) has_register=true ;;
    src/*|tests/*|test/*|lib/*)
      # Check ownership in register
      if [ -f "$REGISTER" ]; then
        owned=false
        while IFS='|' read -r _ spec _ owns _; do
          owns=$(echo "$owns" | xargs)
          [ -z "$owns" ] && continue
          for pattern in $(echo "$owns" | tr ',' '\n'); do
            pattern=$(echo "$pattern" | xargs)
            [ -z "$pattern" ] && continue
            [ "$pattern" = "..." ] && continue
            if [[ "$pattern" == *"**"* ]]; then
              dir="${pattern%%\*\*}"
              [[ "$file" == "$dir"* ]] && owned=true && break 2
            elif [ "$file" = "$pattern" ]; then
              owned=true && break 2
            fi
          done
        done < <(grep -E '^\|.*\.spec' "$REGISTER" 2>/dev/null || true)
        [ "$owned" = false ] && unowned_impl+=("$file")
      fi
      ;;
  esac
done <<< "$COMMITTED_FILES"

# Flag drift
if [ ${#unowned_impl[@]} -gt 0 ]; then
  output+="[Drift] Unowned implementation files committed: ${unowned_impl[*]}"$'\n'
  output+="  → Assign to a spec in REGISTER.md."$'\n'
fi

if [ "$has_definitions" = true ] && [ "$has_contracts" = false ]; then
  output+="[Drift] Definition files changed but contracts.yaml was not updated in this commit."$'\n'
  output+="  → Run /sync-contracts if version pins need updating."$'\n'
fi

if [ "$has_specs" = true ] && [ "$has_register" = false ]; then
  output+="[Drift] Spec files changed but REGISTER.md was not updated in this commit."$'\n'
  output+="  → Run scripts/generate-register.sh to resync."$'\n'
fi

if [ -n "$output" ]; then
  echo "$output"
fi

exit 0
