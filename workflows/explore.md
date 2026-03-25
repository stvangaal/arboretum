# Workflow: Explore

You don't know enough to write a spec yet. Spike, learn, and either produce a spec draft or a documented decision about what not to build.

## When to use

- You have a question about feasibility ("can we do X?")
- You need to evaluate a library, API, or approach
- You're not sure how to decompose a problem into specs
- You want to prototype before committing to a design

## Stages

```
/start → [spike → document]* → decide
```

### 1. Start — `/start`

Create a GitHub issue framed as a question, not a deliverable. "Can we use X for Y?" or "What's the right way to handle Z?"

**Output:** An issue that captures what you're trying to learn.

### 2. Spike-document cycle — repeat as needed

#### 2a. Spike

Write throwaway code to answer a specific question. Spikes live in `spikes/` or a feature branch.

**Ground rules:**
- Spikes are throwaway. Don't polish them.
- Each spike should target one question. "Does this API return what we need?" not "Build the whole feature."
- Time-box if possible. If you haven't learned what you need in a reasonable effort, the question may be wrong.

**Skills:** `superpowers:systematic-debugging` (if investigating existing systems), or hands-on experimentation.

#### 2b. Document

Write down what you learned. This doesn't need to be formal — a few sentences in the issue or a markdown file is fine. The point is to capture the knowledge before you forget it.

**Key questions to answer:**
- What did you try?
- What worked? What didn't?
- What do you now know that you didn't before?
- What's the next question?

### 3. Decide

After one or more spike cycles, you know enough to choose:

**Ready to build** — You understand the problem well enough to write a spec. Transition to the feature workflow: `/consolidate` your findings into a governed spec, then follow feature stages from `/design` onward.

**Another spike needed** — You answered one question but surfaced a new one. Return to step 2.

**Abandon** — The investigation showed this isn't worth pursuing. Document why in the issue and close it. This is a valid outcome — not all explorations lead to code.

## Exit criteria

One of:
- A governed spec in `docs/specs/` ready for the feature workflow
- A documented decision not to proceed (in the GitHub issue)
- A clear next question for another spike cycle

## Transitions

- **→ feature:** When a spike produces enough understanding, `/consolidate` findings and enter the feature workflow at the design step.
- **← feature:** If during a feature's survey/design you discover unknowns, enter this workflow to spike. Return to the feature workflow via `/consolidate`.
