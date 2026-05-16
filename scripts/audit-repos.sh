#!/usr/bin/env bash
# Walk a repo through the audit checklist.
# Usage: ./audit-repos.sh <repo-path>

set -euo pipefail

REPO="${1:-}"
[[ -z "$REPO" ]] && { echo "Usage: $0 <repo-path>"; exit 1; }
[[ ! -d "$REPO" ]] && { echo "Not a directory: $REPO"; exit 1; }

cd "$REPO"

echo "==============================================="
echo "Audit pass: $REPO"
echo "==============================================="

# Step 1: Determine current state
echo ""
echo "Current state:"
echo "  CLAUDE.md present: $([[ -f CLAUDE.md ]] && echo yes || echo no)"
echo "  .claude/ present: $([[ -d .claude ]] && echo yes || echo no)"
echo "  stack-config.json: $([[ -f .claude/stack-config.json ]] && echo yes || echo no)"
echo "  docs/ADRs/: $([[ -d docs/ADRs ]] && echo yes || echo no)"
echo "  docs/runbooks/: $([[ -d docs/runbooks ]] && echo yes || echo no)"
echo "  docs/handoffs/: $([[ -d docs/handoffs ]] && echo yes || echo no)"
echo "  docs/ONBOARDING.md: $([[ -f docs/ONBOARDING.md ]] && echo yes || echo no)"

# Step 2: Walk the maintainer through tier choice
echo ""
echo "Recommended tier (per master handoff):"
case "$(basename "$REPO")" in
  app-repo) echo "  Tier 4 (NL→SQL engine, complex)" ;;
  finance-sync-repo) echo "  Tier 3 (financial integrations)" ;;
  revenue-report-repo) echo "  Tier 3 (delivery pipeline)" ;;
  data-pipeline-repo) echo "  Tier 5 (the maintainer indicated highest complexity)" ;;
  dashboards-repo) echo "  Tier 5 (5 dashboards growing)" ;;
  security-audit-repo) echo "  Tier 1 (thin monitoring repo)" ;;
  mcp-gateway-repo) echo "  Tier 2 (MCP server)" ;;
  *) echo "  Unknown — the maintainer to specify" ;;
esac

echo ""
echo "This script does NOT execute the audit — it surfaces the state."
echo "Run /project-init in this directory via Claude Code to perform the audit."
