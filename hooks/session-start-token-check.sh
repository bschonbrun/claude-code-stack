#!/usr/bin/env bash
# SessionStart hook: warn about tracked tokens expiring soon.
# Silent when nothing to report (--quiet mode in check script).
exec bash "$HOME/.claude/scripts/check-token-expiry.sh" --quiet
