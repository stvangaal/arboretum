# CLAUDE.md — arboretum

## Project Overview

Arboretum is an organizational framework for building software with AI code agents. It gives domain experts a repeatable way to create projects that are well-organized, maintainable, and understandable — even when the human didn't write most of the code.

It is not a build system, test framework, or replacement for Claude Code. It is the layer that makes AI-assisted development predictable and traceable.

See `PRINCIPLES.md` for the seven principles that guide all design decisions.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (CLI)
- [superpowers](https://github.com/anthropics/superpowers) skills package (for design, planning, TDD, and debugging)

## CLI Usage

```bash
# Bootstrap a new spec-driven project
bin/arboretum bootstrap ~/Projects/my-project

# Update an existing project (run from within the project)
./arboretum update
```

## Workflows

Seven workflows cover the full development lifecycle. See `workflows/README.md` for details.

```
new-project      /init-project → /architect → [spike → /consolidate]* → build
feature          /start → survey → /design → plan → build → /finish → /cleanup → /reflect
bug-fix          /start → investigate → classify → fix → /finish → /cleanup → /reflect
explore          /start → spike → document → decide (→ feature or → another spike)
publish          /publish (review → strip → sync)
refactor         /start → orient → scope → test coverage → restructure → verify → /finish → /cleanup
documentation    /start → branch → edit → verify refs → /pr → /cleanup
```

## Skills

**Workflow:** `/start`, `/design`, `/finish`, `/cleanup`, `/reflect`

**Governance:** `/consolidate`, `/init-project`, `/architect`, `/pr`, `/promote-spec`, `/publish`

**Diagnostics:** `/health-check`

**Layer 2:** `/security-review`

### External skills (superpowers)

Arboretum wraps external skills at workflow transition points rather than building its own:

| External skill | Workflow stage |
|---|---|
| `superpowers:brainstorming` | Design |
| `superpowers:writing-plans` | Planning |
| `superpowers:test-driven-development` | Build |
| `superpowers:executing-plans` | Build |
| `superpowers:subagent-driven-development` | Build (alternative) |
| `superpowers:systematic-debugging` | Investigation |

## Development Rules

- **Spec-first gate:** Do not modify source files unless implementing a spec with status `in-progress`. If asked for a code change directly, identify the owning spec, offer to update the spec, and wait for approval.
- **Ownership:** Every source file includes `# owner: <spec-name>` as its first comment line.
- **Permitted without spec change:** implementation-detail refactoring (preserves behaviour, tests pass), patch fixes (code didn't match spec), supplementary test additions.

## Key Documents

| Document | Purpose |
|---|---|
| `PRINCIPLES.md` | Seven principles guiding all design decisions |
| `workflows/` | Workflow definitions for each development scenario |
| `docs/templates/` | Document templates used by skills |
| `.claude/skills/` | Slash skills (Claude Code commands) |
| `examples/rule-flow-engine/` | Fully governed sample project |
