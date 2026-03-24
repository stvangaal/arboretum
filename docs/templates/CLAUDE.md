---
version: 1
---

# CLAUDE.md

## Project Overview

<!-- 2-3 sentences. What does this project do, who uses it, what's the tech stack. -->

## Project Status

<!-- Current phase, what's in progress, what's next. -->

## Workflows

This project uses arboretum workflows. See `workflows/README.md` for details.

| Workflow | When to use |
|---|---|
| **feature** | Adding or changing behaviour |
| **bug-fix** | Something doesn't work as specified |
| **explore** | Need to learn before you can write a spec |

### Development rules

- **Spec-first gate:** Do not modify source files unless implementing a spec with status `in-progress`. If asked for a code change directly, identify the owning spec, offer to update the spec, and wait for approval.
- **Ownership:** Every source file includes `# owner: <spec-name>` as its first comment line.
- **Permitted without spec change:** implementation-detail refactoring (preserves behaviour, tests pass), patch fixes (code didn't match spec), supplementary test additions.
- **Draft mode:** During early development when documents are `draft`, note ambiguities and continue rather than stopping. Stop only for contradictions or infeasibility.

## Testing

This project uses **test-driven development** (TDD). Red-green-refactor:

1. **Red:** Write a failing test that captures expected behaviour.
2. **Green:** Write the minimum code to make it pass.
3. **Refactor:** Clean up while keeping tests green.

Tests are tiered: unit (always) → contract (when shared definitions exist) → integration (when cross-spec dependencies exist). Declare "N/A — [reason]" for inapplicable tiers.

## Git Workflow

- **Branch protection:** Never commit directly to `main`. Feature branches: `feat/`, `fix/`, `docs/`, `chore/`.
- **Explicit staging:** Stage files by name. Never `git add -A` or `git add .`.
- **Commit messages:** Explain *why*, not *what*. Reference issues (e.g., "Closes #12").
- **One logical change per commit.**
- **Pull requests:** Use `/finish` for the full flow, or `/pr` directly.

## Skills

**Workflow:** `/start`, `/design`, `/finish`, `/cleanup`, `/reflect`

**Governance:** `/consolidate`, `/promote-spec`, `/pr`, `/publish`

**Diagnostics:** `/health-check`

## Key Documents

| Document | Location | Status |
|---|---|---|
| **Architecture** | `docs/ARCHITECTURE.md` | <!-- draft / active / not yet created --> |
| **Specs** | `docs/specs/*.spec.md` | <!-- count and status --> |
| **Register** | `docs/REGISTER.md` | <!-- Layer 1+ --> |
| **Definitions** | `docs/definitions/` | <!-- Layer 1+ --> |

## Package Structure

```
<!-- Project directory layout. Update as structure evolves. -->
```

## Running Tests

```bash
<!-- Primary test command -->
```

## Key Design Decisions

<!-- Bullet list of the most important architectural decisions. -->

## Environment

<!-- Runtime requirements, external dependencies, setup instructions. -->
