---
version: 1
name: {{spec-name}}
status: draft
owner: {{group-name or "architecture"}}
owns: []
---

# {{Spec Name}}

## Purpose

<!-- HUMAN WRITES THIS — Why does this exist? What problem does it solve? One paragraph. -->

## Behaviour

<!-- HUMAN WRITES THIS — What should it do? Be as detailed as you want. This is how you steer the AI. -->

<!-- ============================================================
     Everything below this line is filled by Claude.
     The human reviews but doesn't need to write it.
     ============================================================ -->

## Tests

<!-- What to test and at which tier.
     - Unit (always): isolated, mocked dependencies
     - Contract (Layer 1+, if shared definitions): verify conformance
     - Integration (if cross-spec interaction): verify combined behaviour
     Declare "N/A — [reason]" for inapplicable tiers. -->

## Implementation Notes

<!-- File locations, constraints, and guidance for implementation.
     Added when the spec moves to in-progress. -->
