---
name: publish
requires: []
---

# Workflow: Publish

Prepare your project for public sharing on GitHub. Review what's included, strip process artifacts, and sync to a public repo.

## When to use

Your project (or a meaningful part of it) is ready for others to see, use, or contribute to.

## Stages

```
/publish (review → strip → sync)
```

## Artifact Flow

| Step | Reads | Produces | Location | Authority |
|---|---|---|---|---|
| Review | repo state, `.publishignore` | review report (what will/won't ship) | (notes) | — |
| Strip | `.publishignore` | filtered file set | temp staging | — |
| Sync | filtered file set | public repo update (one-way: private → public) | public repo | — |

### 1. Publish — `/publish`

A single skill that handles the publication flow.

#### 1a. Review

Check what will be included in the public repo:

- **Specs** — Are they readable as standalone documentation? A contributor who has never seen arboretum should be able to read a spec and understand what that part of the code does.
- **Architecture** — Does `docs/ARCHITECTURE.md` make sense to an outsider?
- **CLAUDE.md** — Does it help contributors who use Claude Code? Does it make sense to those who don't?
- **Code** — Are ownership comments (`# owner: spec-name`) present? They serve as documentation pointers even for non-arboretum users.

#### 1b. Strip

Apply `.publishignore` to exclude process artifacts:

**Included by default:**
- `CLAUDE.md`, `docs/ARCHITECTURE.md` — project context
- `docs/specs/`, `docs/definitions/` — documentation
- `src/`, `tests/` — code
- `skills/`, `.claude/skills/`, `.claude/hooks/` — slash skills (plugin and project-local) and hooks
- `.arboretum.yml` — framework config

**Excluded by default:**
- `docs/plans/` — ephemeral implementation plans
- `docs/superpowers/` — design-phase brainstorming artifacts
- `docs/templates/` — contributors don't bootstrap new docs from templates

The user can edit `.publishignore` to customize.

#### 1c. Sync

Create the public repo if it doesn't exist, or sync changes if it does. One-way flow: private → public.

### What contributors see

**Contributors with Claude Code:** Get the full arboretum workflow — skills, hooks, `CLAUDE.md` guidance. They can use `/start`, `/design`, `/finish` to contribute following the same workflow the original author used.

**Contributors without Claude Code:** See a well-organized project with markdown specs as documentation, clear file ownership comments, and standard source code. Everything still makes sense — arboretum adds structure but doesn't create lock-in.
