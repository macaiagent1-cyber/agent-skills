---
name: dev-quality
description: >
  Use for all code quality practices: test-driven development, systematic debugging, and
  engineering quality frameworks. Triggers when: writing new code (TDD), something is broken
  or tests are failing (debugging), setting up quality/testing harness for a project (ECC),
  "write tests first", "debug this", "something is broken", "flaky tests", "hanging process",
  "race condition", or any quality-focused engineering task.
---

# Dev Quality

Three integrated quality practices: write tests first, debug systematically, build quality frameworks.

## Mode Selection

```
Writing new code?                              → TDD mode
Something broken / tests failing?             → DEBUG mode
Setting up project quality infrastructure?    → HARNESS mode
```

---

## TDD MODE
*Test-Driven Development — write the failing test before any implementation*

**Core law:** NO CODE WITHOUT A FAILING TEST FIRST. No exceptions.

### The Cycle
```
1. Write failing test
2. Run it — verify it FAILS
3. Write minimal code to make it pass
4. Run it — verify it PASSES
5. Refactor (keep tests green)
6. Commit
```

**If you wrote code before the test:** Delete it. Start over. Not keep as "reference", not "adapt while writing tests" — delete.

### Discipline Rules
- Violating the letter = violating the spirit
- "Simple addition" → still needs a failing test first
- "Documentation update" → still needs a failing test first
- If you catch yourself rationalizing → stop, delete, restart

### Test Design
- One clear assertion per test
- Name the test after the behavior: `test_should_reject_invalid_email`
- Test behavior, not implementation
- Fast tests > slow tests (mock I/O boundaries)

### Red Flags (rationalizing — stop)
| Thought | Reality |
|---------|---------|
| "This is too simple to need a test" | Simple code has the most unexamined bugs |
| "I'll add tests after" | You won't. Write them first. |
| "The test is obvious" | Then it takes 30 seconds to write. Do it. |
| "I just need to spike it" | Spikes get committed. Write the test. |

---

## DEBUG MODE
*Systematic debugging — hypothesize, test, eliminate, never guess*

**Core principle:** Every fix is a hypothesis. Test it. Don't guess.

### The Process

**Step 1: Reproduce reliably**
Cannot fix what you can't reproduce. Find the minimal case that triggers the bug every time.

**Step 2: Understand the system**
Before touching anything: read the error, read the stack trace, read the relevant code. Form a mental model of what SHOULD happen.

**Step 3: Form a hypothesis**
One specific hypothesis: "The bug is caused by X." Not "maybe it's X or Y."

**Step 4: Test the hypothesis**
Add logging, add assertions, run the specific failing case. Does the evidence confirm or deny?

**Step 5: Eliminate and narrow**
Binary search: is the bug in the first half or second half? Progressively narrow the scope.

**Step 6: Fix and verify**
Fix the root cause (not the symptom). Verify the original repro case passes. Verify no regressions.

**Step 7: Add a regression test**
Write a test that would have caught this bug. Commit it with the fix.

### For Specific Bug Types

**Race conditions / timing issues:**
- Replace arbitrary `sleep()`/timeouts with event-based waiting
- Log timestamps at each step
- Look for missing locks, shared mutable state

**Flaky tests:**
- Isolate: run the test 10 times in a row
- Check: external state dependencies, timing assumptions, test order coupling
- Fix: make each test fully self-contained

**Hanging processes:**
- Add timeout + stack dump
- Check: deadlocks, waiting on never-signaled event, infinite loop
- Binary search: add logging to find where it hangs

**Memory / performance:**
- Profile before optimizing (don't guess the bottleneck)
- Measure baseline, change one thing, measure again

### Stop and Escalate When
- Same hypothesis fails 3+ times
- You've spent >30 min and the scope isn't narrowing
- Fix breaks more things than it fixes

---

## HARNESS MODE
*Engineering quality infrastructure — set up the project's quality/testing framework*

**Use when:** Starting a new project, adding testing to an existing one, or establishing team quality norms.

### What to Set Up

**Test infrastructure:**
- Unit test runner (jest, pytest, cargo test, go test)
- Integration test setup (test DB, mock services)
- CI pipeline that runs tests on every PR

**Code quality gates:**
- Linter (eslint, ruff, clippy) with zero-warning policy
- Type checker (tsc, mypy, pyright)
- Pre-commit hooks that block commits with failures

**Coverage baseline:**
- Set a minimum threshold (start at 60%, raise over time)
- Track trend — it should go up, not down

**Documentation:**
- `CONTRIBUTING.md` with how to run tests locally
- Test naming conventions for the project

### Quality Standards Per Task
Every implementation task should:
1. Have tests written first (TDD)
2. Pass linting and type checks
3. Not decrease coverage
4. Have a commit message that describes WHY (not what)

### Red Flags in a Project
- Tests only exist in CI (never run locally) → fix the dev setup
- Flaky tests that are "just skipped" → fix or delete, never ignore
- "We'll add tests later" → that's now, not later
