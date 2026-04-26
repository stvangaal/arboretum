---
name: feature
requires:
  - superpowers
---

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

## Artifact Flow

| Step | Reads | Produces | Location | Authority |
|---|---|---|---|---|
| 1. `/start` | issue, git state, register | workflow choice, scope assessment | (none) | — |
| 2. Survey | `ARCHITECTURE.md`, governed specs, definitions, code | mental model | (none) | — |
| 3. `/design` | issue, principles, architecture | Path A → governed spec at `draft`; Path B → design spec | `docs/specs/` (A) or `docs/superpowers/specs/` (B) | owning (A) / ephemeral (B) |
| 4. Plan | governed spec (A) or design spec (B) | implementation plan | `docs/plans/` | ephemeral |
| 5. Build | plan, spec | code + tests | source dirs, `tests/` | source |
| 6. `/finish` | code + tests + plan + design spec | reconciled governed spec via `/consolidate`; PR | `docs/specs/` (status flips to `active`) | owning |
| 7. `/cleanup` | branch state | clean main | git | — |
| 8. `/reflect` | session memory, what surprised | lessons | memory | — |

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

Brainstorm the change. `/design`'s output depends on the chosen path:

- **Path A** — `/design` consolidates the brainstorm into a governed spec at `docs/specs/<topic>.spec.md`, status `draft`, available for review before planning.
- **Path B** — `/design` writes a design spec at `docs/superpowers/specs/`; the governed spec is born later at `/finish` via `/consolidate`.

**Skills:** `superpowers:brainstorming` (called by `/design`).
**Output:** Path A → governed spec at `docs/specs/` status `draft`. Path B → design spec at `docs/superpowers/specs/`. If architecture boundaries change, updated `docs/ARCHITECTURE.md` regardless of path.

### 4. Plan

Create an implementation plan from the spec. The plan breaks the work into ordered steps with test expectations at each step.

**Skills:** `superpowers:writing-plans`
**Input:** The governed spec(s) from step 3.
**Output:** An implementation plan in `docs/plans/`.

### 5. Build

Implement the plan using TDD. The spec stays at `draft` while the code is being written; `/consolidate` flips it to `active` after the build succeeds (Path A) or creates it at `active` from built state (Path B). No manual promotion step.

**Skills:** `superpowers:test-driven-development`, `superpowers:executing-plans`
**Cycle:** For each plan step: write failing test → write code → refactor → commit.

#### Wrapped delegation — workflow-level TDD wrap

This Build step invokes superpowers' TDD skill directly (no arboretum wrapper skill stands between them). Per `docs/ARCHITECTURE.md ## Wrapped delegation pattern`, the executing agent must brief, capture, and verify around that invocation.

**5a. Brief** — before invoking `superpowers:test-driven-development`, hand it:

- The project's test taxonomy from `CLAUDE.md ## Testing` (the project defines tiers: typically unit / contract / integration; some projects add a domain tier).
- The plan's per-step test expectations (each plan step pairs code work with a tier).
- File-naming and directory conventions for tests as documented in the project.
- The TDD ground rules (red → green → refactor; tests precede code).

**5b. Capture user contributions** — domain test cases that the AI cannot infer from the spec or codebase. Ask the user (via `AskUserQuestion` or equivalent):

> "Before I start implementing, are there domain test cases I should cover that aren't obvious from the spec? For example: known edge cases, regulatory boundaries, prior bug reproductions, customer scenarios."

Capture the response. Each item becomes a required test case in the build.

**5c. Invoke TDD** — proceed with the standard red → green → refactor cycle, including the user-contributed cases and the plan-derived expectations.

**5d. Verify post-build** — before declaring Build complete, confirm:

- **Taxonomy coverage** — every plan step's claimed tier has at least one test in the suite that matches.
- **User-contribution coverage** — each item from 5b has a corresponding test case (or an explicit, written reason why it doesn't apply).
- **No silent skips** — no skipped/pending tests landed without a tracked follow-up.

If any check fails, surface the gap to the user before moving to `/finish`.

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
