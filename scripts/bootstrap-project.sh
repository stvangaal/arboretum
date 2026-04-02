#!/usr/bin/env bash
# bootstrap-project.sh — Initialize a new spec-driven project
#
# Usage:
#   ./bootstrap-project.sh <target-directory> [project-name]
#
# Creates the full directory structure, copies templates, installs hooks,
# and produces a ready-to-use project skeleton. If project-name is omitted,
# the directory name is used.
#
# This script is idempotent — it will not overwrite existing files.

set -euo pipefail

# ── Args ─────────────────────────────────────────────────────────────

usage() {
  echo "Usage: $0 [--layer N] <target-directory> [project-name]"
  echo ""
  echo "Creates a spec-driven project structure in the target directory."
  echo "If project-name is omitted, the directory basename is used."
  echo ""
  echo "Options:"
  echo "  --layer N   Only copy skills with layer <= N (default: 99, copies all)"
  exit 1
}

# Parse options
MAX_LAYER=99
LAYER_EXPLICIT=false
while [ $# -gt 0 ]; do
  case "$1" in
    --layer)
      [ $# -lt 2 ] && usage
      MAX_LAYER="$2"
      LAYER_EXPLICIT=true
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      break
      ;;
  esac
done

if [ $# -lt 1 ]; then
  usage
fi

mkdir -p "$1"
TARGET_DIR="$(realpath "$1")"
PROJECT_NAME="${2:-$(basename "$TARGET_DIR")}"

# Find the script's own directory to locate templates
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Arboretum repo root (parent of scripts/)
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
# Templates are at ../docs/templates/ relative to this script
TEMPLATES_DIR="$(realpath "$SCRIPT_DIR/../docs/templates")"
# Principles are at ../PRINCIPLES.md
PRINCIPLES_FILE="$(realpath "$SCRIPT_DIR/../PRINCIPLES.md")"
# Workflows are at ../workflows/
WORKFLOWS_DIR="$(realpath "$SCRIPT_DIR/../workflows")"
# Hooks are at ../.claude/
HOOKS_DIR="$(realpath "$SCRIPT_DIR/../.claude")"
# Git hooks are at ../.githooks/
GITHOOKS_DIR="$(realpath "$SCRIPT_DIR/../.githooks")"
# Skills are at ../.claude/skills/
SKILLS_DIR="$(realpath "$SCRIPT_DIR/../.claude/skills")"

# Verify source files exist
for f in "$TEMPLATES_DIR/spec.md" "$PRINCIPLES_FILE" "$WORKFLOWS_DIR/README.md"; do
  if [ ! -f "$f" ]; then
    echo "Error: source file not found: $f"
    echo "Run this script from the arboretum project directory."
    exit 1
  fi
done

# ── Helper ───────────────────────────────────────────────────────────

# Portable SHA-256
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

# Track framework-owned files for manifest generation
INSTALLED_FILES=()

copy_if_missing() {
  local src="$1"
  local dst="$2"
  if [ -f "$dst" ]; then
    echo "  exists: $(basename "$dst")"
  else
    cp "$src" "$dst"
    echo "  created: $(basename "$dst")"
  fi
  # Track relative path for manifest (framework-owned files only)
  local relpath="${dst#$TARGET_DIR/}"
  INSTALLED_FILES+=("$relpath")
}

mkdir_if_missing() {
  local dir="$1"
  if [ -d "$dir" ]; then
    echo "  exists: $dir"
  else
    mkdir -p "$dir"
    echo "  created: $dir"
  fi
}

# ── Create directory structure ───────────────────────────────────────

echo "Bootstrapping spec-driven project: $PROJECT_NAME"
echo "Target: $TARGET_DIR"
echo ""

echo "Creating directory structure..."
mkdir_if_missing "$TARGET_DIR"
mkdir_if_missing "$TARGET_DIR/docs"
mkdir_if_missing "$TARGET_DIR/docs/definitions"
mkdir_if_missing "$TARGET_DIR/docs/specs"
mkdir_if_missing "$TARGET_DIR/docs/reference"
mkdir_if_missing "$TARGET_DIR/docs/plans"
mkdir_if_missing "$TARGET_DIR/docs/templates"
mkdir_if_missing "$TARGET_DIR/workflows"
mkdir_if_missing "$TARGET_DIR/.claude"
mkdir_if_missing "$TARGET_DIR/.claude/hooks"

# ── Copy principles and workflows ────────────────────────────────────

echo ""
echo "Copying principles and workflows..."
copy_if_missing "$PRINCIPLES_FILE" "$TARGET_DIR/PRINCIPLES.md"
for wf in "$WORKFLOWS_DIR"/*.md; do
  basename_wf="$(basename "$wf")"
  copy_if_missing "$wf" "$TARGET_DIR/workflows/$basename_wf"
done

# ── Copy templates ───────────────────────────────────────────────────

echo ""
echo "Copying templates..."
for tmpl in "$TEMPLATES_DIR"/*; do
  basename_tmpl="$(basename "$tmpl")"
  copy_if_missing "$tmpl" "$TARGET_DIR/docs/templates/$basename_tmpl"
done

# ── Copy reserved spec templates into docs/specs/ ────────────────────

echo ""
echo "Copying reserved specs..."
for reserved in test-infrastructure.spec.md project-infrastructure.spec.md; do
  if [ -f "$TEMPLATES_DIR/$reserved" ]; then
    copy_if_missing "$TEMPLATES_DIR/$reserved" "$TARGET_DIR/docs/specs/$reserved"
  fi
done

# ── Copy hooks ───────────────────────────────────────────────────────

echo ""
echo "Copying hooks..."
# Session-start hook: always (Layer 0+)
copy_if_missing "$HOOKS_DIR/hooks/session-start.sh" "$TARGET_DIR/.claude/hooks/session-start.sh"
# Pre-implementation check: Layer 1+ (ownership awareness on edits)
if [ "$MAX_LAYER" -ge 1 ]; then
  copy_if_missing "$HOOKS_DIR/hooks/pre-implementation-check.sh" "$TARGET_DIR/.claude/hooks/pre-implementation-check.sh"
fi
# Pre-commit branch check: Layer 2+ only
if [ "$MAX_LAYER" -ge 2 ]; then
  copy_if_missing "$HOOKS_DIR/hooks/pre-commit-branch-check.sh" "$TARGET_DIR/.claude/hooks/pre-commit-branch-check.sh"
fi
# Post-commit drift check: Layer 2+ only
if [ "$MAX_LAYER" -ge 2 ]; then
  copy_if_missing "$HOOKS_DIR/hooks/post-commit-check.sh" "$TARGET_DIR/.claude/hooks/post-commit-check.sh"
fi
chmod +x "$TARGET_DIR/.claude/hooks"/*.sh 2>/dev/null || true

# Generate settings.json based on layer
if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
  echo "  exists: settings.json"
else
  if [ "$MAX_LAYER" -ge 2 ]; then
    # Full settings: all hooks
    copy_if_missing "$HOOKS_DIR/settings.json" "$TARGET_DIR/.claude/settings.json"
  elif [ "$MAX_LAYER" -ge 1 ]; then
    # Layer 1: session-start + pre-implementation check
    cat > "$TARGET_DIR/.claude/settings.json" << 'SETTINGS'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-implementation-check.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
    echo "  created: settings.json"
  else
    # Layer 0: session-start only
    cat > "$TARGET_DIR/.claude/settings.json" << 'SETTINGS'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
    echo "  created: settings.json"
  fi
fi

# ── Copy git hooks ────────────────────────────────────────────────────

echo ""
echo "Copying git hooks..."
mkdir_if_missing "$TARGET_DIR/.githooks"
for hook in "$GITHOOKS_DIR"/*; do
  basename_hook="$(basename "$hook")"
  copy_if_missing "$hook" "$TARGET_DIR/.githooks/$basename_hook"
done
chmod +x "$TARGET_DIR/.githooks"/* 2>/dev/null || true

# ── Copy skills ──────────────────────────────────────────────────────

echo ""
echo "Copying skills..."
if [ -d "$SKILLS_DIR" ]; then
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ ! -d "$skill_dir" ] && continue
    skill_name="$(basename "$skill_dir")"
    # Skip dev-prefixed and archived skills
    if [[ "$skill_name" == dev-* || "$skill_name" == _archived ]]; then
      echo "  skipped ($skill_name)"
      continue
    fi
    # Only copy if SKILL.md exists
    if [ -f "$skill_dir/SKILL.md" ]; then
      # Extract layer from SKILL.md frontmatter
      skill_layer=$(sed -n '/^---$/,/^---$/{ s/^layer:[[:space:]]*\([0-9]\).*/\1/p; }' "$skill_dir/SKILL.md")
      skill_layer="${skill_layer:-0}"
      if [ "$skill_layer" -gt "$MAX_LAYER" ]; then
        echo "  skipped (layer $skill_layer > $MAX_LAYER): $skill_name"
        continue
      fi
      mkdir_if_missing "$TARGET_DIR/.claude/skills/$skill_name"
      copy_if_missing "$skill_dir/SKILL.md" "$TARGET_DIR/.claude/skills/$skill_name/SKILL.md"
    fi
  done
else
  echo "  no skills directory found — skipping"
fi

# ── Create CLAUDE.md from template ───────────────────────────────────

echo ""
echo "Creating CLAUDE.md..."
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  echo "  exists: CLAUDE.md"
else
  sed "s/# CLAUDE.md/# CLAUDE.md — $PROJECT_NAME/" \
    "$TEMPLATES_DIR/CLAUDE.md" > "$TARGET_DIR/CLAUDE.md"
  echo "  created: CLAUDE.md"
fi

# ── Create empty contracts.yaml ──────────────────────────────────────

echo ""
echo "Creating contracts.yaml..."
copy_if_missing "$TEMPLATES_DIR/contracts.yaml" "$TARGET_DIR/contracts.yaml"

# ── Create .publishignore ─────────────────────────────────────────────

echo ""
echo "Creating .publishignore..."
copy_if_missing "$TEMPLATES_DIR/publishignore" "$TARGET_DIR/.publishignore"

# ── Create .arboretum.yml ──────────────────────────────────────────────

echo ""
echo "Creating .arboretum.yml..."
if [ -f "$TARGET_DIR/.arboretum.yml" ]; then
  echo "  exists: .arboretum.yml"
else
  # Prefer remote URL so .arboretum.yml is portable across machines
  ARBORETUM_SOURCE="$REPO_ROOT"
  if remote_url=$(cd "$REPO_ROOT" && git remote get-url origin 2>/dev/null); then
    ARBORETUM_SOURCE="$remote_url"
  fi
  cat > "$TARGET_DIR/.arboretum.yml" << ARBORETUM
# Arboretum project configuration
# layer: 0 = foundation, 1 = structure, 2 = governance
layer: $( [ "$LAYER_EXPLICIT" = true ] && echo "$MAX_LAYER" || echo "0" )
arboretum_home: $ARBORETUM_SOURCE
ARBORETUM
  echo "  created: .arboretum.yml"
fi

# ── Generate manifest ────────────────────────────────────────────────

echo ""
echo "Generating manifest..."
{
  echo "# .arboretum.manifest — auto-generated by arboretum bootstrap"
  echo "# sha256  relative-path"
  for relpath in "${INSTALLED_FILES[@]}"; do
    target_file="$TARGET_DIR/$relpath"
    if [ -f "$target_file" ]; then
      checksum=$(sha256_file "$target_file")
      echo "$checksum  $relpath"
    fi
  done
} > "$TARGET_DIR/.arboretum.manifest"
echo "  created: .arboretum.manifest (${#INSTALLED_FILES[@]} files tracked)"

# ── Initialize git if needed ─────────────────────────────────────────

echo ""
if [ -d "$TARGET_DIR/.git" ]; then
  echo "Git repo already exists."
else
  echo "Initializing git repository..."
  (cd "$TARGET_DIR" && git init -q)
  echo "  initialized."
fi

# Configure git to use .githooks directory
echo ""
echo "Configuring git hooks path..."
current_hooks_path=$(cd "$TARGET_DIR" && git config core.hooksPath 2>/dev/null || true)
if [ "$current_hooks_path" = ".githooks" ]; then
  echo "  already set: core.hooksPath = .githooks"
else
  (cd "$TARGET_DIR" && git config core.hooksPath .githooks)
  echo "  configured: core.hooksPath = .githooks"
fi

# ── Summary ──────────────────────────────────────────────────────────

echo ""
echo "Done. Project structure:"
echo ""
echo "  $TARGET_DIR/"
echo "  ├── CLAUDE.md                    # AI entry point"
echo "  ├── PRINCIPLES.md                # Seven principles"
echo "  ├── contracts.yaml               # Version pins (empty)"
echo "  ├── .publishignore               # Public repo exclusions"
echo "  ├── .arboretum.yml               # Project config"
echo "  ├── workflows/                   # Workflow definitions"
echo "  ├── .githooks/                   # Git hooks (secrets, validation)"
echo "  ├── .claude/"
echo "  │   ├── settings.json            # Hook configuration"
echo "  │   ├── hooks/                   # Automation hooks"
echo "  │   └── skills/                  # Framework skills"
echo "  └── docs/"
echo "      ├── templates/               # Starter templates"
echo "      ├── definitions/             # (empty — create from architecture)"
echo "      ├── specs/                   # Reserved specs"
echo "      ├── reference/               # (empty — add domain knowledge)"
echo "      └── plans/                   # (empty — add during implementation)"
echo ""
echo "Next steps:"
echo "  1. Edit CLAUDE.md with your project overview"
echo "  2. Run /architect to design your architecture"
echo "  3. Use /start to begin your first feature"
