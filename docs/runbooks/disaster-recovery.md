# Runbook: Disaster recovery

**Severity tier:** Critical

## Scenarios

### Lost ~/.claude/

- Restore from `~/.claude.backup.<latest>/`.
- If no backup: re-run `./scripts/install.sh --tier=<N>`.

### Lost laptop

1. Get new laptop, install macOS, Homebrew, Claude Code.
2. Restore API keys to Keychain (from your own records — e.g. a password manager).
3. Clone stack: `git clone git@github.com:bschonbrun/claude-code-stack.git`.
4. Install: `./scripts/install.sh --tier=<N>`.
5. Clone work projects.
6. cost_log + subagent_runs in Supabase — already there.

### Lost stack repo (GitHub down)

- Repo also lives in `~/code/claude-code-stack/` on each machine. Push to alternate remote.
- If lost entirely: the 5 artifacts in the original Claude chat ARE the source.

### Lost Supabase project

- Supabase auto-backs-up. Restore via Supabase dashboard.
- If catastrophic loss: cost_log + subagent_runs history gone. Stack continues to work; perf reviews start fresh.

### Corruption in CLAUDE.md or settings.json

- Restore from backup: `cp ~/.claude.backup.<latest>/CLAUDE.md ~/.claude/CLAUDE.md`
- Or re-install: `./scripts/install.sh --tier=<N> --mode=merge` (preserves user edits, restores stack content).

## Drill

Run a recovery drill quarterly:
1. Move `~/.claude/` aside.
2. Run install from clean.
3. Verify everything works.
4. Restore the moved-aside dir if you want your customizations back.

This catches drift between "what's in the repo" and "what's actually running."
