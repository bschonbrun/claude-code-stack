# Stack test suite

Tests for the stack itself. Run before any release / breaking change.

## Tests

- `test-install.sh` — install in a clean directory; verify all tiers reach pass.
- `test-tier-isolation.sh` — verify each tier installs cleanly without earlier tiers being polluted.
- `test-config-merger.sh` — JSON merge logic doesn't lose user data.
- `test-merger-session-hooks.sh` (v1.1) — verify nested SessionStart hooks from multiple tiers merge correctly (Tier 0's hook + Tier 2's hook both fire after merge).

## Running

```bash
cd tests
./test-install.sh
./test-tier-isolation.sh
./test-config-merger.sh
./test-merger-session-hooks.sh
```

All tests must pass for a release tag. Run in CI via `.github/workflows/test-install.yml`.

> **v1.1.1 note:** `test-merger-session-hooks.sh` (below) invokes a Python merger at
> `scripts/lib/config-merger.py`. The stack currently ships only the bash merger
> (`scripts/lib/config-merger.sh`, a sourced function — not a 2-file→stdout CLI).
> Until a `config-merger.py` with that interface is added (or the test is rewritten
> to drive the bash merger), `test-merger-session-hooks.sh` will not pass. Known gap
> — see the Tier 0 / repo-completion notes.
