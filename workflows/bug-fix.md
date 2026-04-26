---
name: bug-fix
requires:
  - superpowers
---

# Workflow: Bug Fix

Something doesn't work as specified. Investigate, determine whether the spec or the code is wrong, fix the right thing.

## When to use

You have a bug report (usually a GitHub issue) describing behaviour that doesn't match expectations.

## Path selection — A or B?

Bug fixes are almost always **Path A** — the existing spec describes the intended behaviour; the bug is a divergence from the spec. The fix restores conformance.

**Path B applies only** when investigation reveals the bug is actually a *spec gap* — the spec didn't say what should happen in this case. That's a feature-shaped problem; transition to the feature workflow with a design spec rather than treating it as a bug fix.

## Stages

```
/start → investigate → classify → fix → /finish → /cleanup → /reflect
```

## Artifact Flow

| Step | Reads | Produces | Location | Authority |
|---|---|---|---|---|
| 1. `/start` | bug report, issue | confirmed issue with reproduction | GitHub issue | — |
| 2. Investigate | spec, code, test failures | root-cause finding, failing test if possible | `tests/` (test) | source (test) |
| 3. Classify | spec vs code mismatch | decision: code-fix / spec-fix / architecture | (notes) | — |
| 4. Fix | spec (if updated), failing test | code change + passing test; spec edits if behaviour changed | source dirs, `docs/specs/` (HUMAN sections only) | source / owning (if spec touched) |
| 5. `/finish` | code + tests + spec | reconciled spec status via `/consolidate`; PR | `docs/specs/` | owning |
| 6. `/cleanup` | branch state | clean main | git | — |
| 7. `/reflect` | session memory | lessons (especially: what did the spec miss?) | memory | — |

### 1. Start — `/start`

Ensure a GitHub issue exists for this bug. Link to the report.

**Input:** A bug report or user description of broken behaviour.
**Output:** Confirmed issue with reproduction details.

### 2. Investigate

Reproduce the bug and identify the root cause.

**Skills:** `superpowers:systematic-debugging` (for complex bugs)
**Steps:**
1. Reproduce the bug (write a failing test if possible)
2. Identify which spec owns the broken behaviour
3. Read the spec — what does it say should happen?
4. Read the code — what actually happens?
5. Identify the root cause

**Output:** Root cause identified, owning spec known.

### 3. Classify

Determine what needs to change. This is the key decision point:

**Code doesn't match spec** — The spec is correct but the implementation is wrong. This is a straightforward fix. Skip to step 4 — no spec update needed.

**Spec was wrong or incomplete** — The spec didn't account for this case, or described the wrong behaviour. Update the spec first (Purpose or Behaviour section), then fix the code to match.

**Architecture gap** — The bug reveals a missing boundary or unclear ownership. Update `docs/ARCHITECTURE.md` and possibly create a new spec. This may escalate to the feature workflow.

### 4. Fix

Fix the right thing, using TDD.

**If code-only fix:**
1. Write a failing test that reproduces the bug
2. Fix the code to make it pass
3. Commit

**If spec + code fix:**
1. Update the spec (Purpose or Behaviour section)
2. Write a failing test that captures the corrected behaviour
3. Fix the code
4. Commit (the spec's status will reconcile via `/consolidate`/`/health-check` automatically — no manual promotion needed)

#### Wrapped delegation — workflow-level TDD wrap

This Fix step invokes `superpowers:test-driven-development` directly. Apply the workflow-level wrap (see `docs/ARCHITECTURE.md ## Wrapped delegation pattern` and the canonical example in `workflows/feature.md` § Build):

- **Brief** — the test taxonomy from `CLAUDE.md ## Testing`; the tier choice is shaped by where the bug lives (unit for pure-function bugs, contract/integration for interaction bugs); the failing test must encode the bug's *current* misbehaviour before the fix.
- **Capture user contributions** — ask: "Are there related cases in this area that should also have tests, to prevent the same class of bug from recurring?" Each item becomes an additional test.
- **Verify post-fix** — the original failing test now passes; the related cases from the contribution moment have tests; no regressions in tests for nearby behaviour.

Skipping the wrap risks fixing the symptom while leaving a class-of-bug regression hazard unaddressed.

### 5. Finish — `/finish`

Verify the fix. If the spec was updated, `/consolidate` (run as part of `/finish`) reconciles status to `active`. Create pull request.

**PR should reference the GitHub issue** (e.g., "Fixes #42").

### 6. Cleanup — `/cleanup`

After PR merges: switch to main, pull, delete feature branch.

### 7. Reflect — `/reflect`

Especially valuable for bugs: what did the spec miss? Is there a class of bugs this represents? Should other specs be reviewed for the same gap?

## Transitions

- **→ feature:** If classification reveals a spec gap (not just wrong code), the fix becomes a feature. Branch the feature workflow from the current point.
