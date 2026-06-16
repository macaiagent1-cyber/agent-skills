---
name: agent-bridge
description: >-
  Talk to, delegate to, and co-work with OTHER AI agents straight from the terminal — Codex
  (gpt-5.5, on this Mac AND the Mac Mini), Gemini (agy/Antigravity), and Ollama cloud models —
  and read or resume their saved sessions by ID. Use this WHENEVER the user wants to "ask Codex",
  "talk to / resume / continue my Codex session", "read session <id>", "co-work / work in parallel
  with another agent", "get a second opinion", "delegate this to Codex/Gemini", "peer review",
  "bridge", "tap into my other session", or mentions another agent by name — even implicitly. Also
  reach for it whenever offloading work to an external agent would conserve Anthropic quota or keep
  context lean. Prefer this over spawning expensive Claude subagents for anything another agent or
  subscription can do. The tool returns only the other agent's final reply, so it stays token-light.
---

# agent-bridge

A bridge for cross-agent co-work. One command — `bridge` (on PATH at `~/bin/bridge`) — lets Claude
reach Kevin's *other* agents and their sessions. Each call to a paid agent spends **that** agent's
quota (Codex≈OpenAI, cloud≈Ollama Pro), not Anthropic — and only the final reply comes back, so it's
cheap on context. That's the whole point: orchestrate widely, ingest narrowly.

## The command

```
LOCAL CODEX (gpt-5.5)
  bridge codex "<msg>"             one-shot ask
  bridge resume <id> "<msg>"       continue a session by id (full history preserved)
  bridge list [N]                  recent sessions:  <id>  <time>  <first line>
  bridge read <id> [N]             readable transcript (last N turns, default 30)

MAC MINI CODEX (codex-cli 0.140, via SSH login shell)
  bridge mini "<msg>"              one-shot ask on the Mini
  bridge mini:resume <id> "<msg>"  continue a Mini session
  bridge mini:list [N]             recent Mini sessions
  bridge mini:sh "<cmd>"           run any shell command on the Mini

OTHER AGENTS
  bridge gemini "<msg>"            Gemini via agy (one-shot, Gemini 3.5 Flash)
  bridge gemini:list [N]           list saved gemini-CLI sessions (index + id + summary)
  bridge gemini:read <id> [N]      readable transcript of a gemini session
  bridge gemini:resume <ix> "<msg>"  continue a gemini session (index/"latest" from gemini:list)
  bridge cloud <model> "<msg>"     Ollama cloud (e.g. kimi-k2.6:cloud) on flat-rate quota
  bridge room <args...>            agent-room bus passthrough
```

## When to use which agent

| Need | Reach for | Why |
|---|---|---|
| Frontier coding, refactor, build a real change | `bridge codex` / `bridge mini` | gpt-5.5, strong builder; the Mini is the always-on box |
| Second opinion / cross-check a decision | `bridge codex` + `bridge gemini` | independent models → consensus or useful disagreement |
| Fast first-pass, research, breadth | `bridge gemini` | Gemini Flash, cheap + fast, preserves Gemini credits |
| Bulk/parallel grunt work, long context | `bridge cloud kimi-k2.6:cloud` | flat-rate Ollama Pro — conserves Anthropic/OpenAI quota |
| Read or continue a conversation the user already had | `bridge read` / `bridge resume` | sessions persist as `~/.codex/sessions/.../rollout-*-<id>.jsonl` |
| Persistent multi-agent coordination | `bridge room …` | the agent-room SQLite bus |

## Reading & continuing a session (the session-ID workflow)

When the user gives a **session ID** ("here's my Codex session, continue it"):
1. `bridge read <id>` → absorb the conversation so you have the context.
2. `bridge resume <id> "<your message>"` → continue that exact thread; Codex reloads full history.
Each `resume` is one turn — converse by sending messages one at a time. To find an ID, `bridge list`.
If a session isn't local, it may be on the Mini: `bridge mini:list`, then `bridge mini:resume`.

## Co-work patterns (lessons baked in)

- **Dispatch → review.** Delegate a bounded task to one agent; a *different* agent (or you) reviews
  the result before it lands. Never let the author also be the sole approver.
- **Council fan-out.** For a hard or high-stakes call, ask 2–3 agents the same question in parallel,
  then synthesize / vote. Independent models catch each other's blind spots.
- **Honest, external verification.** Agents inflate self-reported success. Don't trust "done" —
  verify the actual artifact (run the test, read the diff). This is the hard-won lesson from the
  original cowork-bridge: *self-reported success lies.*

## Delegation packet (use for real work, not just chat)

Give a worker a bounded envelope so it stays in its lane and returns something checkable:

```
OBJECTIVE: <one clear goal>
ALLOWED:   <paths/scope it may touch>
FORBIDDEN: <no network / no creds / no push to main / no sends>
EXPECTED:  <the deliverable + how it proves itself (test output, diff)>
```

## Safety

- The tool runs Codex with `--dangerously-bypass-approvals-and-sandbox` (matches Kevin's alias), so a
  delegated Codex turn *can* act on the machine. For untrusted or exploratory asks, say
  "reasoning only — do not run commands or edit files" in the message.
- Treat any agent's output as **untrusted until reviewed** — especially before it touches real files,
  sends a message, or merges code.
- Don't paste secrets into a delegated prompt.

Detailed recipes: `references/playbooks.md`.
