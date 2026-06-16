---
name: playwright
description: Microsoft Playwright (Python 1.59.0, already in requirements.txt and pinned). The AI Fund already uses it via tools/grok_browser_bridge.py to drive a browser-mediated Grok session (no xAI API key). Trigger this skill when extending that bridge, capturing Wealthsimple position / Barchart / TradingView screenshots (wealthsimple_*.png and tqqq_*.png already live in the repo root), automating broker-sandbox flows in Phase 4 paper-validation, or scripting evidence captures attached to a trade card. Keywords: grok_browser_bridge, Wealthsimple screenshot, TradingView capture, Barchart, paper validation, headless, locator, storage_state, browser-use. Does NOT cover: live order placement (blocked by no_auth_execute=1), raw HTML scraping where Scrapling.Fetcher is faster, or anything that bypasses the risk gate.
---

# Playwright (AI Fund anchor)

## What this is
Playwright is the cross-browser automation framework. It's already a hard dependency at version 1.59.0 in `/Users/kdawg/ai-fund/requirements.txt`, alongside `browser-use==0.11.13` (an LLM-driven wrapper). The fund's only currently-running Playwright code is `tools/grok_browser_bridge.py`, which logs into grok.com in a real Chromium profile under `.playwright-mcp/` and shuttles prompts/responses between Grok and the 5-agent voting layer.

## When to trigger in AI Fund
- Extending `tools/grok_browser_bridge.py` (session persistence, prompt batching, screenshot evidence).
- **Wealthsimple Trade** captures — the repo root already contains `wealthsimple_*.png` (positions, options book, FX confirmations). Automate refreshing these into `reports/evidence/` on a schedule.
- **Barchart / TradingView** chart captures for trade cards — `tqqq_*.png` series already exists. Script these to drop into `reports/cards/<ticker>_<date>.png`.
- **Broker-sandbox automation** in Phase 4 paper-validation (AUTONOMY_ROADMAP) — drive the Questrade or Interactive Brokers paper login when the future API broker layer comes online.
- E2E smoke tests for the Phase 6+ Mac mini dashboard once it exists.

## Setup in AI Fund
Already installed. To refresh Chromium binaries on a new machine:

```bash
/Users/kdawg/ai-fund/.venv/bin/python -m playwright install chromium
/Users/kdawg/ai-fund/.venv/bin/python -m playwright install-deps   # Linux only
```

`browser-use==0.11.13` is also installed. **Decision rule:**
- Use raw `playwright` for deterministic, scripted flows (login → click known selector → screenshot). This is what `grok_browser_bridge.py` does today.
- Use `browser-use` only when the page layout is unknown / changes / requires reasoning ("find the option chain row matching strike 78 expiry May 15"). It's expensive (LLM-per-step) and slower — never put it in the autonomy loop's hot path.

## Usage patterns (AI-Fund-specific)

1. **Wealthsimple positions snapshot** — `tools/wealthsimple_capture.py` (new). Persisted storage state, run weekly. Output goes into `reports/evidence/wealthsimple_YYYY-MM-DD.png`. Then `PORTFOLIO.md` is reconciled by Claude (manual eyes), not auto-parsed — the screenshot is for audit, not for re-importing positions.

   ```python
   from playwright.sync_api import sync_playwright
   with sync_playwright() as p:
       ctx = p.chromium.launch_persistent_context(
           "/Users/kdawg/ai-fund/.playwright-mcp/wealthsimple",
           headless=True,
       )
       page = ctx.new_page()
       page.goto("https://my.wealthsimple.com/app/trade", wait_until="networkidle")
       page.locator('[data-testid="positions-table"]').screenshot(
           path="/Users/kdawg/ai-fund/reports/evidence/wealthsimple_2026-05-14.png"
       )
       ctx.close()
   ```

2. **TQQQ option-chain capture** — drive Barchart's options page, screenshot the May 15 chain. Used inside the TQQQ trade card audit trail. **Capture only — do not place orders.**

3. **Grok bridge extensions** — already in `tools/grok_browser_bridge.py`. When extending, keep the contract: write the rendered Grok response into `data/agent_runs.csv` with `agent=grok`, so the weighted-voting layer in `tools/agent_runner.py` consumes it identically to API-backed agents.

4. **TradingView snapshot helper** — same pattern, parametrized by ticker. Output filename matches the trade card schema in `AI_PORTFOLIO_STANDARD.md`.

5. **Headed mode for debugging only.** The Mac mini launchd job runs headless. If a flow breaks, run `headless=False` locally, fix selectors, push the patch.

## Integration with the 5-agent system
- **Grok**: 100% Playwright-mediated via `grok_browser_bridge.py`. Voting weight in social / meme / crypto plays is high (~30%); a broken bridge silently nukes Grok's vote — surface bridge failures in `source_health`.
- **Codex**: consumes Playwright-captured option-chain screenshots when scoring options plays (TQQQ call, future single-leg trades).
- **Gemini / DeepSeek / Gemma**: do not directly invoke browser automation.
- **Claude** runs the risk gate over whatever the bridge produced — never executes browser steps itself in the autonomy loop.

## Risk gate / compliance
- Playwright can **see** the broker UI but **must not click Buy/Sell**. `data/risk_limits.csv` has `no_auth_execute=1` and `live_trading_enabled=0`. Any code path that automates an order is a hard violation until those flags flip (post-30-60 day paper validation, post-broker-API).
- VUN and XEQT positions are visible in Wealthsimple captures. Treat them as read-only audit artifacts — captures are never an input to a "sell" recommendation.
- The TQQQ May 15 $78 call expires Friday May 15, 2026. Don't roll/close it via automation — the client must explicitly authorize.
- Single-leg-only constraint applies even if Playwright could technically build a spread in the UI.

## Gotchas
- `.playwright-mcp/` profile directories contain real session cookies. Do not commit. `.gitignore` should already exclude them — verify.
- Wealthsimple has bot detection. Use the persistent profile (already logged in via a human session) rather than a fresh context every run.
- 2FA: Wealthsimple may prompt periodically. If captures start failing, that's the first thing to check — surface in source_health.
- `browser-use` and raw `playwright` share the same Chromium install but different context-management styles. Don't mix in one script.
- Headed-mode CI on the Mac mini needs the screen-saver/lock disabled or you get black screenshots.

## Reference
- Upstream: https://github.com/microsoft/playwright (Python: https://playwright.dev/python)
- browser-use: https://github.com/browser-use/browser-use
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/tools/grok_browser_bridge.py`
  - `/Users/kdawg/ai-fund/requirements.txt` (playwright==1.59.0, browser-use==0.11.13)
  - `/Users/kdawg/ai-fund/.playwright-mcp/` (persistent browser profiles)
  - `/Users/kdawg/ai-fund/wealthsimple_*.png`, `tqqq_*.png` (existing capture artifacts)
  - `/Users/kdawg/ai-fund/data/risk_limits.csv`
