---
name: design
description: Wrapper skill that orchestrates the design phase — runs external brainstorming to produce a design spec, then consolidates into a governed spec ready for implementation. Use at the start of planned work.
disable-model-invocation: false
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: "[path/to/design-spec.md]"
layer: 0
---

# Design

Orchestrates the transition from idea to implementable governed spec. This is a wrapper that coordinates external design skills with arboretum's governance.

## When to use

- Starting planned work (user knows what they want to build)
- After `/start` routes to the planned path
- When the user says "let's design this" or "let's spec this out"

## Procedure

### Step 1: Check for existing design work

If `$ARGUMENTS` is provided, treat it as a path to an existing superpowers design spec:
1. Read the file
2. Confirm with the user: "Found design spec at `<path>`. Consolidate this into a governed spec?"
3. If confirmed, skip to Step 3 (consolidate).

Otherwise, check for unconsolidated design specs:
```bash
ls docs/superpowers/specs/*.md 2>/dev/null
```

If any exist, present them:
> "Found existing design specs:
> 1. `docs/superpowers/specs/<file1>.md` — <first heading>
> 2. `docs/superpowers/specs/<file2>.md` — <first heading>
>
> Consolidate one of these, or start a new design?"

### Step 1b: Survey existing specs

Before starting the brainstorming phase, read existing specs in `docs/specs/` and `docs/ARCHITECTURE.md` to surface governed code that may be relevant to the design topic. This prevents designing something that overlaps with existing work.

### Step 2: Brainstorm (capability: brainstorm)

If no existing design spec is being used, initiate the brainstorming process:

1. Tell the user: "Starting the design phase. I'll use the brainstorm capability to explore your idea and produce a design spec."

2. Invoke the **brainstorm** capability (currently provided by `superpowers:brainstorming`). If the provider is not available, conduct the design conversation directly — ask clarifying questions, propose approaches, present a design for approval, and write a design spec to `docs/superpowers/specs/`.

   The brainstorm process will:
   - Ask clarifying questions
   - Propose approaches
   - Present a design for approval
   - Write a design spec to `docs/superpowers/specs/`

3. **Critical handoff:** When brainstorming completes and wants to transition to planning, intercept. Instead of proceeding to planning, move to Step 3 (consolidate). The governed spec must exist before planning begins.

### Step 3: Consolidate into governed spec

Run `/consolidate` with the design spec path:

1. Invoke the consolidate skill, pointing it at the design spec produced in Step 2 (or provided via `$ARGUMENTS`).
2. The consolidate skill will:
   - Harvest content from the design spec
   - Create or update governed specs in `docs/specs/`
   - Update the register
   - Offer to promote specs to `in-progress`
   - Delete the consumed design spec

3. After consolidation completes, confirm the result:
> "Governed spec created: `docs/specs/<name>.spec.md` (status: in-progress).
> Ready to plan the implementation?"

### Step 4: Transition to planning

Once the governed spec exists and is `in-progress`:

1. Suggest: "The spec is ready. Want to create an implementation plan?"
2. If yes, invoke the **plan** capability (currently provided by `superpowers:writing-plans`), using the governed spec as input — not the design spec. If the provider is not available, create the plan directly following the project's plan template.

## Important

- This skill is the **conductor** for the design phase. It doesn't replace brainstorming — it ensures the output lands in the right place (governed specs, not just design docs).
- The critical value is the **brainstorm → consolidate handoff**. Without this wrapper, brainstorming exits into planning without creating a governed spec, which means hooks and register checks don't work during implementation.
- If the user wants to skip brainstorming and write a spec directly, they can create one from `docs/templates/spec.md`.
- If the user is on the exploratory path and has already explored, skip brainstorming — go straight to consolidation (Step 3).

$ARGUMENTS
