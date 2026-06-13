---
name: superpowers-orchestrator
description: "Intelligently orchestrates all available skills to solve your task. This is your execution engine — it reads all skill descriptions, picks however many skills you actually need (no artificial limits), executes them in smart sequence with outputs feeding as context, handles conflicts and failures gracefully, and synthesizes everything into one unified result. Use whenever you want multiple specialized workflows working together toward a single goal. Trigger with: 'orchestrate my skills', 'use all superpowers', 'activate skills for [task]', 'use superpowers', 'full analysis', or any request where you sense multiple skill domains are relevant. This is your meta-skill that makes all other skills work together seamlessly. Even if the user doesn't explicitly ask for orchestration, trigger this skill when the task clearly spans multiple domains (e.g., creating a report that needs data analysis + document formatting + design)."
compatibility: "Requires: file system access, available_skills context, ability to read SKILL.md files via view tool, MCP connectors (optional — used when available)"
---

# Superpowers Orchestrator

A practical execution engine that reads, selects, and coordinates all available skills to solve your task — without artificial limits or fake scoring.

---

## How It Works

### Phase 1: Skill Discovery (Lightweight Scan)

When invoked:

1. **Scan all skills** in the `available_skills` list injected into context
2. **Extract metadata only**: name, description, file path — do NOT read full SKILL.md files yet
3. **Build a quick-ref index** for this session:

```
Skill Name → Description (first 2 sentences) → Path → Estimated Complexity (light/medium/heavy)
```

Complexity estimate is based on description length and number of bundled resources mentioned. This is a rough heuristic, not a precise measurement.

**Caching**: If the orchestrator has already been invoked this session, reuse the cached index instead of re-scanning. Only refresh if the user mentions new skills or asks to rescan.

### Phase 1b: Connector Discovery (MCP + Tools)

Run immediately after skill discovery — lightweight, no tool calls required.

1. **Scan available MCP connectors** from the session context. Current connectors may include:
   - **Ahrefs** — SEO data, backlinks, keyword research, site metrics
   - **Gmail** — Read/search/draft emails
   - **Google Calendar** — Events, scheduling, availability
   - **Google Drive** — File search, read, create
   - **Notion** — Pages, databases, search
   - **Wix** — Site building, CMS, REST API
   - **QuickBooks** — Financial data, P&L, cash flow, benchmarking
   - **Base44** — App building, entity schemas, data records
   - **Kiwi.com** — Flight search
   - **Desktop Commander** — Local file system, terminal, processes
   - **Claude in Chrome / Control Chrome** — Browser automation
   - **Spotify, iMessages, Google Calendar** — Personal data/actions

2. **Index by capability type**:
```
Connector Name → What it fetches/does → When to route tasks here
```

3. **Identify data-fetch tasks** in the user's prompt that require live data from a connector:
   - "Pull my emails" → Gmail
   - "Check my calendar" → Google Calendar
   - "Get my Q1 financials" → QuickBooks
   - "Search for flights" → Kiwi.com
   - "Find files in my Drive" → Google Drive
   - "SEO analysis for my site" → Ahrefs
   - "Update my Notion page" → Notion

4. **Connector tasks run BEFORE skill tasks** — fetch the data first, then pass it into the skill workflow as input context.

**Connector availability is dynamic**: Only connectors actually present in the session are used. If a connector isn't available, note it and proceed without it.

**Caching**: Connector index is cached alongside skill index for the session.

### Phase 2: Intelligent Selection

For your task:

1. **Parse prompt intent** — what problem are you actually solving? What deliverables are expected? Does it require live data from a connector?
2. **Match against skill metadata** — which skills' descriptions align with that intent?
3. **Match against connector index** — does any part of the task require fetching live data, executing external actions, or reading from a connected service?
4. **Pick however many you need** — skills + connectors combined. No artificial caps. The only constraint is: does this skill or connector genuinely help solve the task?
5. **Rank by execution order** — connectors typically run first (data fetch), then skills (processing + output)
6. **Offer progressive depth** — before executing, tell the user:
   - "I'm going to use Connector X to fetch data, then run Skills A, B, C to process and present it."
   - "I also see Connector Y and Skill D as potentially useful for additional depth. Want me to include them?"
   - User controls depth before tokens are spent.

**Selection is honest**: No percentages, no fake relevance scores. Just: "This skill does X, your task needs X, so I'm including it." If a skill doesn't help, say why it was skipped.

### Phase 3: Dependency Detection (Before Execution)

Before running anything, build a dependency map:

- **Does Skill B need Skill A's output?** → Run A first, feed output forward
- **Are two skills independent?** → Order doesn't matter, run in whatever sequence is logical
- **Circular dependency (A → B → A)?** → Halt immediately, flag it, ask user how to resolve
- **Skill A solves the entire problem?** → Ask: "Skill A covers this fully. Still want me to run B, C for additional perspectives?"

Output a brief execution plan before starting:

```
[EXECUTION PLAN]
0. Connector X (data fetch — provides raw input for skills)
1. Skill A (primary — processes connector data, solves core task)
2. Skill B (uses Skill A output for validation)
3. Skill C (independent — adds complementary perspective)
Skipped: Skill D (description doesn't match task intent)
Skipped: Connector Y (not needed — task doesn't require live data from it)
```

### Phase 4: Execution (Real Work)

**Step 0 — Connector execution (if applicable):**
- Call the relevant MCP connector tools to fetch live data
- Store fetched data tagged with connector name and timestamp
- Pass fetched data as input context into the first relevant skill
- If connector call fails: log error, ask user if they want to proceed without live data or retry

**Step 1+ — Skill execution (for each selected skill, in planned order):**

1. **Read the full SKILL.md** using the `view` tool (only now, not during discovery)
2. **Follow its instructions**: Execute the skill's workflow, run bundled scripts if applicable, produce output
3. **Capture output**: Store result tagged with skill name and timestamp
4. **Check for errors**: If skill fails → log error → continue with next skill (do NOT halt entire chain)
5. **Evaluate forward relevance**: Does the next skill in the chain actually need this output?
   - **YES** → Pass output as context to next skill
   - **NO** → Don't pass it forward; next skill runs clean
   - **PARTIAL** → Extract only the relevant portion and pass that

**Token awareness during execution**:
- Before reading each SKILL.md, estimate remaining token budget
- If budget is at ~80%, pause and ask: "I've used most of our token budget. Want me to synthesize what I have, or continue?"
- Never silently burn through the budget

### Phase 5: Conflict Detection & Resolution

Conflicts are detected as skills execute, not after.

**Type 1: Direct Contradictions** (mutually exclusive recommendations)
- Skill A says "do X", Skill B says "don't do X"
- **Action**: Flag immediately with both recommendations side-by-side
- **Default hierarchy** (if user doesn't choose): Legal/Compliance > Security > Operations > Design/UX
- Higher-priority domain wins by default, but user can always override
- Example:
  ```
  [CONFLICT — DIRECT]
  Skill A recommends: "Position size 2% of portfolio"
  Skill B recommends: "Position size 5% of portfolio"
  Default resolution: Skill A wins (risk management > trading strategy)
  Your call: Override? Or accept default?
  ```

**Type 2: Overlapping Domains** (same area, different approaches)
- Skill A and Skill B both address visual design but with different philosophies
- **Action**: Use higher-relevance skill as primary, note the alternative approach
- Example:
  ```
  [OVERLAP — COMPLEMENTARY]
  Skill A (primary): Modern flat design approach
  Skill B (alternative): Corporate traditional approach
  Using Skill A as primary. Skill B's approach noted as alternative.
  ```

**Type 3: Output Format Mismatches**
- Skill A produces JSON, Skill B expects markdown
- **Action**: Auto-convert if straightforward (with a note). Flag if incompatible and ask user.

### Phase 6: Synthesis (Unified Output)

Once all selected skills complete:

1. **Integrate outputs intelligently** — don't just concatenate. Chain complementary results, merge overlapping content, flag unresolved conflicts.
2. **Decision tree** — show what happened:
   - Which skills ran and why
   - Execution order and what fed into what
   - Any conflicts and how they were resolved
   - Any failures and their impact
   - Token cost per skill (if trackable)
3. **Offer next steps**:
   - "Want me to run additional skills for more depth?"
   - "I flagged this conflict — your call on resolution."
   - "Skill D failed — want me to retry or skip?"

---

## Decision Tree Format (Adaptive Verbosity)

The decision tree adapts to complexity. Don't over-report on simple tasks.

**Simple (1-3 skills, no conflicts)**:
```
[ORCHESTRATION SUMMARY]
├─ Connector X → CALLED (task needs live data from X)
│   └─ Fetched: [brief data summary]
├─ Skill A → EXECUTED (processes connector data, your task needs X)
│   └─ Output: [brief result summary]
├─ Skill B → EXECUTED (complements A with Y)
│   └─ Output: [brief result summary]
└─ Skill C → SKIPPED (not relevant — description covers Z, task doesn't need Z)

[UNIFIED RESULT]
[Integrated output from Connector X → Skill A → Skill B]
```

**Complex (4+ skills/connectors, conflicts, failures)**:
```
[ORCHESTRATION DECISION TREE]
├─ Connector X → CALLED (data fetch — feeds Skill A + B)
│   └─ Fetched: [data summary]
├─ Connector Y → SKIPPED (not needed — task doesn't require Y data)
├─ Skill A → EXECUTED (primary — processes connector data)
│   └─ Output: [result]
├─ Skill B → EXECUTED (uses Skill A output)
│   └─ Output: [result]
├─ Skill C → CONFLICT with Skill B
│   ├─ Resolution: Skill B takes precedence (higher-priority domain)
│   └─ Alternative noted for your awareness
├─ Skill D → FAILED (error: [reason])
│   └─ Impact: Low — Skill A already covers this angle
├─ Skill E → EXECUTED (independent, adds complementary perspective)
│   └─ Output: [result]

[CONFLICTS]
1 conflict detected: Skill C vs Skill B (resolved — Skill B wins)

[FAILURES]
1 failure: Skill D (non-critical, logged)

[UNIFIED RESULT]
[Integrated output from Connector X → Skill A + B + E, conflict resolution noted]

[NEXT STEPS]
- Want me to retry Skill D?
- Want me to also call Connector Y for additional data depth?
```

**Verbosity rules**:
- 1-3 skills, no issues → Concise summary
- 4+ skills, or any conflicts/failures → Full decision tree
- User can request: "concise" or "detailed" to override

---

## Error Handling

### Connector Fails
- Log the error with connector name and reason
- Ask: "Connector X failed to fetch data. Want me to retry, proceed without it, or manually provide the data?"
- Do NOT proceed silently without the data if the entire task depends on it

### Skill Fails Mid-Chain
- Log the error with skill name and reason
- Continue with next skill — do NOT halt the entire orchestration
- At synthesis, report: "Skill X failed because Y. Impact: [low/medium/high]. Want me to retry?"

### Circular Dependency Detected
- Halt before execution begins
- Show the cycle: "Skill A needs Skill B's output, but Skill B needs Skill A's output"
- Ask: "Which should I run standalone first?"

### No Skills Match Intent
- Show what was considered and why each was rejected
- Ask: "Can you rephrase your task, or would you like to manually pick skills?"
- Offer the full skill list for manual selection

### Token Budget Running Low
- Pause before next skill execution
- Show: "Used ~X% of token budget. Remaining skills: Y, Z. Continue or synthesize now?"
- If user continues, proceed carefully. If user bails, synthesize what we have.

### Skill Output is Useless
- If a skill produces output that doesn't move toward the goal, note it
- Don't feed useless output forward to the next skill
- Report in decision tree: "Skill X ran but output wasn't relevant to task. Skipped in synthesis."

---

## Caching & Efficiency

### Session-Level Caching
- **Skill metadata index**: Built once on first orchestration, reused for the session
- **Connector index**: Built alongside skill index, reused for the session
- **Connector data**: Fetched data tagged with connector name + timestamp for lineage tracking
- **Skill outputs**: Tagged with skill name + timestamp
- **Dependency patterns**: Reuse learned chains on repeat similar tasks

### Token Conservation
- Phase 1 (discovery) is cheap — metadata only
- Phase 4 (execution) is expensive — only read full SKILL.md when that skill is about to execute
- Progressive depth — user approves before each expansion
- Forward only relevant output — don't blindly pass everything

---

## Assumptions

1. You want comprehensive solutions, not partial ones
2. Progressive loading (you control depth) is better than burning tokens upfront
3. Conflicts are flagged transparently — we don't hide them or silently resolve them
4. Real execution of skill workflows + connector calls is the goal, not theoretical orchestration
5. No artificial caps on skill or connector count — use as many as the task genuinely requires
6. Honest reasoning over fake precision — "this skill helps because X" not "relevance score: 87.3%"
7. Connectors provide raw data; skills process and present it — they work together, not independently

---

## What This Skill Does NOT Do

- **No fake math**: No TF-IDF, no cosine similarity, no embedding comparisons. Claude doesn't run those at inference time. Selection is based on honest intent-matching against skill descriptions.
- **No hardcoded skill lists**: Scans whatever skills are available at invocation time. New skills are automatically included.
- **No artificial tiers**: No Tier 1/2/3 gating. A skill either helps or it doesn't.
- **No blind execution**: Never runs all skills just because they exist. Picks what's needed, offers depth, you control.
