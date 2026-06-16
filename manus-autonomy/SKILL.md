---
name: manus-autonomy
description: A behavioral skill — NOT an integration. There is no manus.ai MCP, no API call, no product hook. The pattern is the autonomous loop AI Fund already operates: tools/autonomy_cycle.py --loop running the 1-7 pipeline per AUTONOMY_OPERATIONS.md (discover signals → candidates → committee scoring → ranking → alerts → paper queue → tracking → reconcile → sleep). Trigger this skill when the client says "go work overnight," "run the loop," "while I'm away," when extending autonomy_cycle.py, when designing recovery / checkpoint behavior for the Mac mini launchd job, or when deciding how aggressively the fund operates without a human in the loop. Keywords: autonomy_cycle, 1-7 pipeline, paper queue, AUTONOMY_OPERATIONS, launchd, Mac mini, checkpoint, source_health, no_auth_execute. EXPLICIT: this skill never recommends bypassing no_auth_execute=1 or live_trading_enabled=0. Autonomy applies to research/scoring/queueing, never to executing trades.
---

# manus-autonomy (AI Fund anchor)

## What this is
A *behavioral pattern* skill that maps the "long-horizon autonomous operation" style onto AI Fund's existing infrastructure. The fund already runs autonomously — `tools/autonomy_cycle.py --loop` executes the 1-7 pipeline documented in `AUTONOMY_OPERATIONS.md`, persists state across runs, and the Mac mini deployment target schedules it via launchd. This skill formalizes how Claude (and any other agent driving the loop) should behave: decompose, fan-out, checkpoint, resume, never escalate trivially. There is no manus.ai integration. The name is a reference to the operating *style*, not a product.

## When to trigger in AI Fund
- Client says "go work overnight," "run the loop until morning," "while I sleep."
- Extending `tools/autonomy_cycle.py` (new sources, new scoring components, new alert channels).
- Designing the **Mac mini launchd job** for 24/7 paper-advisor mode (Phase 6+ deployment).
- Deciding behavior on failure inside the autonomy loop: which failures retry, which mark a `source_health` degradation, which surface as a human-attention item in the next session's MEMORY.md.
- Building a longer multi-hour task that spans multiple agents (e.g. monthly thesis screener → committee reviews → trade card drafts queued for client review).

## Setup in AI Fund
No install. The infrastructure already exists. The pieces:

```bash
# The loop driver (already in tools/):
/Users/kdawg/ai-fund/.venv/bin/python /Users/kdawg/ai-fund/tools/autonomy_cycle.py --loop

# State persistence (already in data/ and reports/):
ls /Users/kdawg/ai-fund/data/agent_runs.csv /Users/kdawg/ai-fund/data/paper_trades.csv
ls /Users/kdawg/ai-fund/reports/autonomous_daily_brief_*.md

# Risk gates (must remain on):
grep -E "no_auth_execute|live_trading_enabled" /Users/kdawg/ai-fund/data/risk_limits.csv
```

For Phase 6+ Mac mini deployment, a launchd plist at `~/Library/LaunchAgents/com.aifund.autonomy.plist` runs the loop hourly. **The plist must not pass any flag that flips a risk-gate value.**

## Usage patterns (AI-Fund-specific)

1. **The 1-7 pipeline IS the four-phase pattern.** Map the abstract "decompose → fan-out → checkpoint → resume" to AUTONOMY_OPERATIONS.md:
   - Discover signals (step 1) = decompose by source adapter.
   - Build candidates (step 2) = aggregate.
   - Committee scoring (step 3) = fan-out across 5 agents via `tools/agent_runner.py`.
   - Ranking (step 4) = Claude synthesizes.
   - Alerts (step 5) = checkpoint to `reports/autonomous_daily_brief_*.md`.
   - Paper queue (step 6) = `tools/paper_broker.py` (only ever paper, gated by `pre_trade_check.py`).
   - Tracking + reconcile (step 7) = `tools/performance_tracker.py` updates, then sleep.

2. **Checkpointing is already file-based.** Every loop iteration writes:
   - `reports/autonomous_daily_brief_YYYY-MM-DD.md`
   - `data/agent_runs.csv` (every model invocation)
   - `data/paper_trades.csv` (any paper queue addition)
   - Updates to `WATCHLIST.md`, `TRADE_LOG.md`, optionally `MEMORY.md`
   On wake (next session), read MEMORY.md *first*, then resume from the last `STATUS=Pending` item in TRADE_LOG.md.

3. **Fan-out happens inside `agent_runner.py`.** When refining the loop, the fan-out unit is "all 5 agents on the same candidate," not "many candidates in parallel" — the autonomy_cycle deliberately processes candidates sequentially to keep cost predictable. Don't change that without a budget conversation.

4. **Failure protocol.** A source adapter failing (e.g. EDGAR 429) does NOT halt the loop. It writes a `source_health` row marking the source degraded, the brief shows it, and Claude weights the remaining sources higher for that cycle. Loop continues.

5. **Recovery on wake.** If launchd missed runs (Mac mini was offline, network dropped), the next start reads the last brief's timestamp and decides: catch up by running one full cycle and explicitly noting the gap in MEMORY.md. Don't try to back-fill N missed cycles — the data is stale, surface the gap honestly.

## Integration with the 5-agent system
The 5 agents fan out per candidate inside step 3. Weighted votes per play type live in `data/agent_weights.csv`. Claude is always the final synthesizer and risk-gate runner. No agent except Claude is allowed to mark a candidate as `STATUS=Recommended`. DeepSeek/Gemma (local Ollama) are the cheap overflow voters; if Anthropic or OpenAI API is rate-limited, the loop falls back to local models with a logged degradation rather than skipping the vote.

## Risk gate / compliance — THE PINNED RULES
This skill never recommends:
- Flipping `no_auth_execute=1` → 0.
- Flipping `live_trading_enabled=0` → 1.
- Selling **VUN** or **XEQT** under any circumstance.
- Closing or rolling the **TQQQ May 15 2026 $78 call** absent explicit client instruction.
- Claiming a trade was executed without client confirmation.
- Auto-publishing to X.com or anywhere external without client sign-off.

"Autonomous" in AI Fund means the loop *researches, scores, and queues for review*. The client decides. Always. Even if the loop runs unattended for a week, Phase 0 is paper-advisor mode — the only execution path is the client tapping Buy in Wealthsimple after reading a trade card.

## Gotchas
- **Don't loop without a retry cap.** Source adapters get one retry, then degrade. Agent API calls get one retry, then fall back to local Ollama, then degrade.
- **Cost budget.** Hourly cycles × 5 agents × paid APIs adds up. The DeepSeek/Gemma overflow path exists for a reason. Watch `data/agent_runs.csv` cost columns.
- **Mac mini sleep / network drops.** launchd will not wake the mini. Configure caffeinate or set "wake for network access" in System Settings.
- **State drift between sessions.** The client may execute a trade in Wealthsimple between cycles. Reconciliation at session start (asking "any trades since last session?") is part of the protocol, not optional.
- **Don't fan out where the work is inherently sequential.** Step 3 → step 4 → step 5 must run in order. Parallelism is within step 3, never across steps.
- **"Autonomous" is for means, not destructive ends.** The skill is not cover for skipping the risk gate, posting publicly, or executing on the client's behalf.

## Reference
- Upstream framing only: https://manus.im (referenced for "action engine" language — no integration exists)
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/AUTONOMY_OPERATIONS.md` (the 1-7 pipeline canonical doc)
  - `/Users/kdawg/ai-fund/AUTONOMY_ROADMAP.md` (phase plan)
  - `/Users/kdawg/ai-fund/tools/autonomy_cycle.py`
  - `/Users/kdawg/ai-fund/tools/agent_runner.py`
  - `/Users/kdawg/ai-fund/tools/pre_trade_check.py`
  - `/Users/kdawg/ai-fund/tools/paper_broker.py`
  - `/Users/kdawg/ai-fund/data/risk_limits.csv`
  - `/Users/kdawg/ai-fund/MEMORY.md`, `/Users/kdawg/ai-fund/TRADE_LOG.md`
