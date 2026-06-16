---
name: taste-skill
description: Taste-Skill (upstream Leonxlnx) is a frontend "remove AI slop" skill installed via npx skills add — its native target is React/UI work. AI Fund has no frontend today; the Phase 6+ Mac mini dashboard is planned but not built. So this skill is re-anchored to AI Fund's REAL output discipline: trade cards, daily briefs, and the public AI portfolio voice. Trigger when generating a trade card via tools/trade_card_generator.py, when drafting the daily brief that goes to reports/autonomous_daily_brief_*.md, when writing X.com publish copy under the AI_PORTFOLIO_STANDARD.md voice rules, or when refusing to use the engagement-bait phrasing that makes LLM output sound like ChatGPT slop. Keywords: trade card, daily brief, AI_PORTFOLIO_STANDARD, voice, signal density, no slop, no emoji, no em-dashes-as-drama, public AI portfolio. Does NOT cover: the future dashboard's CSS (when that exists, the upstream skill applies directly); brand strategy; Python logic.
---

# taste-skill (AI Fund anchor)

## What this is
Upstream Leonxlnx/taste-skill is a frontend-design taste filter for AI coding agents. It says: no purple gradients, no emoji-as-icon, no Inter-for-everything, prefer real spacing scales, prefer editorial CSS Grid layouts. The AI Fund has no frontend yet — the Phase 6+ Mac mini dashboard is roadmap, not code. So we honor the lineage (taste-as-anti-slop discipline) and re-anchor it to what AI Fund actually ships **today**: text. Trade cards. Daily briefs. The eventual X.com / public-AI-portfolio voice. The skill teaches Claude to write output that does not sound like default LLM output.

## When to trigger in AI Fund
- Generating a trade card via `tools/trade_card_generator.py` (the plain-text AI FUND TRADE CARD format in `AI_PORTFOLIO_STANDARD.md`).
- Writing the daily brief that lands in `reports/autonomous_daily_brief_YYYY-MM-DD.md`.
- Drafting any copy meant for the public AI portfolio (eventual X.com publishing).
- Rewriting client-facing output that came out vague, hedged, or engagement-baited.
- Phase 6+ — when the dashboard exists, the upstream taste-skill applies directly to its React code; keep this skill for the text layer.

## Setup in AI Fund
No install needed for the text discipline. If/when the dashboard is built:

```bash
# Future, only when Phase 6+ frontend exists:
cd /Users/kdawg/ai-fund/dashboard   # does not exist yet
npx skills add https://github.com/Leonxlnx/taste-skill
```

For now this skill lives entirely as Claude-side writing rules, enforced when generating `reports/*.md` and trade cards.

## Usage patterns (AI-Fund-specific)

1. **Trade card voice rules** (enforced when `trade_card_generator.py` output is reviewed):
   - Signal section: name the trigger in <= 12 words. No "interesting setup," no "potential opportunity."
   - Thesis: 3 sentences max. Concrete numbers (price, ratio, date). Skip adjectives.
   - Counter-thesis: must be sharp. "Earnings miss" is not enough; say *what miss* would kill it.
   - Trade plan: entry, target, stop, size, platform, order type — all numeric. No "around X" or "in the range of."
   - Portfolio fit: name the exposure %, the correlation, the cash impact.
   - Status: one of the 6 enums (`Watching / Recommended / Executed / Passed / Closed / Expired`). Never invent a 7th.

2. **Daily brief discipline.** The brief is information density per line, not narrative arc. Each section is data-first; commentary is bounded to one sentence per section. Forbidden:
   - "It's worth noting that..."
   - "The market appears to be..."
   - "Investors should consider..."
   - Bullet points that are entire paragraphs.
   - Closing motivational summary. The brief ends when the data ends.

3. **Anti-slop checklist** (apply before any client-facing output ships):
   - No emoji.
   - No em-dash-for-drama ("The trade — and this is the key — needs..."). Em-dashes are for parentheticals only.
   - No "Let me explain" / "Here's the thing" framing.
   - No three-bullet "key takeaways" tail when one sentence would do.
   - No "potentially," "could possibly," "might be worth" hedging when the agent has actual conviction. If conviction is low, *say* it's low and name the gap.
   - No "the AI agrees" / "the model is confident" anthropomorphic phrasing. The committee voted X; the score was Y; that's the language.

4. **Public AI portfolio voice (`AI_PORTFOLIO_STANDARD.md`).** When eventually publishing trades to X.com under the public-AI-portfolio brand:
   - Trade announcement = the trade card, untouched. No "exciting trade idea" preamble.
   - Honest losses are published with the same format as wins. Same enums.
   - Source attribution per agent: "Codex flagged options flow; Gemini cross-checked filings; Claude approved at 0.62 conviction." Not "the AI saw."

5. **Recovery from slop.** If a draft comes back vague: cut every sentence that doesn't carry a number, a name, or a decision. Whatever's left is the actual content.

## Integration with the 5-agent system
- **Claude** is the only voice the client sees. Gemini / Grok / Codex / DeepSeek+Gemma write internal artifacts in `data/agent_runs.csv` — those are raw and don't need taste discipline. The synthesis pass Claude does is where this skill applies.
- **Grok**, in particular, tends toward engagement-baited phrasing because of its source diet (X.com). When Claude synthesizes a brief that includes a Grok-driven signal, strip the social-media affect and reduce to: source, signal, conviction.
- No voting-weight implication. This skill is downstream of the vote, upstream of client output.

## Risk gate / compliance
- The voice rules NEVER soften the pinned hard rules. A trade card that recommends selling VUN or XEQT is wrong content; no amount of voice polish fixes that.
- "Confidence" language must match conviction score honestly. If the committee scored 0.51, the card says "low conviction" — not "compelling setup."
- Forward-looking statements need disclaimers per `AI_PORTFOLIO_STANDARD.md`. Voice discipline does not include dropping the disclaimer for flow.
- Compliance text (paper-mode, Phase 0, advisor-assist) appears verbatim where the standard requires it. Don't paraphrase it for tone.

## Gotchas
- This is text discipline, not a design system. When the Phase 6+ dashboard ships, switch to the upstream skill for the React side.
- Anti-slop ≠ terse-to-the-point-of-unclear. The goal is signal density, not minimalism for its own sake.
- Claude has trained biases toward the very phrasings this skill bans ("It's worth noting," "potentially," three-bullet endings). Expect to scrub on review, not just on first draft.
- The trade-card schema in `AI_PORTFOLIO_STANDARD.md` is the contract. Voice rules cannot reorder the 6 sections or rename them.
- Upstream Leonxlnx has multiple variants (minimalist, soft, brutalist). Map to AI Fund as: trade cards = brutalist (raw, no decoration); daily brief = minimalist (spacious, dense); public X posts = minimalist with verbatim trade-card body.

## Reference
- Upstream: https://github.com/Leonxlnx/taste-skill
- Site: https://tasteskill.dev
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/AI_PORTFOLIO_STANDARD.md` (the 6-section card schema, public voice)
  - `/Users/kdawg/ai-fund/tools/trade_card_generator.py`
  - `/Users/kdawg/ai-fund/reports/autonomous_daily_brief_*.md`
  - `/Users/kdawg/ai-fund/PROTOCOL.md` (output format)
  - `/Users/kdawg/ai-fund/TRADE_LOG.md`
