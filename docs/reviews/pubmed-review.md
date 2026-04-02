# Review: stvangaal/pubmed — Arboretum's First Spawn

**Reviewed:** 2026-04-02
**Repository:** https://github.com/stvangaal/pubmed
**Declared layer:** 2 (governance)
**Created:** 2026-03-23 (~10 days of active development)

## Project Summary

A weekly automated pipeline that identifies practice-changing clinical publications from PubMed, summarizes them with Claude Sonnet, and delivers curated digests to clinicians via email and blog archive. Currently active for two domains: stroke and neurology. Runs on GitHub Actions, costs ~$1.15/week.

The project was built by a neurologist (domain expert, non-developer) using arboretum's governance framework — making it a direct test of arboretum's core promise: domain experts can build maintainable software with AI agents.

---

## What's Working Well

### 1. Architecture document is a model artifact

The `docs/ARCHITECTURE.md` is the strongest artifact in the project and a proof point for arboretum's architecture template. It includes:

- ASCII pipeline diagram with data flow annotations and volume estimates
- Stage descriptions with realistic throughput numbers (~40-130 retrieved, ~4-10 filtered)
- Shared definitions indexed by type (flowing data vs config data)
- An "Essentials" table ranking what matters most (HIGH / MODERATE / EASY TO MISS)
- Three recommended spikes with concrete success criteria
- 11 architecture decisions with rationale, alternatives considered, and dates
- Extension points tied to specific GitHub issues (#4, #5)
- A scope fence explicitly separating in-scope, planned, and not-planned work
- Phase map and dependency graph

This is what the architecture template should produce. The "Essentials" table and "Recommended Spikes" sections are particularly effective — they give a newcomer immediate orientation on what matters.

### 2. Domain model is clean and well-separated

`src/models.py` demonstrates good discipline:

- Every dataclass references its canonical definition (`See docs/definitions/...`)
- Domain objects (`PubmedRecord`, `LiteratureSummary`) are clearly separated from config objects (`SearchConfig`, `FilterConfig`, etc.)
- Cost tracking (`LLMUsage`) is pragmatic — tracks tokens by stage with pricing built in
- Type hints are consistent throughout, using modern Python syntax (`list[str]`, `str | None`)

### 3. Pipeline orchestrator is readable

`src/pipeline.py` reads like a script of the architecture diagram. Each stage is clearly labeled with logging, volumes are tracked at each boundary, and empty-result edge cases are handled gracefully. The `--test` mode (1-day window, reduced limits, no email) enables cheap iteration — a practical addition that shows operational maturity.

### 4. Multi-domain config design is well-executed

Architecture decision A10 (domain-scoped config directories) stands out:

- `config/domains/_template/` makes onboarding mechanical — copy and customize
- Schema versioning with advisory warnings (not fatal errors) is pragmatic for a solo project
- Each domain is fully self-contained and copyable
- No code changes needed to add a new domain

### 5. Ownership headers are present

Source files consistently include `# owner: <spec-name>` as their first comment line. This is the most fundamental arboretum requirement and it's being followed. The ownership is meaningful — specs map to coherent pipeline stages.

### 6. Definitions directory is fully populated

All 10 shared definitions exist in `docs/definitions/`, matching what the architecture declares. The `pubmed-record.md` definition is particularly thorough:

- Complete Python schema with field-level documentation
- Detailed constraints (date normalization rules, status values, author format)
- Changelog tracking field additions with affected spec references

### 7. Real operational data grounds the documentation

The README and architecture include concrete numbers from actual production runs:

- ~$1.05/run for triage, ~$0.10/run for summarization
- ~200 articles searched, ~40-130 retrieved, ~4-10 filtered, ~25 summaries
- Weekly cost: ~$1.15

This grounds the project in reality rather than hypotheticals and makes the documentation trustworthy.

### 8. Git history shows healthy human-AI collaboration

The commit log demonstrates the intended arboretum pattern:

- Stephen (human): merges PRs, renames workflows, updates metrics, makes domain decisions
- Claude (AI): implements features, fixes bugs, updates specs, handles mechanical changes

This matches Principle 3: "Humans own what/why, AI owns how."

---

## What Should Change

### Critical (governance violations)

#### C1. Spec statuses do not reflect reality

The register shows:

| Spec | Register Status | Actual State |
|------|----------------|--------------|
| `project-infrastructure` | draft | Running in production |
| `pubmed-query` | ready | Implemented, tested, running weekly |
| `rule-filter` | ready | Implemented, tested, running weekly |
| `llm-triage` | ready | Implemented, tested, running weekly |
| `llm-summarize` | ready | Implemented, tested, running weekly |
| `blog-publish` | ready | Implemented, tested, running weekly |
| `digest-build` | in-progress | Running in production |
| `email-send` | in-progress | Running in production |
| `domain-config` | implemented | Correct |
| `stroke-migration` | implemented | Correct |
| `neurology-setup` | draft | Has config, has workflow, likely running |

**8 of 11 specs haven't been promoted to match their actual state.** The status machine (`draft -> ready -> in-progress -> implemented`) exists to answer "what's done?" — when everything reads as "ready" but is actually deployed and running, the register loses its value as a steering instrument.

**Recommendation:** Run `/promote-spec` on all specs with working code and tests. At minimum: `project-infrastructure`, `pubmed-query`, `rule-filter`, `llm-triage`, `llm-summarize`, `blog-publish` -> `implemented`.

#### C2. contracts.yaml is empty

The file exists but contains `specs: {}`. Meanwhile:

- The project declares Layer 2 (governance) in `.arboretum.yml`
- 10 definitions exist with version headers
- Specs reference definitions in their Requires/Provides tables

At Layer 2, `contracts.yaml` should pin definition versions so that contract tests can mechanically verify that specs and definitions stay in sync.

**Recommendation:** Either populate `contracts.yaml` with the actual version pins (run `/sync-contracts`), or downgrade `.arboretum.yml` to `layer: 1` until the project is ready for contract enforcement.

#### C3. All definitions are stuck at v0/draft

Every definition file is `v0` / `draft`, yet the code they describe is implemented and running in production. The `pubmed-record` definition even has a changelog showing field additions (`source_topic`, `preindex`) — changes that in arboretum's model should trigger a version bump.

In arboretum's versioning scheme, v0 means "still being shaped." These definitions are clearly past that point.

**Recommendation:** Promote stable definitions to v1/stable. Priority: `pubmed-record`, `search-config`, `filter-config`, `literature-summary`, `summary-config`.

### Important (structural improvements)

#### I1. CLAUDE.md describes arboretum, not the project

The pubmed project's `CLAUDE.md` opens with "Arboretum is a spec-driven development framework for AI code agents" — it's the arboretum framework's CLAUDE.md, not the project's. Per arboretum's CLAUDE.md template, this file should describe what pubmed is, its pipeline stages, key commands (`python src/pipeline.py --domain stroke --test`), project-specific dev rules, and available skills.

This matters because CLAUDE.md is the AI agent's primary context for every session. A project-specific CLAUDE.md would help Claude understand the domain (clinical literature), the pipeline stages, and operational constraints without re-reading the full architecture.

**Recommendation:** Rewrite CLAUDE.md using the project template. Key sections: project overview (the pipeline), key commands, domain config structure, development rules, available skills.

#### I2. No CI for tests

The GitHub Actions workflows only run the pipeline (`src/pipeline.py --domain stroke`). There is no workflow that runs `pytest` on pushes or pull requests. Tests exist in `tests/` but are not enforced.

**Recommendation:** Add a `ci.yml` workflow that runs `pytest` on push/PR to main. This is table stakes for Layer 2.

#### I3. Unowned files not caught

The register's "Unowned Code" section is empty, but several files likely lack ownership:

- `.github/workflows/*.yml` — CI infrastructure
- `config/domains/CHANGELOG.md` — schema migration log
- `scripts/` directory contents
- `spikes/` directory contents
- `SPEC-WORKFLOW.md` — workflow documentation
- `project-graph.yaml` — orientation graph

**Recommendation:** Run `/health-check` to identify orphaned files. Assign infrastructure files to `project-infrastructure`; assign config files to `domain-config`.

### Minor (polish)

#### M1. Legacy flat config files still present

The directory listing shows `config/*.yaml` (legacy flat configs) alongside `config/domains/`. The architecture says domain-scoped config replaced these. Dead config files create confusion about which are authoritative.

**Recommendation:** Remove legacy configs if they're no longer used, or document them as the fallback when `--domain` is omitted.

#### M2. neurology-setup spec is draft but the domain is running

The register shows `neurology-setup` as `draft`, but there's a dedicated GitHub Actions workflow (`weekly-digest-neurology.yml`) that runs the neurology domain. If it's running in production, the spec should reflect that.

#### M3. stroke-migration is marked disposable but persists

The architecture marks `stroke-migration` as `[disposable]` — a one-time migration spec. If the migration is complete (it's marked `implemented`), consider archiving or removing the spec to reduce register noise.

#### M4. No PRINCIPLES.md in the project

Arboretum's bootstrap creates a `PRINCIPLES.md` in every project. It's absent from pubmed. While the principles are embedded in the workflow, the explicit file helps new contributors and serves as a touchstone.

---

## Summary Scorecard

| Area | Rating | Notes |
|------|--------|-------|
| Architecture | **Strong** | Thorough, decision-rich, well-structured, best-in-class |
| Code quality | **Strong** | Clean models, readable pipeline, good separation of concerns |
| Definitions | **Good** | All present, well-documented, but stuck at v0/draft |
| Specs | **Good** | All 11 exist with correct ownership, but statuses are stale |
| Register | **Fair** | Structure is correct but status data is wrong; unowned files not caught |
| Contracts | **Weak** | Empty despite Layer 2 declaration |
| CI/Testing | **Fair** | Tests exist in `tests/` but no CI enforcement on PR |
| CLAUDE.md | **Weak** | Describes arboretum framework, not the pubmed project |
| Human-AI collaboration | **Strong** | Clear separation in commits; human steers, AI implements |
| Operational maturity | **Strong** | Running weekly, test mode, cost tracking, dedup, error handling |

---

## Bottom Line

The pubmed project demonstrates that arboretum's architecture and spec templates produce excellent design artifacts when used by a domain expert. The ARCHITECTURE.md, definitions, domain model, and pipeline code are all high quality. The project is genuinely useful — it's running in production, delivering clinical digests weekly for ~$1/week.

The primary gap is **governance bookkeeping**: specs and definitions haven't been promoted to reflect reality, contracts.yaml is empty, and CLAUDE.md hasn't been customized. The code outpaced the paperwork.

This is a common and understandable pattern for a fast-moving solo project. The fix is mechanical: a single focused session would bring governance in line with the already-strong codebase.

---

## Recommended Actions (priority order)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| 1 | Promote spec statuses to match reality | ~15 min | Restores register as source of truth |
| 2 | Bump stable definitions to v1 | ~10 min | Enables contract testing |
| 3 | Populate contracts.yaml (or downgrade to Layer 1) | ~10 min | Aligns layer declaration with practice |
| 4 | Rewrite CLAUDE.md for the pubmed project | ~20 min | Improves every future AI session |
| 5 | Add CI workflow for pytest | ~10 min | Catches regressions on PR |
| 6 | Run /health-check to catch orphaned files | ~5 min | Completes register coverage |
| 7 | Clean up legacy flat configs | ~5 min | Removes confusion about config authority |

---

## Implications for Arboretum

This review surfaces feedback for arboretum itself:

1. **Promotion friction**: The pubmed project built working software without promoting specs. This suggests the promotion step has too much friction or isn't naturally prompted. Consider: should `/finish` auto-promote, or should `/health-check` flag "code exists but spec says draft"?

2. **CLAUDE.md bootstrap**: The project shipped with arboretum's CLAUDE.md rather than a project-specific one. The `/init-project` skill should more aggressively scaffold project-specific content (name, description, key commands) rather than copying the framework template.

3. **Layer 2 is aspirational**: The project declared Layer 2 from the start but hasn't used contracts. Either the layer should auto-detect based on actual usage, or `/health-check` should warn when Layer 2 is declared but contracts.yaml is empty.

4. **The governance artifacts that matter most**: Architecture + definitions + ownership headers carried the project effectively. Contracts and spec status were neglected without consequence. This suggests arboretum should emphasize the high-value artifacts and make the bookkeeping ones more automated or less prominent until they're needed.
