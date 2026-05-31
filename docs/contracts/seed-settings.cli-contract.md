---
script: scripts/seed-settings.sh
version: 1.0
invokers:
  - type: skill
    name: arboretum:/init (init Step 6)
  - type: script
    name: scripts/upgrade-sync.sh
  - type: developer
related-designs:
  - docs/superpowers/specs/2026-05-26-pipeline-overhaul-ws5-governance-script-contracts-design.md
---
<!-- owner: pipeline-contracts-template -->

# Contract for `scripts/seed-settings.sh`

## Surface

Idempotent settings seeder. Given a target `settings.json` path and a template `settings.json` path, either copies the template verbatim (when the target is absent) or merges the template's `permissions.allow` entries into the target (when the target already exists), appending only entries not already present and preserving the target's existing hooks, allow entries, and entry order. The merge is performed via `jq`; if `jq` is absent the script prints a loud, actionable message to stderr and exits `0` — it never silently corrupts the target. Invoked by the `/init` skill during project setup (Step 6) and by `upgrade-sync.sh --apply` to merge the plugin's settings template into the project's `.claude/settings.json`.

## Protocol

### Arguments

```
seed-settings.sh <target-settings.json> <template-settings.json>
```

- `<target-settings.json>` *(required, positional $1)* — path to the project's `.claude/settings.json` to create or update. When absent, the template is copied to this path and the script exits. When present, its `permissions.allow` entries and hooks are preserved, and only new template entries are appended.
- `<template-settings.json>` *(required, positional $2)* — path to the arboretum settings template (e.g. `docs/templates/settings.json.template`). Must be an existing file; missing template exits `1`.

Both arguments are required. Missing either triggers bash's `:?` expansion, which emits a usage error message and exits `1`.

### Exit codes

- `0` — success. One of: (a) target was absent — template copied verbatim; (b) target was present and `jq` is available — allow-list merge completed and target updated atomically; (c) target was present but `jq` is absent — merge skipped, actionable message printed to stderr.
- `1` — precondition error. Template file not found at `<template-settings.json>`. Error message emitted to stderr. Also triggered when either required positional argument is missing (bash `:?` expansion).

No other exit codes. When `set -euo pipefail` propagates an unexpected subcommand failure the shell may return that subcommand's code, but such cases are not part of the documented contract.

### Side effects

- **Copy path (target absent):** writes `<target-settings.json>` as a verbatim copy of the template.
- **Merge path (target present, `jq` available):** rewrites `<target-settings.json>` atomically — stages the merged JSON to a temp file in the same directory (`$(dirname "$TARGET")/.settings-seed.XXXXXX`), then `mv`s it into place. The target is never truncated and left incomplete; the original is preserved if the write is interrupted. The temp file is removed on exit via `trap`.
- **jq-absent path (target present, `jq` missing):** no disk writes. Prints two lines to stderr and exits `0`.
- **No network calls.** No processes spawned beyond `jq` (merge path only).

## Test surface

- **CLI-1: Copy-on-absent.** When `<target-settings.json>` does not yet exist, the script copies the template verbatim and exits `0`. The resulting target file matches the template byte-for-byte.
- **CLI-2: Merge-on-present.** When `<target-settings.json>` already exists and `jq` is available, the script exits `0` and the merged target contains all `permissions.allow` entries from both the original target and the template with no duplicates; the target's hooks and existing entries are preserved.
- **CLI-3: Missing-template exits 1.** When `<template-settings.json>` does not exist, the script exits `1` and emits an error message to stderr.
- **CLI-4: jq-absent graceful degradation.** When `jq` is absent and the target exists, the script exits `0` (merge skipped) and emits an actionable message to stderr — it never writes to or truncates the target.
- **CLI-5: Atomic write — no truncation.** The merge result is staged to a temp file and `mv`d into place; the target is never left in a half-written state.

## Versioning

- **1.0** — initial contract (2026-05-30).
