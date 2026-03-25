# Workflow: Feature

Add or change behaviour in an existing project. This covers new features, enhancements, and refactors that change interfaces. Design-heavy — you survey what exists, design the change, then build it.

## When to use

You have a GitHub issue describing something to add or change, and the project already exists with specs and architecture.

## Stages

```
/start → survey → /design → plan → build → /finish → /cleanup → /reflect
```

### 1. Start — `/start`

Ensure a GitHub issue exists for this work. Determine scope — which specs and architectural boundaries are involved.

**Input:** A change request (from the user or a GitHub issue).
**Output:** Confirmed issue, initial assessment of which specs are touched.

### 2. Survey

Read the existing specs, architecture, and code that this change touches. Understand the current state before proposing changes.

**What to read:**
- `docs/ARCHITECTURE.md` — does this change fit within existing boundaries, or does it cross them?
- Affected specs in `docs/specs/` — what do they currently say?
- Shared definitions in `docs/definitions/` — are any involved?
- The actual code owned by affected specs — what exists today?

**Output:** A clear picture of what exists and what needs to change.

### 3. Design — `/design`

Brainstorm the change, then consolidate into governed spec updates.

**Skills:** `superpowers:brainstorming` (called by `/design`), then `/consolidate` to formalize.
**Output:** Updated or new specs in `docs/specs/` with status `draft`. If architecture boundaries change, updated `docs/ARCHITECTURE.md`.

### 4. Plan

Create an implementation plan from the spec. The plan breaks the work into ordered steps with test expectations at each step.

**Skills:** `superpowers:writing-plans`
**Input:** The governed spec(s) from step 3.
**Output:** An implementation plan in `docs/plans/`.

### 5. Build

Implement the plan using TDD. Promote affected specs to `in-progress` before writing code.

**Skills:** `/promote-spec` (to `in-progress`), `superpowers:test-driven-development`, `superpowers:executing-plans`
**Cycle:** For each plan step: write failing test → write code → refactor → commit.

### 6. Finish — `/finish`

Verify implementation matches spec. Promote spec to `implemented`. Create pull request.

**Skills:** `/finish` orchestrates: health check → spec promotion → `/pr`
**Output:** A pull request with governance context.

### 7. Cleanup — `/cleanup`

After PR merges: switch to main, pull, delete feature branch, verify spec status.

### 8. Reflect — `/reflect`

Capture lessons while context is fresh. What surprised you? What did the AI get right or wrong? What would you change about the spec?

## Transitions

- **→ explore:** If during survey or design you discover unknowns that need spiking, pause this workflow and enter explore. Return via `/consolidate`.
- **← explore:** When returning from an explore spike, re-enter this workflow at the design step with the new governed spec.
