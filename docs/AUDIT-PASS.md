# Retroactive Audit Pass

How to bring an existing repo onto the stack after the stack itself is
installed and verified. Run this once per repo you want to retrofit.

## Order of operations

When retrofitting multiple repos, go lowest blast radius first: thin
monitoring or utility repos before complex application repos. Auditing a
simple repo first builds confidence in the process, and the lessons learned
carry into the harder ones.

A rough ordering heuristic:

1. Monitoring / drift-checker repos — Tier 1, low risk
2. Isolated services (e.g. an MCP server) — Tier 2
3. Well-defined delivery pipelines — Tier 3
4. Complex application repos — Tier 4
5. Highest-complexity or multi-surface repos (dashboards, large data
   pipelines) — Tier 5

## Per-repo audit flow

Each repo audit is its own Claude Code session. **DO NOT BATCH.**

### Step 1: Confirm tier choice
- Decide the tier for this repo (use the heuristic above as a starting point;
  override based on the repo's real complexity).
- Use `/project-init` in the repo.

### Step 2: Backfill ADRs for existing decisions
- Identify the major past decisions (e.g. a monorepo split, a choice of
  integration platform, deploy-script-vs-CLI, where a shared schema lives).
- For each: write a retroactive ADR. Use the template. Status: "Accepted"
  (you're documenting an existing decision, not proposing a new one).
- Number them starting from the next available number.
- This is bus-factor protection — a successor reads these to understand WHY
  things are the way they are.

### Step 3: Write runbooks for deployed components
- For each deployed component (e.g. an edge function): create
  `docs/runbooks/<component>.md`.
- Use the template.
- Pull from any existing CLAUDE.md "Operational facts" sections — that
  content gets distributed into runbooks.
- After runbooks exist, the CLAUDE.md can be slimmed down (Liu's test).

### Step 4: Write ONBOARDING.md
- For human successors.
- Use the template.
- 5-step walkthrough specific to this repo.

### Step 5: Cross-repo data-flow diagram
- Mermaid or simple ASCII.
- Which tables this repo writes; which tables this repo reads from elsewhere.
- Save at `docs/architecture/data-flow.md`.
- Eventually: aggregate into a top-level cross-repo data-flow doc.

### Step 6: Add stack-config.json + per-repo settings
- Run `/project-init` if not already done.
- Choose tier and domain mode (`financial-code`, `schema-migration`,
  `deploy`, etc.).
- Configure subagents per the tier.

### Step 7: Configure subagents for this repo's domain
- Financial repos → `domain_mode: financial-code` in stack-config.
- Bulk data-processing repos → `domain_mode: data-operation`.
- UI / dashboard repos → `domain_mode: ui-design`.

### Step 8: Add cost-log integration to LLM-using scripts
- Find every script that calls an LLM.
- Wrap calls to write to the `cost_log` table.
- Already-shipped scripts get instrumented retroactively.

### Step 9: Bring CLAUDE.md up to standard
- Apply Liu's test line-by-line.
- Move operational content to runbooks.
- Move decisions to ADRs.
- Result: CLAUDE.md is short, focused on past-failure warnings and
  environmental constraints.
- Per-repo CLAUDE.md after this should be under 100 lines for most repos.

### Step 10: Verify
- `./scripts/verify.sh --repo=<path>` (per-repo onboarding check).
- Open Claude Code in the repo; verify foreman dispatches correctly.

### Step 11: Commit + open PR
- Commit message: `chore: stack audit at tier <N>`
- PR description summarizes: ADRs added, runbooks added, CLAUDE.md changes,
  tier chosen.
- Merge after review.

## Estimated time

- Simple repo (Tier 1-2): ~2 hours
- Medium repo (Tier 3): ~3 hours
- Complex repo (Tier 4-5): ~4-5 hours

Spread across multiple sessions. Each repo is a self-contained PR.

## Success criteria

For each repo:
- [ ] stack-config.json present with explicit tier
- [ ] CLAUDE.md under 100 lines, passes Liu's test
- [ ] All major past decisions captured in ADRs
- [ ] All deployed components have runbooks
- [ ] ONBOARDING.md exists and a successor could follow it
- [ ] docs/handoffs/ archive started
- [ ] Cross-repo data-flow documented
- [ ] LLM-using scripts log to cost_log
- [ ] Foreman dispatches correctly in this repo

## Post-audit follow-ups

After every repo is audited, a few project-wide items are worth a final
pass — they need the complete picture rather than a single repo's view:

- **Deployed-component vs. repo-source reconciliation.** A shared backend
  often accumulates more deployed components than the audited repos account
  for. Cross-reference every deployed component against repo source and
  classify each as owned, externally owned, or orphaned. Orphaned active
  components are a security and cost surface — retire them deliberately.
- **Dormant / dead-code review.** Components gated behind permanently-false
  flags, or superseded engines still deployed, should be either revived or
  removed. These are product decisions, not cleanup — surface them to the
  maintainer rather than deciding unilaterally.
