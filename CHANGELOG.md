# Changelog

All notable changes to the Claude Code Stack are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning is [SemVer](https://semver.org/).

## [Unreleased]

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
- The stack was rolled out to all 7 production repos (Tiers 1–5), one PR per
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
- Phase 2 (Claude Code Plugin distribution) deferred until v1 proven across the maintainer's 7 production repos
