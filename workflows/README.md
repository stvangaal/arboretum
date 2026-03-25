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
```

## Skill legend

| Notation | Meaning |
|---|---|
| `/skill` | Arboretum skill (user invokes) |
| `skill` | External skill (called by arboretum or user) |
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

This prevents the workflow from stalling during early development when everything is being shaped simultaneously. Once documents move to `ready` or `stable`, the strict "stop and report" rule applies.

## Revision protocol

When Claude discovers during implementation that a spec is wrong (not ambiguous, but wrong — an API doesn't exist, a performance constraint makes the design infeasible):

1. **Stop implementation** of the affected behaviour
2. **Document the finding** — what was attempted, what failed, why it won't work
3. **Propose alternatives** — 1-3 approaches with trade-offs
4. **Set the spec status to `revision-needed`**
5. **Continue implementing unaffected parts** if they are independent

The user reviews, selects an approach, and updates the spec. The spec returns to `ready` or `draft` for re-implementation.

## Anti-patterns

- **Orphan code.** Files exist that no spec claims. Fix: assign to a spec or delete.
- **Inline schemas.** A spec defines a data structure another spec also needs. Fix: extract to a shared definition.
- **Ghost dependencies.** A spec uses something from another module without declaring it. Fix: audit imports against declared requires.
- **Junk-drawer specs.** A spec like "shared-utils" accumulates unrelated code. Fix: split into purpose-specific specs.
- **Architecture drift.** The architecture document no longer matches the specs. Fix: update architecture when specs change.
- **Premature strictness.** Applying stable-definition rules to drafts still being shaped. Fix: use v0 for draft definitions; strict versioning only after `stable`.

## Detailed workflows

- [new-project](new-project.md)
- [feature](feature.md)
- [bug-fix](bug-fix.md)
- [explore](explore.md)
- [publish](publish.md)
- [refactor](refactor.md)
- [documentation](documentation.md)
