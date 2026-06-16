---
name: codex-dispatcher
description: >
  Intelligent task router that decides when to offload large or multi-file coding tasks to the
  OpenAI Codex CLI running locally, rather than handling them directly in Claude — preserving
  Claude's rate limits for tasks only Claude does well. ALWAYS trigger this skill when the user
  asks to: refactor 3+ files, scaffold a project or feature from scratch, generate boilerplate
  across multiple entities (CRUD, components, schemas, test suites), write test suites for
  existing code, perform any task requiring 10+ sequential tool calls, or explicitly says
  "use codex", "run codex", or "codex exec". Also trigger when the task is described as
  "large", "repetitive", or "codebase-wide". Skip for questions, reviews, single-file fixes,
  or quick additions — handle those directly.
---

# Codex Dispatcher Skill

## Operational Terms (defined upfront)

- **Codex CLI**: The OpenAI Codex CLI tool installed locally on the user's Mac, used as a
  subordinate coding agent for heavy tasks.
- **Delegate**: Send the task to Codex CLI instead of handling it in Claude.
- **Handle in-house**: Claude resolves the task directly, no Codex involved.
- **Sandbox mode**: The file-system access level granted to Codex for a given task.
- **Reasoning effort**: How deeply Codex thinks before writing code (maps to `--reasoning` flag).
- **Resume**: Continue a previous Codex session with the same model/effort settings.

---

## Step 1 — Delegate or Not?

Evaluate the task against this decision matrix:

| Condition | Action |
|---|---|
| Refactoring or renaming across 3+ files | **Delegate** |
| Scaffolding a project, feature, or module | **Delegate** |
| Boilerplate generation for 3+ entities | **Delegate** |
| Writing test suites for existing code | **Delegate** |
| Estimated 10+ sequential tool calls | **Delegate** |
| User says "use codex" / "run codex" / "codex exec" | **Delegate** |
| Question, explanation, or code review | **Handle in-house** |
| Changes in 1–2 files | **Handle in-house** |
| Quick bug fix or small addition | **Handle in-house** |
| Advice or architecture discussion | **Handle in-house** |

If delegating → proceed to Step 2.
If handling in-house → exit this skill and complete the task normally.

---

## Step 2 — Detect the Codex CLI Binary

Before building any command, locate the binary. Run this detection block once per session:

```bash
# Check common install locations in order
CODEX_BIN=""

for candidate in \
  "$HOME/.local/bin/codex" \
  "$HOME/bin/codex" \
  "/usr/local/bin/codex" \
  "/opt/homebrew/bin/codex" \
  "/Applications/Codex.app/Contents/MacOS/codex" \
  "/Applications/Codex.app/Contents/MacOS/Codex"; do
  if [ -x "$candidate" ]; then
    CODEX_BIN="$candidate"
    break
  fi
done

# Also try PATH
if [ -z "$CODEX_BIN" ]; then
  CODEX_BIN=$(which codex 2>/dev/null)
fi

echo "CODEX_BIN=$CODEX_BIN"
```

If `CODEX_BIN` is empty → **fall back to Claude** (handle in-house) and tell the user:
> "Codex CLI not found in common locations. I'll handle this directly. Install Codex CLI and
> retry if you want to use it."

If found → **detect available models**:

```bash
"$CODEX_BIN" --list-models 2>/dev/null || "$CODEX_BIN" models 2>/dev/null || "$CODEX_BIN" --help 2>/dev/null | grep -i model
```

Parse the output to build the model list dynamically. If the flag doesn't exist, note that
model names can't be validated and present them as free-text input.

---

## Step 3 — Ask User Preferences

Ask the user two questions (can be combined into one message):

**1. Model**
Present the detected model list (or a free-text prompt if detection failed). Recommend the
most capable option as the default.

Example:
> "Which model should Codex use? (Default: most capable available)"

**2. Reasoning effort**
Present these options and default to `xhigh`:

| Label | Flag value | When to use |
|---|---|---|
| Extra High (default) | `xhigh` | Complex refactors, architecture work |
| High | `high` | Standard multi-file tasks |
| Medium | `medium` | Well-defined boilerplate |
| Low | `low` | Repetitive pattern fills |
| Minimal | `minimal` | Simple renames, fast pass |

Store both values as `$CODEX_MODEL` and `$CODEX_EFFORT` for use in Step 4.

---

## Step 4 — Build and Run the Codex Command

### Sandbox Mode Selection

Pick sandbox mode based on task type:

| Task type | Sandbox mode |
|---|---|
| Read + explain only | `read-only` |
| Writing to project workspace only | `workspace-write` |
| Needs system access (install deps, run scripts) | `full` |

> **High-impact flags** (`full` sandbox, `--force`, anything that modifies outside the repo):
> Always ask for explicit user confirmation before running.

### Command Template

```bash
"$CODEX_BIN" \
  --model "$CODEX_MODEL" \
  --reasoning "$CODEX_EFFORT" \
  --sandbox "$SANDBOX_MODE" \
  --no-git-check \
  --quiet \
  --yes \
  --prompt "$TASK_PROMPT"
```

Flag glossary (adjust if your Codex version uses different names — verify with `--help`):

| Flag | Purpose |
|---|---|
| `--model` | Model to use |
| `--reasoning` | Reasoning effort level |
| `--sandbox` | File system access scope |
| `--no-git-check` | Skip git clean-state requirement |
| `--quiet` | Suppress verbose internal logging |
| `--yes` / `--auto-run` | Don't prompt Codex mid-task for confirmations |
| `--prompt` | The task instruction |

> **Flag verification**: If any flag causes a non-zero exit with an "unknown flag" error,
> run `"$CODEX_BIN" --help` and remap to the correct flag name before retrying.

### Writing the Task Prompt

Brief Codex as if it's a developer new to the project. Structure:

```
You are working on [PROJECT_NAME / brief description].

Your task: [EXACT TASK DESCRIPTION]

Constraints:
- [List any specific constraints: naming conventions, file structure, frameworks, etc.]
- Do not modify files outside: [scope]
- Follow existing patterns in [reference file(s) if known]

Success criteria:
- [What done looks like]
```

---

## Step 5 — Monitor and Resume

After launching:
- Stream or tail output if possible.
- If the user says **"codex resume"** → reuse `$CODEX_MODEL` and `$CODEX_EFFORT` from the
  current session. Pass the resume flag if Codex supports it (`--resume` or `--continue`),
  otherwise re-invoke with the same prompt + "Continue where you left off."

---

## Step 6 — Critical Review (Do Not Skip)

Claude does not blindly accept Codex output. After Codex finishes:

1. **Read the diff or changed files.**
2. **Apply independent judgment** — does the output match the task spec?
3. **Flag disagreements** — if Codex made a wrong architectural choice or introduced a bug,
   document it specifically.
4. **Dispute if necessary** — re-invoke Codex with a correction prompt that references the
   exact issue: `"In [file] at [location], you did X. This is wrong because Y. Do Z instead."`
5. **Escalate to Claude** — if Codex keeps making the same error after 2 correction attempts,
   handle that specific sub-task in-house.

---

## Error Handling

| Error condition | Response |
|---|---|
| Binary not found | Fall back to Claude, inform user |
| Non-zero exit code | Report exact error, ask user how to proceed |
| "Rate limit" in output | Fall back to Claude for this task |
| Unknown flag error | Re-run `--help`, remap flags, retry once |
| High-impact flag required | Ask user permission before proceeding |
| Codex loops / hangs >2min | Kill process, report, fall back to Claude |

---

## Step 7 — Wrap-Up

After Codex finishes (and after critical review), always output a summary in this format:

```
✅ Codex finished.
Model: [model used]
Reasoning effort: [effort used]
What was done: [2-3 sentence plain English summary]

Want to continue, refine, or make additional changes?
```

Then wait for user direction.

---

## Session State to Preserve

Track these across a session for resume capability:

```
CODEX_BIN=       # resolved binary path
CODEX_MODEL=     # chosen model
CODEX_EFFORT=    # chosen reasoning effort
SANDBOX_MODE=    # sandbox level used
LAST_PROMPT=     # last task prompt sent
```
