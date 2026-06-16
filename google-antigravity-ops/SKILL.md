---
name: google-antigravity-ops
description: Use when working with Gemini model routing, Google Antigravity, AGY CLI, Gemini CLI migration, Antigravity plugins, Agent Skills, MCP configuration, hooks, webhooks, or Kevin's local Google AI agent setup.
---

# Google Antigravity Ops

Keep the lingo precise. Gemini is the model family and capability layer.
Antigravity is a tool surface around agents, skills, plugins, MCP, hooks, IDE
workflows, and the `agy` CLI. Do not describe Antigravity itself as the model or
as the agent.

When facts may have changed, verify official Google Antigravity or Google AI
documentation before giving setup, migration, pricing, model, or tooling advice.

## Route Selection

When the user asks to use Gemini, Google AI, or external agents, choose the
execution route by task:

- Use `agy` / Antigravity CLI for Google AI developer workflows that benefit
  from AGY plugins, skills, subagents, hooks, MCP, workspace context, or
  long-running agent orchestration.
- Use Gemini CLI when the user explicitly asks for it or when a lightweight
  terminal Gemini interaction is the better fit.
- Use Antigravity IDE / VS Code-style workflows when the work is editor-centric
  or benefits from IDE integration.
- Use Gemini API / SDK paths when building programmatic integrations, managed
  agents, webhooks, or application code.
- Use other external-agent harnesses when they better match the task, budget,
  permissions, or model requirements.

## Local Workflow

1. Confirm AGY is available with `command -v agy` and `agy --version`.
2. Inspect installed AGY plugins with `agy plugin list`.
3. Validate local plugins before relying on them with `agy plugin validate <path>`.
4. Install local plugins with `agy plugin install <path>`.
5. Use `agy --print "<prompt>"` for non-interactive checks.

## Local Paths

- Global instructions: `/Users/kdawg/AGENTS.md`
- Workspace Antigravity customization: `/Users/kdawg/.agents/`
- Workspace skills: `/Users/kdawg/.agents/skills/`
- Workspace MCP config: `/Users/kdawg/.agents/mcp_config.json`
- Workspace hooks: `/Users/kdawg/.agents/hooks.json`
- Imported plugins and manifest: `/Users/kdawg/.gemini/config/plugins/` and `/Users/kdawg/.gemini/config/import_manifest.json`
- AGY CLI settings and logs: `/Users/kdawg/.gemini/antigravity-cli/`

## Migration Rules

- Treat Gemini CLI extensions as Antigravity plugins.
- Prefer `.agents/skills` for workspace skills.
- Keep MCP server definitions in `mcp_config.json`; do not invent or enable
  MCP servers without a known command or remote `serverUrl`.
- Keep hooks disabled until a concrete command, endpoint, or safety gate is
  intentionally selected.
- Never print OAuth credentials, API keys, or token files while inspecting AGY.
