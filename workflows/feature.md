# Workflow: Feature

Add or change behaviour in an existing project. This covers new features, enhancements, and refactors that change interfaces. Design-heavy — you survey what exists, design the change, then build it.

## When to use

You have a GitHub issue describing something to add or change, and the project already exists with specs and architecture.

## Path selection — A or B?

This workflow supports both governance paths.

- **Path A (spec-first)** — *default for well-understood features.* Write the governed spec, then build. Use when the design is clear; you can describe Behaviour upfront.
- **Path B (design-first)** — *default for genuinely exploratory features.* Brainstorm, build, then `/consolidate` produces the governed spec from built state. Use when the design is still emerging and the right Behaviour wording will only crystallize after seeing the code.

If unsure, default to Path A — it's cheaper to switch from A to B (drop the spec, brainstorm fresh) than from B to A (you've already coded against unsettled design).

The Stages below describe Path A; for Path B, the order changes to: design spec → plan → build → `/consolidate` (creates governed spec from built state) → `/finish`.

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

Implement the plan using TDD. The spec stays at `draft` while the code is being written; `/consolidate` flips it to `active` after the build succeeds (Path A) or creates it at `active` from built state (Path B). No manual promotion step.

**Skills:** `superpowers:test-driven-development`, `superpowers:executing-plans`
**Cycle:** For each plan step: write failing test → write code → refactor → commit.

### 6. Finish — `/finish`

Verify implementation matches spec. `/consolidate` runs as part of `/finish` to auto-flip the spec status to `active`. Create pull request.

**Skills:** `/finish` orchestrates: health check → spec promotion → `/pr`
**Output:** A pull request with governance context.

### 7. Cleanup — `/cleanup`

After PR merges: switch to main, pull, delete feature branch, verify spec status.

### 8. Reflect — `/reflect`

Capture lessons while context is fresh. What surprised you? What did the AI get right or wrong? What would you change about the spec?

## Transitions

- **→ explore:** If during survey or design you discover unknowns that need spiking, pause this workflow and enter explore. Return via `/consolidate`.
- **← explore:** When returning from an explore spike, re-enter this workflow at the design step with the new governed spec.
