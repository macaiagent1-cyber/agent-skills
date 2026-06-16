---
name: writing
description: >
  Use for all writing tasks — technical docs, implementation plans, internal communications,
  and skill content. Triggers when: "write a doc", "draft a proposal", "create a spec",
  "write a plan", "status report", "write up", "internal comms", "newsletter", "3P update",
  "PRD", "RFC", "design doc", "write a skill", or any substantial writing task. Also use when
  writing or editing skill SKILL.md files — this skill governs skill content quality.
---

# Writing

All writing modes under one skill: docs, plans, internal comms, and skill content.

## Mode Selection

```
Writing a document, proposal, spec, or RFC?   → DOC mode
Writing an implementation plan for code?       → PLAN mode
Writing internal comms, status updates, FAQs?  → COMMS mode
Writing or editing a SKILL.md file?            → SKILL CONTENT mode
```

---

## DOC MODE
*Co-author documentation through structured 3-stage workflow*

**Offer the workflow upfront.** Explain the three stages. If user declines, work freeform.

### Stage 1: Context Gathering
Ask meta-questions first:
1. What type of doc? (spec, decision doc, proposal, RFC)
2. Who's the audience?
3. What's the desired impact?
4. Template or format to follow?

Then encourage an **info dump** — background, alternatives considered, team dynamics, timeline pressures, technical dependencies. Don't organize yet, just get it all out.

Follow up with 5–10 numbered clarifying questions. User can answer in shorthand.

If integrations are available (Drive, Slack, etc.) — use them to pull context directly.

### Stage 2: Refinement & Structure
Build section by section:
1. Ask 5–10 clarifying questions about the section
2. Brainstorm 5–20 options for what to include
3. User curates (keep/remove/combine)
4. Gap check — anything missing?
5. Draft the section
6. Iterate via surgical edits until user is satisfied

Start with the section that has the most unknowns (core proposal for decision docs, technical approach for specs).

Use `str_replace` for edits — never reprint the whole doc.

**After 3 iterations with no substantial changes:** ask if anything can be removed.

### Stage 3: Reader Testing
Test with a fresh Claude that has no context from this conversation.

**Predict reader questions** → test them with a sub-agent (or ask user to test manually in a new chat) → surface gaps → loop back to refinement for any sections that fail.

**Exit condition:** Reader Claude consistently answers questions correctly without new gaps.

---

## PLAN MODE
*Write comprehensive implementation plans for multi-step code tasks*

Announce: "I'm using the writing skill to create the implementation plan."

**Context:** Run in a dedicated worktree (set up by dev-workflow skill first).
**Save to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

### Before Writing
- If spec covers multiple independent subsystems → suggest breaking into sub-project plans
- Map out which files will be created/modified and their responsibilities first
- Design units with clear boundaries; files that change together should live together

### Plan Structure

**Required header:**
```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use agent-orchestration (SUBAGENT DEV mode).

**Goal:** [One sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]
---
```

**Each task:**
```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**
[actual test code here]

- [ ] **Step 2: Run test to verify it fails**
Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "[message]"

- [ ] **Step 3: Write minimal implementation**
[actual implementation code here]

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**
`git commit -m "feat: [description]"`
```

### Plan Quality Rules
**Never write:** "TBD", "TODO", "implement later", "add appropriate error handling", "similar to Task N", steps without actual code.

Every step must contain what an engineer needs. If a step changes code, show the code.

### Self-Review After Writing
1. Spec coverage — can you point to a task for every requirement?
2. Placeholder scan — any red flags from the rules above?
3. Type consistency — do function names/types match across tasks?

**Execution handoff:** After saving, offer subagent-driven (recommended) vs inline execution via agent-orchestration skill.

---

## COMMS MODE
*Internal communications — status reports, updates, newsletters, FAQs*

**Supported formats:**
- 3P updates (Progress, Plans, Problems)
- Company newsletters
- FAQ responses
- Status reports / leadership updates
- Project updates
- Incident reports

### How to Use
1. Identify the communication type from the request
2. Load the appropriate format from `examples/` directory:
   - `examples/3p-updates.md` — Progress/Plans/Problems
   - `examples/company-newsletter.md` — Company-wide newsletters
   - `examples/faq-answers.md` — FAQ answers
   - `examples/general-comms.md` — Anything else
3. Follow the instructions in that file for formatting, tone, content gathering

If no matching format → ask for clarification or desired format.

---

## SKILL CONTENT MODE
*Write or edit SKILL.md files with correct structure and effective triggers*

**Core principle:** Writing skills IS TDD applied to process documentation. Write test cases → watch baseline fail → write skill → watch tests pass → close loopholes.

### SKILL.md Structure
```yaml
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions — NOT what the skill does]
---
```

Then: Overview → When to Use → Core Pattern → Quick Reference → Common Mistakes

### Critical: Description = Trigger, Not Summary
```yaml
# BAD: summarizes workflow
description: Use when executing plans — dispatches subagent per task with code review

# GOOD: just triggering conditions
description: Use when executing implementation plans with independent tasks
```

### Quality Rules
- **Token efficiency:** Frequently-loaded skills load into EVERY conversation. Keep lean (<500 lines ideal).
- **Cross-reference:** `Use superpowers:skill-name` not `@skills/path/SKILL.md` (force-loads, burns context)
- **No rationalization tables** unless skill is a discipline skill (TDD, verification, etc.)
- **Keyword coverage:** Include error messages, symptoms, synonyms, tool names users would search for
- **One excellent example** beats many mediocre ones — make it complete, runnable, from a real scenario

### Iron Law
```
NO SKILL WITHOUT A FAILING TEST FIRST
```
Write before testing? Delete it. Start over. No exceptions — not for "simple additions."

After drafting, use skill-creator (builder skill) to run evals, iterate, and package.
