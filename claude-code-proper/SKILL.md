---
name: claude-code-proper
description: Use when Codex needs to delegate bounded coding, review, audit, refactor, or implementation work to Claude Code from the terminal, especially when the user wants Claude Code, Opus/Sonnet, Max-plan usage, non-interactive `claude -p` jobs, safe permissions, or subscription-login behavior instead of API-key usage.
---

# Claude Code Proper

Use Claude Code as a bounded specialist, not an unbounded background process. Prefer official Claude Code CLI behavior and keep the parent Codex session responsible for final edits, validation, and user reporting unless the user explicitly wants Claude to edit directly.

## Guardrails

- Prefer signed-in Claude Code subscription auth. Avoid API-key or bare mode unless the user explicitly authorizes API-key usage.
- Before invoking Claude, remove `ANTHROPIC_API_KEY` from the subprocess environment unless the user requested API billing.
- Check the installed CLI with `claude --help` when relying on advanced flags; Claude Code evolves quickly.
- Use `-p` for non-interactive delegation.
- Prefer Claude Code's native project agents and `--agent` / `--agents` flags for delegated specialists.
- For repeatable project workers, sync or create `.claude/agents/<agent>.md` files instead of passing every persona only in an ad hoc prompt.
- Use Claude Code hooks for observability when the user wants real agent behavior: `PreToolUse`, `PostToolUse`, `SubagentStart`, `SubagentStop`, `Stop`, and `SessionEnd` are especially useful.
- Use `--permission-mode plan` for advisory work and audits.
- Use constrained tools for implementation work, for example `--allowedTools Read,Edit,Bash` plus a narrow prompt and clear file ownership.
- Add `--no-session-persistence` for one-off delegated jobs.
- Add `--max-turns <n>` to prevent runaway work. Use enough room for inspect -> reason -> report; avoid accidental tiny caps like 4 for serious audits.
- When using Kevin's AirAgent wrapper, pass turn budget as `air claude audit --turns <n> ...`; the wrapper translates that to Claude Code's native `--max-turns`.
- Prefer `--output-format text` for human-readable audits and `--output-format json` only when parsing is needed.
- For long or serious work, require a small result contract: summary, files inspected, files changed, validation, risks, next steps.
- For design work, prefer a proposer -> critic -> judge pattern over one monolithic Claude answer.
- Never use `bypassPermissions`, `dontAsk`, or destructive shell permissions unless the user explicitly asks and the scope is safe.
- Give Claude a concrete task, exact repository path, explicit write scope, validation commands, and final output requirements.
- After Claude returns, inspect and validate locally. Do not blindly trust its report.

## Recommended Commands

Advisory audit:

```bash
env -u ANTHROPIC_API_KEY claude -p "$PROMPT" \
  --model opus \
  --effort max \
  --permission-mode plan \
  --tools "Read,Grep,Glob,Bash" \
  --output-format text \
  --no-session-persistence \
  --max-turns 14
```

Advisory audit with a temporary native subagent:

```bash
env -u ANTHROPIC_API_KEY claude -p "$PROMPT" \
  --model opus \
  --effort max \
  --agents '{"auditor":{"description":"Finds high-signal code risks","prompt":"You are a senior code auditor. Return actionable findings only.","tools":["Read","Grep","Glob","Bash"],"model":"opus","effort":"max"}}' \
  --agent auditor \
  --permission-mode plan \
  --tools "Read,Grep,Glob,Bash" \
  --output-format text \
  --no-session-persistence \
  --max-turns 14
```

Bounded implementation:

```bash
env -u ANTHROPIC_API_KEY claude -p "$PROMPT" \
  --model sonnet \
  --effort high \
  --tools "Read,Grep,Glob,Edit,MultiEdit,Write" \
  --permission-mode acceptEdits \
  --output-format text \
  --no-session-persistence \
  --max-turns 14
```

Use Opus for strategic audits, hard debugging, architecture decisions, and high-stakes reviews. Use Sonnet for implementation passes where speed and quota matter.

## Project Agent Pattern

For a repo that repeatedly delegates to Claude Code:

1. Create `.claude/agents/<name>.md` with YAML frontmatter:

```markdown
---
name: safe-auditor
description: Finds high-signal reliability and safety risks
tools: Read, Grep, Glob, Bash
model: opus
---

You are a bounded reviewer. Do not edit files. Return findings with file targets, validation, and risks.
```

2. Use a project `.claude/settings.local.json` hook logger when observability matters:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "./.claude/hooks/observer.mjs PreToolUse" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "./.claude/hooks/observer.mjs Stop" }]
      }
    ]
  }
}
```

3. Keep hook logging best-effort. A telemetry failure should not block Claude unless the hook is intentionally enforcing safety.

4. Store a run manifest with model, profile, prompt hash, files touched, validation, and artifact paths.

5. For multi-agent thinking, run bounded rounds:

```text
proposer -> critic -> judge
```

Keep each leg small and save the transcript after every leg so partial work survives quota or timeout failures.

## Prompt Template

Include:

```text
Repository: /absolute/path
Task: one sentence
Mode: advisory only OR edit files directly
Write scope: exact files/directories Claude may edit
Forbidden actions: no delete/push/deploy/destructive commands
Validation: exact commands to run
Output: concise summary, changed files, tests run, unresolved risks
Stop condition: stop after max-turns or when validation passes/fails
```

For advisory-only work, tell Claude: "Do not edit files." For implementation work, tell Claude: "You are not alone in the codebase. Do not revert changes made by others."

## Failure Handling

- If Claude hangs, stop it and kill leftover helper processes it started.
- If Claude reports auth, quota, or usage-limit errors, record that and fall back to another provider or local model.
- If a Claude job hits the turn cap, rerun with a narrower prompt or the AirAgent wrapper's `--turns` flag instead of embedding a max-turns instruction inside the task text.
- If Claude tries to use API keys unexpectedly, stop and rerun with the API key removed from the environment.
- If Claude creates broad or unrelated edits, do not apply them; narrow the task and rerun.

## References

Read `references/official-docs.md` when you need current option details, auth notes, or source links.
