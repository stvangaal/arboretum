# Project Register

## Definitions Index

| Definition | Version | Status | Primary Implementor | Required By |
|------------|---------|--------|---------------------|-------------|

<!-- No shared definitions yet. -->

## Spec Index

| Spec | Phase | Status | Owns (files/directories) | Depends On |
|------|-------|--------|--------------------------|------------|
| consolidate-spec.spec.md | Phase 0 | draft | .claude/skills/consolidate/SKILL.md | — |
| git-workflow-tooling.spec.md | Phase 0 | draft | .githooks/pre-commit, .claude/hooks/pre-commit-branch-check.sh, .claude/skills/pr/SKILL.md, .claude/skills/security-review/SKILL.md, scripts/bootstrap-project.sh | — |
| workflow-management.spec.md | Phase 0 | in-progress | workflows/README.md, workflows/new-project.md, workflows/feature.md, workflows/bug-fix.md, workflows/explore.md, workflows/publish.md, workflows/refactor.md, workflows/documentation.md, .claude/skills/dev-manage-workflows/SKILL.md | — |

## Phase Summary

| Phase | Specs (count) | Status |
|-------|--------------|--------|
| Phase 0 | 3 | draft |

## Unowned Code
<!-- This section should always be empty. If it is not, something
     needs to be assigned to a spec or deleted. -->

## Dependency Resolution Order
<!-- Topological sort of the spec dependency graph, grouped by phase.
     This is the order in which specs should be implemented. -->

### Phase 0
1. git-workflow-tooling (no dependencies)
2. consolidate (no dependencies)
3. workflow-management (no dependencies)
