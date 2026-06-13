---
name: gemini-cli-proper
description: Use when Codex needs to delegate bounded research, code review, multimodal inspection, long-context synthesis, or advisory implementation planning to Google Gemini CLI from the terminal, especially when the user wants Gemini subscription-login behavior, high reasoning, non-interactive jobs, or CLI usage without API keys.
---

# Gemini CLI Proper

Use Gemini CLI as a bounded advisor or worker. Keep Codex responsible for final edits, validation, and the user-facing report unless the user explicitly asks Gemini to edit directly.

## Guardrails

- Prefer signed-in Gemini CLI subscription auth. Do not use `GEMINI_API_KEY` or `GOOGLE_API_KEY` unless the user explicitly authorizes API-key usage.
- Before invoking Gemini, remove Gemini and Google API-key environment variables unless the user requested API billing.
- Use non-interactive prompt mode for delegated work: `gemini -p "$PROMPT"`.
- Use `--approval-mode plan` for advisory work and audits.
- Use `--skip-trust` for headless runs inside known local repos.
- Prefer `--output-format text` for human-readable audits and `--output-format json` only when parsing is needed.
- Use the strongest available Gemini model for high-stakes research, architecture, long-context synthesis, and multimodal inspection; use Flash for quick summaries or low-stakes routing.
- Set a timeout and keep the task bounded. Gemini should inspect only the files, URLs, or artifacts required by the prompt.
- For code work, ask Gemini for findings, patch plans, or specific file suggestions first. Apply final edits in Codex unless a separate write-safe workflow is approved.
- Never allow destructive shell commands, credential access, deploys, git push, or broad filesystem edits from a delegated Gemini job.
- After Gemini returns, inspect and validate locally. Do not blindly trust its report.

## Recommended Commands

Advisory audit or research:

```bash
env -u GEMINI_API_KEY -u GOOGLE_API_KEY gemini -p "$PROMPT" \
  --model pro \
  --approval-mode plan \
  --skip-trust \
  --output-format text
```

Fast low-cost pass:

```bash
env -u GEMINI_API_KEY -u GOOGLE_API_KEY gemini -p "$PROMPT" \
  --model flash \
  --approval-mode plan \
  --skip-trust \
  --output-format text
```

JSON result contract:

```bash
env -u GEMINI_API_KEY -u GOOGLE_API_KEY gemini -p "$PROMPT" \
  --model pro \
  --approval-mode plan \
  --skip-trust \
  --output-format json
```

## Prompt Template

Include:

```text
Repository or artifact: /absolute/path
Task: one sentence
Mode: advisory only OR bounded write proposal
Allowed scope: exact files/directories/URLs/artifacts
Forbidden actions: no credentials, delete, deploy, push, destructive commands, or API keys
Validation: exact commands or checks to recommend
Output: concise findings, files inspected, risks, suggested changes, remaining unknowns
Stop condition: stop when findings are clear or if blocked by auth/quota/permissions
```

Ask Gemini to end with a compact JSON block when the output will be parsed by AirAgent or another tool.

## Good Uses

- Current public research and synthesis, especially with citations requested by the user.
- Long-context comparison across docs, logs, or source files.
- Independent codebase audit before Codex edits.
- TUI/UX critique with screenshots or captured output.
- Fallback advisor when Claude Code or Codex CLI hits a usage cap.

## Failure Handling

- If Gemini reports auth, quota, or usage-limit errors, record that and fall back to Claude Code, Codex CLI, Ollama Cloud, or local models.
- If Gemini tries to request API keys unexpectedly, stop and rerun with API-key env removed.
- If Gemini hangs, terminate the process and preserve any partial output or artifact path.
- If Gemini proposes broad unrelated edits, narrow the prompt and rerun; do not apply the broad patch.
