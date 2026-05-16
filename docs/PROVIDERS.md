# Provider Setup Guides

> **v1.1.1 note:** The OpenAI and Google sections below have been adapted from the
> original artifacts. OpenAI-family and Gemini-family work routes through their
> local CLIs (Codex, Gemini), not direct API keys — see ADR-011 and ADR-012.

## Anthropic (required for all tiers)

You already have this (Claude Code itself requires it).
- API key in Keychain under `anthropic-api-key`.
- Verify: `security find-generic-password -s anthropic-api-key -w > /dev/null && echo OK`.

For prompt caching to work (Tier 2+):
- No special config — caching is opt-in via API call parameters. The stack configures this in subagent setup.

For spend protection:
- Set a monthly budget in console.anthropic.com.
- Recommend $500/mo cap as starting point; raise if Tier 4 perf-review shows it's not enough.

## OpenAI / Codex (required for Tier 2+)

Per ADR-011, the stack reaches the OpenAI / GPT-5.5 family through the **local Codex CLI**,
not a direct OpenAI API key. The `reviewer`, `product-critic`, and `security-auditor`
subagents orchestrate Codex via `codex exec`.

- Install: the Codex CLI (`codex`) — verify with `codex --version`.
- Auth: `codex login` (one-time). Credentials are stored by Codex itself in `~/.codex/auth.json`.
- No Keychain item is used.
- Verify: `codex --version` succeeds and `~/.codex/auth.json` exists.

### Spend protection
- Codex billing is via the Codex CLI account. Set spend limits in that account.
- Note: Codex calls are NOT metered into the stack's `cost_log`.

## Google / Gemini (required for Tier 3+)

Per ADR-012, the stack reaches the Gemini family through the **local Gemini CLI**,
not a direct Google AI Studio API key. The `architecture-critic`, `red-team`, and
`historian` subagents orchestrate Gemini via `gemini -p`.

- Install: `brew install gemini-cli` (Google's official CLI).
- Auth: run `gemini` once and log in with a Google account. Credentials are stored in `~/.gemini/`.
  (An AI Studio API key is an alternative auth method but is not required.)
- No Keychain item is used.
- Verify: `gemini --version` succeeds; a `gemini -p "test"` call returns output.

### Spend protection
- Gemini billing is via the Gemini CLI account / Google account quota.
- Note: Gemini calls are NOT metered into the stack's `cost_log`.

## Ollama (Tier 5)

Install:
```bash
brew install ollama
```

Start the daemon:
```bash
brew services start ollama
```

Pull recommended models (per `docs/HARDWARE.md`):
```bash
ollama pull llama3.2:3b
ollama pull llama3.1:8b        # if 16GB+
ollama pull qwen2.5-coder:32b  # if 24GB+
ollama pull llama3.3:70b       # if 36GB+
```

Verify:
```bash
ollama list
ollama run llama3.2:3b "Hello"
```

### Network policy
Ollama runs entirely local — no API key, no network.

## Pricing verification (mandatory before any cost-sensitive operation)

API pricing changes more often than docs are updated. The /cost-gate skill and /model-audit skill MUST verify pricing live via WebSearch / WebFetch before computing estimates.

Reference values (verified 2026-05-15 — confirm before using):
- Claude Opus 4.7: ~$5/M in, ~$25/M out
- Claude Sonnet 4.6: ~$3/M in, ~$15/M out
- Claude Haiku 4.5: ~$1/M in, ~$5/M out
- GPT-5.5: ~$2.50/M in, ~$15/M out (reached via Codex)
- Gemini 2.5 Pro: ~$1.25/M in, ~$10/M out (reached via the Gemini CLI)

Apr 2026 friction: 3.4× cost underforecast on a Sonnet BOL run. Don't trust cached numbers.
