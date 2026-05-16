## What

<One-paragraph description of the change.>

## Why

<Why is this change needed? Reference issue if any.>

## Tier / scope

- [ ] Affects tier 0
- [ ] Affects tier 1
- [ ] Affects tier 2
- [ ] Affects tier 3
- [ ] Affects tier 4
- [ ] Affects tier 5
- [ ] Affects stack philosophy (requires ADR)

## Checklist

- [ ] Tested with `./scripts/install.sh --tier=<N> --mode=fresh` in clean dir
- [ ] `./scripts/verify.sh --tier=<N>` passes
- [ ] CHANGELOG.md updated
- [ ] If new subagent: model assignment justified in description; routing rules in foreman updated
- [ ] If new skill: description field clearly states trigger conditions; passes routing rule test
- [ ] If philosophy-affecting: ADR added under docs/ADRs/
- [ ] If new schema: migration is idempotent and reversible
- [ ] Liu's test applied to any new markdown: would removing this cause a mistake?
