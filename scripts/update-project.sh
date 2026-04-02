#!/usr/bin/env bash
# update-project.sh — Update framework-owned files in a spawned project
#
# Requires bash 4+ (uses associative arrays).
#
# Usage:
#   arboretum update          (run from within a spawned project)
#
# Compares upstream arboretum files against the local project using a
# manifest-based three-way merge:
#
#   upstream unchanged + local unchanged → skip
#   upstream unchanged + local modified  → skip (preserve local edits)
#   upstream changed   + local unchanged → update
#   upstream changed   + local modified  → conflict (backup + update + warn)
#
# New upstream files (not yet in the project) are installed.
# Layer filtering from .arboretum.yml is respected.

set -euo pipefail

# Guard: require bash 4+
if [ -z "${BASH_VERSION:-}" ]; then
  echo "Error: this script requires bash. Run with: bash $0" >&2
  exit 1
fi

# ── Portable SHA-256 ────────────────────────────────────────────────

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    echo "Error: neither sha256sum nor shasum found" >&2
    exit 1
  fi
}

# ── Resolve arboretum source ───────────────────────────────────────

PROJECT_DIR="$(pwd)"
MANIFEST="$PROJECT_DIR/.arboretum.manifest"
CONFIG="$PROJECT_DIR/.arboretum.yml"

if [ ! -f "$CONFIG" ]; then
  echo "Error: .arboretum.yml not found. Is this an arboretum project?"
  exit 1
fi

# Read layer
MAX_LAYER=$(sed -n 's/^layer:[[:space:]]*\([0-9]*\).*/\1/p' "$CONFIG")
MAX_LAYER="${MAX_LAYER:-0}"

# Resolve arboretum home: ARBORETUM_HOME env var → arboretum_home in config
if [ -n "${ARBORETUM_HOME:-}" ]; then
  ARBORETUM_DIR="$ARBORETUM_HOME"
elif grep -q '^arboretum_home:' "$CONFIG" 2>/dev/null; then
  ARBORETUM_DIR=$(sed -n 's/^arboretum_home:[[:space:]]*//p' "$CONFIG")
else
  echo "Error: cannot find arboretum source."
  echo "Set ARBORETUM_HOME or add arboretum_home: to .arboretum.yml"
  exit 1
fi

if [ ! -d "$ARBORETUM_DIR" ] || [ ! -f "$ARBORETUM_DIR/bin/arboretum" ]; then
  echo "Error: arboretum source not found at: $ARBORETUM_DIR"
  exit 1
fi

ARBORETUM_DIR="$(realpath "$ARBORETUM_DIR")"

# Source directories
TEMPLATES_DIR="$ARBORETUM_DIR/docs/templates"
PRINCIPLES_FILE="$ARBORETUM_DIR/PRINCIPLES.md"
WORKFLOWS_DIR="$ARBORETUM_DIR/workflows"
HOOKS_DIR="$ARBORETUM_DIR/.claude"
GITHOOKS_DIR="$ARBORETUM_DIR/.githooks"
SKILLS_DIR="$ARBORETUM_DIR/.claude/skills"

# ── Read existing manifest ─────────────────────────────────────────

declare -A MANIFEST_CHECKSUMS
FIRST_RUN=false

if [ -f "$MANIFEST" ]; then
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    checksum="${line%%  *}"
    filepath="${line#*  }"
    MANIFEST_CHECKSUMS["$filepath"]="$checksum"
  done < "$MANIFEST"
else
  FIRST_RUN=true
fi

# ── Counters ───────────────────────────────────────────────────────

COUNT_UPDATED=0
COUNT_NEW=0
COUNT_UNCHANGED=0
COUNT_LOCAL_MOD=0
COUNT_CONFLICT=0

# New manifest entries
declare -A NEW_MANIFEST

# ── Sync logic ─────────────────────────────────────────────────────

# sync_file <upstream-path> <relative-path>
#
# Applies the three-way merge for a single file.
sync_file() {
  local upstream="$1"
  local relpath="$2"
  local target="$PROJECT_DIR/$relpath"

  local upstream_sum
  upstream_sum=$(sha256_file "$upstream")

  # Record in new manifest regardless of outcome
  NEW_MANIFEST["$relpath"]="$upstream_sum"

  if [ ! -f "$target" ]; then
    # New file — install it
    mkdir -p "$(dirname "$target")"
    cp "$upstream" "$target"
    echo "  new:      $relpath"
    COUNT_NEW=$((COUNT_NEW + 1))
    return
  fi

  local current_sum
  current_sum=$(sha256_file "$target")

  local manifest_sum="${MANIFEST_CHECKSUMS[$relpath]:-}"

  if [ "$upstream_sum" = "$current_sum" ]; then
    # Already matches upstream
    COUNT_UNCHANGED=$((COUNT_UNCHANGED + 1))
    return
  fi

  if [ -z "$manifest_sum" ]; then
    # No manifest entry (first run or new file added to manifest tracking)
    # Treat as conflict — we can't tell who changed it
    cp "$target" "$target.bak"
    cp "$upstream" "$target"
    echo "  conflict: $relpath"
    echo "            → backed up to $relpath.bak"
    COUNT_CONFLICT=$((COUNT_CONFLICT + 1))
    return
  fi

  if [ "$upstream_sum" = "$manifest_sum" ]; then
    # Upstream unchanged, local modified — preserve local
    echo "  skipped:  $relpath (locally modified)"
    # Record current checksum so we don't re-flag next time
    NEW_MANIFEST["$relpath"]="$manifest_sum"
    COUNT_LOCAL_MOD=$((COUNT_LOCAL_MOD + 1))
    return
  fi

  if [ "$current_sum" = "$manifest_sum" ]; then
    # Upstream changed, local unchanged — safe to update
    cp "$upstream" "$target"
    echo "  updated:  $relpath"
    COUNT_UPDATED=$((COUNT_UPDATED + 1))
    return
  fi

  # Both changed — conflict
  cp "$target" "$target.bak"
  cp "$upstream" "$target"
  echo "  conflict: $relpath"
  echo "            → backed up to $relpath.bak"
  COUNT_CONFLICT=$((COUNT_CONFLICT + 1))
}

# ── Walk framework-owned files ─────────────────────────────────────

echo "arboretum update (layer: $MAX_LAYER, source: $ARBORETUM_DIR)"
echo ""

if [ "$FIRST_RUN" = true ]; then
  echo "  Note: first update — generating manifest. Files that differ from"
  echo "  upstream have been backed up to .bak files."
  echo ""
fi

# 1. PRINCIPLES.md
sync_file "$PRINCIPLES_FILE" "PRINCIPLES.md"

# 2. Workflows
for wf in "$WORKFLOWS_DIR"/*.md; do
  [ ! -f "$wf" ] && continue
  sync_file "$wf" "workflows/$(basename "$wf")"
done

# 3. Templates
for tmpl in "$TEMPLATES_DIR"/*; do
  [ ! -f "$tmpl" ] && continue
  sync_file "$tmpl" "docs/templates/$(basename "$tmpl")"
done

# 4. Hooks (layer-filtered)
sync_file "$HOOKS_DIR/hooks/session-start.sh" ".claude/hooks/session-start.sh"

if [ "$MAX_LAYER" -ge 1 ]; then
  sync_file "$HOOKS_DIR/hooks/pre-implementation-check.sh" ".claude/hooks/pre-implementation-check.sh"
fi

if [ "$MAX_LAYER" -ge 2 ]; then
  sync_file "$HOOKS_DIR/hooks/pre-commit-branch-check.sh" ".claude/hooks/pre-commit-branch-check.sh"
  sync_file "$HOOKS_DIR/hooks/post-commit-check.sh" ".claude/hooks/post-commit-check.sh"
fi

# Ensure hooks are executable
chmod +x "$PROJECT_DIR/.claude/hooks"/*.sh 2>/dev/null || true

# 5. Git hooks
for hook in "$GITHOOKS_DIR"/*; do
  [ ! -f "$hook" ] && continue
  sync_file "$hook" ".githooks/$(basename "$hook")"
done
chmod +x "$PROJECT_DIR/.githooks"/* 2>/dev/null || true

# 6. Skills (layer-filtered, skip dev-* and _archived)
if [ -d "$SKILLS_DIR" ]; then
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ ! -d "$skill_dir" ] && continue
    skill_name="$(basename "$skill_dir")"

    # Skip dev-prefixed and archived skills
    if [[ "$skill_name" == dev-* || "$skill_name" == _archived ]]; then
      continue
    fi

    if [ -f "$skill_dir/SKILL.md" ]; then
      # Extract layer from SKILL.md frontmatter
      skill_layer=$(sed -n '/^---$/,/^---$/{ s/^layer:[[:space:]]*\([0-9]\).*/\1/p; }' "$skill_dir/SKILL.md")
      skill_layer="${skill_layer:-0}"
      if [ "$skill_layer" -gt "$MAX_LAYER" ]; then
        continue
      fi
      mkdir -p "$PROJECT_DIR/.claude/skills/$skill_name"
      sync_file "$skill_dir/SKILL.md" ".claude/skills/$skill_name/SKILL.md"
    fi
  done
fi

# ── Write updated manifest ─────────────────────────────────────────

{
  echo "# .arboretum.manifest — auto-generated by arboretum update"
  echo "# sha256  relative-path"
  for filepath in $(printf '%s\n' "${!NEW_MANIFEST[@]}" | sort); do
    echo "${NEW_MANIFEST[$filepath]}  $filepath"
  done
} > "$MANIFEST"

# ── Summary ─────────────────────────────────────────────────────────

echo ""
echo "Summary: $COUNT_UPDATED updated, $COUNT_NEW new, $COUNT_UNCHANGED unchanged, $COUNT_LOCAL_MOD locally modified, $COUNT_CONFLICT conflict(s)"

if [ "$COUNT_CONFLICT" -gt 0 ]; then
  echo ""
  echo "Review .bak files to reconcile conflicts with your local changes."
fi
