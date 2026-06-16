---
name: ollama-model-agents
description: Use when an agent needs to launch, configure, route, or advise work through Ollama local/cloud models, Ollama's OpenAI-compatible API, Anthropic-compatible API, or `ollama launch` integrations such as Claude Code, Codex CLI/App, Copilot CLI, Cline CLI, OpenCode, Droid, Goose, OpenClaw, Hermes Agent, Pi/Oh My Pi, IDEs, assistants, RAG, and automation tools. Also use when maximizing Ollama cloud model context, quota, cost, or tool-use efficiency.
---

# Ollama Model Agents

Treat Ollama as an agent launcher and model router, not only as a local model runner. Keep the parent agent or Linda responsible for final synthesis, approval gates, validation, proof packs, and user-visible handoff.

## Operating Modes

Choose the narrowest mode that fits the task:

1. `ollama launch <integration>` for supported harnesses and visible agent windows.
2. OpenAI-compatible `/v1` endpoints for OpenAI-shaped tools.
3. Anthropic-compatible `/v1/messages` endpoints for Claude-shaped tools.
4. Native `/api/chat`, `ollama run`, or official JS/Python libraries for direct model calls.

## Required Checks

- Check current project constraints first. A provider can be unavailable for the present build session while still remaining part of Linda's runtime design.
- Verify current cloud model names before relying on them. Ollama cloud models and aliases change.
- Prefer `ollama launch <tool> --config` to create or inspect configuration before starting a long visible session.
- For local agentic coding, run with at least a 64k context window when possible. Cloud models usually run at their maximum context by default.
- Strip paid provider API-key variables unless Kevin explicitly approves an emergency API-key route: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `OPENROUTER_API_KEY`, `XAI_API_KEY`, `DEEPSEEK_API_KEY`, `QWEN_API_KEY`, `DASHSCOPE_API_KEY`, `GLM_API_KEY`, and `ZHIPUAI_API_KEY`.
- Record backend, harness, model, local/cloud status, context target, task intent, elapsed time, and failure/quota state for Linda's outcome ledger.

## Fast Selection

- Visible engineering session: `ollama launch codex-app --model <model>` or `ollama launch opencode --model <model>`.
- Claude-shaped tool ecosystem: `ollama launch claude --model <model>` or Anthropic-compatible environment variables.
- Codex CLI: `ollama launch codex --model <model>` or `codex --oss -m <model>`.
- Copilot/Cline/Droid coding agents: launch the matching integration when their workflow fits the user request.
- Personal-assistant harnesses: use `ollama launch hermes` or `ollama launch openclaw` when evaluating Linda's harness layer.
- Direct model opinion: use native Ollama APIs or `ollama run` when a full harness would add noise.

## Model Routing

- Use coding-focused cloud models for implementation, repo audits, and tool-heavy coding passes.
- Use reasoning-focused cloud models for architecture critique, adversarial review, planning, and second opinions.
- Use smaller or local models for cheap classification, summarization, triage, and budget fallback.
- Prefer subscription, local, or Ollama entitlement routes first. Direct provider API-key billing is emergency-only.
- Treat `:cloud` models as remote compute even when accessed through the local Ollama server.

## References

- Read `references/ollama-launch-matrix.md` for integration-specific commands and launch patterns.
- Read `references/ollama-routing-playbook.md` for API compatibility, context length, quota behavior, and Linda safety policy.
