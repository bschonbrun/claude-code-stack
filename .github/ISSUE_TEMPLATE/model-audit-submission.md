---
name: Model audit
about: Propose a model assignment change
title: '[MODEL AUDIT] '
labels: model-audit
---

## Current assignment

Subagent: <name>
Current model: <model>

## Proposed change

New model: <model>

## Evidence

### Benchmark
- Benchmark used: <name>
- Source: <link>
- Current model rank: <X>
- Proposed model rank: <Y>

### Cost
- Current model cost per typical invocation: $<...>
- Proposed model cost: $<...>
- Delta: <+/- X%>

### Quality
- Has /agent-performance-review or other internal data observed this?
- If yes, attach the report.

## Risks

<What could go wrong with the new model? Adversarial-family rule still satisfied?>

## Proposed pilot

- [ ] Sandbox first (run in parallel for 2 weeks, compare outputs)
- [ ] Direct switch with rollback plan
