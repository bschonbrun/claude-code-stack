# Runbook: Updating the stack to a new version

**Severity tier:** Medium

## What this is

Pulling the latest stack changes and re-installing.

## Symptoms

- Want to use new features.
- Bug fix released.
- /librarian recommends a refresh.

## Steps

1. Backup current state (auto, but verify):
   ```bash
   ls -dt ~/.claude.backup.* | head
   ```
2. Pull latest:
   ```bash
   cd ~/code/claude-code-stack
   git fetch
   git log HEAD..origin/main --oneline  # see what's new
   ```
3. Review changes — especially CHANGELOG.md and any new ADRs.
4. Update:
   ```bash
   git pull
   ./scripts/install.sh --tier=<your tier> --mode=merge
   ```
5. Verify:
   ```bash
   ./scripts/verify.sh --tier=<your tier>
   ```
6. Test in a project:
   - Open Claude Code in a project.
   - Try a recent skill.
   - Watch for unexpected behavior.

## If something breaks

```bash
# Roll back
~/.claude && rm -rf ~/.claude
cp -R ~/.claude.backup.<latest> ~/.claude
# investigate
```

## Multi-machine

Update each machine separately. Don't try to sync via filesystem — each machine pulls from git.
