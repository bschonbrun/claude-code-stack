# Claude Code Stack — org admin repo

This repo auto-installs the [Claude Code Stack](https://github.com/bschonbrun/claude-code-stack)
cloud bootstrap into every repo in your org tagged with a GitHub topic. Once a
repo has the bootstrap, its Claude Code **cloud** sessions (web + iOS)
self-install the stack — so `/goodmorning`, `/handoff`, etc. just work.

It runs entirely on GitHub Actions — **no server to host**. A reconciler opens
one pull request per repo, idempotently (skips repos already current).

## What it does

- **Scope:** repos in your org tagged with the topic in `config.yml`
  (default `claude-stack`).
- **Action:** adds `.claude/hooks/cloud-bootstrap.sh` + a `SessionStart` hook +
  a portable-core skill set, via a PR.
- **When:** hourly cron + a manual **Run workflow** button. New tagged repos are
  picked up on the next run.

## One-time setup

1. **Create this repo** from the template (the easiest path is to run
   `/team-init` from a local Claude Code session with the stack installed; it
   scaffolds and pushes everything). Or copy the `templates/team-admin/`
   contents into a new repo by hand.

2. **Add the token secret.** Create a GitHub **fine-grained PAT** with access to
   the repos you want managed and these permissions: **Contents: Read and
   write**, **Pull requests: Read and write**, **Metadata: Read**. In this repo:
   *Settings → Secrets and variables → Actions → New repository secret*:
   - Name: `STACK_RECONCILE_TOKEN`
   - Value: the PAT

3. **Edit `config.yml`:** set `org`, confirm `topic`/`tier`, list any `exclude`.

4. **Tag your repos.** On each repo you want managed: *About → ⚙ → Topics* → add
   `claude-stack` (or your chosen topic).

5. **Dry run first.** Actions tab → *Claude Stack reconcile* → **Run workflow**
   (leave *dry_run* checked). Read the log — it lists repos it *would* change.

6. **Go live.** Set `enabled: true` in `config.yml` and commit. The hourly cron
   (and live manual runs) now open PRs. Review + merge them per repo.

## Safety

- **`enabled: false`** (default) forces dry-run — nothing is written until you
  flip it.
- Manual runs default to **dry-run**.
- The reconciler **never overwrites** a repo's existing `.claude/settings.json`
  — it deep-merges only the `SessionStart` entry — and skips portable-core
  skills that already exist.
- Changes land as **pull requests**, so branch protection and review apply.
- A `.claude/.stack-bootstrap-version` stamp lets it skip up-to-date repos and
  refresh stale ones.

## Reference

- Cloud distribution model + paths: <https://github.com/bschonbrun/claude-code-stack/blob/main/docs/CLOUD.md>
