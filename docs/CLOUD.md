# Cloud sessions (Claude Code on the web + iOS)

How to make the stack's custom skills/commands (`/goodmorning`, `/handoff`,
`/foreman`, …) work in Claude Code **cloud** sessions — not just the Mac
Desktop app.

## Why this is needed

The Mac Desktop app runs Claude Code locally and reads your real home
directory: `~/.claude/skills/` and `~/.claude/commands/`. That's where your
personal commands live, so they "just work."

**Cloud sessions (web/iOS) run in an isolated, ephemeral container.** The repo
is cloned fresh at container start, but your laptop's `~/.claude` is **never**
synced up. A cloud session only ever sees skills/commands from two places:

1. **The repo itself** — anything committed under the repo's `.claude/`
   (`.claude/skills/<name>/SKILL.md`, `.claude/settings.json`, `.claude/hooks/…`).
   Cloned with the repo; works on every surface.
2. **The container's `~/.claude/`** — starts essentially empty, and is only
   populated by whatever the environment's **SessionStart setup script** runs
   at boot.

That's the whole reason a project-committed skill works in cloud but a personal
`~/.claude/` skill does not.

> **Note on terminology:** in this stack, every slash command *is* a skill
> (`skills/<name>/SKILL.md`). There is no separate `commands/` directory.
> `/goodmorning`, `/handoff`, etc. are all skills. When the docs say
> "skills/commands," they mean these SKILL.md directories.

## Two distribution paths

| Path | Mechanism | Scope | Set up where |
|---|---|---|---|
| **A. Personal / global** | Environment setup script clones this repo and runs `install.sh` into `~/.claude` | **Every** cloud session of **every** repo | Once, in the Claude Code web **environment** config |
| **B. Project-specific** | `/project-init` commits a bootstrap hook + portable-core skills into the repo's `.claude/` | **One** repo, travels with it | Per repo, via `/project-init` |

Both paths run the **same** logic — `scripts/cloud-bootstrap.sh` → token-auth
clone → `install.sh --tier=2 --skip-requirements` (idempotent: backs up
`~/.claude`, deep-merges JSON, user wins on conflict). They share a per-boot
marker (`/tmp/.claude-stack-cloud-bootstrap.done`), so if both fire, the first
wins and the second no-ops.

---

## Path A — register the environment setup script (covers every repo)

Setup scripts are configured **per environment**, not stored in a target repo.
See the official docs:
<https://code.claude.com/docs/en/claude-code-on-the-web>.

### 1. Add the repo-read token to the environment

This repo is **private**, so the clone needs a credential. In your Claude Code
web environment config, add an environment variable / secret:

| Name | Value |
|---|---|
| `CLAUDE_STACK_REPO_TOKEN` | A GitHub **fine-grained PAT** scoped to `bschonbrun/claude-code-stack` with **Contents: read-only** (or a classic token with `repo` scope) |

Never paste the token into any file in any repo. It lives only in the
environment config. The bootstrap reads it from the environment and passes it
to `git` via `GIT_ASKPASS`, so it never lands in `argv` or `.git/config`.

Optional overrides (defaults shown):

| Name | Default |
|---|---|
| `CLAUDE_STACK_REPO` | `github.com/bschonbrun/claude-code-stack` |
| `CLAUDE_STACK_REF` | `main` |
| `CLAUDE_STACK_TIER` | `2` |

### 2. Confirm the network policy allows the clone

The clone only works if the environment's **network policy** permits outbound
git to GitHub. If your environment uses a restricted policy, allow
`github.com` (and its `codeload`/`objects` hosts). If the policy blocks it, the
bootstrap warns and exits 0 — the session still works, just without the stack.

### 3. Register the setup script

Paste this as the environment's **setup script** (it inlines the bootstrap so
the target repo doesn't need to contain anything):

```bash
# Claude Code Stack — cloud bootstrap (environment setup script)
# Requires CLAUDE_STACK_REPO_TOKEN to be set in this environment.
set -u
REPO="${CLAUDE_STACK_REPO:-github.com/bschonbrun/claude-code-stack}"
REPO="${REPO#https://}"; REPO="${REPO%.git}"
REF="${CLAUDE_STACK_REF:-main}"
TIER="${CLAUDE_STACK_TIER:-2}"

if [ -z "${CLAUDE_STACK_REPO_TOKEN:-}" ]; then
  echo "[stack-cloud-bootstrap] CLAUDE_STACK_REPO_TOKEN not set; skipping." >&2
  exit 0
fi
export CLAUDE_STACK_REPO_TOKEN

TMP="$(mktemp -d)"; ASKPASS="$(mktemp)"
trap 'rm -rf "$TMP" "$ASKPASS"' EXIT
printf '#!/bin/sh\nexec printf "%%s" "$CLAUDE_STACK_REPO_TOKEN"\n' > "$ASKPASS"
chmod +x "$ASKPASS"

GIT_TERMINAL_PROMPT=0 GIT_ASKPASS="$ASKPASS" \
  git clone --depth 1 --branch "$REF" \
  "https://x-access-token@${REPO}.git" "$TMP/stack" \
  && bash "$TMP/stack/scripts/install.sh" --tier="$TIER" --skip-requirements
```

This is intentionally the same flow as the committed
[`scripts/cloud-bootstrap.sh`](../scripts/cloud-bootstrap.sh). If you prefer to
keep one source of truth, you can instead make the environment setup script a
two-liner that clones once and execs the committed script:

```bash
git clone --depth 1 \
  "https://x-access-token:${CLAUDE_STACK_REPO_TOKEN}@github.com/bschonbrun/claude-code-stack.git" \
  /tmp/claude-stack \
  && CLAUDE_CODE_REMOTE=true bash /tmp/claude-stack/scripts/cloud-bootstrap.sh
```

(The inline version above is preferred because it keeps the token out of the
clone URL / process list.)

---

## Path B — make a single repo self-bootstrap (no env config)

Run `/project-init` in the target repo and accept the **cloud-session support**
prompt. It commits, idempotently:

- `.claude/hooks/cloud-bootstrap.sh` — a copy of this repo's bootstrap.
- A `SessionStart` entry in `.claude/settings.json` that runs it.
- A **portable-core** skill set (`config/portable-core-skills.json`:
  `goodmorning`, `handoff`, `operating`, `project-init`) copied into
  `.claude/skills/` so the core workflow exists even before the clone finishes
  or if the network policy blocks it.

The repo still needs `CLAUDE_STACK_REPO_TOKEN` defined in whatever environment
its cloud sessions run in (the full stack arrives via the clone). The committed
portable-core skills work with no token at all.

---

## Verify `/goodmorning` resolves in a fresh cloud session

1. Start a fresh cloud session (web or iOS) on any repo whose environment has
   `CLAUDE_STACK_REPO_TOKEN` set.
2. The SessionStart bootstrap should print an install log (the same one
   `install.sh` emits). Confirm it ends with `All checks passed.`
3. In the session, run a quick check:
   ```bash
   ls ~/.claude/skills/goodmorning/SKILL.md && echo "goodmorning present"
   ```
4. Type `/goodmorning`. It should resolve and run the boot summary.

If it doesn't resolve:
- **No install log at all** → the setup script isn't registered (Path A) or the
  repo's hook isn't committed/executable (Path B).
- **`CLAUDE_STACK_REPO_TOKEN is not set`** warning → add the token to the
  environment config.
- **`could not clone … after 3 attempts`** → the network policy is blocking
  GitHub, or the token lacks read access to the repo.

---

## Should we package this as a Claude Code plugin instead?

**Recommendation: not yet — and a plugin would not replace the bootstrap
anyway.** Reasoning:

- **A plugin doesn't solve the cloud problem on its own.** The container starts
  with an empty `~/.claude`. A plugin would still have to be *installed* at
  session start — i.e. you'd still need a setup-script step
  (`claude plugin marketplace add … && claude plugin install …`). And a
  **private** marketplace needs the same token handling we just built. So the
  bootstrap (or its equivalent) is required either way; the plugin would only
  change the *install command*, not remove the setup step.
- **ADR-007 already deferred plugins until "v1 proven,"** and
  [`PHASE-2-PLUGIN.md`](./PHASE-2-PLUGIN.md) lists the triggers (Tier 4 live
  30+ days, repos audited, no breaking changes for 2 weeks, privacy scrub,
  polished README). Those gates haven't been met. Converting now trades a
  working, iterable git-clone flow for an opinionated format mid-iteration.
- **What we built is plugin-compatible.** When the Phase-2 triggers hit, the
  cloud story becomes a one-line swap inside the *same* setup script: replace
  the `git clone … && install.sh` step with `claude plugin install …`. The
  token mechanism, network-policy caveat, idempotency marker, and `/project-init`
  wiring all carry over.

**Verdict:** keep the git-clone bootstrap as the cloud mechanism now; revisit
the plugin packaging as part of Phase 2, at which point it's an install-command
swap rather than a re-architecture.
