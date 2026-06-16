# agent-bridge — Playbooks

Concrete recipes. All use the `bridge` command (see ../SKILL.md).

## 1. Continue a Codex session the user already had
The user gives a session ID and says "keep going / continue this."
```
bridge read <id> 20            # understand the context first
bridge resume <id> "<next message, continuing the thread>"
```
Send follow-ups one at a time with more `bridge resume <id> "…"`. The session keeps full memory.

## 2. Second opinion / cross-check a decision
```
bridge codex "Reasoning only. <decision + options>. One-line verdict + one-line why."
bridge gemini "Same question, independently: <decision>. Verdict + why."
```
If they agree → high confidence. If they differ → surface the disagreement to Kevin; that's signal.

## 3. Council fan-out for a hard call
Ask 2–3 agents in parallel, then synthesize:
```
bridge codex "<hard question>"
bridge cloud kimi-k2.6:cloud "<same question>"
bridge gemini "<same question>"
```
Pick the strongest answer; graft the best ideas from the others. Record the decision + evidence.

## 4. Delegate a real build task (owner → reviewer)
```
bridge codex "OBJECTIVE: fix X in src/foo.ts per spec.
ALLOWED: src/foo.ts, tests/foo.test.ts   FORBIDDEN: other paths, network, push.
EXPECTED: failing test -> fix -> green; show the diff + test output."
```
Then **review it yourself or with another agent** before it merges. Author ≠ sole approver.

## 5. Cross-machine: hand work to the always-on Mini
```
bridge mini "OBJECTIVE: <task that should run on the Mac Mini>. <delegation packet>"
bridge mini:sh "cd ~/dev/Linda && pnpm test 2>&1 | tail -20"   # run/inspect on the Mini
```

## 6. Conserve Anthropic quota — route bulk to flat-rate cloud
For large, mechanical, or long-context work, prefer the Ollama Pro pool:
```
bridge cloud kimi-k2.6:cloud "<bulk task: summarize these 40 files / draft these tests / …>"
```
Keep Claude (you) as the orchestrator + reviewer; let the cheap models do the volume.

## 7. Verify, don't trust ("self-reported success lies")
After any agent claims it finished, confirm the real artifact:
```
bridge mini:sh "cd ~/dev/Linda && git diff --stat && pnpm test 2>&1 | tail -5"
```
A green claim with no passing test is not done. This rule killed the original Linda twice.

## Notes
- `bridge codex`/`mini` each cost roughly one Codex turn (~15k tokens of *Codex's* quota, not yours).
- `bridge list` / `bridge read` are free (local file reads).
- If `bridge read` can't find a session, it may be on the Mini (`bridge mini:list`) or archived.
