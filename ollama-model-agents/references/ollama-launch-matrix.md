# Ollama Launch Matrix

Sources checked on 2026-06-14:

- Ollama CLI reference: https://docs.ollama.com/cli
- Ollama integrations overview: https://docs.ollama.com/integrations
- Claude Code integration: https://docs.ollama.com/integrations/claude-code
- Codex App integration: https://docs.ollama.com/integrations/codex-app
- Codex CLI integration: https://docs.ollama.com/integrations/codex
- Copilot CLI integration: https://docs.ollama.com/integrations/copilot-cli
- Cline CLI integration: https://docs.ollama.com/integrations/cline-cli
- OpenCode integration: https://docs.ollama.com/integrations/opencode
- Droid integration: https://docs.ollama.com/integrations/droid
- Goose integration: https://docs.ollama.com/integrations/goose
- Pi integration: https://docs.ollama.com/integrations/pi
- Oh My Pi integration: https://docs.ollama.com/integrations/oh-my-pi
- OpenClaw integration: https://docs.ollama.com/integrations/openclaw
- Hermes Agent integration: https://docs.ollama.com/integrations/hermes

## Core Pattern

`ollama launch` configures and starts external agents against Ollama local or cloud models. Use `--config` when you want to write or inspect config without opening a long-running session. Use `--yes -- <tool args>` only for bounded, noninteractive tasks that are already approved.

```bash
ollama launch
ollama launch <integration>
ollama launch <integration> --model <model>
ollama launch <integration> --model <model> --config
ollama launch <integration> --model <model> --yes -- <integration args>
```

## Coding Agents

| Integration | Primary Use | Launch Pattern | Notes |
| --- | --- | --- | --- |
| Claude Code | Claude-shaped coding harness with Ollama model backend | `ollama launch claude --model kimi-k2.6:cloud` | Supports headless prompts through `--yes -- -p "..."`; local agentic use should target at least 64k context. |
| Codex App | Visible Codex desktop backed by Ollama | `ollama launch codex-app --model kimi-k2.6:cloud` | Supports restore flow. Good when Kevin wants to see the agent window. |
| Codex CLI | Terminal Codex backed by Ollama | `ollama launch codex --model qwen3-coder:480b-cloud` | Manual alternative: `codex --oss -m <model>`. |
| Copilot CLI | GitHub Copilot CLI as an Ollama-backed coding agent | `ollama launch copilot --model kimi-k2.5:cloud` | Supports headless prompts through the integration args. |
| Cline CLI | Cline terminal agent backed by Ollama | `ollama launch cline --model kimi-k2.6:cloud -- "prompt"` | `--config` writes config without starting. |
| OpenCode | Terminal coding agent | `ollama launch opencode --model qwen3-coder:480b-cloud` | Docs recommend at least 64k context for local models. |
| Droid | Factory Droid coding agent | `ollama launch droid --config` | Manual config can target cloud models and high max token settings. |
| Goose | General coding/productivity agent | Configure Ollama provider in Goose | Can use local host or direct `https://ollama.com` with `OLLAMA_API_KEY`. |
| Pi / Oh My Pi | Terminal-first agent with extensions/plugins | `ollama launch pi --model qwen3.5:cloud`; `ollama launch omp` | Useful for lightweight extensible workflows. |

## Assistant Harnesses

| Integration | Primary Use | Launch Pattern | Notes |
| --- | --- | --- | --- |
| Hermes Agent | Personal-assistant style harness | `ollama launch hermes --model kimi-k2.6:cloud` | Points Hermes at Ollama's OpenAI-compatible endpoint. Candidate Linda host harness. |
| OpenClaw | OpenClaw assistant harness | `ollama launch openclaw --model qwen3-coder:480b-cloud` | Alias `clawdbot` may be supported. Candidate Linda host harness. |

## Other Listed Integrations

The integrations overview also lists IDEs and tools such as VS Code, Cline extension, Roo Code, JetBrains, Xcode, Zed, Onyx, n8n, and marimo. Verify the specific integration page or local `ollama launch <name> --help` before first use because supported launch flags can differ.

## Linda Rule

For Linda, the launched integration is a harness or sidecar, not the source of truth. Linda owns identity, memory permissions, provider routing, approval gates, outcome ledger, and final user response.
