---
name: consolidate
description: Reconcile a branch's code with its governed specs — regenerate AUTO sections, preserve HUMAN sections (stale-flagging broken refs), append harvested decisions from design specs and plans
disable-model-invocation: false
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: "[path/to/design-spec.md]"
layer: 0
---

# Consolidate

Reconcile the branch with its governance. For each governed spec touched by this branch:

- **AUTO sections** (frontmatter, status, Tests, Implementation Notes → Design record) regenerate silently from current code, tests, and citation files.
- **HUMAN sections** (Purpose, Behaviour, free-text Implementation Notes) are preserved. v1 stale detection scans for file-path-token references that no longer exist on disk; any matches are surfaced to the user for review. (Function-name and test-case detection are deferred — see issue #108.)
- **APPEND-AUTO sections** (Decisions) accumulate new rows harvested from design specs (`docs/superpowers/specs/*-design.md`) and plans (`docs/plans/*.md`) referenced by this spec. Existing rows are never modified or removed. The Source column is the idempotency key.

When all reconciliation succeeds, the spec's status flips automatically: `draft → active` (first reconciliation) or `stale → active` (after drift). Design specs and plans are **retained as permanent historical records** — never deleted by this skill.

## Procedure

### Step 1: Detect base branch and gather changes

1. Determine the base branch:

   ```bash
   git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main"
   ```

2. Find the merge base:

   ```bash
   git merge-base <base-branch> HEAD
   ```

3. List all changed files on this branch:

   ```bash
   git diff --name-only <merge-base>...HEAD
   ```

4. If no changed files are found, exit early: "No changes to consolidate on this branch."

5. Categorise each changed file:

   | Category | Glob patterns | Needs spec ownership? |
   |----------|--------------|----------------------|
   | Source | `src/**`, `scripts/**`, `.claude/skills/**/SKILL.md`, `skills/**/SKILL.md`, `.claude/hooks/**`, `tests/**` | Yes |
   | Governance | `docs/specs/**`, `docs/REGISTER.md`, `docs/ARCHITECTURE.md`, `docs/definitions/**`, `contracts.yaml` | No (outputs of this process) |
   | Ephemeral | `docs/plans/**`, `docs/superpowers/**` | No (harvest, don't own) |
   | Config/meta | `CLAUDE.md`, `.gitignore`, `settings.json`, `*.yaml` (non-contracts) | No |

   Files not matching any pattern default to **Source** (need ownership).

6. Present a summary to the user.

### Step 2: Identify design specs and plans for harvest

1. If `$ARGUMENTS` is a path, treat it as the design spec being harvested.

2. Otherwise, scan `docs/superpowers/specs/*.md` for design specs and `docs/plans/*.md` for plans. Both are harvest sources for the Decisions table.

3. If governed specs being updated already cite design specs / plans in their `### Design record` subsection, those are also harvest sources (decisions accumulate over a spec's lifetime).

4. Present the list of harvest sources to the user. They are **not deleted** after harvest — they are permanent records.

### Step 3: Check existing governance state

1. Verify required template:

   ```bash
   ls docs/templates/spec.md docs/templates/register.md 2>/dev/null
   ```

   If either is missing, error: "Required template missing: `docs/templates/<name>.md`. Cannot proceed." Stop.

2. Check `docs/REGISTER.md`:
   - If yes: read it. Build a map of file → owning spec from the "Spec Index" table's "Owns" column.
   - If no: bootstrap from `docs/templates/register.md`.

3. Check `docs/specs/`:
   - If yes: read existing governed specs to understand current coverage.
   - If no: create it.

4. Cross-reference source files from Step 1 against the register map:
   - **Owned + changed** — file has a spec owner; the spec needs reconciliation. Read the owning spec.
   - **Unowned** — file has no spec owner; needs assignment to a new or existing spec.

### Step 4: Propose reconciliation plan

Present a structured reconciliation plan to the user:

```
## Reconciliation Plan

### Bootstrapping required
- [ ] Create `docs/REGISTER.md` from template (only if absent)
- [ ] Create `docs/specs/` directory (only if absent)

### New governed specs to create
- `docs/specs/<proposed-name>.spec.md`
  - Would own: <file1>, <file2>, ...
  - Status on creation: `active` if code already exists for the listed owns, otherwise `draft`
  - Content source: harvest from `<design-spec-path>` (if provided) or code analysis only

### Governed specs to reconcile (already exist; touched by this branch)
- `docs/specs/<existing-name>.spec.md` — owns `<changed-file>`
  - AUTO regenerate: frontmatter, Tests, Design record
  - HUMAN scan: Purpose, Behaviour, free-text Implementation Notes
  - Decisions to append: <count> new rows from design specs / plans

### Design specs and plans to harvest decisions from
- `docs/superpowers/specs/<file>.md` (retained, not deleted)
- `docs/plans/<file>.md` (retained, not deleted)

### # owner: header rewrites needed (Path B grouping reconciliation)
<!-- Only show if final grouping differs from headers committed in source files. -->
- `<source-file>`: `# owner: <old-name>` → `# owner: <new-name>`

### Files not requiring spec ownership
- <config/meta/governance/ephemeral files>
```

When grouping files, follow `workflows/README.md ## Spec sizing`. Test files belong with the source files they test.

Wait for user approval before proceeding.

### Step 5: Execute on approval

#### 5a. Bootstrap (if needed)

If `docs/specs/` does not exist, create it. If `docs/REGISTER.md` does not exist, create it from `docs/templates/register.md`.

#### 5b. Create new governed specs

For each new spec in the approved plan:

1. Read `docs/templates/spec.md` for the structure.

2. Determine status:
   - If owned files already exist on disk and there's evidence the code matches the spec's intended behaviour (Path B post-build): `active`.
   - Otherwise (Path A pre-build, or pre-implementation draft): `draft`.

3. Populate sections:
   - **Purpose** — if a design spec is provided, harvest from its problem statement. Otherwise stub: `<!-- HUMAN — Why does this exist? -->`
   - **Behaviour** — if a design spec is provided, harvest from its deliverable spec / procedure. Otherwise stub: `<!-- HUMAN — What should the system do? -->` Per the collaborative authoring model, do NOT generate Behaviour from code in code-analysis-only mode.
   - **Tests** (AUTO) — list each test file under owns by name with tier; declare "N/A — [reason]" for inapplicable tiers.
   - **Implementation Notes → Design record** (AUTO) — citation list of design specs and plans referenced by this spec.
   - **Decisions** (APPEND-AUTO) — initial row(s) harvested from referenced design specs / plans (see Decision harvest below).

4. Present the drafted spec to the user. Wait for approval before writing.

5. Write the spec to `docs/specs/<name>.spec.md`.

#### 5c. Reconcile existing governed specs (regeneration)

For each existing spec touched by this branch:

1. Read the current spec.

2. **Regenerate AUTO sections** silently:
   - Frontmatter (name, owner, owns) — recompute from REGISTER and current code.
   - Status — see Step 5e (auto-flip rules below).
   - Tests — re-derive from current test files.
   - Implementation Notes → Design record — rebuild citation list from referenced design specs and plans.

3. **Scan HUMAN sections** (Purpose, Behaviour, free-text Implementation Notes) for stale references. See "Stale reference detection" below. For each section that has stale flags, prompt the user.

4. **Harvest decisions** from referenced design specs and plans into the Decisions table. See "Decision harvest" below.

5. Present diff of all changes to the user. Wait for approval before writing.

#### 5d. Update REGISTER.md

1. Add/update entries for each new or reconciled spec in the "Spec Index" table.
2. Update the "Definitions Index" if new specs reference definitions.
3. Update the "Dependency Resolution Order" if dependencies changed.

#### 5e. Auto-flip status

Per the simplified state machine (`draft / active / stale`):

- A spec at `draft` whose reconciliation succeeded with code present → flip to `active`.
- A spec at `stale` whose reconciliation resolved the drift → flip to `active`.
- A spec at `active` with no detected drift → leave at `active` (no-op).
- A spec at `draft` with no code yet → leave at `draft` (no-op).

No prompts. The flip happens automatically as part of writing the reconciled spec.

#### 5f. Update contracts.yaml

If `contracts.yaml` exists and new specs reference shared definitions, add version pins. Otherwise skip.

#### 5g. # owner: header rewriting (Path B grouping reconciliation)

If the approved reconciliation plan included header rewrites (because final grouping differs from what files committed to):

1. For each affected source file: edit the first comment line in place (`# owner: <new-name>`).
2. Update the corresponding `Owns` cell in REGISTER.md (already done in 5d, but verify).

### Step 6: Verify

1. Run `scripts/health-check.sh`.
2. Present results.
3. Summarise what was done:

   ```
   ## Consolidation Complete

   ### Created
   - <new spec files>
   - <REGISTER.md if bootstrapped>

   ### Reconciled
   - <spec> — AUTO regenerated; HUMAN unchanged; <N> decisions appended; status: <new>
   - <spec> — AUTO regenerated; <N> HUMAN sections stale-flagged; status: <new>

   ### Retained (no deletion)
   - <design specs and plans referenced>

   ### Header rewrites
   - <files whose # owner: was rewritten>

   ### Health Check
   <pass/fail summary>
   ```

## Regeneration model

The governed spec is regenerated on each pass to reflect current code, while preserving human-authored content and accumulating decision history.

Sections are classified by authorship:

- **AUTO** — frontmatter, status, Tests, Implementation Notes → Design record subsection. Regenerated silently from current code/tests/citations on every pass.
- **HUMAN** — Purpose, Behaviour, free-text Implementation Notes. Never overwritten. Scanned for stale references; flagged matches prompt the user.
- **APPEND-AUTO** — Decisions. New rows harvested from design specs and plans referenced by this spec. Existing rows are never modified or removed. The Source column is the idempotency key — `/consolidate` does not re-add a decision whose source artifact + decision ID is already cited.

## Stale reference detection (HUMAN sections)

For each HUMAN section in an existing spec being regenerated:

1. Extract candidate references via regex:
   - Backtick-wrapped paths: `` `docs/foo.md` `` matches `docs/foo.md`.
   - Naked path tokens matching `(\.?\w[\w./-]*\.\w+)`.
2. For each candidate, check `[ -e "$candidate" ]` (file exists).
3. If any references are missing, the section is "stale-flagged":
   - Print: "Stale references in `<spec-file>` § `<section-name>`: `<missing-refs>`"
   - Prompt: "Review the section now? (y / n / skip)"
   - On `y`: present the section for inline edit.
   - On `n` / `skip`: leave unchanged but record the flag for the consolidation summary.

Function-name and test-case stale detection is out of scope for v1 (see issue tracker for the richer guided-reconciliation flow).

## Decision harvest from design specs and plans

For each design spec or plan referenced in the spec's `### Design record` subsection:

1. Read the file.
2. Extract decision-shaped content: tables with "Decision" / "Alternatives" columns, or numbered "Decision summary" lists.
3. For each decision found, check whether a matching row already exists in the spec's Decisions table — match by `Source artifact path + decision ID`.
4. If no match, append a new row with `Source = "<artifact-path> (decision <ID>)"`.

Idempotency: re-running `/consolidate` with no new design specs / plans produces zero new rows.

## # owner: header rewriting (Path B grouping reconciliation)

Path B source files commit to a `# owner:` value matching the design-spec topic. If `/consolidate` decides at execution time to group files into a different spec name (per cohesion criteria), it must rewrite the headers and the REGISTER.md entry.

Procedure:

1. After deciding on the final grouping (Step 4 reconciliation plan), compare each source file's current `# owner:` value to its assigned spec name.
2. For each mismatch: edit the file's first comment line in place (`# owner: <new-spec-name>`).
3. Update the corresponding `Owns` cell in REGISTER.md.
4. Confirm with the user before applying — header rewrites are visible commits and the user may prefer to keep the original grouping.

## Important Notes

- **Never auto-commit.** All changes to governed documents require user approval before writing to disk. Present drafts and proposed edits, then wait for confirmation.
- **Design specs and plans are permanent records.** Never delete them. They are cited from the governed spec's Design record subsection and harvested for decisions.
- **Respect collaborative authoring.** When harvesting from design specs, transplant human-authored content. When no design spec exists, stub Behaviour for the human to write — do not generate it from code.
- **Status auto-flips.** No "promote to active" prompts. `draft → active` (or `stale → active`) happens automatically when reconciliation succeeds. The human's commitment moment is the act of running `/consolidate`.
- **Idempotency.** Running this skill twice with no intervening code or harvest changes produces no diff. AUTO sections regenerate to the same content; HUMAN sections are unchanged; the Decisions table is unchanged because the Source column dedups already-cited decisions.

$ARGUMENTS
