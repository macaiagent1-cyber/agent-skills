# agent-skills

Merlin's personal skills hub for cross-agent use.

Install in any agent that supports the [npx skills](https://skills.sh/) ecosystem (Claude Code, Codex, Gemini, Cursor, etc.):

```bash
npx skills add macaiagent1-cyber/agent-skills
```

## Skills included (16)

### Media generation
- **higgsfield-generate** — Image/video gen via Higgsfield AI (Sora 2, Veo 3.1, Kling 3.0, Nano Banana, Flux, etc.)
- **higgsfield-marketplace-cards** — Marketplace product image cards (main, secondary, A+ modules)
- **higgsfield-product-photoshoot** — Brand-quality product photography (studio, lifestyle, ad creative, restyle)
- **higgsfield-soul-id** — Train a personalized Soul Character for identity-faithful generation

### Web / browser control
- **kimi-webbridge** — Control the user's real browser via local daemon (navigate, click, fill, screenshot)
- **turnstile-spin** — Cloudflare Turnstile bypass / handling

### Cloud / infra (Cloudflare stack)
- **cloudflare** — General Cloudflare workflows
- **cloudflare-email-service** — Email routing and workers via Cloudflare
- **durable-objects** — Cloudflare Durable Objects patterns
- **sandbox-sdk** — Cloudflare Sandbox SDK
- **workers-best-practices** — Cloudflare Workers best practices
- **wrangler** — Wrangler CLI workflows
- **web-perf** — Web performance optimization

### Agent / tooling
- **agents-sdk** — Agent SDK patterns
- **find-skills** — Discover and install skills from the open ecosystem
- **google-antigravity-ops** — Google Antigravity operations

## Usage

```bash
# Install all skills
npx skills add macaiagent1-cyber/agent-skills

# Install a single skill
npx skills add macaiagent1-cyber/agent-skills@kimi-webbridge

# Update to latest
npx skills update

# List installed
npx skills list
```

## Cross-agent use

This repo is designed so any agent on any machine can install the same skill set:

```bash
# On Codex
npx skills add macaiagent1-cyber/agent-skills

# On Claude Code
npx skills add macaiagent1-cyber/agent-skills

# On Gemini, Cursor, etc.
npx skills add macaiagent1-cyber/agent-skills
```

Update once, all agents stay in sync.

## Owner

- Merlin (macaiagent1@gmail.com)
- GitHub: [macaiagent1-cyber](https://github.com/macaiagent1-cyber)

## License

Original skills (kimi-webbridge): MIT.
Higgsfield-* skills are vendored copies from [higgsfield-ai/skills](https://github.com/higgsfield-ai/skills) — consult upstream for license.
Cloudflare-related skills are derived from public Cloudflare documentation.
