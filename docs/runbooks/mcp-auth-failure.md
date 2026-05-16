# Runbook: MCP authentication failure

**Component type:** Connector / Auth
**Severity tier:** High

## What this is

When an MCP server (Supabase, GitHub, etc.) returns 401 or "Unauthorized" during use. Common cause: token expired or rotated.

## Symptoms

- Tool call returns `{"error": "Unauthorized"}` or `401`.
- Claude Code mentions "MCP server returned unauthorized."
- mcp-health-check hook reports token issues at session start.

## Diagnose

1. Check Keychain for the relevant token:
   ```bash
   security find-generic-password -s <item-name> > /dev/null && echo OK
   ```
2. Test the token directly with a known-good endpoint:
   ```bash
   TOKEN=$(security find-generic-password -s <item-name> -w)
   curl -s -H "Authorization: Bearer $TOKEN" <provider-endpoint> | head
   ```

## Fix

### Supabase Management API
1. Visit https://supabase.com/dashboard/account/tokens
2. Generate a new token.
3. Update Keychain:
   ```bash
   security add-generic-password -s 'supabase-management-token' -a "$USER" -w '<new-token>' -U
   ```

### GitHub
1. Visit https://github.com/settings/tokens
2. Re-authenticate `gh` CLI: `gh auth refresh`.

### OpenAI / Anthropic / Google
1. Generate new key in provider console.
2. Update Keychain item:
   ```bash
   security add-generic-password -s '<item-name>' -a "$USER" -w '<new-key>' -U
   ```

## Verify

Re-run the failing command. Should succeed.

## Escalation

If token rotation doesn't fix it:
1. Check provider status page (vendor-specific outage).
2. Check rate limits (some providers return 401 for rate limit, confusingly).
3. Test from a different network (in case of IP-based blocks).
