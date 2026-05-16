# Backup & Disaster Recovery

## What gets backed up automatically

- Every `install.sh` run creates `~/.claude.backup.<timestamp>/`.
- Last 5 backups retained; older ones pruned automatically.

## What's NOT automatically backed up

- `<project>/.claude/` directories — these are per-project; rely on git.
- Supabase data (cost_log, subagent_runs, model_audits) — rely on Supabase's backup.
- Project state (handoffs, ADRs, runbooks in docs/) — committed to git per repo.

## Disaster scenarios

### "I deleted ~/.claude/ by accident"
- Restore from `~/.claude.backup.<latest>/`
- `cp -R ~/.claude.backup.<latest>/ ~/.claude/`

### "I want to roll back to before the last install"
- Same as above. Backup taken before install.

### "Stack is broken; I want to start over"
- `./scripts/uninstall.sh` (interactive, asks first).
- Then `./scripts/install.sh --tier=N --mode=fresh`.

### "Laptop died; need to set up on new machine"
1. Install Claude Code from anthropic.com.
2. Clone stack repo: `git clone git@github.com:bschonbrun/claude-code-stack.git`.
3. Add API keys to new machine's Keychain.
4. Run `./scripts/install.sh --tier=N`.
5. Per-project state lives in git; clone each project as usual.
6. Cost log + subagent_runs are in Supabase, accessible from any machine.

### "Stack repo was lost"
- It's on GitHub. Re-clone.
- If GitHub is also gone (catastrophic): the artifacts in this Claude chat ARE the source.

## Backup strategy for the stack repo itself

- GitHub is primary remote.
- Recommend a second remote (Codeberg, GitLab, or just `bundle` to iCloud Drive monthly).
- Tag releases for stable points.

## Per-project backup

- Use git remotes; that's the backup.
- `docs/handoffs/` and `docs/ADRs/` are in the repo — committed regularly.
- Cost-projection, coverage-snapshot, validation files are in `.claude/` which is gitignored — these are session-private and intentionally not backed up.
