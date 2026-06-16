# Ollama Routing Playbook

Sources checked on 2026-06-14:

- API introduction: https://docs.ollama.com/api/introduction
- Cloud models: https://docs.ollama.com/cloud
- OpenAI compatibility: https://docs.ollama.com/api/openai-compatibility
- Anthropic compatibility: https://docs.ollama.com/api/anthropic-compatibility
- Tool calling: https://docs.ollama.com/capabilities/tool-calling
- Context length: https://docs.ollama.com/context-length
- Pricing and limits: https://ollama.com/pricing
- Cloud model search: https://ollama.com/search?c=cloud&o=newest

## Access Paths

Local server:

```bash
ollama serve
ollama run <model>
curl http://localhost:11434/api/chat
```

Cloud model through local Ollama:

```bash
ollama signin
ollama pull gpt-oss:120b-cloud
ollama run gpt-oss:120b-cloud
```

Direct cloud API:

```bash
export OLLAMA_API_KEY=<key>
curl https://ollama.com/api/chat
```

## OpenAI-Compatible Tools

Use this path for tools that expect OpenAI-style APIs:

```bash
export OPENAI_API_KEY=ollama
export OPENAI_BASE_URL=http://localhost:11434/v1
```

Supported endpoints include chat completions, completions, models, embeddings, and the non-stateful Responses API. The Responses API supports streaming, tools/function calling, and reasoning summaries, but not server-side conversation state such as `previous_response_id`.

If a tool hardcodes OpenAI model names, create an alias:

```bash
ollama cp qwen3-coder:480b-cloud gpt-4.1
```

## Anthropic-Compatible Tools

Use this path for Claude-shaped clients:

```bash
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
unset ANTHROPIC_API_KEY
```

Supported Messages API features include messages, streaming, system prompts, multi-turn conversations, vision, tools, tool results, and extended-thinking style fields. Do not rely on unsupported Anthropic features such as prompt caching, batches, citations, PDF document blocks, or count_tokens.

## Context Policy

- For local agentic coding, web search, and repository work, target at least 64k context.
- Start local Ollama with a larger context when needed:

```bash
OLLAMA_CONTEXT_LENGTH=64000 ollama serve
ollama ps
```

- Ollama cloud models normally use their maximum context by default.
- The OpenAI-compatible API does not set context length by request; use a model configuration or local server setting when context matters.

## Quota and Efficiency

- Ollama Free, Pro, Max, and Team plans have different cloud concurrency and usage ceilings.
- Pro can run more cloud models concurrently than Free; Max raises concurrency and usage further.
- Usage is based on GPU time, so shorter requests, fewer repeated context dumps, and cached/shared context are more efficient.
- Session limits reset every 5 hours and weekly limits reset every 7 days, per Ollama pricing docs.
- For Linda, use small/cheap models for routing and classification; save large cloud models for implementation, hard reasoning, long context, and final critique.

## Model Selection

Model names change, so verify before use with Ollama search/library pages or local `ollama list`. Cloud models seen on 2026-06-14 include:

- Coding and agentic work: `kimi-k2.7-code`, `kimi-k2.6`, `qwen3-coder:480b-cloud`, `qwen3-coder-next`, `minimax-m3`, `minimax-m2.7`.
- Reasoning and critique: `deepseek-v4-pro`, `deepseek-v4-flash`, `glm-5.1`, `nemotron-3-ultra`, `nemotron-3-super`.
- General and multimodal exploration: `qwen3.5`, `gemma4`, `gemini-3-flash-preview`.

Check deprecation notices before wiring a model into Linda permanently. Ollama announced cloud model retirements for 2026-06-16 on its cloud docs.

## Linda Safety Policy

- Ollama can turn cloud or local models into CLI agents, but Linda must own action authority.
- Use visible launches when Kevin wants to watch work on the Mac Mini.
- Use `--config` before first launch so the setup can be reviewed.
- Use headless `--yes` only for bounded prompts with explicit tool limits.
- Do not delegate credential reads, external sends, deploys, destructive shell commands, data deletion, or `git push` without explicit approval.
- Every delegated run should leave an outcome record: model, harness, prompt goal, allowed tools, files touched, result, confidence, and fallback path.
