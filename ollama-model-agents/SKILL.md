---
name: ollama-model-agents
description: Use when Codex needs to run, route, or advise multi-model work through Gemini CLI, direct Ollama models such as DeepSeek/Qwen/GLM, or Claude Code wrapped through Ollama's Anthropic-compatible API.
---

# Ollama Model Agents

Use this skill when Kevin asks for Gemini CLI, Ollama cloud/local models, DeepSeek, Qwen/QWIN, GLM, or Claude Code routed through Ollama. Keep Codex responsible for final synthesis and validation.

## Backends

- **Gemini CLI**: current research, long-context synthesis, independent advisory review.
- **Direct Ollama**: DeepSeek, Qwen, GLM, Gemma, Llama, local survival-mode opinions.
- **Claude Code via Ollama**: Claude Code harness using an Ollama model through Anthropic-compatible API.

## Required Checks

1. Run `ollama list` to confirm installed or cloud-available models.
2. Prefer a dry run first when building commands for Linda.
3. Do not use API keys unless Kevin explicitly approves a specific emergency task. Subscription-authenticated CLIs, Ollama cloud entitlement, and local Ollama models are the default.
4. Strip paid provider API-key environment variables before delegated model calls: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `OPENROUTER_API_KEY`, `XAI_API_KEY`, `DEEPSEEK_API_KEY`, `QWEN_API_KEY`, `DASHSCOPE_API_KEY`, `GLM_API_KEY`, and `ZHIPUAI_API_KEY`.
5. For Claude Code through Ollama, set:

```bash
ANTHROPIC_AUTH_TOKEN=ollama
ANTHROPIC_BASE_URL=http://localhost:11434
```

## Commands

Gemini CLI:

```bash
env -u GEMINI_API_KEY -u GOOGLE_API_KEY gemini -p "$PROMPT" \
  --model pro \
  --approval-mode plan \
  --skip-trust \
  --output-format text
```

Direct Ollama:

```bash
ollama run deepseek-v4-pro:cloud "$PROMPT"
ollama run qwen3.5:cloud "$PROMPT"
ollama run glm-5.1:cloud "$PROMPT"
ollama run qwen3.5:4b "$PROMPT"
```

Claude Code through Ollama:

```bash
ANTHROPIC_AUTH_TOKEN=ollama \
ANTHROPIC_BASE_URL=http://localhost:11434 \
claude -p "$PROMPT" \
  --model qwen3.5:cloud \
  --permission-mode plan \
  --tools Read,Grep,Glob,Bash \
  --output-format text \
  --no-session-persistence \
  --max-turns 8
```

Ollama integration launcher:

```bash
ollama launch claude --model qwen3.5:cloud
ollama launch claude --model deepseek-v4-pro:cloud --config
ollama launch claude --model glm-5.1:cloud --config
```

## Routing Rules

- Default to local or cheap routes for simple work.
- Use `qwen3.5:cloud` through Claude Code for codebase-aware audits and implementation proposals.
- Use `deepseek-v4-pro:cloud` for hard reasoning and adversarial critique.
- Use `glm-5.1:cloud` for architecture and whole-system planning.
- Use Gemini CLI when web/current research or long-context synthesis matters.
- Use local models for survival-mode checks and budget fallback.

## Safety

- Default to advisory mode and `--permission-mode plan`.
- Use subscription/local routes by default; API-key billing is emergency-only and needs explicit Kevin approval.
- Never delegate credential reads, deploys, git push, external sends, file deletion, or destructive shell commands.
- Record backend, model, task intent, elapsed time, and whether the model is local or cloud when used in Linda.
- If a model hangs or hits quota, stop and fall back to a smaller local route.
