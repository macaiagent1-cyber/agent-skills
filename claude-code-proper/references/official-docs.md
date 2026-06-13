# Official Claude Code Notes

Source links checked on 2026-05-06:

- CLI reference: https://code.claude.com/docs/en/cli-reference
- Headless / programmatic mode: https://code.claude.com/docs/en/headless
- Best practices: https://code.claude.com/docs/en/best-practices
- Authentication: https://code.claude.com/docs/en/authentication
- Pro/Max plan usage: https://support.anthropic.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan

Important points:

- `claude -p` runs Claude Code non-interactively for scripts and delegated jobs.
- `--permission-mode plan` starts in planning mode and is the safest default for audits.
- `--permission-mode` accepts modes including `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, and `bypassPermissions`; avoid permissive modes unless explicitly approved.
- `--model` accepts aliases such as `sonnet` or `opus`.
- `--output-format` supports `text`, `json`, and `stream-json` for print mode.
- `--no-session-persistence` keeps one-off runs from being saved for resume.
- `--max-turns` limits agentic turns in print mode.
- Claude Code can authenticate with a Claude subscription; `--bare` and `ANTHROPIC_API_KEY` are API-key-oriented paths and should not be used unless requested.
- Best-practice theme: control context size, give narrow tasks, provide validation, and keep the human/parent agent in charge of reviewing results.
