#!/usr/bin/env bash
# Claude Code Stack — cloud session bootstrap
#
# WHY: Claude Code *cloud* sessions (claude.ai/code on web + iOS) run in an
# ephemeral container. The repo is cloned fresh, but the user's laptop
# ~/.claude is NEVER synced up — so personal/global skills like /goodmorning
# and /handoff are not discoverable. This script installs the stack into the
# container's ~/.claude at session start so they load on every surface.
#
# USED TWO WAYS (see docs/CLOUD.md):
#   1. As the ENVIRONMENT setup script (configured per-environment in the
#      Claude Code web UI). Then EVERY cloud session of EVERY repo gets the
#      stack, without committing anything into each project.
#   2. Copied into a single repo's .claude/hooks/ by /project-init and wired
#      to that repo's SessionStart hook, so that repo self-bootstraps the
#      stack in cloud with no per-environment config.
#
# It clones this (PRIVATE) repo with a token from the environment, then runs
# the idempotent installer: install.sh --mode=merge backs up ~/.claude and
# deep-merges JSON (user wins on conflict), so re-runs are safe.
#
# REQUIRED ENV:
#   CLAUDE_STACK_REPO_TOKEN   GitHub token with read access to the private
#                             repo. NEVER hardcode it — set it in the
#                             environment config (Claude Code web secret/env).
#
# OPTIONAL ENV:
#   CLAUDE_STACK_REPO   default: github.com/bschonbrun/claude-code-stack
#   CLAUDE_STACK_REF    default: main
#   CLAUDE_STACK_TIER   default: 2
#
# EXIT POLICY: best-effort. A missing token or a network-blocked clone prints
# a prominent warning and exits 0 — it never hard-fails the cloud session.

set -uo pipefail

log() { printf '[stack-cloud-bootstrap] %s\n' "$*" >&2; }

# Only meaningful in the remote/cloud container. Local sessions install the
# stack themselves via ./scripts/install.sh, so this is a true no-op there.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Idempotency: run at most once per container boot. Both the environment
# setup script and a repo's committed hook may fire — whichever lands first
# wins; the rest no-op on this marker.
MARKER="/tmp/.claude-stack-cloud-bootstrap.done"
if [ -f "$MARKER" ]; then
  exit 0
fi

REPO="${CLAUDE_STACK_REPO:-github.com/bschonbrun/claude-code-stack}"
REF="${CLAUDE_STACK_REF:-main}"
TIER="${CLAUDE_STACK_TIER:-2}"

# Strip any scheme the caller supplied so we control the auth method.
REPO="${REPO#https://}"
REPO="${REPO#http://}"
REPO="${REPO%.git}"

if [ -z "${CLAUDE_STACK_REPO_TOKEN:-}" ]; then
  log "WARNING: CLAUDE_STACK_REPO_TOKEN is not set."
  log "The Claude Code Stack repo is private, so its skills/commands cannot be"
  log "synced into this cloud session. Set CLAUDE_STACK_REPO_TOKEN in the"
  log "environment config (see docs/CLOUD.md). Continuing without the stack."
  exit 0
fi
# install.sh shells out to git; make sure the token reaches the askpass helper.
export CLAUDE_STACK_REPO_TOKEN

# Clone shallow into a temp dir. Keep the token OUT of argv and out of
# .git/config by supplying it through GIT_ASKPASS rather than embedding it in
# the clone URL. The username (x-access-token) lives in the URL; git asks the
# helper only for the password, which we answer with the token.
TMP="$(mktemp -d)"
ASKPASS="$(mktemp)"
cleanup() { rm -rf "$TMP" "$ASKPASS"; }
trap cleanup EXIT

printf '#!/bin/sh\nexec printf "%%s" "$CLAUDE_STACK_REPO_TOKEN"\n' > "$ASKPASS"
chmod +x "$ASKPASS"

clone_url="https://x-access-token@${REPO}.git"

attempt=0
max=3
delay=2
until GIT_TERMINAL_PROMPT=0 GIT_ASKPASS="$ASKPASS" \
      git clone --depth 1 --branch "$REF" "$clone_url" "$TMP/stack" >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge "$max" ]; then
    log "WARNING: could not clone $REPO (ref $REF) after $max attempts."
    log "Check the environment's network policy and CLAUDE_STACK_REPO_TOKEN."
    log "Continuing without the stack."
    exit 0
  fi
  log "clone attempt $attempt failed; retrying in ${delay}s..."
  sleep "$delay"
  delay=$((delay * 2))
done

log "cloned $REPO@$REF; installing tier $TIER into ~/.claude (merge mode)..."
if bash "$TMP/stack/scripts/install.sh" --tier="$TIER" --skip-requirements; then
  log "stack tier $TIER installed. Custom skills/commands are now available."
  : > "$MARKER"
else
  log "WARNING: install.sh exited non-zero; some stack pieces may be missing."
fi
