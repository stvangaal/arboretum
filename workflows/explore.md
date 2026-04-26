---
name: explore
requires:
  - superpowers
---

# Workflow: Explore

You don't know enough to write a spec yet. Spike, learn, and either produce a spec draft or a documented decision about what not to build.

## When to use

- You have a question about feasibility ("can we do X?")
- You need to evaluate a library, API, or approach
- You're not sure how to decompose a problem into specs
- You want to prototype before committing to a design

## Spike vs. Path B — what are you producing?

The explore workflow accommodates both *spikes* (output is knowledge) and the early stages of *Path B* (output will eventually be shipped code). The decision rule is **"what artifact emerges at the end?"**

- **Spike:** the deliverable is a *findings document*. Code (if any) is reference-only and never owned by a spec. Branch is `spike/*` and gets deleted after the findings are captured.
- **Path B:** the deliverable is *shipped code* with an owning governed spec. Branch is `feat/*` and merges.

If you don't know yet, start as a spike — it's easier to graduate to Path B later than to retroactively delete code that turned out to be exploratory.

## Stages

```
/start → [spike → document]* → decide
```

## Artifact Flow

| Step | Reads | Produces | Location | Authority |
|---|---|---|---|---|
| 1. `/start` | the question, codebase | issue framed as a question (not a deliverable) | GitHub issue | — |
| 2a. Spike | code, docs, library / API surface | throwaway working code | `spikes/` or `spike/*` branch | (throwaway — never owned) |
| 2b. Document | spike outcome | findings (what tried / what worked / what now known / next question) | issue body or markdown file | ephemeral |
| 3. Decide | findings | exit choice (continue / Path A / Path B / file / close) | issue + branch state | — |

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

Document your findings, then choose one of five options:

1. **Continue exploring** — more knowledge needed. Keep spiking on the same branch or start a new spike.
2. **Transition to Path B** — enough knowledge to start code, but design still emerging. Document, then start a `feat/*` branch via `/design`.
3. **Transition to Path A** — enough knowledge to write the governed spec upfront. Document, then start with `/design` → governed spec → plan → build.
4. **File for later** — worth doing, but not now. Capture findings as a tracked GitHub issue, close the spike branch.
5. **Close (no action)** — the spike answered "no, not worth doing" or "no change needed." Close the branch with the findings retained as a record.

Re-invoke `/start` with the chosen next step. The findings document remains as historical record regardless of the choice.

## Exit criteria

One of:
- A governed spec in `docs/specs/` ready for the feature workflow
- A documented decision not to proceed (in the GitHub issue)
- A clear next question for another spike cycle

## Transitions

- **→ feature:** When a spike produces enough understanding, `/consolidate` findings and enter the feature workflow at the design step.
- **← feature:** If during a feature's survey/design you discover unknowns, enter this workflow to spike. Return to the feature workflow via `/consolidate`.
