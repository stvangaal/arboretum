#!/usr/bin/env bash
# owner: workflow-management
# _smoke-test-skill-prose-v2.sh — Prose-regression checks for the v2-only
# sections of /start and /design. These are structural invariants —
# accidental edits that break the v2 routing will be caught here.
set -euo pipefail
[ -n "${BASH_VERSION:-}" ] || { echo "run with bash" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

fail() { echo "FAIL: $1" >&2; [ -n "${2:-}" ] && printf '%s\n' "$2" >&2; exit 1; }
ok() { echo "PASS: $1"; }

START="skills/start/SKILL.md"
DESIGN="skills/design/SKILL.md"

# /start invariants

# Case 1: Step 0 (flag read) exists in /start
grep -q "^### 0\. Read the pipeline\.workflow flag" "$START" \
  || fail "case 1 — /start Step 0 (flag read) missing"
ok "case 1 — /start Step 0 present"

# Case 2: Step 4-v2 (agent-target triage) exists in /start
grep -q "^### 4-v2\. Agent-target triage" "$START" \
  || fail "case 2 — /start Step 4-v2 missing"
ok "case 2 — /start Step 4-v2 present"

# Case 3: /start v2 everything-else routes to /design (PR2's central edit)
grep -q "Hand off to \`/design\` with the issue number" "$START" \
  || fail "case 3 — /start v2 everything-else does not invoke /design"
ok "case 3 — /start v2 everything-else routes to /design"

# Case 4: /start no longer falls through to v1 Path A/B under v2
if grep -q "For PR1 of WS2, continue with Step 4 (Path A/B determination)" "$START"; then
  fail "case 4 — /start v2 everything-else still has the PR1 fallback prose"
fi
ok "case 4 — /start v2 everything-else fallback removed"

# /design invariants

# Case 5: /design Step 0 (flag read) exists
grep -q "^### Step 0: Read the pipeline\.workflow flag" "$DESIGN" \
  || fail "case 5 — /design Step 0 (flag read) missing"
ok "case 5 — /design Step 0 present"

# Case 6: /design Step 0-v1 exists (the renamed v1-only path-selection step)
grep -q "^### Step 0-v1: Determine path — A or B?" "$DESIGN" \
  || fail "case 6 — /design Step 0-v1 missing (rename of old Step 0)"
ok "case 6 — /design Step 0-v1 present"

# Case 7: /design Section v2 exists
grep -q "^## Section v2: Unified design phase" "$DESIGN" \
  || fail "case 7 — /design Section v2 missing"
ok "case 7 — /design Section v2 present"

# Case 8: /design Section v2 has all 5 sub-sections (v2.1 through v2.5)
SUBS=$(grep -c "^### v2\." "$DESIGN")
[ "$SUBS" = "5" ] || fail "case 8 — /design Section v2 expected 5 sub-sections, found $SUBS"
ok "case 8 — /design Section v2 has 5 sub-sections (v2.1-v2.5)"

# Case 9: /design Section v2 names all 4 Branch 1 modes (D5).
# Extract just Section v2 (delimited by `## Section v2:` and the next `## ` heading)
# so v1 occurrences of mode words don't false-pass the check.
SECTION_V2=$(awk '
  /^## Section v2:/ { flag = 1; next }
  /^## / && flag { flag = 0 }
  flag { print }
' "$DESIGN")
for mode in brainstorm investigate coverage-baseline none; do
  echo "$SECTION_V2" | grep -q "$mode" \
    || fail "case 9 — /design Section v2 missing Branch 1 mode: $mode"
done
ok "case 9 — /design Section v2 names all 4 Branch 1 modes (scoped to v2 block only)"

# Case 10: /design Section v2 invokes superpowers:writing-plans
grep -q "superpowers:writing-plans" "$DESIGN" \
  || fail "case 10 — /design Section v2 does not invoke superpowers:writing-plans"
ok "case 10 — /design Section v2 folds in planning via superpowers:writing-plans"

# Case 11: /design Section v2 exits to /build with design spec path
grep -q "/build docs/superpowers/specs" "$DESIGN" \
  || fail "case 11 — /design Section v2 does not exit to /build with design spec path"
ok "case 11 — /design Section v2 exits to /build correctly"

echo "ALL PASS: skill-prose v2 invariants"
