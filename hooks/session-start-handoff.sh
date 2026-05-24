#!/usr/bin/env bash
# SessionStart hook:
# - Show ✅ banner with current stack settings + edit shortcuts if initialized.
# - Show ⚠️ warn if in a git repo without .claude/stack-config.json.
# - Auto-load .claude/next_prompt.md handoff if present.
# - Print a one-line key-commands footer.
# Stays silent outside git repos and inside the stack source repo itself.

set -euo pipefail

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
# Prevents banners from firing on the stack itself or forks of it.
is_stack_source_repo() {
  [[ -d "$GIT_ROOT/agents" ]] && \
  [[ -d "$GIT_ROOT/skills" ]] && \
  [[ -f "$GIT_ROOT/scripts/install.sh" ]]
}

# Read a JSON field from stack-config.json, with a fallback string.
# Args: <jq filter> <fallback>
read_cfg() {
  if command -v jq &>/dev/null && [[ -f "$STACK_CONFIG" ]]; then
    jq -r "$1 // \"$2\"" "$STACK_CONFIG" 2>/dev/null || echo "$2"
  else
    echo "$2"
  fi
}

if is_stack_source_repo; then
  # Stack source repo — skip both banners
  :
elif [[ -f "$STACK_CONFIG" ]]; then
  # Initialized — show ✅ banner with current settings + edit shortcuts
  TIER=$(read_cfg '.stack_tier' '?')
  DOMAIN=$(read_cfg '.domain_mode' 'none')
  STRICT=$(read_cfg 'if .strict_mode then "strict" else "permissive" end' '?')
  SENSITIVITY=$(read_cfg '.sensitivity.level' 'normal')

  echo ""
  echo "✅ Stack active — Tier $TIER · $DOMAIN · $STRICT · sensitivity:$SENSITIVITY"
  echo "   Change settings: /tier · /domain-mode · /strict-mode · /sensitivity · /cost-cap"
  echo "   Re-run init: /project-init (asks before overwriting)"
  echo ""
else
  # Uninitialized git repo — soft warn
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

# Handoff if present, otherwise a brief reminder.
if [[ -f "$HANDOFF" ]]; then
  echo "──────────────────────────────────────────────"
  echo "Handoff from previous session:"
  echo "──────────────────────────────────────────────"
  cat "$HANDOFF"
  echo "──────────────────────────────────────────────"
  echo "Run /goodmorning for full bootup (git state, PRs, CI)."
elif ! is_stack_source_repo; then
  echo "No handoff from previous session. Run /goodmorning for context, or just start working."
fi

# Condensed one-line footer (skip on stack source repo)
if ! is_stack_source_repo; then
  echo ""
  echo "── /goodmorning · /handoff · /project-init · /budget-guard · /operating ──"
fi
