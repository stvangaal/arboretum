# Workflow: Bug Fix

Something doesn't work as specified. Investigate, determine whether the spec or the code is wrong, fix the right thing.

## When to use

You have a bug report (usually a GitHub issue) describing behaviour that doesn't match expectations.

## Stages

```
/start → investigate → classify → fix → /finish → /cleanup → /reflect
```

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
2. `/promote-spec` to `in-progress` (if not already)
3. Write a failing test that captures the corrected behaviour
4. Fix the code
5. Commit

### 5. Finish — `/finish`

Verify the fix. Promote spec to `implemented` if it was updated. Create pull request.

**PR should reference the GitHub issue** (e.g., "Fixes #42").

### 6. Cleanup — `/cleanup`

After PR merges: switch to main, pull, delete feature branch.

### 7. Reflect — `/reflect`

Especially valuable for bugs: what did the spec miss? Is there a class of bugs this represents? Should other specs be reviewed for the same gap?

## Transitions

- **→ feature:** If classification reveals a spec gap (not just wrong code), the fix becomes a feature. Branch the feature workflow from the current point.
