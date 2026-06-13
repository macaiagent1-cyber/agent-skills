# agent-skills

Merlin's universal skills hub for cross-agent use.

**One install, every agent.** Works with Claude Code, Codex, Cursor, Gemini, Antigravity, Hermes, OpenCode, GitHub Copilot — anything in the [npx skills](https://skills.sh/) ecosystem.

```bash
# Full stack (hub + curated community packs):
curl -fsSL https://raw.githubusercontent.com/macaiagent1-cyber/agent-skills/main/install.sh | bash

# Just this hub:
npx skills add macaiagent1-cyber/agent-skills
```

---

## 76 skills bundled

### Original skills (Merlin)
- **kimi-webbridge** — Drive the user's real browser via local daemon

### Higgsfield AI (vendored from [higgsfield-ai/skills](https://github.com/higgsfield-ai/skills))
- higgsfield-generate, higgsfield-marketplace-cards, higgsfield-product-photoshoot, higgsfield-soul-id

### Cloudflare stack
- cloudflare, cloudflare-email-service, durable-objects, sandbox-sdk
- workers-best-practices, wrangler, web-perf, turnstile-spin

### Agent infrastructure
- agents-sdk, find-skills, google-antigravity-ops
- agent-orchestration, gemini-dispatcher, codex-dispatcher
- superpowers-orchestrator, dispatching-parallel-agents
- subagent-driven-development, executing-plans, writing-plans

### Frontend / UI design references
- ui-ux-pro-max, impeccable-style, taste-skill
- emil-kowalski, framer-motion, dev21-components
- styleui, ali-imam-ui, watermelon-ui, skiper-ui
- huashu-design, cult-ui

### Engineering workflow
- planning, brainstorming, builder, design
- dev-quality, dev-workflow, code-review
- receiving-code-review, requesting-code-review
- test-driven-development, systematic-debugging
- verification-before-completion, finishing-a-development-branch
- using-git-worktrees, ecc-harness-methodology

### Document creation
- docx, pptx, pdf, xlsx
- canvas-design, brand-guidelines, theme-factory
- writing, internal-comms, doc-coauthoring
- algorithmic-art, slack-gif-creator

### Specialized
- trading-agents, autoresearch, manus-autonomy
- playwright, scrapling
- mcp-builder, skill-creator, web-artifacts-builder
- consolidate-memory, schedule, setup-cowork
- using-superpowers, writing-skills

---

## Recommended add-ons (install separately)

```bash
npx skills add mattpocock/skills            # Engineering skills
npx skills add addyosmani/agent-skills      # Production engineering
npx skills add multica-ai/andrej-karpathy-skills  # Karpathy patterns
npx skills add K-Dense-AI/scientific-agent-skills  # 140+ science
npx skills add anthropics/claude-plugins-official  # Big official set
```

Or run `install.sh` to get everything in one shot.

---

## Frameworks & memory layers (linked, not vendored)

- [mem0ai/mem0](https://github.com/mem0ai/mem0) — Universal memory layer
- [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) — Persistent context
- [crewAIInc/crewAI](https://github.com/crewAIInc/crewAI) — Multi-agent framework
- [swarmclawai/swarmclaw](https://github.com/swarmclawai/swarmclaw) — Multi-agent runtime
- [exo-explore/exo](https://github.com/exo-explore/exo) — Run frontier AI locally
- [TauricResearch/TradingAgents](https://github.com/TauricResearch/TradingAgents) — Trading framework
- [CloakHQ/CloakBrowser](https://github.com/CloakHQ/CloakBrowser) — Stealth browser
- [bytedance/UI-TARS-desktop](https://github.com/bytedance/UI-TARS-desktop) — Multimodal agent stack
- [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph) — Code knowledge graph

---

## Cross-agent install pattern

```bash
# Same command, every agent, every machine:
npx skills add macaiagent1-cyber/agent-skills

# On a new machine, full stack in one command:
curl -fsSL https://raw.githubusercontent.com/macaiagent1-cyber/agent-skills/main/install.sh | bash

# Update everywhere:
npx skills update
```

---

## Attribution

| Source | Skills | Original Repo |
|---|---|---|
| Higgsfield AI | 4 skills | [higgsfield-ai/skills](https://github.com/higgsfield-ai/skills) |
| Anthropic Skills | many | [anthropics/skills](https://github.com/anthropics/skills) |
| Superpowers | several | [obra/superpowers](https://github.com/obra/superpowers) |
| Addy Osmani | several | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| Cloudflare set | 7 skills | Cloudflare docs / Cowork bundled |
| kimi-webbridge | 1 skill | Merlin (original) |

Vendored skills retain their original licenses (see individual `SKILL.md` headers).

---

## Owner

- Merlin (macaiagent1@gmail.com)
- Primary: [macaiagent1-cyber](https://github.com/macaiagent1-cyber)
- Stars/research: [kevinthegamer](https://github.com/kevinthegamer)
