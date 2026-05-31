---
script: .claude/hooks/prompt-timestamp.sh
version: 1.0
invokers:
  - type: hook
    name: Claude UserPromptSubmit
  - type: developer
related-designs:
  - docs/superpowers/specs/2026-05-28-prompt-timestamps-design.md
  - docs/superpowers/specs/2026-05-26-pipeline-overhaul-ws5-governance-script-contracts-design.md
---
<!-- owner: pipeline-contracts-template -->

# Contract for `.claude/hooks/prompt-timestamp.sh`

## Surface

`UserPromptSubmit` hook. On every user prompt submission Claude Code invokes this hook and attaches its stdout as `additionalContext` to the submitted prompt. The hook emits exactly one line — `[YYYY-MM-DD HH:MM:SS] user prompt submitted` — using the local wall-clock time reported by `date(1)`. This places a durable per-turn timestamp in the transcript adjacent to the prompt it stamps, surviving context compression for post-hoc wait-delta analysis. The hook takes no arguments, reads no stdin, reads no environment variables, and writes no files.

## Protocol

### Arguments

The hook takes no positional arguments and no flags. Claude Code's `UserPromptSubmit` hook contract passes no stdin to the hook — the hook neither reads stdin nor inspects any environment variables. It is invoked as:

```
bash .claude/hooks/prompt-timestamp.sh
```

The hook produces its timestamp solely from the local system clock via:

```bash
date '+[%Y-%m-%d %H:%M:%S] user prompt submitted' || true
```

The `|| true` tail is load-bearing: if `date(1)` were somehow unavailable, the hook exits 0 (unstamped submission) rather than propagating exit 127 as a warning-surfacing hook failure.

### Exit codes

- `0` — always. The hook unconditionally exits 0: either `date(1)` succeeds and the timestamp line is emitted, or `date(1)` fails and `|| true` ensures a clean exit with no output. No other exit code is possible.

### Side effects

Stdout: exactly one line on success — `[YYYY-MM-DD HH:MM:SS] user prompt submitted` — where the bracketed timestamp is the local wall-clock time at invocation. On a non-zero `date(1)` *exit*, `|| true` absorbs the failure and zero bytes are written to stdout. The hook itself emits nothing to stderr. **Caveat:** `|| true` masks `date`'s exit *code*, not a shell-level `date: command not found` — if `date` were entirely absent from `PATH`, that diagnostic would still reach stderr. `date` is a base utility the hook never alters, so this edge case is outside the hook's control rather than a contract guarantee. No disk writes. No network calls. No subprocesses beyond `date(1)` itself. Pinned in CLI-3.

## Test surface

- **CLI-1: Output shape.** When invoked normally, the hook emits exactly one line to stdout matching `^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] user prompt submitted$`. No trailing whitespace, no extra lines, no stderr output.
- **CLI-2: Exit code invariant.** The hook exits 0 on every code path — including when `date(1)` is stubbed to fail — because `|| true` absorbs any non-zero exit from `date(1)`.
- **CLI-3: No-side-effect invariant.** On the success path and the non-zero-`date`-exit path the hook itself writes zero bytes to stderr (the `date: command not found` shell diagnostic that would arise if `date` were absent from `PATH` is out of scope — see Side effects caveat). It performs no disk writes and no network calls. The only subprocess spawned is `date(1)`.
- **CLI-4: Failure-mode silent unstamped.** When `date(1)` is replaced with a stub that exits non-zero, the hook exits 0 with zero stdout bytes — the prompt proceeds unstamped rather than surfacing a hook warning.

## Versioning

- **1.0** — initial contract (2026-05-30).
