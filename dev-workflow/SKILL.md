---
name: dev-workflow
description: >
  Use for the full development lifecycle: setting up isolated git workspaces, executing written
  implementation plans, and finishing/shipping branches. Triggers when: "set up a worktree",
  "create workspace", "execute this plan", "implement this plan", "finish the branch", "merge",
  "create PR", "ship this", implementation is complete and needs to be shipped, or starting any
  multi-task development that needs an isolated environment. Required before any plan execution.
---

# Dev Workflow

Full development lifecycle: workspace setup → plan execution → branch completion.

## Mode Selection

```
Starting new feature needing isolation?       → WORKTREE SETUP mode
Have a written plan to execute?               → EXECUTE PLAN mode
Implementation done, need to ship?            → FINISH BRANCH mode
```

---

## WORKTREE SETUP MODE
*Create an isolated git workspace before multi-task development*

**Always set up before:** executing plans, subagent-driven development, any work that shouldn't touch main/master.

```bash
# Create the worktree
git worktree add ../[project]-[feature] -b [feature-branch]

# Verify
git worktree list

# Set up environment
cd ../[project]-[feature]
# Install deps, copy .env files as needed
```

**Never start implementation on main/master without explicit user consent.**

---

## EXECUTE PLAN MODE
*Load a written plan and execute it task-by-task*

Announce: "Using dev-workflow to implement this plan."

**Note:** Much better with subagents. If subagents available → hand off to agent-orchestration (SUBAGENT DEV mode) for higher quality.

### Process

**Step 1: Load and Review**
1. Read the plan file
2. Review critically — identify questions or concerns
3. Raise concerns with human partner before starting
4. If clear → create TodoWrite with all tasks

**Step 2: Execute Tasks**
For each task:
1. Mark `in_progress`
2. Follow each step exactly
3. Run verifications as specified
4. Mark `completed`

**Step 3: Finish**
After all tasks → use FINISH BRANCH mode.

### Stop and Ask When
- Blocker (missing dep, repeated test failure, unclear instruction)
- Plan has critical gaps
- Verification fails 3+ times on same task

Never force through blockers. Ask.

---

## FINISH BRANCH MODE
*Verify, choose integration path, clean up*

Announce: "Using dev-workflow to finish this branch."

**Core:** Verify tests → Present options → Execute → Clean up.

### Step 1: Verify Tests
```bash
npm test / cargo test / pytest / go test ./...
```
If tests fail → show failures, stop. Cannot proceed until tests pass.

### Step 2: Determine Base Branch
```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

### Step 3: Present Options
```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (handle later)
4. Discard this work
```

### Step 4: Execute

**Option 1 — Merge locally:**
```bash
git checkout <base-branch> && git pull && git merge <feature-branch>
# run tests
git branch -d <feature-branch>
git worktree remove <path>  # cleanup
```

**Option 2 — Push + PR:**
```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets>
## Test Plan
- [ ] <verification steps>
EOF
)"
```
Keep worktree (PR may need changes).

**Option 3 — Keep as-is:**
Report location. Do NOT cleanup worktree.

**Option 4 — Discard:**
Require typed "discard" confirmation, then:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
git worktree remove <path>
```

### Cleanup Reference
| Option | Cleanup worktree | Delete branch |
|--------|-----------------|---------------|
| 1. Merge | ✓ | ✓ |
| 2. PR | — | — |
| 3. Keep | — | — |
| 4. Discard | ✓ | ✓ force |

**Never:** Proceed with failing tests, delete work without typed "discard", force-push without explicit request.
