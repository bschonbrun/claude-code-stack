# Security

## Secret management

- **Never** store secrets in `.env` files committed to git.
- **Never** store secrets in CLAUDE.md or any other context file.
- API keys / tokens live in macOS Keychain.
- Reference them in scripts via `security find-generic-password -s '<name>' -w`.

### Known Keychain items
- `anthropic-api-key`

> **v1.1.1 note:** The original artifacts also listed `openai-api-key` and
> `google-ai-api-key`. Per ADR-011 and ADR-012, OpenAI-family work goes through the
> Codex CLI (auth in `~/.codex/auth.json`) and Gemini-family work through the Gemini
> CLI (auth in `~/.gemini/`) — neither uses a Keychain item. Other repo-specific
> tokens (e.g. `supabase-service-role-key`, `supabase-management-token`)
> are added per project as needed.

To add: `security add-generic-password -s '<name>' -a "$USER" -w '<value>' -U`
To verify (without printing): `security find-generic-password -s '<name>' > /dev/null && echo OK`

## Data handling

- Sensitive data: tag it `sensitive: true` in stack-config.json. Foreman routes such tasks to local-ops (Tier 5).
- Never paste production data into chat with hosted models.
- For prod-data debugging: use local-ops + Ollama, or anonymize/sample first.

## Audit trail

- All subagent invocations log to subagent_runs (Tier 4).
- Cost log captures every API call.
- Git history captures every code change.
- Handoffs in docs/handoffs/ capture session-level decisions.

## Incident response

See `agents/incident-commander.md` and `docs/runbooks/`. For Sev 1+: invoke incident-commander immediately, log live, postmortem within 48h.

## Vendor security posture

- Anthropic: see anthropic.com/security.
- OpenAI: see openai.com/security.
- Google: see cloud.google.com/security.
- Supabase: weekly-security-audit repo monitors drift.

## Stack-level CVE handling

If a vulnerability is found in the stack itself:
1. Security-auditor subagent assesses severity.
2. Fix in private branch.
3. ADR documenting the issue and fix.
4. Once patched: notify any external users (when stack is public).
