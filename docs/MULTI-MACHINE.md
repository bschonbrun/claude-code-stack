# Multi-Machine Setup

the maintainer's situation: MacBook Air (current), possibly MacBook Pro (future), plus an offline Ollama server (no stack install there).

## What's machine-local vs shared

| Resource | Per-machine | Shared |
|---|---|---|
| `~/.claude/` content | yes (machine config) | repo is source of truth |
| API keys (Keychain) | yes (per-machine) | no |
| Project source code | yes (git checkout) | git remote shared |
| `docs/handoffs/` | git-tracked, shared via remote | yes |
| `docs/ADRs/`, runbooks, postmortems | git-tracked, shared | yes |
| `cost_log` | no | yes (Supabase) |
| `subagent_runs` | no | yes (Supabase) |
| `model_audits` | no | yes (Supabase) |
| `.claude/cost-projections/` etc. | per-machine, gitignored | no |

## Setting up a second machine

1. Install Claude Code (from anthropic.com).
2. Clone the stack repo: `git clone git@github.com:bschonbrun/claude-code-stack.git`.
3. Add API keys to Keychain (don't sync Keychain across machines — manual is safer).
4. Run `./scripts/install.sh --tier=<same as primary>`.
5. Clone work projects.
6. Cost log + subagent_runs already have history from primary machine.

## Keeping machines in sync

- Stack updates: `cd claude-code-stack && git pull && ./scripts/update.sh`. Do this regularly on each machine.
- API keys: when rotating, rotate on each machine. Don't try to sync via iCloud Keychain — security risk.
- Custom local additions (skills/agents not in the stack): commit to a personal branch of claude-code-stack, push, pull on each machine.

## Offline Ollama server

Per the maintainer's plan: an offline server running Ollama for sensitive-data work.

- Server install: standard Ollama install on the server OS.
- Network: the server is intentionally offline; access via local network only.
- Local-ops subagent on the maintainer's laptop can route to the server (configure via OLLAMA_HOST env var or stack-config.json).
- See `agents/local-ops.md` for how routing happens.

Don't install the full stack on the server. The server is purely an inference endpoint.
