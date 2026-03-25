# Narrative Walkthrough — Outline

A narrative showing a complete development cycle with arboretum, including mistakes, backtracking, and recovery. This is the most powerful onboarding tool — it shows what the process feels like, not just what the rules are.

> This outline will be fleshed out with actual terminal sessions after implementation.

## Scene 1: Starting with an idea

User has an idea for a feature. They describe it to Claude. Claude uses `/start`, detects a feature workflow, confirms with the user, and creates a GitHub issue.

**What the human sees:** Claude asks clarifying questions, then confirms the plan.

## Scene 2: Discovering unknowns — workflow transition

During the design phase, Claude and the user realise they need to explore a library before committing to an approach. The feature workflow pauses, and they transition to the explore workflow.

**What the human sees:** Claude says "I think we need to spike on X before designing this. Let me switch to an exploration."

## Scene 3: Spike produces understanding

The spike answers the question. Claude runs `/consolidate` to capture the learnings as a governed spec.

**What the human sees:** Claude presents a draft spec for review. The human adjusts the Behaviour section.

## Scene 4: Back to feature — design, plan, build

With the spec in place, they return to the feature workflow at the design step. Plan is created, TDD build begins.

**What the human sees:** A structured plan, then iterative red-green-refactor cycles with commits at each step.

## Scene 5: Spec was wrong — revision protocol

During build, Claude discovers the spec assumed an API that doesn't exist. Claude stops, documents the issue, proposes alternatives.

**What the human sees:** Claude says "The spec says X, but the API actually does Y. Here are three alternatives." The human picks one, updates the spec.

## Scene 6: Recovery, finish, PR, reflect

Build completes. Claude runs `/finish` — health check passes, spec is promoted to `implemented`, PR is created with governance context.

**What the human sees:** A PR with a clear summary, spec references, and health-check results.

## Scene 7: Later — governance debt recovery

Weeks later, the user starts new work. The session-start hook reports drift — some files are unowned, the register is stale. They run `/health-check` to triage and fix.

**What the human sees:** A report of what drifted and clear recovery actions.
