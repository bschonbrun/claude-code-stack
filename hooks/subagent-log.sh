#!/usr/bin/env bash
# PreToolUse hook (matcher: Agent): log every subagent dispatch as JSONL.
# Powers /team-status and the team-utilization sections in /goodmorning and /handoff.
# Append-only; tiny rows (~200B); concurrent appends are atomic on POSIX.

set -uo pipefail

LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/subagent-runs.jsonl"
mkdir -p "$LOG_DIR"

# Claude Code exposes tool input fields as CLAUDE_TOOL_INPUT_<param>.
AGENT="${CLAUDE_TOOL_INPUT_subagent_type:-unknown}"
DESC="${CLAUDE_TOOL_INPUT_description:-}"
MODEL="${CLAUDE_TOOL_INPUT_model:-}"

# Resolve project: git root if any, else cwd.
PROJECT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"

# Read session start (written by SessionStart hook); empty if missing.
SESSION_START=""
[[ -f "$HOME/.claude/state/session-start.txt" ]] && \
  SESSION_START="$(cat "$HOME/.claude/state/session-start.txt" 2>/dev/null || true)"

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DESC_TRIMMED="${DESC:0:200}"

# Use jq for safe JSON encoding (handles quotes, newlines, unicode).
if command -v jq &>/dev/null; then
  jq -nc \
    --arg ts "$TS" \
    --arg session_start "$SESSION_START" \
    --arg project "$PROJECT" \
    --arg agent "$AGENT" \
    --arg desc "$DESC_TRIMMED" \
    --arg model "$MODEL" \
    '{event:"dispatch", ts:$ts, session_start:$session_start, project:$project, agent:$agent, desc:$desc, model:$model}' \
    >> "$LOG_FILE" 2>/dev/null || true
fi

exit 0
