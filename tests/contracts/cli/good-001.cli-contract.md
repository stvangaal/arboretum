---
script: scripts/example-good.sh
version: 1.0
invokers:
  - type: skill
    name: /example
  - type: developer
related-designs:
  - docs/superpowers/specs/example.md
---

# Contract for `scripts/example-good.sh`

## Surface

The example-good script prints a fixture message and exits.

## Protocol

### Arguments

None.

### Exit codes

- `0` — success

### Side effects

Read-only — no side effects.

## Test surface

- **CLI-1:** Running with no args exits 0 with the fixture message on stdout.

## Versioning

- **1.0** — initial contract (2026-05-26)
