#!/usr/bin/env bash
# owner: pipeline-state-tracking
# _smoke-test-statusline.sh — Verify .claude/hooks/statusline.sh renders
# the full rich line: <model> | <project>/<branch> | ctx N% | 5h:N% 7d:N%
# | wt:name | [#N /stage], with graceful omission of absent segments and
# control-char scrubbing on string fields (spec §Defense in depth).
set -euo pipefail
[ -n "${BASH_VERSION:-}" ] || { echo "run with bash" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_TMP=$(mktemp -d)
trap 'rm -rf "$ROOT_TMP"' EXIT

fail() { echo "FAIL: $1" >&2; [ -n "${2:-}" ] && printf '%s\n' "$2" >&2; exit 1; }
ok() { echo "PASS: $1"; }

# Build a fixture project at a known path with a known branch. We
# initialize a git repo so the hook's `git rev-parse --abbrev-ref HEAD`
# call resolves to the branch we choose. The fixture also stubs
# scripts/refresh-stage-cache.sh so the hook's background refresh is a
# no-op (we provide the cache file directly when needed).
new_fixture() {
  local name="$1" branch="${2:-main}"
  local fix="$ROOT_TMP/$name"
  mkdir -p "$fix/.claude/hooks" "$fix/scripts" "$fix/.arboretum"
  cp "$REPO_ROOT/.claude/hooks/statusline.sh" "$fix/.claude/hooks/"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$fix/scripts/refresh-stage-cache.sh"
  chmod +x "$fix/scripts/refresh-stage-cache.sh"
  # `git init -b` is git 2.28+; use init + checkout for portability,
  # matching the convention in the other smoke tests.
  git -C "$fix" init -q
  git -C "$fix" config user.email f@e.com
  git -C "$fix" config user.name f
  git -C "$fix" config commit.gpgsign false
  git -C "$fix" commit -q --allow-empty -m seed
  git -C "$fix" checkout -q -b "$branch" 2>/dev/null || git -C "$fix" branch -m "$branch"
  echo "$fix"
}

run_hook() {
  local fix="$1" stdin="$2"
  printf '%s' "$stdin" | CLAUDE_PROJECT_DIR="$fix" bash "$fix/.claude/hooks/statusline.sh"
}

# ── Case 1: full line — all segments present ─────────────────────────
fix=$(new_fixture proj_full ember-thrush)
cat > "$fix/.arboretum/active-stage-cache.json" <<'JSON'
{"issue": 307, "stage": "/build", "ts": "2026-05-23T14:05:00Z"}
JSON
input='{"model":{"display_name":"Opus 4.7"},"workspace":{"project_dir":"'$fix'","git_worktree":"ember-thrush"},"context_window":{"used_percentage":42.7},"rate_limits":{"five_hour":{"used_percentage":24.5},"seven_day":{"used_percentage":27.1}}}'
out=$(run_hook "$fix" "$input")
expected="Opus 4.7  |  proj_full/ember-thrush  |  ctx 42%  |  5h:24% 7d:27%  |  wt:ember-thrush  |  [#307 /build]"
[ "$out" = "$expected" ] || fail "case 1 — full line shape" "got:      $out
expected: $expected"
ok "case 1 — full line shape with all segments"

# ── Case 2: chip omitted when cache absent ───────────────────────────
fix=$(new_fixture proj_nochip main)
input='{"model":{"display_name":"Opus 4.7"},"workspace":{"project_dir":"'$fix'"},"context_window":{"used_percentage":8}}'
out=$(run_hook "$fix" "$input")
echo "$out" | grep -q '\[#' && fail "case 2 — chip should be absent without cache" "$out"
[ "$out" = "Opus 4.7  |  proj_nochip/main  |  ctx 8%" ] \
  || fail "case 2 — line shape without chip" "got: $out"
ok "case 2 — chip omitted when active-stage-cache absent"

# ── Case 3: 5h/7d segment omitted when either window absent ──────────
fix=$(new_fixture proj_partial_rl main)
input='{"model":{"display_name":"M"},"workspace":{"project_dir":"'$fix'"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":24}}}'
out=$(run_hook "$fix" "$input")
echo "$out" | grep -qE '5h:|7d:' \
  && fail "case 3 — 5h:/7d: segment must be all-or-nothing" "$out"
[ "$out" = "M  |  proj_partial_rl/main  |  ctx 50%" ] \
  || fail "case 3 — line shape with partial rate-limit data" "got: $out"
ok "case 3 — 5h:/7d: segment omitted when either window absent"

# ── Case 4: ctx segment omitted when used_percentage is null ─────────
fix=$(new_fixture proj_noctxseg main)
input='{"model":{"display_name":"M"},"workspace":{"project_dir":"'$fix'"},"context_window":{"used_percentage":null}}'
out=$(run_hook "$fix" "$input")
echo "$out" | grep -qE '(^|\| )ctx [0-9]' \
  && fail "case 4 — ctx segment should be absent when null" "$out"
[ "$out" = "M  |  proj_noctxseg/main" ] \
  || fail "case 4 — line shape without ctx" "got: $out"
ok "case 4 — ctx segment omitted when context_window.used_percentage is null"

# ── Case 5: wt: segment omitted in main worktree (no git_worktree) ───
fix=$(new_fixture proj_mainwt main)
input='{"model":{"display_name":"M"},"workspace":{"project_dir":"'$fix'"},"context_window":{"used_percentage":10}}'
out=$(run_hook "$fix" "$input")
echo "$out" | grep -q 'wt:' && fail "case 5 — wt: should be absent in main worktree" "$out"
ok "case 5 — wt: segment omitted in main worktree"

# ── Case 6: control characters scrubbed (defense in depth) ───────────
fix=$(new_fixture proj_scrub main)
# Build the input via python so we get real ESC (0x1b) bytes, not
# literal backslash-escape sequences. The branch can't easily carry
# control chars (git rejects them), so we test model + git_worktree.
input=$(python3 -c 'import json; print(json.dumps({"model":{"display_name":"Opus\x1b[31mEVIL\x1b[0m"},"workspace":{"project_dir":"'"$fix"'","git_worktree":"wt\x1b[5mBLINK\x1b[0m"},"context_window":{"used_percentage":1}}))')
out=$(run_hook "$fix" "$input")
# After scrubbing, the ESC bytes (0x1b) are gone; the literal brackets
# and letters remain visible but harmless.
echo "$out" | LC_ALL=C grep -q $'\x1b' \
  && fail "case 6 — ESC byte must be scrubbed from output" "$(printf '%s' "$out" | od -c | head)"
# Confirm the harmless residue around the scrubbed control bytes is
# still rendered (proves scrub, not drop) — the [31m / [0m / [5m
# literals remain because their `[`, digits, `m` are printable chars.
echo "$out" | grep -q 'Opus\[31mEVIL\[0m' \
  || fail "case 6 — scrubbed model should preserve printable residue" "$out"
echo "$out" | grep -q 'wt:wt\[5mBLINK\[0m' \
  || fail "case 6 — scrubbed worktree should preserve printable residue" "$out"
ok "case 6 — control characters scrubbed from string fields"

echo
echo "statusline smoke tests passed."
exit 0
