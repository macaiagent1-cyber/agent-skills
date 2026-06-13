---
name: huashu-design
description: Chinese-language Claude Code design skill (upstream alchaincyf/huashu-design, 画术 = design technique) for hi-fi prototypes, slide decks, MP4 animations, and a 5-axis critique system. Honest caveat — upstream is predominantly Chinese, AI Fund has no design surface today. Portable parts: brand-asset protocol, batched-question workflow, 5-axis critique — applied to AI Fund's public-grade output per AI_PORTFOLIO_STANDARD.md. Trigger on "huashu", "design protocol", "brand spec", "5-axis critique", "investor deck", "mockup", or any visual/marketing deliverable. Does NOT cover Chinese sales copy (homophone 话术 vs 画术), trade-card schema, or backend logic.
---

# huashu-design (AI Fund anchor)

## What this is
Upstream alchaincyf/huashu-design is a Chinese-language Claude Code skill that ships a 20-style design vocabulary, a Junior-Designer workflow, a 5-step brand-asset protocol (extract real colors from official sources, never the model's memory), a 5-axis critique (philosophical consistency / visual hierarchy / execution detail / function / innovation), and a Stage+Sprite animation engine that exports MP4/GIF.

Two honesty markers up front:
1. **Language barrier** — the upstream SKILL.md and most reference files are in Chinese. Claude can translate on the fly, but expect Chinese strings in generated comments and references. Tell it the output audience language explicitly.
2. **AI Fund has no design surface today.** No frontend, no deck, no marketing site. The Phase 6+ Mac mini dashboard is on the roadmap, not in the repo. So the portable part of huashu-design here is the *protocol discipline*: brand-asset rigor, batched clarifying questions, 5-axis review — applied to AI Fund's text-and-future-pixel deliverables.

## When to trigger in AI Fund
- Client asks for an **investor / partner deck** explaining the fund.
- Client asks for a **mockup** of the future Phase 6+ dashboard.
- Drafting a **public AI portfolio launch** asset for X.com (image + copy) per `AI_PORTFOLIO_STANDARD.md`.
- Producing a **trade-card visual** (chart + card layout) that goes beyond the plain-text generator.
- Running a **design critique** on anything visual the fund eventually produces.
- Defining a **brand-spec.md** if/when AI Fund gets a visual identity (colors, type, voice).

## Setup in AI Fund
Installation is optional — most of the value is the protocol, which Claude can follow without the upstream files. If you want the upstream toolchain:

```bash
# Optional. Requires Node 18+ and ffmpeg.
npx skills add alchaincyf/huashu-design
```

This drops a Playwright-renderer toolchain, html2pptx exporter, and starter components (iPhone bezel, browser chrome, deck stage). The renderer overlaps with the project's existing Playwright install — do not install a separate Playwright stack. If invoking the upstream Python renderer, point it at `/Users/kdawg/ai-fund/.venv/bin/python`.

## Usage patterns (AI-Fund-specific)

1. **Brand Asset Protocol → AI Fund brand-spec.** Today there is no `brand-spec.md`. When asked to produce one, follow the upstream rule: do NOT invent colors. Sources of truth:
   - Existing `wealthsimple_*.png` screenshots (broker context).
   - `tqqq_*.png` (chart aesthetic the client is already using).
   - The plain-text trade-card format in `AI_PORTFOLIO_STANDARD.md` (the *real* current brand).
   Output: `/Users/kdawg/ai-fund/brand-spec.md` with CSS variables, type pairing, voice notes. All future visual work uses `var(--brand-*)`. Never paint over the public AI portfolio standard's voice.

2. **Investor / partner deck.** When generating, use the Junior-Designer workflow: batch clarifying questions first (audience, length, tone, must-include data), grey-block first pass, iterate on actual data, then visual polish. Deck content must match the fund's real state — Phase 0, $11,654 CAD inception, advisor-assist mode, paper-validation window. Forbidden: implying live execution, implying multi-leg options access, implying any non-Wealthsimple-supported trade type.

3. **5-axis critique on output.** Apply when the client asks "is this any good?" on a visual:
   - Philosophical consistency: does it match `AI_PORTFOLIO_STANDARD.md` voice?
   - Visual hierarchy: does the eye land on the trade decision first, not the decoration?
   - Execution detail: real numbers? Real dates? No lorem ipsum?
   - Function: can the audience act on it?
   - Innovation: does it look like every other AI-fund Twitter thread, or like this fund?

4. **Dashboard mockups (Phase 6+).** When the Mac mini dashboard is ready to design, run huashu's iPhone/macOS-frame components to mock the daily-brief view and the trade-queue view *before* writing React. Deliver as static HTML in `/Users/kdawg/ai-fund/research/mockups/` for client review.

5. **Pair with taste-skill.** huashu produces deliverables (decks, mockups, MP4); taste-skill enforces the text/voice discipline inside those deliverables. Use them together — huashu's slide says *what* and taste-skill enforces *how it reads*.

## Integration with the 5-agent system
- **Claude** is the only agent that produces client-visible design work. Gemini may research brand examples for inspiration; Codex may compute the numbers that go on slides. The synthesis voice is Claude's.
- No voting-weight implication — this is downstream of trading decisions, not a decision input.
- Public AI portfolio publishing eventually involves Grok (since publishing is on X.com), but huashu's role is the artifact, not the channel.

## Risk gate / compliance
- Decks and public assets must NEVER claim execution that didn't happen. If the deck shows a "TQQQ +X%" tile, that number is paper-only (Phase 0) and labeled as such.
- VUN / XEQT positions visible in any portfolio screenshot in a deck — disclose they are permanent TFSA holds, not active trades.
- Single-leg options constraint: the deck cannot show a "covered strangle" or "iron condor" example as part of the fund's strategy. Only single-leg long calls, long puts, covered calls.
- FX cost (1.5% on USD): if a deck mentions cost basis, the FX leg has to be in the math.
- Forward-looking claims need disclaimer language per `AI_PORTFOLIO_STANDARD.md`.

## Gotchas
- **Language barrier.** Tell Claude the audience language up front, otherwise comments in generated HTML may come out in Chinese.
- **Naming confusion.** 画术 (huà shù, "drawing technique") sounds identical to 话术 (huà shù, "scripted persuasion / sales talk"). This skill is the *former*. It is not for writing sales copy in Chinese; don't try to make it draft Wealthsimple persuasion scripts.
- **Personal-use license on upstream.** Commercial use needs the author's permission. Check before publishing.
- **Heavy local toolchain** (ffmpeg, Playwright browsers, Node 18+). Most AI Fund work doesn't need it — the protocol discipline is most of the value.
- **Don't use huashu to design the trade-card text layout.** That schema is set by `AI_PORTFOLIO_STANDARD.md` and is non-negotiable. huashu sits above the schema (deck, brand, mockup), not inside it.
- **Quality cap.** Author flags that blank-canvas brand design caps ~60-65/100 quality without a designer in the loop. For high-stakes investor decks, treat huashu output as a strong draft, not the final.

## Reference
- Upstream: https://github.com/alchaincyf/huashu-design
- Site: https://www.huasheng.ai/
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/AI_PORTFOLIO_STANDARD.md` (governs all client-visible output)
  - `/Users/kdawg/ai-fund/PROTOCOL.md` (decision-flow + output format)
  - `/Users/kdawg/ai-fund/MANDATE.md` (fund mandate — what's in scope for decks)
  - `/Users/kdawg/ai-fund/research/mockups/` (suggested layout for future visual work)
  - `/Users/kdawg/ai-fund/wealthsimple_*.png`, `/Users/kdawg/ai-fund/tqqq_*.png` (visual reference material)
