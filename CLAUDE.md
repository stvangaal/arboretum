# CLAUDE.md — arboretum

## Project Overview

Arboretum is an organizational framework for building software with AI code agents. It gives domain experts a repeatable way to create projects that are well-organized, maintainable, and understandable — even when the human didn't write most of the code.

It is not a build system, test framework, or replacement for Claude Code. It is the layer that makes AI-assisted development predictable and traceable.

See `PRINCIPLES.md` for the seven principles that guide all design decisions.

## What You'll Experience

As a human using arboretum, your role is to **decide what to build** and **review what Claude produces**. Here's what that looks like:

1. **You describe what you want** — in plain language, as a GitHub issue or a conversation with Claude.
2. **Claude routes to a workflow** — it picks the right sequence of steps (feature, bug-fix, explore, etc.) and follows it.
3. **You review specs** — before code is written, Claude presents a spec describing what will be built. You approve, adjust, or reject.
4. **Claude builds** — following the spec, using TDD, with ownership tracking.
5. **You review the result** — via pull request, with governance context (which specs were touched, health-check status).

You don't need to understand every skill or hook. You need to understand specs (your steering wheel) and workflows (the sequence Claude follows).

## How Governance Works

**Checking that Claude is following the process:**

- Every source file should have an `# owner: <spec-name>` comment — if files are missing this, ask Claude to run `/health-check`
- Specs have one of three statuses: `draft` (being authored), `active` (matches current code), or `stale` (drift detected). Transitions are automatic via `/consolidate` and `/health-check` — no manual promotion step.
- PRs should reference specs and include health-check results — if they don't, the `/pr` skill wasn't used

**Key artifacts to review:**

| Artifact | What to look for |
|---|---|
| `docs/specs/*.spec.md` | Does the Purpose match your intent? Does Behaviour cover the right cases? |
| `docs/ARCHITECTURE.md` | Does the big picture still make sense? |
| `docs/REGISTER.md` | Are all files owned? Any orphans? |
| Pull requests | Does the summary match what you asked for? |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (CLI)
- [superpowers](https://github.com/anthropics/superpowers) skills package (optional — workflows degrade gracefully without it)

## CLI Usage

```bash
# Bootstrap a new spec-driven project
bin/arboretum bootstrap ~/Projects/my-project

# Update an existing project (run from within the project)
./arboretum update
```

## Reference

### Workflows

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

### Skills

**Workflow:** `/start`, `/design`, `/finish`, `/cleanup`, `/reflect`

**Governance:** `/consolidate`, `/init-project`, `/architect`, `/pr`, `/publish`

**Diagnostics:** `/health-check`

**Layer 2:** `/security-review`

### Capability slots (external skills)

Arboretum defines abstract capabilities that workflows need. Each has a current provider (from the superpowers package), but workflows degrade gracefully if the provider is absent.

| Capability | Current provider | Workflow stage |
|---|---|---|
| Brainstorm | `superpowers:brainstorming` | Design |
| Plan | `superpowers:writing-plans` | Planning |
| Build (TDD) | `superpowers:test-driven-development` | Build |
| Build (execute) | `superpowers:executing-plans` | Build |
| Build (parallel) | `superpowers:subagent-driven-development` | Build (alternative) |
| Debug | `superpowers:systematic-debugging` | Investigation |

## Two-Path Governance

Arboretum supports two paths to a governed spec:

- **Path A (spec-first):** governed spec (status `draft` → `active`) → tests + code → PR.
- **Path B (design-first):** brainstorm → design spec (`docs/superpowers/specs/`) → plan → tests → code → `/consolidate` → governed spec (status `draft` → `active`) → PR.

Both paths land at the same end state: every PR has an owning governed spec at status `active`. The cross-path invariants are stated centrally in `workflows/README.md ## Cross-path invariants` — those rules hold regardless of which path is taken.

## Development Rules

- **Spec-first gate:** Code modification is allowed when the changed files' `# owner:` headers point to a recognized topic — either an existing governed spec at `docs/specs/<topic>.spec.md` (status `draft` or `active`) or an in-flight design spec at `docs/superpowers/specs/*-<topic>-design.md` (Path B). On Path A the governed spec exists before the code; on Path B the design spec is the in-flight authority and `/consolidate` materializes the governed spec at the same topic name before PR.
- **Ownership:** Every source file includes `# owner: <spec-name>` as its first comment line.
- **Permitted without spec change:** implementation-detail refactoring (preserves behaviour, tests pass), patch fixes (code didn't match spec), supplementary test additions.

## Key Documents

| Document | Purpose |
|---|---|
| `PRINCIPLES.md` | Seven principles guiding all design decisions |
| `workflows/` | Workflow definitions for each development scenario |
| `docs/templates/` | Document templates used by skills |
| `skills/` | Slash skills (Claude Code commands) |
| `examples/rule-flow-engine/` | Fully governed sample project |
