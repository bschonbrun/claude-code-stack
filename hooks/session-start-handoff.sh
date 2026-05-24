#!/usr/bin/env bash
# SessionStart hook:
# - Auto-load .claude/next_prompt.md if it exists.
# - Warn if the current git repo isn't stack-initialized (no .claude/stack-config.json).
# - Stay silent outside git repos and inside the stack source repo itself.

set -euo pipefail

# Find the current git repo root (the right "project boundary").
# Returns empty if we're not inside a git work tree.
git_root() {
  git rev-parse --show-toplevel 2>/dev/null || true
}

GIT_ROOT="$(git_root)"

# Not in a git repo — silent. Could be a scratch dir, wrapper folder, etc.
if [[ -z "$GIT_ROOT" ]]; then
  exit 0
fi

STACK_CONFIG="$GIT_ROOT/.claude/stack-config.json"
HANDOFF="$GIT_ROOT/.claude/next_prompt.md"

# Detect "this IS the stack source repo" by structural markers.
# Prevents the warn from firing on the stack itself or forks of it.
is_stack_source_repo() {
  [[ -d "$GIT_ROOT/agents" ]] && \
  [[ -d "$GIT_ROOT/skills" ]] && \
  [[ -f "$GIT_ROOT/scripts/install.sh" ]]
}

# Warn block — printed when we're in a consumer git repo with no stack-config.
if [[ ! -f "$STACK_CONFIG" ]] && ! is_stack_source_repo; then
  echo ""
  echo "⚠️  ──────────────────────────────────────────"
  echo "This repo is not stack-initialized."
  echo "  Path: $GIT_ROOT"
  echo "  Missing: .claude/stack-config.json"
  echo ""
  echo "Run /project-init to enable foreman + skills + cost gates."
  echo "(project-init now has a discovery pass — it reads your git"
  echo " history, deps, and existing CLAUDE.md to pre-fill defaults.)"
  echo "──────────────────────────────────────────────"
  echo ""
fi

# Existing behavior: handoff if present, otherwise a brief reminder.
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
