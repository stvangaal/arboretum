# Workflows

Workflows guide you through a best-practice sequence of steps for common development scenarios. Each workflow is a series of skills invoked in order — some arboretum-owned, some external.

## Choosing a workflow

```
What are you doing?
│
├── Starting from scratch?
│   └── new-project
│
├── Project exists, you know what to build?
│   └── feature
│
├── Something is broken?
│   └── bug-fix
│
├── Not sure what to build, need to learn?
│   └── explore
│
├── Restructuring without changing behaviour?
│   └── refactor
│
├── Updating documentation only?
│   └── documentation
│
├── Have an existing project you want to govern?
│   └── retrofit
│
└── Ready to share your project publicly?
    └── publish
```

## Workflow overview

```
new-project      /init-project → /architect → [spike → /consolidate]* → build
feature          /start → survey → /design → plan → build → /finish → /cleanup → /reflect
bug-fix          /start → investigate → classify → fix → /finish → /cleanup → /reflect
explore          /start → spike → document → decide (→ feature or → another spike)
publish          /publish (review → strip → sync)
refactor         /start → orient → scope → test coverage → restructure → verify → /finish → /cleanup
documentation    /start → branch → edit → verify refs → /pr → /cleanup
retrofit         assess → bootstrap → triage → govern-one → [expand]*
```

## Cross-path invariants

These rules hold regardless of which path you take. The paths differ in *governance timing*, not in *delivery rigour*.

1. Every source file has `# owner: <spec-name>` from its first commit (not retrofitted at PR time).
2. Every PR has an owning governed spec at status `active` (or `draft` for WIP, with the spec activated as part of the PR).
3. Tests land before or alongside implementation (TDD discipline, both paths).
4. The Behaviour section of the governed spec is human-authored regardless of path.
5. PRs scope by intent, not "everything in the tree" — hunk-staging when needed.
6. Pick one path per slice — don't mix Path A and Path B within a single PR. If exploration mid-Path-B reveals shared definitions or contract locks are needed, pause and author the governed spec before continuing.

## Skill legend

| Notation | Meaning |
|---|---|
| `/skill` | Arboretum skill (user invokes) |
| `capability` | Abstract capability (current provider in parentheses, degrades gracefully if absent) |
| `step` | Manual step (Claude guides, no skill needed) |
| `[x]*` | Repeat as needed |
| `→` | Proceed to next step |

## Spec sizing

A spec should have a **single reason to change**. If two behaviours can evolve independently, they should be separate specs. If two pieces of code always change together and share internal state, they belong in the same spec.

**Signs a spec is too large:**
- Its Behaviour section has multiple unrelated subsystems
- Different parts could be implemented and tested independently
- It owns files in multiple unrelated directories

**Signs a spec is too small:**
- It cannot be tested without mocking its own internals
- Its provides are only consumed by one other spec and could be inlined
- It has no independent reason to exist

## Draft mode

When all involved documents (the spec and its dependencies) have status `draft`:

- Claude **notes ambiguities** and **continues with its best interpretation**, rather than stopping
- Hard stops are reserved for **contradictions** (the spec says two incompatible things) and **infeasibility** (the approach cannot work as described)
- Minor TBDs, stylistic choices, and edge case questions are logged and implementation proceeds

This prevents the workflow from stalling during early development when everything is being shaped simultaneously. Once documents move to `active`, the strict "stop and report" rule applies.

## Revision protocol

When Claude discovers during implementation that a spec is wrong (not ambiguous, but wrong — an API doesn't exist, a performance constraint makes the design infeasible):

1. **Stop implementation** of the affected behaviour
2. **Document the finding** — what was attempted, what failed, why it won't work
3. **Propose alternatives** — 1-3 approaches with trade-offs
4. **The spec's status will flip to `stale`** automatically (via `/health-check`) when drift is detected, or remain `active` if `/consolidate` reconciles immediately
5. **Continue implementing unaffected parts** if they are independent

The user reviews, selects an approach, and updates the spec. The spec stays at `active` (or returns to it via `/consolidate` once the new code lands).

## Anti-patterns

- **Orphan code.** Files exist that no spec claims. Fix: assign to a spec or delete.
- **Inline schemas.** A spec defines a data structure another spec also needs. Fix: extract to a shared definition.
- **Ghost dependencies.** A spec uses something from another module without declaring it. Fix: audit imports against declared requires.
- **Junk-drawer specs.** A spec like "shared-utils" accumulates unrelated code. Fix: split into purpose-specific specs.
- **Architecture drift.** The architecture document no longer matches the specs. Fix: update architecture when specs change.
- **Premature strictness.** Applying stable-definition rules to drafts still being shaped. Fix: use v0 for draft definitions; strict versioning only after `stable`.

## Workflow transitions

Real development is non-linear. These transitions define when and how to pivot between workflows mid-stream.

| From | To | When |
|------|-----|------|
| feature → | explore | During survey/design you discover unknowns that need spiking. Pause the feature workflow, enter explore. Return via `/consolidate`. |
| bug-fix → | feature | Classification reveals a spec gap (not just wrong code). The fix becomes a feature. Branch the feature workflow from the current point. |
| refactor → | bug-fix | Restructuring surfaces a bug. Pause the refactor, capture the bug as a separate issue. Fix inline if trivial, or start a bug-fix branch. |
| explore → | feature | A spike produces enough understanding. `/consolidate` findings and enter the feature workflow at the design step. |
| any → | documentation | You discover docs-only issues during any workflow. Note them for a separate documentation pass after the current workflow completes. |

**Transition protocol:**
1. Note where you are in the current workflow (so you can return)
2. Commit or stash in-progress work
3. Enter the target workflow at its natural entry point
4. When the target workflow completes, return to the original workflow where you left off (if applicable)

## Signs governance is working

- You're rarely surprised by what Claude implements (your specs are clear)
- When you change one spec, other specs don't break unexpectedly (ownership is clean)
- New team members can understand the project by reading specs, not code (traceability works)
- `/health-check` runs clean most of the time (drift is caught early)
- You spend more time deciding what to build than debugging what was built

## Signs governance needs adjustment

- You're spending more time on governance than on the actual work (over-governed — drop a layer)
- Specs are routinely out of date (under-maintained — simplify specs or add automation)
- Claude keeps asking for permission to update specs (spec-first gate is friction, not value — check if specs are too granular)

## Governance debt

Governance debt is accumulated drift between specs, register, code, and contracts. It happens naturally — branches merge, files get added without ownership, specs go stale.

### Detecting it

Run `/health-check`. It reports all categories of drift.

### Triage by severity

| Severity | Examples | Action |
|----------|----------|--------|
| **Blocking** | Spec contradictions, circular dependencies | Fix immediately — these prevent correct implementation |
| **Moderate** | Unowned files, stale version pins, register gaps | Fix before next PR — these cause confusion |
| **Low** | Missing optional docs, cosmetic spec issues | Fix when convenient — these don't affect correctness |

### Recovery patterns

- **Many unowned files** → run `/consolidate` to batch-create specs
- **Stale register** → run `scripts/generate-register.sh` to regenerate
- **Spec/code divergence** → `/health-check` flips spec to `stale`; run `/consolidate` to reconcile (either update the spec to match code, or revert the code to match the spec)
- **Abandoned branch governance** → delete orphaned specs, regenerate register

### Prevention

Run `/health-check` before every PR. The `/finish` skill already suggests this.

## Detailed workflows

- [new-project](new-project.md)
- [feature](feature.md)
- [bug-fix](bug-fix.md)
- [explore](explore.md)
- [publish](publish.md)
- [refactor](refactor.md)
- [documentation](documentation.md)
- [retrofit](retrofit.md)
