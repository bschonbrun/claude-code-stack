#!/usr/bin/env bash
# Test: install in a clean dir succeeds for each tier.

set -euo pipefail

TMPDIR="$(mktemp -d)"
ORIG_HOME="$HOME"
export HOME="$TMPDIR"

trap "export HOME='$ORIG_HOME'; rm -rf '$TMPDIR'" EXIT

cd "$(dirname "$0")/.."

failures=0

for tier in 0 1 2 3 4 5; do
  echo "=== Testing tier $tier in clean $HOME ==="
  rm -rf "$HOME/.claude"
  if ./scripts/install.sh --tier="$tier" --mode=fresh > /tmp/install-$tier.log 2>&1; then
    echo "  [PASS] Tier $tier installed"
  else
    echo "  [FAIL] Tier $tier — see /tmp/install-$tier.log"
    failures=$((failures + 1))
  fi
  if ./scripts/verify.sh --tier="$tier" > /tmp/verify-$tier.log 2>&1; then
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
