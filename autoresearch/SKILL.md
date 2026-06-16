---
name: autoresearch
description: Karpathy's autoresearch is a minimal pattern — one editable file, fixed wall-clock budget, one scalar metric, append-only log, an agent iterates overnight. Trigger inside AI Fund when refining the committee scoring weights in score_trade.py / data/agent_weights.csv, when searching watchlist filter thresholds (tools/watchlist_report.py scoring cutoffs), when sweeping backtest parameters as Phase 3 paper validation matures, or when tuning agent prompts where the metric is a logged paper-trade Sharpe / hit-rate / risk-adjusted return. Keywords: overnight search, scalar metric, score_trade weights, watchlist threshold, paper Sharpe, hit-rate, prompt search, parameter sweep, append-only log. Does NOT cover: live-money optimization (blocked by no_auth_execute=1), hyperparameter libraries (use scipy.optimize or PyPortfolioOpt directly for numeric sweeps), or anything without a deterministic scalar — qualitative "is the brief better?" judgments don't fit.
---

# autoresearch (AI Fund anchor)

## What this is
A tiny pattern from Karpathy: pick ONE file the agent may edit, run a FIXED time-budget experiment, score it on ONE scalar metric, keep the change if better, revert if worse, append every attempt to a log, repeat overnight. The repo's value is the discipline, not the code. For AI Fund, the pattern fits parameter and prompt refinement on the committee-scoring stack — but only where the eval is deterministic and the metric is honest paper-trade performance, not model self-grading.

## When to trigger in AI Fund
- Refining **`data/agent_weights.csv`** — how Claude/Gemini/Grok/Codex/DeepSeek+Gemma vote on each play type. Metric: held-out paper-trade hit-rate or risk-adjusted return over a backtest window.
- Tuning **`tools/score_trade.py`** scoring weights (signal × source × thesis × risk components).
- Sweeping **`tools/watchlist_report.py`** filter thresholds — what conviction floor surfaces a watchlist name into the daily brief.
- Backtest parameter sweeps in Phase 3 paper validation (entry trigger thresholds, stop-loss widths, position-size formulas).
- Agent-prompt search where the metric is paper-trade Sharpe over the validation window — NOT "did the prose sound smart."

## Setup in AI Fund
No external dep beyond what's in the venv. The pattern is a directory structure plus a small harness. Create:

```bash
mkdir -p /Users/kdawg/ai-fund/research/loops/weights_v1
cd /Users/kdawg/ai-fund/research/loops/weights_v1
touch program.md experiment.py harness.py log.jsonl
```

Files:
- `program.md` — natural-language description of the goal, constraints (pinned rules from CLAUDE.md, single-leg only, no VUN/XEQT sells), and the one file the agent may edit.
- `experiment.py` — the editable file (a copy of `data/agent_weights.csv` loader + scorer, or a parameterized version of `tools/score_trade.py`).
- `harness.py` — fixed-budget runner; calls the AI Fund backtest path, returns one scalar.
- `log.jsonl` — append-only `{timestamp, diff, metric, kept, rationale}`.

Run with the project venv:
```bash
/Users/kdawg/ai-fund/.venv/bin/python harness.py
```

## Usage patterns (AI-Fund-specific)

1. **Agent-weight search.** Lock everything else; let the agent edit only the weights matrix for a single play type (e.g. options plays — currently Codex-heavy). Metric: simulated paper-trade Sharpe on the 30-60 day validation window per `data/paper_trades.csv`. Wall-clock budget: 2 min per candidate. Run 100 candidates overnight, accept top-3, manual review.

2. **`score_trade.py` weight tuning.** The committee score combines signal strength, source credibility, thesis quality, risk score. Let the agent edit the linear weights only. Metric: hit-rate of plays that crossed the recommendation threshold over the last 30 paper days.

3. **Watchlist threshold search.** `tools/watchlist_report.py` ranks WATCHLIST.md names. Sweep the conviction floor and the staleness penalty. Metric: precision@5 — of the top-5 surfaced watchlist names, how many subsequently produced a trade card the client accepted (proxy: `STATUS=Recommended` in TRADE_LOG.md).

4. **Backtest stop-loss / entry-trigger sweep.** Editable: a single config dict. Metric: max drawdown × hit-rate (risk-adjusted). Forbidden: editing anything that touches `pre_trade_check.py` or `risk_limits.csv`.

5. **Prompt search for a single agent** — e.g. Codex's options-Greeks prompt. Editable file: `prompts/codex_options.md`. Metric: agreement-with-eventually-profitable-paper-trade on a labeled set in `data/labeled_options.csv`. Average 3 runs per candidate to denoise LLM variance.

Pattern: copy `program.md` and `harness.py` from `https://github.com/karpathy/autoresearch`, point the harness at the AI Fund backtest CLI, read the scalar from a logged paper-trade summary.

## Integration with the 5-agent system
- The loop is run *by* Claude (or Codex for parameter sweeps) **outside** the autonomy_cycle.py runtime — it is a research tool, not a hot-path optimizer.
- Outputs that update `data/agent_weights.csv` directly affect future voting. **Require a human approval pass** before the weight file is replaced in production — `cp research/loops/weights_v1/best.csv data/agent_weights.csv.candidate`, then `MEMORY.md` notes the swap is pending client confirmation.
- DeepSeek/Gemma (local Ollama) are good cheap drivers for the loop because they're not rate-limited.

## Risk gate / compliance
- Backtest harnesses MUST honor pinned rules: no VUN / XEQT sell candidates ever appear in the candidate stream, single-leg-only options, FX-aware ETF substitution.
- `no_auth_execute=1` and `live_trading_enabled=0` are *not* knobs the loop may flip — the editable file must be a config / weight / prompt, never `data/risk_limits.csv`.
- Metric must come from a deterministic backtest or paper-validation slice. Live-money optimization is forbidden in Phase 0. The whole point of the 30-60 day paper window is to avoid optimizing on real capital.
- Optimization can produce overfit weights. Always evaluate on a held-out slice (e.g. last 7 days) that the loop never sees.

## Gotchas
- **LLM non-determinism.** Prompt edits + same input = different output. Average 3-5 runs per candidate or you'll keep noise as "improvement."
- **Overfitting** is the default failure mode. Reserve a forward-walk slice the loop cannot touch.
- **Cost.** 100 iterations × a Claude API call per iteration is real money. Prefer local DeepSeek/Gemma for the driver; reserve Claude/Gemini for the final review pass.
- **The metric is the bug surface.** If the metric rewards "buy everything," the loop finds that. Sanity-cap the metric (e.g. penalize position concentration >30%, cash <10% — same as Claude's risk gate).
- **Don't optimize on too few trades.** Phase 0 has ~zero paper history; build the eval slice first via `tools/performance_tracker.py` before unleashing the loop.

## Reference
- Upstream: https://github.com/karpathy/autoresearch
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/research/loops/` (suggested layout; create as needed)
  - `/Users/kdawg/ai-fund/tools/score_trade.py`
  - `/Users/kdawg/ai-fund/tools/watchlist_report.py`
  - `/Users/kdawg/ai-fund/tools/performance_tracker.py`
  - `/Users/kdawg/ai-fund/data/agent_weights.csv`
  - `/Users/kdawg/ai-fund/data/paper_trades.csv`
