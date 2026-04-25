# Principles

Arboretum is an organizational framework for AI-assisted software development. These principles guide how projects are structured when an AI agent writes most of the code and the human is a domain expert steering the work.

## 1. Decide before you build

Write down what you want and why before any code exists. An AI agent with clear intent produces better code than one given vague instructions. The spec is the steering wheel.

## 2. Every file has one owner

One spec owns each file. No shared ownership, no orphans. When you didn't write every line yourself, this is how you answer "why does this exist?" — find the owning spec.

## 3. Humans own the what and why. AI owns the how

The human writes purpose and behaviour. The AI derives implementation, cross-references, and boilerplate. This keeps the human in control of the decisions that matter.

## 4. Make change safe by making it small

Single ownership, explicit dependencies, bounded specs — these exist so that changing one thing doesn't silently break another. The goal isn't to prevent change, it's to make change predictable.

## 5. Right-size the structure

A 500-line project doesn't need version-pinned contracts. Start with the minimum structure that keeps things traceable. Add governance when you feel the pain of not having it — not before.

## 6. Use what exists

Don't build skills, tools, or processes that the ecosystem already provides. Arboretum is an organizational layer. When a good external tool exists, integrate it — don't compete with it.

## 7. Learn from each cycle

After shipping a change, capture what surprised you — what the AI got wrong, what the spec missed, what worked unexpectedly well. Domain expertise grows fastest when you reflect while context is fresh.

---

## Two-path governance

Arboretum supports two paths to a governed spec: **Path A (spec-first)** writes the governed spec before the code; **Path B (design-first)** writes a design spec, builds the code, then runs `/consolidate` to produce the governed spec from built state. Both paths land at the same end state — every PR has an owning governed spec at status `active`. The cross-path invariants are stated centrally in `workflows/README.md ## Cross-path invariants`; this principle does not duplicate them.
