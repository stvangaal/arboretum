---
script: scripts/handoff-commit-wip.sh
version: 1.0
invokers:
  - type: skill
    name: arboretum:/handoff
  - type: developer
related-designs:
  - docs/superpowers/specs/2026-05-26-pipeline-overhaul-ws5-governance-script-contracts-design.md
---
<!-- owner: pipeline-contracts-template -->

# Contract for `scripts/handoff-commit-wip.sh`

## Surface

Commits all in-flight changes in a project directory into a single `wip: handoff <YYYY-MM-DD>` commit and pushes the branch, so work survives a machine switch. Usage: `handoff-commit-wip.sh [project-dir]`. When `project-dir` is omitted the script uses the current repository root (`git rev-parse --show-toplevel`). The script is safe to call on a clean tree — it reports "clean tree — nothing to commit" and exits 0 without creating a commit. The caller (the `/handoff` skill) is responsible for obtaining the user's confirmation before invoking this script; the script just acts.

## Protocol

### Arguments

- `$1` — Optional. Absolute or relative path to the project directory (the git working tree root). Defaults to `$(git rev-parse --show-toplevel)` when omitted, falling back to `$(pwd)` if that also fails. The script `cd`s into this directory before any git operations.

No flags. No variadic arguments.

### Exit codes

- `0` — Success. One of: (a) working tree was dirty — a `wip: handoff` commit was created and the branch was pushed; (b) working tree was clean — reported "clean tree — nothing to commit" with no commit created.
- `1` — Pre-flight failure. One of: (a) `$1` is not a directory; (b) `$PROJECT_DIR` is not inside a git repository; (c) the current branch is `main` or `master` (the script refuses to create a wip commit on a protected branch).
- `2` — Post-stage failure. `git commit` or `git push` failed after `git add -A` was already run.

### Side effects

When the working tree is dirty:

1. **`git add -A`** — stages all untracked and modified files in `$PROJECT_DIR`.
2. **`git commit -q -m "wip: handoff <YYYY-MM-DD>"`** — creates a single commit with today's UTC date. Subject line is always in this format; no body.
3. **`git push -q`** — pushes to the tracking remote (existing upstream). If no upstream is set, sets one via `git push -q -u <first-remote> <branch>` on the branch being handed off. Fails with exit 2 and message "push failed: no git remote configured" when no remote exists at all.
4. **stdout** — the short SHA of the new commit (`git rev-parse --short HEAD`).

When the working tree is clean: emits "clean tree — nothing to commit" to stdout; no staging, no commit, no push.

## Test surface

- **CLI-1: Clean-tree no-op.** When the working tree is clean, the script exits 0, emits "clean tree — nothing to commit" to stdout, and creates no git commit.
- **CLI-2: Dirty-tree commit.** When the working tree has uncommitted changes, the script stages all files, creates a commit whose subject matches `^wip: handoff [0-9]{4}-[0-9]{2}-[0-9]{2}$`, and exits 0. Stdout is a short SHA (7–12 hex characters).
- **CLI-3: Protected-branch refusal.** When the current branch is `main` or `master`, the script exits 1 with message "refusing to wip-commit on <branch>" on stderr, regardless of tree state.
- **CLI-4: Non-repo failure.** When the argument is a directory that is not a git repository, the script exits 1 with "not a git repository" on stderr.

## Versioning

- **1.0** — initial contract (2026-05-30).
