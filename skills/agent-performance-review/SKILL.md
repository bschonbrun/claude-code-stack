---
name: agent-performance-review
description: Run monthly to evaluate how each subagent has actually performed over the last 30 days. Reads subagent_runs table, identifies patterns of failure/success, proposes prompt refinements or model changes. Distinct from /model-audit (which looks outside at benchmarks) — this looks inside at actual outcomes. Targets the assumption that current configuration is still optimal.
---

# /agent-performance-review

Look at what subagents actually did. Find what's not working.

## When to use

- First of each month, alongside /model-audit
- When a specific subagent feels off ("validator keeps missing things")
- Before quarterly planning ("is the stack delivering?")

## Steps

### 1. Pull subagent_runs
- Query subagent_runs for last 30 days.
- Group by subagent.
- For each: invocations, success rate, avg cost, p50/p95 wall time, escalation rate.

### 2. Identify performance issues

For each subagent:
- **High failure rate** (>15% in 30d): something's off — wrong model, wrong prompt, wrong scope.
- **High escalation rate** (>20% in 30d): subagent can't handle what foreman dispatches.
- **Low usage** (<5 invocations in 30d): unused — either not needed or not triggering.
- **Cost outliers**: subagent costing >2x its expected per-invocation budget.
- **Wall-time outliers**: subagent taking >2x its expected duration.

### 3. Identify pattern issues

Cross-cutting:
- Which task types have highest failure?
- Which subagent pairs (handoffs) have highest re-do rate?
- Which approval gates get rejected most often?
- **(v1.1) Orchestration mode comparison.** For each task type, compare success rate / cost / wall-time across `main-thread`, `agent-teams`, and `hybrid` modes. If one mode is meaningfully outperforming for a given task class, surface it. If `agent-teams` is consistently underperforming `main-thread` for a task class, propose restricting it. This is how the stack learns whether the experimental orchestration is actually worth using.

### 4. Generate proposals

For each issue, propose:
- **Prompt refinement** — specific edit to the subagent's .md file or foreman skill
- **Model change** — propose escalation or downgrade
- **Scope change** — narrow what foreman dispatches to this subagent
- **Orchestration-mode change** (v1.1) — propose changing default mode for a task class
- **Retirement** — if unused for 60+ days, propose removal (librarian's decision)

### 5. Write report

`docs/agent-perf/<YYYY-MM-DD>.md`:

```
# Agent performance review: <date>

## At a glance
- Total invocations: <N>
- Total cost: $<X>
- Average success rate: <%>
- Top subagent by usage: <name> (<N> invocations)
- Top subagent by cost: <name> ($<X>)
- Top failure cause: <pattern>

## Per-subagent
### architect
- Invocations: <N> | Success: <%> | Avg cost: $<X> | p95 wall: <Y>min
- Notable: <pattern>
- Proposal: <none / refinement / model change>

### implementer
...

## Cross-cutting patterns
- <pattern>: observed in <N> sessions, suggested action: <...>

## Proposals summary
- <change>: <evidence> — apply? Y/N
```

### 6. Hand to librarian
After approval: librarian implements the prompt refinements (PRs to claude-code-stack).
