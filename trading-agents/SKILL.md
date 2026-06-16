---
name: trading-agents
description: TauricResearch/TradingAgents is a LangGraph-based multi-agent trading framework — Analysts (fundamentals/sentiment/news/technical), Bull-vs-Bear researchers, a Trader, a Risk Management Team, a Portfolio Manager, plus reflection memory. It is ALREADY VENDORED at /Users/kdawg/ai-fund/external/TradingAgents. AUTONOMY_ROADMAP.md Phase 3 is explicit: use it as a debate-flow REFERENCE only — never as an execution authority. Trigger this skill when porting debate-loop patterns into tools/agent_runner.py, when refining the 5-agent weighted vote, when adding a structured bull/bear pass before Claude's risk gate, or when comparing flow architectures. Keywords: TradingAgents, vendored, debate loop, LangGraph, agent_runner, weighted vote, risk gate, reference only. Does NOT cover: replacing the 5-agent system, importing TradingAgents' data sources, or any execution authority — Claude remains lead strategist and risk officer.
---

# TradingAgents (AI Fund anchor)

## What this is
TradingAgents is Tauric Research's multi-agent LLM trading framework (LangGraph state machine, four analyst roles, debate-driven researcher pair, risk team, portfolio manager, reflection memory). For AI Fund it is **already vendored** at `/Users/kdawg/ai-fund/external/TradingAgents` and treated per `AUTONOMY_ROADMAP.md` Phase 3 as a *reference architecture*, not a runtime. The fund's actual orchestrator stays `tools/agent_runner.py` with 5 weighted voters (claude, gemini, grok, codex, deepseek+gemma) — TradingAgents is a pattern library to borrow from, not swap to.

## When to trigger in AI Fund
- Adding a **bull/bear debate pass** to `tools/agent_runner.py` before Claude's risk gate — e.g. force the two highest-divergence votes to argue one round and have Claude synthesize.
- Designing the **reflection memory** that `LEARNINGS.md` should feed back into the next session (TradingAgents writes `trading_memory.md`; AI Fund already has `MEMORY.md` + `LEARNINGS.md` — port the reflection prompt shape).
- Designing **risk-team / portfolio-manager separation** as a future refactor of Claude's currently-monolithic risk gate.
- Reading reference implementations of LangGraph state machines when extending `autonomy_cycle.py` step 3 (committee scoring).
- Comparing AI Fund's persona/source-weighted ensemble to TradingAgents' role-based hierarchy when the client asks "should we restructure?"

## Setup in AI Fund
Already cloned. To work inside the vendored copy:

```bash
cd /Users/kdawg/ai-fund/external/TradingAgents
# Use the project venv, not a separate conda env:
/Users/kdawg/ai-fund/.venv/bin/pip install -e . --no-deps
# Inspect graph definitions without running:
ls tradingagents/graph/
```

**Important:** do NOT install TradingAgents' transitive dependencies into the AI Fund venv. It pulls Alpha Vantage / OpenAI clients that duplicate what we already have. Read its source for patterns; do not import it into `tools/`.

## Usage patterns (AI-Fund-specific)

1. **Port the debate loop shape into `tools/agent_runner.py`.** Today every agent votes independently and weights aggregate. Add an optional `--debate` flag that, when conviction spread > X, picks the top bull and top bear and runs N rounds of structured rebuttal before Claude synthesizes. Reference: `external/TradingAgents/tradingagents/graph/researcher_debate.py`. Keep the loop inside agent_runner — do not actually instantiate `TradingAgentsGraph`.

2. **Port the reflection prompt** that TradingAgents injects into the next-run prompt from realized return. AI Fund already logs `data/agent_runs.csv` and `LEARNINGS.md`; the missing piece is a templated "what did we learn from prior same-ticker decisions" block in the agent prompt. Read `external/TradingAgents/tradingagents/memory/` for the prompt shape, then implement in `agent_runner.py`'s prompt builder.

3. **Borrow the risk-team / PM split conceptually.** Currently Claude does both risk evaluation and final synthesis. Phase 3+ could split: a "risk agent" prompt (caps, exposure, hard-rules check from CLAUDE.md), then a separate "portfolio manager" pass that approves/rejects. Even running both as Claude with different prompts gives auditability.

4. **Do NOT call `propagate()` on AI Fund tickers.** TradingAgents has its own data path, persona-less analysts, and decision schema. Running it in parallel produces a 6th vote whose lineage is unclear and whose data sources duplicate yfinance + your scrapers.

5. **When asked "should we replace agent_runner with TradingAgents?" — the answer is no.** The 5-agent weighted vote with Claude as risk officer is the fund's identity. The flat-vs-hierarchical tradeoff favors flat for a Phase 0 fund with $11,654 capital where every layer adds latency and token cost.

## Integration with the 5-agent system
- **Claude** owns synthesis and risk; TradingAgents' "Portfolio Manager" role maps to Claude's existing final pass.
- **Gemini** maps to TradingAgents' Fundamentals + News analyst — already its lane.
- **Grok** maps to Sentiment analyst — already its lane.
- **Codex** maps to Technical analyst — already its lane.
- **DeepSeek/Gemma** are second-opinion overflow; no TradingAgents analog, leave as-is.
- Voting weights in `data/agent_weights.csv` stay the source of truth. TradingAgents has no weights — it stacks roles. Don't try to mix.

## Risk gate / compliance
- TradingAgents itself has no concept of `no_auth_execute=1` / `live_trading_enabled=0`. If any code path ever instantiates `TradingAgentsGraph().propagate(...)` and acts on its output, that bypasses the AI Fund risk gate. Forbidden.
- TradingAgents will happily recommend selling anything. **VUN and XEQT are permanent TFSA holds.** Any port of its prompts must include the pinned hard rules from `CLAUDE.md`.
- Single-leg-only Wealthsimple constraint is not in TradingAgents' worldview. If you borrow its Trader prompt, strip multi-leg suggestions.
- TQQQ May 15 $78 call: TradingAgents' reflection logic could suggest rolling. Pinned rule: only on explicit client request.

## Gotchas
- LangGraph is a heavy dep. Don't add it to `requirements.txt` just for the reference reading — it's already an indirect dep via langchain==1.3.0 in the AI Fund venv.
- TradingAgents' default config calls multiple deep-think LLMs per ticker. At AI Fund's scale (single account, hourly autonomy_cycle), this is overkill and cost-prohibitive.
- Persona dilution: forcing Buffett-style fundamentals into a generic "Fundamentals Analyst" role loses signal. AI Fund keeps source-attribution per agent identity; don't flatten that to "analyst said X."
- The vendored copy can drift from upstream. Record the commit SHA in `external/TradingAgents/COMMIT.txt` if you treat any specific version as authoritative.

## Reference
- Upstream: https://github.com/TauricResearch/TradingAgents
- Paper: https://arxiv.org/abs/2412.20138
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/external/TradingAgents/` (vendored)
  - `/Users/kdawg/ai-fund/tools/agent_runner.py`
  - `/Users/kdawg/ai-fund/tools/autonomy_cycle.py` (step 3 committee scoring)
  - `/Users/kdawg/ai-fund/AUTONOMY_ROADMAP.md` (Phase 3 note: reference only)
  - `/Users/kdawg/ai-fund/data/agent_weights.csv`
  - `/Users/kdawg/ai-fund/LEARNINGS.md`, `/Users/kdawg/ai-fund/MEMORY.md`
