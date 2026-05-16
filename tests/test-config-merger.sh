#!/usr/bin/env bash
# Test: merge_json preserves user keys when adding stack keys.

set -euo pipefail

source "$(dirname "$0")/../scripts/lib/config-merger.sh"

TMP="$(mktemp -d)"
trap "rm -rf '$TMP'" EXIT

# User's config with custom keys
cat > "$TMP/target.json" << 'EOF'
{
  "user_pref": "important_value",
  "hooks": {
    "user_custom_hook": "do-something.sh"
  }
}
EOF

# Stack's config to merge in
cat > "$TMP/source.json" << 'EOF'
{
  "stack_managed": true,
  "hooks": {
    "PostToolUse": [{"matcher": "Edit", "command": "tsc"}]
  }
}
EOF

merge_json "$TMP/source.json" "$TMP/target.json"

# Verify user_pref survives
if ! jq -e '.user_pref == "important_value"' "$TMP/target.json" > /dev/null; then
  echo "FAIL: user_pref lost"
  exit 1
fi

# Verify user_custom_hook survives
if ! jq -e '.hooks.user_custom_hook == "do-something.sh"' "$TMP/target.json" > /dev/null; then
  echo "FAIL: user hook lost"
  exit 1
fi

# Verify stack content added
if ! jq -e '.stack_managed == true' "$TMP/target.json" > /dev/null; then
  echo "FAIL: stack content missing"
  exit 1
fi

echo "PASS: config merger preserves user data"
