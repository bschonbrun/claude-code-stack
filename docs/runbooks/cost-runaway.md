# Runbook: Cost runaway

**Severity tier:** High (cost can compound fast)

## What this is

A subagent or skill is racking up unexpected charges. Daily cost log shows abnormal spend.

## Symptoms

- ops hook prints "alert: daily spend exceeded threshold".
- Manual check of `cost_log_daily_summary` view shows $$$.
- Specific subagent dominates `cost_log_by_subagent_30d`.

## Diagnose

1. Query the daily summary:
   ```sql
   SELECT * FROM cost_log_daily_summary ORDER BY day DESC LIMIT 7;
   ```
2. Find the offender:
   ```sql
   SELECT subagent, model, COUNT(*), SUM(cost_usd)
   FROM cost_log
   WHERE occurred_at > NOW() - INTERVAL '24 hours'
   GROUP BY subagent, model
   ORDER BY SUM(cost_usd) DESC;
   ```
3. Find the specific session:
   ```sql
   SELECT session_id, task_summary, SUM(cost_usd)
   FROM cost_log
   WHERE occurred_at > NOW() - INTERVAL '24 hours'
   GROUP BY session_id, task_summary
   ORDER BY SUM(cost_usd) DESC LIMIT 10;
   ```

## Fix

- If a specific bulk job is running: kill it. `pkill -f <script-name>` if local; abort cleanly otherwise.
- If a subagent is in a loop: check foreman's escalation rules. Usually 2-round limit before escalating to user. If not enforced: BUG.
- If a model assignment is wrong (e.g., using Opus for trivial work): update model-routing.json or use override.

## Verify

- Check next hour's cost log; should return to baseline.

## Prevent recurrence

- Run /cost-gate before bulk jobs (mandatory).
- Set provider-level monthly cap (Anthropic, OpenAI, Google billing settings).
- Review with /agent-performance-review monthly to catch trends.
