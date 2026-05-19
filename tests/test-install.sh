#!/usr/bin/env bash
# Test: install in a clean dir succeeds for each tier.
# Uses --skip-requirements: this tests install *mechanics* (file placement,
# verify pass), not whether this machine has codex/gemini/ollama installed —
# so it runs the same on a bare CI runner as on a fully provisioned laptop.

set -euo pipefail

TMPDIR="$(mktemp -d)"
ORIG_HOME="$HOME"
export HOME="$TMPDIR"

trap "export HOME='$ORIG_HOME'; rm -rf '$TMPDIR'" EXIT

cd "$(dirname "$0")/.."

failures=0

# Tier 5 omitted: its verify checks for pulled Ollama models, which can't be
# satisfied under a sandboxed HOME or on a CI runner (same reason the install
# matrix in test-install.yml skips tier 5).
for tier in 0 1 2 3 4; do
  echo "=== Testing tier $tier in clean $HOME ==="
  rm -rf "$HOME/.claude"
  if ./scripts/install.sh --tier="$tier" --mode=fresh --skip-requirements > /tmp/install-$tier.log 2>&1; then
    echo "  [PASS] Tier $tier installed"
  else
    echo "  [FAIL] Tier $tier — see /tmp/install-$tier.log"
    failures=$((failures + 1))
  fi
  if ./scripts/verify.sh --tier="$tier" --skip-requirements > /tmp/verify-$tier.log 2>&1; then
    echo "  [PASS] Tier $tier verified"
  else
    echo "  [FAIL] Tier $tier verify — see /tmp/verify-$tier.log"
    failures=$((failures + 1))
  fi
done

if [[ "$failures" -gt 0 ]]; then
  echo ""
  echo "$failures failures."
  exit 1
fi

echo "All tiers install + verify pass."
