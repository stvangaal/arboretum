#!/usr/bin/env bash
# owner: pipeline-contracts-template
# _smoke-test-contract-roadmap-build-orientation.sh — Contract test for
# docs/contracts/roadmap-build-orientation.cli-contract.md. Asserts CLI-1..CLI-3
# against scripts/roadmap/build-orientation.sh.
#
# build-orientation.sh has no file-driven test mode (unlike render-run.sh), so
# we exercise the two gh-independent invariants directly:
#   CLI-1: config-absent path — run from a tmpdir with no roadmap.config.yaml;
#          assert exit 0 + empty stdout.
#   CLI-2: no-gh nag passthrough — present config but PATH-shadowed gh stub
#          that reports auth failure; assert exit 0 and nag output may be
#          present but orientation header is absent. (gh-independence is the
#          key invariant; nag.sh output depends on pulse-file state, so we only
#          assert the absence of the orientation header, not a specific nag line.)
#   CLI-3: orientation block format check skipped (requires live gh + a real
#          repo with issues); documented here as N/A — requires live gh.
#
# No network calls. No gh. trap ... EXIT for cleanup.
# Picked up automatically by ci-checks.sh's === Smoke tests === loop.
set -uo pipefail
[ -n "${BASH_VERSION:-}" ] || { echo "Error: requires bash. Run: bash $0" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/roadmap/build-orientation.sh"
[ -f "$SCRIPT" ] || { echo "FAIL: $SCRIPT not found" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail=0
pass() { echo "PASS: $1"; }
fail_case() { echo "FAIL: $1" >&2; [ -n "${2:-}" ] && echo "  $2" >&2; fail=1; }

# ── CLI-1: config-absent → exit 0 + empty stdout ──────────────────────────────
# Run from a temp directory that is not a git repo and has no roadmap.config.yaml.
# roadmap_config_path() will find nothing → script exits 0 with no output.
stdout_absent=$(cd "$TMP" && bash "$SCRIPT" 2>/dev/null); rc_absent=$?

if [ "$rc_absent" = 0 ] && [ -z "$stdout_absent" ]; then
  pass "CLI-1: config-absent exits 0 with empty stdout"
else
  fail_case "CLI-1: config-absent exits 0 with empty stdout" \
    "rc=$rc_absent stdout=[${stdout_absent}]"
fi

# ── CLI-2: config-present + no gh → nag passthrough; orientation header absent ─
# Create a minimal roadmap.config.yaml in a temp project dir so the config guard
# passes. Shadow gh with a stub that exits non-zero on 'auth status' so the gh
# guard fires. The orientation header ([Roadmap] ...) must NOT appear in stdout.
# We do NOT assert a specific nag line because nag.sh depends on pulse-file state
# (pulse file may or may not exist; strategic-review-due fires only when
# time_horizon_end is set). We assert only: exit 0 AND no [Roadmap] header.
PROJECT_DIR="$TMP/project"
mkdir -p "$PROJECT_DIR"
printf 'repo: placeholder\n' > "$PROJECT_DIR/roadmap.config.yaml"

# Fake git so roadmap_project_root returns our tmpdir (not the real repo).
FAKE_GIT_DIR="$TMP/fake-bin"
mkdir -p "$FAKE_GIT_DIR"
# Fake git: 'git rev-parse --show-toplevel' → project dir; all else pass-through.
cat > "$FAKE_GIT_DIR/git" <<GITEOF
#!/usr/bin/env bash
if [ "\${1:-}" = "rev-parse" ] && [ "\${2:-}" = "--show-toplevel" ]; then
  echo "$PROJECT_DIR"
  exit 0
fi
exec /usr/bin/git "\$@"
GITEOF
chmod +x "$FAKE_GIT_DIR/git"

# Fake gh: 'gh auth status' exits 1 to trigger the no-gh path; all else fail.
cat > "$FAKE_GIT_DIR/gh" <<GHEOF
#!/usr/bin/env bash
if [ "\${1:-}" = "auth" ] && [ "\${2:-}" = "status" ]; then
  exit 1
fi
exit 1
GHEOF
chmod +x "$FAKE_GIT_DIR/gh"

stdout_nogh=$(cd "$PROJECT_DIR" && PATH="$FAKE_GIT_DIR:$PATH" bash "$SCRIPT" 2>/dev/null); rc_nogh=$?

if [ "$rc_nogh" = 0 ] && ! printf '%s\n' "$stdout_nogh" | grep -q '^\[Roadmap\]'; then
  pass "CLI-2: config-present + no-gh exits 0, no orientation header in stdout"
else
  fail_case "CLI-2: config-present + no-gh exits 0, no orientation header in stdout" \
    "rc=$rc_nogh stdout=[${stdout_nogh}]"
fi

# ── CLI-3: orientation block format ───────────────────────────────────────────
# N/A — requires live gh and a real repo with issues. Asserted manually; omitted
# from automated smoke test to avoid network dependency.
echo "SKIP: CLI-3 (requires live gh)"

if [ "$fail" = 0 ]; then
  echo "SMOKE TEST PASSED"
  exit 0
else
  echo "SMOKE TEST FAILED" >&2
  exit 1
fi
