# Changelog

All notable changes to the Claude Code Stack are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning is [SemVer](https://semver.org/).

## [Unreleased]

### Fixed
- **`/project-init` `.gitignore` block now covers all runtime scratch**
  (`stack_version` → `1.1.4`). The block previously only ignored
  `.claude/scratch/`, `.claude/worktrees/`, and `.claude/cost-projections/`,
  but stack skills also write `.claude/plans/` (`/plan`), `.claude/sessions/`
  (foreman/architect→implementer→validator flow, incl. the nested
  `architect-handoff.md`), `.claude/design-targets/` (`/design-match`),
  `.claude/coverage-snapshots/` (`/coverage-snapshot`), `.claude/reviews/`
  (`/review-handoff`), `.claude/validations/` (`/validate-output`), and
  `.claude/next_prompt.md` (`/handoff`) — none of which were ignored. Stacked
  projects accumulated this scratch as untracked noise in `git status` (one
  project showed ~1,300 untracked lines). Expanded the inline block in
  `skills/project-init/SKILL.md` step 6 to the full superset and documented
  which skill owns each path. Shared/tracked files (`.claude/stack-config.json`,
  `CLAUDE.md`, `docs/handoffs/`) are explicitly kept tracked; host-level
  `~/.claude/{logs,state,projects}/` are out of scope (they live in `$HOME`,
  not the project). Existing projects pick up the wider block on the next
  `/project-init` re-run. Follow-up noted in-skill: consolidating the scratch
  paths under a single `.claude/scratch/` subtree (one ignore line) is a
  cross-skill refactor tracked separately.

### Added
- **Adaptive brevity enforcement (`brevity-drift.sh`)**: new
  `UserPromptSubmit` hook that keeps the response-style rules from decaying
  mid-session. `brevity-reinforce.sh` injects the full rules once at
  `SessionStart`, but that dilutes as context grows and the model drifts back
  to verbose prose. This hook measures the assistant's most recent response on
  every turn and injects a one-shot correction **only** when it exceeded
  budget (default: >120 words or >6 sentences) — silent when already terse, so
  it never becomes noise the model tunes out. Fail-safe: any transcript-parse
  problem yields no output and a clean exit, so the hook can never block a
  turn. Wired into the global settings template's `UserPromptSubmit` ahead of
  `dispatch-nudge.sh`; installed at tier 0.
- **Local stack-freshness checks**: `install.sh` now writes an install stamp
  to `~/.claude/.stack-install.json` (source SHA, branch, repo path, tier,
  timestamp). New shared helper `lib/stack-freshness.sh` (installed at Tier 0)
  reads the stamp, fetches the source repo, and reports how many commits the
  installed stack is behind `origin/<branch>` — best-effort and non-fatal
  (missing stamp / offline / no repo all resolve to a benign status; exit 10
  signals "behind"). Wired into two skills:
  - `/goodmorning` gains a `Stack: N behind — run update.sh` line in the daily
    summary fence (nudge only; omitted when current — never auto-updates,
    respecting the print-and-wait contract).
  - `/project-init` gains an interactive check in step 1a that offers to run
    `update.sh` before initializing when the local install is stale.
  Addresses the gap where local `~/.claude` silently drifts behind `main`
  (web sessions self-install fresh, but local installs are manual).
- **Parallel-mode safety + `dynamic-workflows` orchestration mode**: two
  hardening changes to `/foreman` for the Opus 4.8 experimental
  orchestration features.
  1. *File-ownership / no-overlap rule* — new "Parallel-mode safety"
     subsection in the `/foreman` dispatch protocol (mirrored in the
     `foreman-team-lead` agent). Under `agent-teams`/`hybrid`, only
     read-only roles (reviewer, red-team, security/accessibility-auditor,
     read-only validator) parallelize; writers (implementer, data-engineer)
     stay sequential, and parallel batches must partition by file ownership
     so no two agents edit the same file. `hybrid` reframed as the
     recommended mode: main-thread critical write path + parallel
     review/audit only.
  2. *`dynamic-workflows` mode* — added to the `orchestration_mode` enum in
     `stack-config-schema.json` and to `/foreman` step 2, with a
     "Dynamic-workflows guardrails" subsection: read-only by default,
     mandatory `/cost-gate` before every workflow launch (treated as a
     `pre-bulk-job`), no headless writes, `CLAUDE_CODE_DISABLE_WORKFLOWS=1`
     kill-switch documented, and domain-mode overrides required for
     financial-code / schema-migration / confidential work.
- **Team-status Phase 1.5 — outcome logging**: new `subagent-complete-log.sh`
  PostToolUse Agent hook pairs with the existing PreToolUse dispatch log.
  Each completion row carries `event:"complete"`, success bool, and
  `wall_seconds` (computed against the most recent matching dispatch).
  Pre-existing dispatch rows now carry `event:"dispatch"` explicitly.
  Together these unlock real per-agent metrics in
  `/agent-performance-review`, which has also been pointed at the JSONL log
  (was referencing a non-existent `subagent_runs` table).
- **Token-expiry monitor**: new manifest at
  `~/.claude/state/token-expiry.json` plus
  `scripts/check-token-expiry.sh` (modes: check / --quiet / add). A
  SessionStart hook calls `--quiet` so a fresh session prints a warning
  banner only when a tracked token is within 30 days of expiry, silent
  otherwise. Catches the failure mode where a Supabase PAT silently expires.
- **Dispatch-nudge**: new `dispatch-nudge.sh` UserPromptSubmit hook
  injects a soft system-reminder when a prompt looks like multi-step
  engineering work (build / add / implement / fix / refactor / migrate)
  in a Tier 2+ project but no `/foreman` or `/dispatch` was used. Skips
  slash commands, short prompts (<12 words), and uninitialized projects.
  Targets the habit of routing non-trivial work through the team.
- **Statusline mode chip** (Claude Code CLI only): new `statusline.sh`
  StatusLine hook reads `.claude/stack-config.json` and emits a single-line
  chip — e.g. `🟢 agent-teams · T3 · strict · schema-migration · 🔒sensitive`
  or `⚪ uninit`. Wired in the global settings template. Does not render in
  the Claude Desktop app; the SessionStart banner is the Desktop analogue.
- **SessionStart banner now shows orchestration_mode**. Old format:
  `✅ Stack active — Tier 3 · schema-migration · strict · sensitivity:normal`;
  new format prefixes with mode: `... — main-thread · Tier 3 · ...`.
  Default reads `main-thread`; flips to `agent-teams` or `hybrid` if
  `/agent-teams on|hybrid` was used.
- **Shared runtime lib**: new `lib/find-stack-config.sh` does the
  walk-up + wrapper-fallback resolution to the nearest
  `.claude/stack-config.json`. Used by `statusline.sh` and `dispatch-nudge.sh`;
  available for future hooks that need the same lookup.
- **Team-status instrumentation (Phase 1)**: every subagent dispatch is now
  logged to `~/.claude/logs/subagent-runs.jsonl` via a PreToolUse hook
  matched on the `Agent` tool. Each row carries timestamp, session_start,
  project (git root or cwd), agent, description, and model. Powers a new
  `/team-status` skill (roster + utilization + benched roles over a
  configurable window, with `--global`, `--window`, `--session`, and
  `--replan` modes) and new mini-sections in `/goodmorning` (Team line in
  the summary fence listing benched roles over 14d) and `/handoff`
  (`## Team this session` section with counts and rule-based misses for
  domain-mode-required agents that weren't dispatched). SessionStart hook
  also stamps `~/.claude/state/session-start.txt` so /handoff can compute
  session-scoped counts.
- Global CLAUDE.md now includes a "Session start protocol" directive
  telling the assistant to echo the SessionStart hook banner verbatim
  in its first response. Without this, the ✅/⚠️ banner reached the model
  as system context but was never visible to the user in the Claude Code
  Desktop app — hooks are a context-injection mechanism, not a UI surface.
  Lands in `~/.claude/CLAUDE.md` on next install via the existing
  CLAUDE_CODE_STACK_MANAGED section.
- SessionStart hook now shows a ✅ banner with current settings when a
  repo is initialized — tier, domain mode, strict-mode flag, sensitivity
  level — plus shortcut commands to change any of them (`/tier`,
  `/domain-mode`, `/strict-mode`, `/sensitivity`, `/cost-cap`) and a
  reminder that `/project-init` can be re-run safely. Surfaces the
  per-setting edit skills that were previously hidden.
- SessionStart hook now warns when opening an un-initialized git repo
  (no `.claude/stack-config.json`). Soft, non-blocking — points to
  `/project-init`. Auto-detects the stack source repo itself by structural
  markers (`agents/`, `skills/`, `scripts/install.sh`) so the warn doesn't
  fire on the stack or forks of it. Stays silent in non-git dirs.
- The bottom "── Claude Code Stack ──" multi-line marketing banner is now
  a single-line key-commands footer
  (`/goodmorning · /handoff · /project-init · /budget-guard · /operating`).
  Less noise per session, same discoverability.
- `project-init` discovery pass — before asking the user any questions,
  reads git log, branch state, prior handoffs (`.claude/next_prompt.md`,
  `docs/handoffs/`), package manifests (`package.json`, `pyproject.toml`,
  etc.), README, and any partial `.claude/` setup. Prints a 5-line
  discovery summary and pre-fills tier + domain-mode suggestions based
  on what's actually in the repo. Catches the "ran init on a mature
  in-flight project, got asked cold questions about a stack it could
  have inferred" failure mode.
- `handoff` auto-stages the `docs/handoffs/<timestamp>.md` archive when
  in a git repo, and prints an explicit commit hint. Surfaces the
  archive-vs-live split: archive is sharable with collaborators, live
  `.claude/next_prompt.md` is local-only by design.
- `verify.sh --repo=PATH` — verifies a single repo is correctly onboarded
  onto the stack: `stack-config.json` exists and is valid JSON, `stack_tier`
  is 0–5, `stack_version` is set, and `domain_mode` (if any) is a real mode
  from `config/domain-modes.json`. Soft-warns on missing §11 audit artifacts
  (ADRs, runbooks, ONBOARDING). Complements `--tier=N`, which only checks
  the global install — gives the §11 audit a one-command per-repo health
  check it previously lacked.
- CI now runs the full `tests/` suite in a `unit-tests` job
  (`test-install.yml`). Previously only the per-tier install/verify matrix
  ran — the merger, conflict, and tier-isolation tests were never exercised
  in CI. `test-merger-interactive.sh` (expect-driven) added alongside.

### Changed
- `config-merger.sh` — `merge_json` no longer silently overwrites a user's
  scalar value with the stack's on a conflict. The user's value is kept by
  default; the stack value is applied only on approval — prompted when a
  terminal is present, otherwise (or with `STACK_MERGE_NONINTERACTIVE` set)
  the user value is kept and a `<target>.merge-conflicts` report is written.
  Objects still deep-merge and arrays still concatenate. Makes
  `install.sh --mode=merge` honor its documented "preserves user
  customizations" contract.

### Fixed
- **`brevity-reinforce.sh` was never installed**: the `SessionStart`
  brevity-reinforcement hook was wired into
  `config/settings.global.template.json` but missing from every tier
  manifest's `files.global`, so `install.sh` never copied it to
  `~/.claude/hooks/`. The configured `SessionStart` command pointed at a file
  that did not exist, so the brevity baseline never fired at all — the main
  reason the response style "never happened without constant reminders."
  Registered it (and the new `brevity-drift.sh`) in the tier-0 manifest with
  matching smoke tests. (Same class of bug as the `subagent-log.sh` /
  `statusline.sh` miss below.)
- Tier manifests now correctly register `subagent-log.sh` and
  `statusline.sh`, which the team-status Phase 1 commit (a9406eb) had
  installed into the working copy but never added to `tier-2.json` /
  `tier-0.json` / `settings.global.template.json`. Fresh installs were
  therefore missing the team-utilization features. Backfilled in
  `07e0a93`.
- `scripts/update.sh` was referenced by `docs/MULTI-MACHINE.md` and the repo
  structure docs but never existed. Written: pulls latest, then re-runs
  `install.sh` in merge mode; refuses to run on a dirty working tree.
- `model-routing.json` routed `local-ops` to `ollama/qwen-2.5-coder-7b` — not
  a valid ollama tag, and a model `tier-installer.sh` never pulls. Corrected
  to `ollama/qwen2.5-coder:32b`, the code model the installer actually pulls
  and `HARDWARE.md` recommends.
- `config-merger.sh` `append_stack_section` declared `end_marker` only inside
  the replace branch; the append branch read it unset, aborting any
  `install.sh --mode=merge` of `CLAUDE.md` under `set -u` (the documented
  default + `update.sh` path). Declaration hoisted so both branches see it.
  Surfaced by wiring the test suite into CI.

## [1.1.3] — 2026-05-17

### Added
- `--skip-requirements` flag on `install.sh` — downgrades missing-command /
  missing-Keychain checks to warnings. Lets CI test install mechanics for
  every tier without the external tools (`codex`, `gemini`) the tiers expect.
- Project templates (`PROJECT-CLAUDE`, `PROJECT-ONBOARDING`, `PROJECT-README`)
  now install to `~/.claude/templates/` at Tier 0, so `/project-init` (Tier 1)
  can actually find them.

### Changed
- `stack_version` bumped to `1.1.3` in `stack-config` / `stack-defaults`
  templates and the `project-init` skill.
- `project-init` skill: completed the previously dangling step 6 (CLAUDE.md
  scaffold, docs/ tree, `.gitignore`, suggested commit); step 1 now runs
  `git init` after a single confirmation when the directory is not a repo.
- Tier-0 manifest installs all doc templates; Tier-2 manifest no longer
  redundantly re-installs the ADR/RUNBOOK templates (Tier 2 extends Tier 0).

### Fixed
- CI `test-install.yml` was failing on Tiers 2–4 (`requirement-fail: codex`).
  The workflow now installs with `--skip-requirements`.
- Removed dead `docs/MODEL-STRATEGY.md` link from README — pointed at
  `config/model-routing.json` + ADR-004 instead.
- Deleted duplicate `config/claude.md.repo.template` (byte-identical to
  `templates/PROJECT-CLAUDE.md.template`, which is now canonical).
- `config-merger.sh` `deep_merge` was broken for nested data: jq function
  args are call-by-name filters, so the recursion re-evaluated them against
  the reduce accumulator (`{}[0]` → "cannot index object with number").
  Never surfaced before because a first install `cp`s settings.json; only
  a merge-mode re-install onto an existing file hits the path. Args are now
  bound to `$`-variables. Found re-installing the stack post-1.1.3.
- foreman skill read the wrong stack-config field name (`approval_gates`);
  the schema, template, and all project configs use `required_approvals`.
  Renamed foreman's read to `required_approvals` so tier approval gates are
  actually applied. Also rewrote step 6 so foreman reads
  `domain-modes.json[domain_mode].approval_gates` and applies the domain
  review checkpoints — previously they never fired.

## [1.1.2] — 2026-05-17

### Added
- `/operating` skill — on-demand guide for running Claude Code with the stack.
- `docs/OPERATING.md` — the operating guide (source of truth for `/operating`).
- Session-start stack blurb in `session-start-handoff.sh`: what the stack is,
  the key commands, and a pointer to `/operating`.
- `remoteControlAtStartup: true` default in the Tier-0 global settings template.

### Changed
- Tier-0 manifest installs and smoke-tests the `/operating` skill.

### Notes
- Remote Control auto-enable via `remoteControlAtStartup` is currently buggy
  upstream (anthropics/claude-code#54527, OPEN — the setting does not
  auto-enable on new sessions). The reliable mechanism today is the shell
  alias `claude --remote-control`; the template setting is the correct config
  and becomes a no-op-but-correct default once #54527 lands. The earlier
  `--remote-control` CLI flag request (#39347) and the config-reset bug
  (#29929) are both CLOSED.

## [1.1.1] — 2026-05-16

### Changed
- Corrected model IDs: `llama3.2:8b` → `llama3.1:8b` (Llama 3.2 has no 8B);
  Haiku IDs given dated form; provider prefixes made consistent across
  agent definitions and `model-routing.json`.
- Tier-2 manifest rewritten to the working install format.
- Schemas `002`/`003` (`subagent_runs`, `model_audits`) placed in the
  Supabase `stack` schema for consistency with `cost_log`.

### Added
- Repo-completion pass: ops docs, runbooks, project templates, test suite,
  `.github/` CI workflows, uninstall + audit-repos scripts.
- ADR-011 (OpenAI-family review via the local Codex CLI) and ADR-012
  (Gemini-family review via the local Gemini CLI).
- `docs/AUDIT-PASS.md` — the retroactive per-repo audit plan.

### Notes
- The stack was rolled out to every repo in the rollout (Tiers 1–5), one PR per
  repo. Each repo gained `.claude/stack-config.json`, retroactive ADRs,
  runbooks, `docs/ONBOARDING.md`, and a cross-repo data-flow doc. That
  rollout is tracked in each repo's `docs/handoffs/`, not here.

## [1.0.0] — 2026-05-15

### Added
- Initial stack release: Tiers 0-5
- 21 subagent definitions
- 15 skills
- 6 hooks
- Multi-provider model routing (Anthropic, OpenAI, Google, Ollama)
- Self-improvement skills (model-audit, agent-performance-review)
- Per-project tier selection via /project-init
- Strict mode foreman orchestration
- Apache 2.0 license
- 8 initial ADRs

### Notes
- Tier 4 self-improvement requires 30 days of subagent_runs data to be meaningful
- Phase 2 (Claude Code Plugin distribution) deferred until v1 proven across the maintainer's production repos
