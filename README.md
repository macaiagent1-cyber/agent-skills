# agent-skills

Merlin's universal skills hub for cross-agent use.

**One install, every agent.** Works with Claude Code, Codex, Cursor, Gemini, Antigravity, Hermes, OpenCode, GitHub Copilot — anything in the [npx skills](https://skills.sh/) ecosystem.

```bash
npx skills add macaiagent1-cyber/agent-skills
```

---

## Bundled skills (16 — installed by default)

### Media generation
- **higgsfield-generate** — Higgsfield AI images/video (Sora 2, Veo 3.1, Kling 3.0, Nano Banana, Flux)
- **higgsfield-marketplace-cards** — Marketplace product image cards (main, secondary, A+ modules)
- **higgsfield-product-photoshoot** — Brand-quality product photography
- **higgsfield-soul-id** — Train a personalized Soul Character for identity-faithful generation

### Web / browser control
- **kimi-webbridge** — Drive the user's real browser via local daemon
- **turnstile-spin** — Cloudflare Turnstile handling

### Cloudflare / infra
- **cloudflare** — General Cloudflare workflows
- **cloudflare-email-service** — Email routing via Workers
- **durable-objects** — Durable Objects patterns
- **sandbox-sdk** — Cloudflare Sandbox SDK
- **workers-best-practices** — Workers best practices
- **wrangler** — Wrangler CLI workflows
- **web-perf** — Web performance optimization

### Agent / tooling
- **agents-sdk** — Agent SDK patterns
- **find-skills** — Discover and install skills from the ecosystem
- **google-antigravity-ops** — Google Antigravity operations

---

## Recommended add-ons (install separately)

Curated from the open skills ecosystem. These are the ones I trust enough to install on top.

### Engineering skills
```bash
npx skills add mattpocock/skills            # Skills for Real Engineers
npx skills add addyosmani/agent-skills      # Production-grade engineering skills
npx skills add multica-ai/andrej-karpathy-skills  # Karpathy's CLAUDE.md improvements
npx skills add obra/superpowers             # Agentic skills framework
```

### Domain-specific skills
```bash
npx skills add K-Dense-AI/scientific-agent-skills    # 140+ scientific skills
npx skills add Imbad0202/academic-research-skills    # research → write → review → revise
npx skills add yetone/native-feel-skill              # Native-feeling desktop UI
npx skills add ComposioHQ/awesome-codex-skills       # Curated Codex skills
```

### Official Anthropic
```bash
npx skills add anthropics/claude-plugins-official    # Official Claude Code Plugins
npx skills add anthropics/claude-for-legal           # Legal workflows
npx skills add anthropics/financial-services         # Financial services
```

---

## Recommended frameworks & memory (not skills — install via their docs)

These are runtimes/frameworks that pair well with the skills above.

### Memory layers
- [mem0ai/mem0](https://github.com/mem0ai/mem0) — Universal memory layer for AI agents
- [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) — Persistent context across sessions for every agent
- [MemTensor/MemOS](https://github.com/MemTensor/MemOS) — Self-evolving memory OS
- [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) — Persistent memory for AI coding agents
- [memvid/memvid](https://github.com/memvid/memvid) — Serverless single-file memory layer

### Multi-agent frameworks
- [crewAIInc/crewAI](https://github.com/crewAIInc/crewAI) + [crewAI-tools](https://github.com/crewAIInc/crewAI-tools)
- [swarmclawai/swarmclaw](https://github.com/swarmclawai/swarmclaw) — Multi-agent runtime, MCP tools, 23+ LLM providers
- [bytedance/deer-flow](https://github.com/bytedance/deer-flow) — Long-horizon SuperAgent harness
- [Hmbown/CodeWhale](https://github.com/Hmbown/CodeWhale) — Open-source agent harness

### Local / privacy
- [exo-explore/exo](https://github.com/exo-explore/exo) — Run frontier AI locally
- [tinyhumansai/openhuman](https://github.com/tinyhumansai/openhuman) — Personal AI super intelligence

### Specialized
- [TauricResearch/TradingAgents](https://github.com/TauricResearch/TradingAgents) — Multi-agent financial trading framework
- [HKUDS/AI-Trader](https://github.com/HKUDS/AI-Trader) — 100% automated agent-native trading
- [CloakHQ/CloakBrowser](https://github.com/CloakHQ/CloakBrowser) — Stealth Chromium for bot-detection bypass
- [bytedance/UI-TARS-desktop](https://github.com/bytedance/UI-TARS-desktop) — Multimodal AI agent stack
- [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph) — Code knowledge graph for all agents
- [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) — HTML → video, built for agents

### Audit / quality
- [johnpaulhayes/ocaudit](https://github.com/johnpaulhayes/ocaudit) — Deterministic audit for agent workspaces
- [millionco/react-doctor](https://github.com/millionco/react-doctor) — Catches bad React from agents

---

## Cross-agent install pattern

```bash
# Same command, every agent, every machine:
npx skills add macaiagent1-cyber/agent-skills

# Then optionally add the recommended ones above.
```

Update everywhere with one command:
```bash
npx skills update
```

---

## Owner

- Merlin (macaiagent1@gmail.com)
- Primary GitHub: [macaiagent1-cyber](https://github.com/macaiagent1-cyber)
- Stars/research account: [kevinthegamer](https://github.com/kevinthegamer)

## License

- Original skills (`kimi-webbridge` and Cloudflare-set): MIT
- Higgsfield-* skills: vendored from [higgsfield-ai/skills](https://github.com/higgsfield-ai/skills) — consult upstream
- Recommendations above remain under their original licenses
