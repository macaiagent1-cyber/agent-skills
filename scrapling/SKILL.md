---
name: scrapling
description: Scrapling is a Python stealth-scraping framework (Parsel-fast selectors, three fetchers — HTTP/dynamic/stealth — Cloudflare-Turnstile bypass, Scrapy-style spiders with pause/resume). Trigger inside AI Fund when the autonomy_cycle.py signal-discovery layer needs sources beyond yfinance — SEC EDGAR 8-K/13F/Form 4 filings (the SEC filings adapter is currently inactive per source_health in autonomous_daily_brief reports), the options_flow adapter (also inactive — needs Barchart/MarketChameleon scrape), Canadian-listed ETF data Wealthsimple actually trades (ZQQ, XEQT, VUN, VFV via TMX Money / globeandmail.com), or news/social signals Grok-via-browser can't cheaply cover. Keywords: signal discovery, source adapter, SEC filings, EDGAR, options flow, ETF data, TMX, source_health, autonomy_cycle. Does NOT cover: paid proxy networks, captcha-solving services, X.com scraping (use tools/grok_browser_bridge.py), or any execution path — scrapers feed signals only, the risk gate still applies.
---

# Scrapling (AI Fund anchor)

## What this is
Scrapling is an adaptive Python scraping framework: lxml-fast selectors with self-healing locators, plus three fetchers (`Fetcher` HTTP, `DynamicFetcher` Playwright, `StealthyFetcher` anti-bot). For AI Fund it is a candidate library to fix the inactive source adapters in `tools/autonomy_cycle.py` and to add Canadian-broker-relevant data sources yfinance doesn't cover well.

## When to trigger in AI Fund
- Reviving the **SEC filings adapter** in `tools/autonomy_cycle.py` (marked inactive in the latest `reports/autonomous_daily_brief_*.md` source_health table) — 8-K, 13F, Form 4 insider activity.
- Reviving the **options_flow adapter** (also inactive) — scraping Barchart / MarketChameleon unusual-options-activity tables.
- Pulling **Canadian-listed ETF** metadata (ZQQ, XEQT, VUN, VFV, HXQ, etc.) from TMX Money or globeandmail.com — relevant because Wealthsimple charges 1.5% FX on USD, so a Canadian equivalent is often the recommended trade.
- Adding **Substack / news** sources that complement Gemini's research role when a paywall or Cloudflare blocks plain requests.
- When `tools/screener.py` (monthly thesis screener) needs a new structured source for fundamentals.

## Setup in AI Fund
Use the project venv. Scrapling is not currently in `requirements.txt`.

```bash
/Users/kdawg/ai-fund/.venv/bin/pip install scrapling
/Users/kdawg/ai-fund/.venv/bin/python -m scrapling install   # Playwright browsers for fetchers
```

Pin the version in `/Users/kdawg/ai-fund/requirements.txt` after testing. Playwright is already installed (1.59.0), so the browser binaries may already be cached at `~/Library/Caches/ms-playwright/`.

## Usage patterns (AI-Fund-specific)

1. **Fix the SEC filings adapter** — add a new module `tools/adapters/sec_filings.py` invoked by `autonomy_cycle.py` step 1 (signal discovery). Use plain `Fetcher` (no JS, no stealth needed) against EDGAR; respect SEC's 10 req/sec limit. Output rows of `{cik, ticker, form_type, filed_date, url}` into the candidate stream consumed by `score_trade.py`.

   ```python
   from scrapling.fetchers import Fetcher
   page = Fetcher.get(
       "https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0000320193&type=8-K",
       headers={"User-Agent": "AI Fund research macaiagent1@gmail.com"},
   )
   for row in page.css("table.tableFile2 tr"):
       yield {"form": row.css("td:nth-child(1)::text").get(),
              "date": row.css("td:nth-child(4)::text").get()}
   ```

2. **Options flow adapter** — Barchart's unusual-options page is Cloudflare-gated. Use `StealthyFetcher` and cache results aggressively (this runs in autonomy_cycle's hourly loop). Hand the parsed rows to Codex (technicals / Greeks agent), which is the weighted voter for options plays.

3. **Canadian ETF metadata** — `tools/adapters/tmx_etfs.py` pulls daily NAV/volume for the Wealthsimple-tradable universe. Feeds the FX-aware swap logic that recommends ZQQ over QQQ. Keep a static map of `{us_ticker: ca_equivalent}` cached on disk; refresh weekly.

4. **Watchlist enrichment** — `tools/watchlist_report.py` currently scores tickers from WATCHLIST.md. Add a Scrapling-fed news/filings snapshot column so the daily brief shows *why* a watchlist name moved.

5. **Do NOT use Scrapling for X.com / Reddit** — that's Grok's lane, handled via `tools/grok_browser_bridge.py` with playwright already. Splitting it doesn't help.

## Integration with the 5-agent system
- **Gemini** (research / fundamentals) consumes SEC filings, news, Substack output.
- **Codex** (technicals / options) consumes options-flow and TMX ETF data.
- **Grok** is browser-mediated for social and stays on `grok_browser_bridge.py`.
- **Claude** (lead / risk officer) never invokes scrapers directly — synthesizes the resulting candidate rows and runs the risk gate.
- No voting-weight change. Sources are upstream of scoring.

## Risk gate / compliance
Scrapers produce **signals only**. They do not bypass `data/risk_limits.csv` flags (`no_auth_execute=1`, `live_trading_enabled=0`). They do not touch VUN or XEQT positions (permanent TFSA holds). They cannot trigger an order — paper or live — that path runs through `tools/pre_trade_check.py` → `tools/paper_broker.py`. A scraper failing or returning stale data must be reflected in the next brief's `source_health` table, not silently ignored.

## Gotchas
- SEC EDGAR requires a descriptive User-Agent with contact email — using a fake one risks an IP ban that breaks the autonomy loop.
- Stealth fetchers are 2-5s per page and RAM-heavy. The Mac mini deployment target needs throttling.
- Adaptive selectors need an initial training scrape — first runs after a site redesign will miss data; surface this as a source_health degradation, don't let it look like "no signals."
- TOS: Barchart and Seeking Alpha forbid scraping in their terms. This is research-grade in Phase 0; do not productize without legal review.
- Scrapling ships its own MCP server. Do NOT install it as a separate MCP — Claude already has playwright and direct file access; another MCP just adds tool-context bloat.

## Reference
- Upstream: https://github.com/D4Vinci/Scrapling
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/tools/autonomy_cycle.py` (step 1 signal discovery)
  - `/Users/kdawg/ai-fund/tools/screener.py` (monthly thesis screener)
  - `/Users/kdawg/ai-fund/tools/watchlist_report.py`
  - `/Users/kdawg/ai-fund/reports/autonomous_daily_brief_*.md` (source_health table)
  - `/Users/kdawg/ai-fund/data/risk_limits.csv`
