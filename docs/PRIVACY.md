# Privacy

## What leaves your machine

Stock Claude Code: every API call to Anthropic includes the conversation context.

Stack additions:
- API calls to OpenAI (Codex, GPT-5) include context for those subagents.
- API calls to Google (Gemini) include context for those subagents.
- Supabase writes for cost_log and subagent_runs include: subagent name, model, token counts, cost, wall time, task summary, outcome. **Does NOT include**: code contents, secrets, personally identifiable user data.

## What stays on your machine

- Ollama inference (Tier 5).
- File system operations.
- Git operations.
- Keychain operations.

## Handoff archive privacy

`docs/handoffs/<date>.md` are committed to git. If pushed to GitHub:
- Public repo: handoffs are public. Strip secrets before /handoff writes the file.
- Private repo: handoffs are private to repo collaborators.

The scribe subagent is responsible for never including secrets in handoffs. Reviewer should also flag any leaked secrets before merge.

## When opening the stack repo to the public (Phase 2)

Before going public:
- Scrub all ADRs, runbooks, handoffs for project-specific secrets or sensitive data.
- Remove the maintainer-specific paths (e.g., `<home>/...`) from examples.
- Replace Supabase project ref (`<your-supabase-ref>`) with a placeholder.
- Audit ALL files in docs/ for accidental leaks.
- Use `git filter-repo` or similar if needed to scrub history.

## User data in subagent_runs

The `task_summary` and `input_summary` fields could leak sensitive context. The librarian subagent reviews these monthly and proposes scrubbing if needed.
