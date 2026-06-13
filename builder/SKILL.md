---
name: builder
description: >
  Use when building tools, integrations, and skills: MCP servers (connecting LLMs to external APIs),
  web artifacts (interactive HTML/JS tools, dashboards, visualizations), or new Claude skills
  (creating/editing SKILL.md files with evals). Triggers when: "build an MCP", "create an MCP server",
  "integrate [service] with Claude", "build a web tool", "create a dashboard", "make an artifact",
  "create a new skill", "write a skill for", "package this skill", or any request to build
  something that extends Claude's capabilities.
---

# Builder

Three modes for extending Claude's capabilities: MCP servers, web artifacts, and skills.

## Mode Selection

```
Connecting Claude to an external API/service?    → MCP mode
Creating an interactive web tool or dashboard?   → WEB ARTIFACT mode
Creating or improving a SKILL.md + evals?        → SKILL CREATOR mode
```

---

## MCP MODE
*Build MCP (Model Context Protocol) servers — connect LLMs to external services*

**Quality bar:** Measured by how well it enables LLMs to accomplish real-world tasks.

### Phase 1: Research & Plan

**Recommended stack:**
- Language: TypeScript (best SDK support, most AI-friendly)
- Remote servers: Streamable HTTP, stateless JSON
- Local servers: stdio

**Study the API:** Review service documentation, authentication requirements, data models.

**Tool design principles:**
- Comprehensive API coverage over workflow-specific tools (when uncertain)
- Consistent naming: `{service}_{action}_{resource}` (e.g., `github_create_issue`)
- Concise descriptions that help agents find the right tool quickly
- Actionable error messages that guide toward solutions

**Load docs as needed:**
- MCP spec: start at `https://modelcontextprotocol.io/sitemap.xml`
- TypeScript SDK: `https://raw.githubusercontent.com/modelcontextprotocol/typescript-sdk/main/README.md`
- Python SDK: `https://raw.githubusercontent.com/modelcontextprotocol/python-sdk/main/README.md`
- Local guides: `./reference/node_mcp_server.md`, `./reference/python_mcp_server.md`, `./reference/mcp_best_practices.md`

### Phase 2: Implementation

**Per tool:**
- Input schema with Zod (TS) or Pydantic (Python), with constraints and clear descriptions
- Output schema with `outputSchema` + `structuredContent` where possible
- Async/await for I/O, proper error handling, pagination support
- Annotations: `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint`

**Shared infrastructure first:** API client with auth, error helpers, response formatting, pagination.

### Phase 3: Test

```bash
# TypeScript
npm run build
npx @modelcontextprotocol/inspector

# Python
python -m py_compile server.py
npx @modelcontextprotocol/inspector
```

Code quality: no duplicated code, consistent error handling, full type coverage, clear descriptions.

### Phase 4: Evaluations

Create 10 evaluation questions that test realistic, complex use cases requiring multiple tool calls.
Each question must be: independent, read-only, complex, realistic, verifiable, stable.

Save as XML:
```xml
<evaluation>
  <qa_pair>
    <question>Find discussions about... what number X was determined?</question>
    <answer>3</answer>
  </qa_pair>
</evaluation>
```

Load `./reference/evaluation.md` for complete evaluation guide.

---

## WEB ARTIFACT MODE
*Build interactive HTML/JS tools, dashboards, data visualizations*

**Use when:** User needs something they can interact with in their browser — a tool, dashboard, calculator, visualizer, or interactive demo.

### Process

**1. Clarify requirements:**
- What data does it display or manipulate?
- Does it need to connect to live data or work with static/pasted data?
- What interactions does it need? (filters, charts, forms, etc.)
- Target environment: embedded in Claude artifacts, standalone HTML file, or web app?

**2. Choose tech stack:**
- Simple interactive tool → vanilla HTML/CSS/JS (no dependencies, works everywhere)
- Data visualization → add Chart.js or D3 via CDN
- Complex UI → add Alpine.js or Vue via CDN
- Avoid build tooling unless the user explicitly wants a full project

**3. Build it:**
- Single self-contained HTML file unless building a full project
- All CSS and JS inline or via CDN (no local file dependencies)
- Mobile-responsive by default
- Dark/light mode if appropriate

**4. Quality check:**
- Works without any server (can open directly in browser)
- No console errors on load
- Handles empty/invalid data gracefully
- Accessible: proper labels, keyboard navigation

**5. Deliver:**
- Save as `.html` file
- Tell user exactly how to open/use it
- If data-driven: show how to load their data

---

## SKILL CREATOR MODE
*Create new skills with the full eval/iterate/package loop*

**This mode governs the operational loop.** For the content rules of what a skill should look like, see the writing skill (SKILL CONTENT mode).

### The Loop
1. **Understand intent** — what should the skill enable? When should it trigger? Expected output?
2. **Research** — check existing similar skills, study patterns, understand edge cases
3. **Draft SKILL.md** — name, description (trigger conditions), body following writing skill's structure
4. **Write 2-3 test prompts** — realistic, the kind a real user would type
5. **Run test prompts** — on Claude.ai: simulate yourself; in Claude Code: dispatch subagents
6. **Evaluate results** — qualitative first (does it do the right thing?), then quantitative assertions
7. **Iterate** — improve based on what failed, generalize from feedback
8. **Optimize description** — use `run_loop.py` for trigger accuracy (Claude Code only)
9. **Package** — `python -m scripts.package_skill <skill-path>`

### On Claude.ai (no subagents)
- Simulate test runs yourself: read the skill, then complete the test prompt following it
- Skip baseline runs and quantitative benchmarking
- Focus on qualitative: does the skill produce the right output?
- Still organize results into iteration directories

### Updating an Existing Skill
1. Note the exact skill name and directory name — preserve them unchanged
2. Copy to writable location (`/tmp/skill-name/`) before editing (installed path may be read-only)
3. Edit the copy
4. Package from the copy: `python -m scripts.package_skill /tmp/skill-name/`
5. Output `.skill` file with the original name (not `skill-name-v2`)

### Good Description = Good Triggering
```yaml
# BAD: summarizes what it does
description: A skill for debugging code problems

# GOOD: specific triggering conditions
description: Use when tests are failing, something is broken, or you see error messages —
  guides systematic debugging. Triggers on: "debug this", "broken", "failing tests",
  "race condition", "flaky", "hanging"
```

**Descriptions should be slightly "pushy"** — mention that the skill should be used even when not explicitly requested, to prevent undertriggering.

### Scripts
- Package: `python -m scripts.package_skill <path>`
- Eval loop: `python -m scripts.run_loop --eval-set <path> --skill-path <path> --model <id> --max-iterations 5`
- Benchmark viewer: `python eval-viewer/generate_review.py <workspace> --skill-name <name> --benchmark <benchmark.json>`

Skill creator base: `/Users/iam/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/e2dba3b4-66af-4351-94f7-33200f61d0ea/9e7012ef-c36e-4f02-abba-cc84ed11ef00/skills/skill-creator`
