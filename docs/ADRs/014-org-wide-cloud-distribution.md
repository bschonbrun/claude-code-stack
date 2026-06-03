# ADR 014: Org-wide cloud distribution via a reconciler Action

**Status:** Accepted
**Date:** 2026-06-03
**Author:** the maintainer + Claude

## Context

The cloud bootstrap (ADR-013 / `docs/CLOUD.md`) makes a repo's cloud sessions
self-install the stack once the bootstrap files are committed (Path B). Doing
that by hand per repo doesn't scale to a whole org/team. We want: every existing
repo and every new repo in an org to get the bootstrap automatically, and the
mechanism to be reusable by other orgs (the stack repo is public).

Constraint: nothing in GitHub or any repo can configure Claude Code's **cloud
environment** (Path A setup script is Anthropic-side). Org automation can only
ever apply Path B — commit the bootstrap into repos.

## Decision

Ship a **per-org admin repo** (template: `templates/team-admin/`) containing a
**reconciler GitHub Action**. It runs on an hourly cron + manual dispatch,
enumerates repos tagged with a GitHub **topic**, and opens one **pull request**
per repo that is missing or has a stale bootstrap. A `/team-init` skill
scaffolds the admin repo and captures `org`/`topic`/`tier`.

Chosen parameters (see decisions log below): no hosting (Action, not a GitHub
App), delivery via PRs, hourly cron + manual run (no webhook relay in v1),
scope by topic tag.

## Alternatives considered

- **GitHub App + hosted backend.** Instant events, clean install, scoped tokens
  — but requires an always-on server someone hosts and trusts with write access
  to others' repos. Rejected for v1; revisit if external demand + a host exist.
- **Serverless webhook relay for instant new-repo coverage.** Reintroduces a
  hosted component we explicitly avoided. Deferred — hourly cron is enough.
- **Push to main instead of PRs.** Faster but ignores branch protection and is
  less reversible. Rejected; PRs are the safe default.
- **Scope = whole org or a team's repos.** Topic tagging is opt-in and
  org/team-agnostic, which generalizes better to other orgs. Team-slug scoping
  can be added later as another `scope` mode.

## Consequences

- **Positive:** zero hosting; each org owns its config + token; forkable from a
  public repo; idempotent; safe-by-default (dry-run until `enabled: true`).
- **Negative:** new-repo coverage is eventually-consistent (≤ cron interval).
  One PR per repo on first sweep (review burden). Requires a PAT with write
  across managed repos (the one irreducible secret).
- **Locked in:** the bootstrap version stamp `.claude/.stack-bootstrap-version`
  is how the reconciler detects drift — keep writing it.

## Decisions log (from the 2026-06-03 session)

- Mechanism: **Action, no hosting**.
- Delivery: **pull requests**.
- New-repo speed: **hourly cron + manual run** (no webhook relay).
- Scope: **topic-tagged repos**.

## Not yet verified

The reconciler has offline unit coverage (`tests/test-reconcile.sh`, stubbed
`gh`/`git`) but has **not** been run against a live org. Before enabling write
mode, run it in dry-run against the target org and have it security-reviewed
(it holds a write-scoped PAT and mutates many repos).

## References

- `docs/CLOUD.md`, `templates/team-admin/`, `skills/team-init/SKILL.md`
- ADR-007 (git repo vs plugin), ADR-013 (core/overlay model)
