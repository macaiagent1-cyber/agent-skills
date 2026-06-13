---
name: planning
description: >
  Use before any creative or implementation work — turn ideas into fully formed designs, then
  verify work is complete before calling it done. Triggers when: about to build anything new,
  "let's build", "add a feature", "create X", "design Y", planning any multi-step task,
  OR completing any task and about to say it's done (verification). MUST be used before any
  implementation skill. Also triggers on: "brainstorm", "ideas for", "help me think through",
  "is this done", "verify", "check before finishing".
---

# Planning

Two modes: explore ideas before building, and verify completion before shipping.

## Mode Selection

```
About to start any creative or implementation work?   → BRAINSTORM mode
About to call a task complete / ship something?       → VERIFY mode
```

**HARD RULE:** BRAINSTORM mode MUST run before any implementation. No code, no scaffolding, no implementation action until design is approved. This applies to every project regardless of perceived simplicity.

---

## BRAINSTORM MODE
*Turn ideas into approved designs before any implementation begins*

### The Checklist (complete in order)

1. **Explore project context** — read files, docs, recent commits, understand current state
2. **Offer visual companion** — only if upcoming questions benefit from mockups/diagrams (own message, not combined)
3. **Ask clarifying questions** — one at a time. Purpose, constraints, success criteria. Multiple choice preferred.
4. **Propose 2-3 approaches** — with trade-offs and your recommendation. Lead with the recommendation.
5. **Present design** — section by section scaled to complexity, get approval after each
6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
7. **Spec self-review** — scan for placeholders, contradictions, ambiguity, scope issues. Fix inline.
8. **User reviews spec** — "Spec written to `<path>`. Review it before we start the implementation plan."
9. **Transition** — invoke writing skill (PLAN mode) to create the implementation plan

**Terminal state:** Invoking writing skill (PLAN mode). Do NOT invoke any implementation skill directly.

### Process Details

**Scoping:** Before asking details, assess scope. If the request describes multiple independent subsystems → flag and decompose first. Each sub-project gets its own spec → plan → implementation cycle.

**Questioning:** One question per message. Focus on understanding purpose, constraints, success criteria. Prefer multiple choice. Go back and clarify if something doesn't land.

**Approaches:** Present 2-3 options conversationally with reasoning. Not bullet lists — actual recommendation with "I'd recommend X because Y, but here's the trade-off."

**Design:** Scale each section to complexity (few sentences if simple, 200-300 words if nuanced). Ask "does this look right?" after each section. Be ready to revise.

**Design for isolation:** Break system into units with one clear purpose, well-defined interfaces, independently understandable and testable. Can someone understand it without reading its internals?

**Existing codebases:** Explore structure first, follow patterns. Improve code you're working in if it has problems that affect the work — but no unrelated refactoring.

### Spec Self-Review
After writing the spec:
1. Placeholder scan — any "TBD", "TODO", vague requirements? Fix them.
2. Internal consistency — do sections contradict each other?
3. Scope check — focused enough for a single implementation plan?
4. Ambiguity — any requirement interpretable two ways? Pick one, make it explicit.

Fix inline, no need to re-review.

---

## VERIFY MODE
*Check work is genuinely complete before calling it done*

**Use before:** Saying "done", creating a PR, merging to main, delivering any output to a user.

### The Verification Checklist

**1. Requirements coverage**
- Read the original request / requirements one more time
- Can you point to specific output that satisfies each requirement?
- Any requirement missing or only partially implemented?

**2. Edge cases**
- What happens with empty input?
- What happens with invalid input?
- What happens at scale limits?
- What happens when dependencies fail?

**3. Tests**
- Do all tests pass?
- Are the tests testing the right behavior (not just implementation)?
- Are there obvious gaps in test coverage?

**4. Integration**
- Does this work with the rest of the system?
- Are there any interfaces that changed without updating consumers?
- Did you check both the happy path and error path?

**5. Output quality**
- If this is a document: does a fresh reader (no context) understand it?
- If this is code: would a code reviewer find obvious issues?
- If this is a design: does it meet the quality bar set at the start?

**6. Non-regression**
- Did existing functionality that was working before still work?
- Run the full test suite, not just the new tests

### If Verification Finds Issues
Don't hide them. Report exactly:
```
Before marking complete, I found:
- [issue 1]: [specific description]
- [issue 2]: [specific description]

Fixing now / Need your input on [X].
```

Fix before declaring done.

### What "Done" Actually Means
- Requirements met: yes
- Tests pass: yes
- No known regressions: yes
- Edge cases handled: yes
- Output reviewed against original ask: yes

Only then: "This is complete."
