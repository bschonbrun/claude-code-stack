#!/usr/bin/env bash
# SessionStart hook: auto-load .claude/next_prompt.md if it exists.
# If absent, print a brief reminder that /goodmorning provides full bootup.

set -euo pipefail

# Find project root (cwd or nearest parent containing .claude/)
find_project_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.claude" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT="$(find_project_root || true)"

if [[ -z "$PROJECT_ROOT" ]]; then
  # Not in a project; silent
  exit 0
fi

HANDOFF="$PROJECT_ROOT/.claude/next_prompt.md"

if [[ -f "$HANDOFF" ]]; then
  echo "──────────────────────────────────────────────"
  echo "Handoff from previous session:"
  echo "──────────────────────────────────────────────"
  cat "$HANDOFF"
  echo "──────────────────────────────────────────────"
  echo "Run /goodmorning for full bootup (git state, PRs, CI)."
else
  echo "No handoff from previous session. Run /goodmorning for context, or just start working."
fi

echo ""
echo "── Claude Code Stack ──────────────────────────"
echo "This project runs on the stack: foreman orchestrates, subagents do"
echo "the work, you approve at gates."
echo "Key commands: /goodmorning (session start) · /handoff (session end)"
echo "· /project-init (new project) · /budget-guard (before bulk LLM jobs)"
echo "Run /operating for the full guide — how this is set up to operate."
echo "──────────────────────────────────────────────"
