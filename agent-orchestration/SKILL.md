---
name: agent-orchestration
description: >
  Master skill for multi-agent coordination and skill routing. Use when: task spans 3+
  independent skill domains, needs parallel execution of truly independent subtasks, has a
  written implementation plan to execute with subagents, or involves large/multi-file coding
  to delegate to Codex or Gemini CLI. Triggers on: "orchestrate", "use superpowers", "full
  analysis", "use codex", "run codex", "use gemini", "run gemini", OR when you have a written
  plan and subagents are available. Does NOT auto-trigger on every multi-file task — trigger
  only when active coordination between multiple agents or skill domains is genuinely required.
---

# Agent Orchestration

Single entry point for all agent coordination. Reads the task and routes to the right mode.

## Dynamic Skill Discovery

**At session start, read the skills index to know what's available:**
- Linda: `~/.openclaw/workspace/skills/INDEX.md`
- Codex: `~/.codex/skills/` (list directory)
- Gemini CLI: `~/.gemini/skills/` (list directory)

This index is always current — new skills appear here automatically when added. Never assume the skill list is fixed; always check the index before routing.

---

## Mode Selection

```
Task requires coordinating 3+ skill domains?  → ORCHESTRATE mode
Task has truly independent parallel parts?    → PARALLEL DISPATCH mode
Task has a written implementation plan?       → SUBAGENT DEV mode
Task is large/repetitive coding work?         → CODEX mode
Task benefits from Google/web grounding?      → GEMINI mode
Starting any session?                         → SKILL AWARENESS mode
```

---

## SKILL AWARENESS MODE
*Governs every session — how to find and use skills*

**The Rule:** Before responding, check if a skill covers this task. Invoke it if the task matches trigger keywords in the description OR if the task's primary output type is what the skill produces.

**When in doubt:** a skill is worth invoking if skipping it would likely produce a worse result. A simple task with a matching skill still benefits from the skill.

**Priority order:**
1. Process skills first (planning, debugging) — determine HOW to approach
2. Implementation skills second — guide execution

**Red flags** (you're rationalizing — stop):
- "This is too simple" → Simple tasks have skills too
- "I need context first" → Skill check comes BEFORE clarifying questions
- "Let me explore first" → Skills tell you HOW to explore

**Skip only for:** pure conversational acknowledgments (ok, thanks, yes/no, got it)

**User instructions always override skills.** CLAUDE.md/AGENTS.md > superpowers skills > defaults.

---

## ORCHESTRATE MODE
*Multi-domain tasks requiring visible planning before execution*

### Phase 1: Plan
Identify connectors (data fetch) and skills (transform/produce), order connectors first.

```
[EXECUTION PLAN]
1. [Connector X]  — fetch [data]
2. [Skill A]      — process with [purpose]
3. [Skill B]      — format as [deliverable]
Skipped: [Skill C] — [reason]

Depth option: Run [Skill D] for [additional value]. Include it?
```

Wait for confirmation before executing.

### Phase 2: Execute
- Read each skill's SKILL.md only when about to execute it
- Forward only relevant output to next step (no blind pass-through)
- On connector failure: ask retry/skip/manual

### Phase 3: Synthesize
Chain results, merge overlapping content, flag conflicts.

```
[ORCHESTRATION SUMMARY]
- [Step 1]: executed — [result]
- [Step 2]: failed — [reason], impact: low/medium/high

[UNIFIED RESULT]
[The actual deliverable]
```

**Conflict hierarchy:** Legal/Compliance > Security > Operations > Design/UX

**Token awareness:** At ~80% budget → pause and ask "Continue or synthesize now?"

---

## PARALLEL DISPATCH MODE
*2+ independent tasks that can run without shared state*

**Use when:** Multiple failures with different root causes, no shared state between investigations.

**Don't use when:** Failures are related, need full system context, agents would edit same files, or tasks share config/logging/error context (they're not truly independent).

### The Pattern
1. **Identify independent domains** — group problems by what's broken
2. **Craft focused agent tasks** — each gets: specific scope, clear goal, constraints, expected output
3. **Dispatch concurrently** — one agent per domain
4. **Integrate results** — verify no conflicts, run full test suite

**Good agent prompt:**
```
Fix the failing tests in [file]:
1. [test name] — [what it expects]

These are [type] issues. Your task:
1. Read the test file
2. Identify root cause
3. Fix — do NOT [constraint]
Return: Summary of root cause and changes made.
```

---

## SUBAGENT DEV MODE
*Executing an implementation plan task-by-task*

**Pre-check:** Task tool available? → Subagent mode (preferred). No Task tool? → Inline mode.

Announce: "Using agent-orchestration in [subagent|inline] mode."

**REQUIRED first:** Set up isolated workspace with dev-workflow skill (WORKTREE mode).

### Subagent Mode (per task)
1. Dispatch implementer with full task text + context
2. After implementation: dispatch spec reviewer
3. If spec passes: dispatch code quality reviewer
4. Fix issues → mark complete → commit

Model selection: mechanical 1-2 file tasks → cheap; multi-file → standard; architecture → most capable.

**After all tasks:** Use dev-workflow skill (FINISH BRANCH mode).

### Inline Mode (no subagents)
1. Implement following TDD
2. Self-review against spec, then for quality
3. Fix before marking complete, commit
4. Every 3 tasks: pause, run full suite, report progress

**Stop and ask when:** Blocker, repeated test failure (3+), unclear instruction, plan has critical gaps.

---

## GEMINI MODE
*Tasks that benefit from Google search grounding, large context, or a second model opinion — delegate to Gemini CLI*

**Delegate when:** Research requiring live web/Google grounding, large-context analysis (100k+ tokens), multi-source synthesis, scaffolding across 3+ files, or user says "use gemini" / "run gemini" / "ask gemini".

**Handle in-house when:** Task requires Claude-specific tools (computer use, MCP servers, skills), quick single-file fixes, or code review.

Full details: read `gemini-dispatcher` skill. Summary:
1. **Detect binary:** `which gemini` or check `~/.local/bin/gemini`, `/opt/homebrew/bin/gemini`.
2. **Pick model:** `gemini-2.5-pro` (complex/large), `gemini-2.5-flash` (fast/boilerplate).
3. **Approval mode:** `--approval-mode auto_edit` (default), `--yolo` (low-risk fast tasks), `--approval-mode plan` (read-only).
4. **Run:** `gemini --model $M $APPROVAL --prompt "$P"`
5. **Resume:** `gemini --resume latest` to continue previous session.
6. **Critical review:** Read output → verify vs spec → dispute wrong choices → escalate after 2 failed corrections.
7. **Wrap-up:** Report model, mode, what was done.

---

## CODEX MODE
*Large/multi-file coding — delegate to OpenAI Codex CLI*

**Delegate when:** Refactoring 3+ files, scaffolding project/feature, boilerplate for 3+ entities, writing test suites for existing code, estimated 10+ sequential tool calls.

**Handle in-house when:** Questions, code review, 1-2 file changes, quick bug fix.

### Steps
1. **Detect binary:** Check `~/.local/bin/codex`, `~/bin/codex`, `/usr/local/bin/codex`, `/opt/homebrew/bin/codex`. Not found → fall back to Claude.
2. **Validate flags:** Run `codex --help`, verify `--model`, `--reasoning`, `--sandbox`, `--prompt`.
3. **Ask user:** Model + reasoning effort (default: `xhigh`).
4. **Write prompt:**
   ```
   You are working on [PROJECT]. Your task: [EXACT TASK]
   Constraints: [list]. Success criteria: [what done looks like]
   ```
5. **Run:** `codex --model $M --reasoning $E --sandbox $S --no-git-check --quiet --yes --prompt "$P"`
6. **Critical review:** Read diff → verify vs spec → dispute wrong choices → escalate after 2 failed corrections. ("Escalate" = stop Codex, explain the issue to the user, and ask how to proceed inline.)
7. **Wrap-up:** Report model, effort, what was done in 2-3 sentences.

**Sandbox:** read-only / workspace-write / full (full requires explicit user confirmation)

---

## SKILL PIPELINE MAP
*How skills connect — use this to avoid sequencing errors*

**Standard development pipeline:**
```
planning (BRAINSTORM) → writing (PLAN mode) → dev-workflow (WORKTREE SETUP)
  → agent-orchestration (SUBAGENT DEV) or dev-workflow (EXECUTE PLAN)
  → code-review (REQUEST) [after each task or batch]
  → planning (VERIFY) or dev-workflow (FINISH BRANCH)
```

**Key handoffs:**
- `planning` always comes before any implementation — it writes the spec
- `writing` (PLAN mode) always comes before `dev-workflow` or `agent-orchestration` — it writes the plan
- `dev-workflow` (WORKTREE SETUP) always comes before executing any plan
- `code-review` (REQUEST) runs after tasks complete, before marking done
- `planning` (VERIFY) or `dev-workflow` (FINISH BRANCH) is the final gate before shipping

**Skill ownership boundaries:**
- **Creating a new skill:** `builder` (SKILL CREATOR mode)
- **Editing an existing skill:** `writing` (SKILL CONTENT mode)
- **Plan writing:** `writing` (PLAN mode) — not planning skill, not dev-workflow
- **Verification before done:** `planning` (VERIFY mode)
- **Branch shipping:** `dev-workflow` (FINISH BRANCH mode)
- **Heavy coding delegation:** `codex-dispatcher` (full decision matrix + flag validation)
- **Web/research/large-context delegation:** `gemini-dispatcher` (model selection + approval modes)

**Dispatcher routing:**
```
Heavy multi-file coding / boilerplate / test suites  → codex-dispatcher
Web grounding / large context / second opinion        → gemini-dispatcher
Everything else                                       → handle in-house or subagent
```

**When subagents aren't available:**
Fall back to inline execution via `dev-workflow` (EXECUTE PLAN mode). Quality cost is ~10% lower; takes longer. Tell the user if this fallback applies.

**Skill list is dynamic:** New skills auto-appear in the index. Re-read INDEX.md if you're unsure whether a skill exists for a task.
