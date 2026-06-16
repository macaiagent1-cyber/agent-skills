---
name: gemini-dispatcher
description: >
  Intelligent task router that decides when to offload tasks to the Gemini CLI running locally,
  rather than handling them directly in Claude — preserving Claude's rate limits for tasks only
  Claude does well. ALWAYS trigger this skill when the user asks to: research using Google search,
  run large-context analysis (Gemini has 1M+ token context), perform multi-source web synthesis,
  scaffold a project across 3+ files, or explicitly says "use gemini", "run gemini", "ask gemini",
  or "gemini exec". Also trigger when the task benefits from Google's knowledge or live search
  grounding, or when the user wants a second model's opinion. Skip for quick single-file fixes,
  code review, or anything requiring Claude-specific tools (computer use, MCP servers, skills).
---

# Gemini Dispatcher Skill

## Operational Terms (defined upfront)

- **Gemini CLI**: The Google Gemini CLI tool installed locally, used as a subordinate agent.
- **Delegate**: Send the task to Gemini CLI instead of handling it in Claude.
- **Handle in-house**: Claude resolves the task directly, no Gemini involved.
- **Approval mode**: How much Gemini auto-approves tool calls during a run.
- **YOLO mode**: Gemini auto-accepts all tool actions without prompting (`--yolo`).
- **Resume**: Continue a previous Gemini session (`--resume latest` or by index).

---

## Step 1 — Delegate or Not?

| Condition | Action |
|---|---|
| Task benefits from Google search / live web grounding | **Delegate** |
| Large-context analysis (>100k tokens of input) | **Delegate** |
| Multi-source research synthesis | **Delegate** |
| Scaffolding or boilerplate across 3+ files | **Delegate** |
| User says "use gemini" / "run gemini" / "ask gemini" | **Delegate** |
| User wants a second model opinion on something | **Delegate** |
| Quick bug fix or 1–2 file change | **Handle in-house** |
| Task requires Claude-specific tools (computer use, MCP, skills) | **Handle in-house** |
| Code review or architectural advice | **Handle in-house** |
| Question or explanation only | **Handle in-house** |

If delegating → proceed to Step 2.
If handling in-house → exit this skill and complete the task normally.

---

## Step 2 — Detect the Gemini CLI Binary

```bash
GEMINI_BIN=""

for candidate in \
  "$HOME/.local/bin/gemini" \
  "$HOME/bin/gemini" \
  "/usr/local/bin/gemini" \
  "/opt/homebrew/bin/gemini"; do
  if [ -x "$candidate" ]; then
    GEMINI_BIN="$candidate"
    break
  fi
done

if [ -z "$GEMINI_BIN" ]; then
  GEMINI_BIN=$(which gemini 2>/dev/null)
fi

echo "GEMINI_BIN=$GEMINI_BIN"
```

If `GEMINI_BIN` is empty → fall back to Claude (handle in-house) and tell the user:
> "Gemini CLI not found. I'll handle this directly. Install it with `npm install -g @google/gemini-cli` and retry."

---

## Step 3 — Pick Model and Approval Mode

### Model

Default to the most capable available. Common options:

| Model | When to use |
|---|---|
| `gemini-2.5-pro` | Complex reasoning, large context, best quality |
| `gemini-2.5-flash` | Faster, lower cost, good for boilerplate/research |
| `gemini-2.0-flash` | Lightweight, quick tasks |

Pass with `-m` / `--model`. If unsure, ask the user or default to `gemini-2.5-pro`.

### Approval Mode

| Mode | Flag | When to use |
|---|---|---|
| Auto-approve edits, prompt for destructive | `--approval-mode auto_edit` | Default for coding tasks |
| Auto-approve everything | `--yolo` | Fast boilerplate, low-risk scaffolding |
| Prompt for every action | *(omit flag)* | Unfamiliar codebase, sensitive changes |
| Read-only / plan only | `--approval-mode plan` | Research, analysis, no writes |

> **YOLO mode** (`--yolo`) skips all confirmations. Only use for well-scoped, low-risk tasks.
> Always tell the user when you're using it.

Store as `$GEMINI_MODEL` and `$GEMINI_APPROVAL`.

---

## Step 4 — Build and Run the Command

### Command Template

```bash
"$GEMINI_BIN" \
  --model "$GEMINI_MODEL" \
  $GEMINI_APPROVAL \
  --output-format text \
  --prompt "$TASK_PROMPT"
```

### Optional Flags

| Flag | Purpose |
|---|---|
| `-m` / `--model` | Model to use |
| `--approval-mode` | Tool approval policy |
| `--yolo` | Auto-accept all tool actions |
| `-p` / `--prompt` | Non-interactive (headless) mode |
| `-r` / `--resume` | Resume a previous session (`latest` or index) |
| `--sandbox` | Run in sandbox (restricted file access) |
| `--include-directories` | Add extra dirs to workspace |
| `--output-format` | `text`, `json`, or `stream-json` |

> **Flag verification**: If any flag causes a non-zero exit with "unknown option", run
> `"$GEMINI_BIN" --help` and remap before retrying.

### Writing the Task Prompt

Structure the prompt so Gemini has full context:

```
You are working on [PROJECT_NAME / brief description].

Your task: [EXACT TASK DESCRIPTION]

Constraints:
- [Naming conventions, file structure, frameworks]
- Do not modify files outside: [scope]
- Follow existing patterns in [reference file(s) if known]

Success criteria:
- [What done looks like]
```

---

## Step 5 — Monitor and Resume

After launching:
- Stream output if possible (`--output-format stream-json` for structured output).
- If the user says **"gemini resume"** → reuse `$GEMINI_MODEL` and `$GEMINI_APPROVAL`.
  Pass `--resume latest` to continue the most recent session, or `--resume <index>` for a specific one.
  Run `"$GEMINI_BIN" --list-sessions` to show available sessions if needed.

---

## Step 6 — Critical Review (Do Not Skip)

Claude does not blindly accept Gemini output. After Gemini finishes:

1. **Read the diff or output.**
2. **Apply independent judgment** — does the output match the task spec?
3. **Flag disagreements** — wrong architectural choice, introduced a bug, missed a constraint.
4. **Dispute if necessary** — re-invoke Gemini with a correction prompt referencing the exact issue:
   `"In [file] at [location], you did X. This is wrong because Y. Do Z instead."`
5. **Escalate to Claude** — if Gemini repeats the same error after 2 correction attempts, handle
   that sub-task in-house.

---

## Error Handling

| Error condition | Response |
|---|---|
| Binary not found | Fall back to Claude, inform user |
| `GEMINI_API_KEY` missing | Tell user to set it in `~/.env` or shell profile |
| Non-zero exit code | Report exact error, ask user how to proceed |
| "Rate limit" in output | Wait or fall back to Claude |
| Unknown flag error | Re-run `--help`, remap flags, retry once |
| Gemini loops / hangs >2min | Kill process, report, fall back to Claude |

---

## Step 7 — Wrap-Up

After Gemini finishes (and after critical review), output:

```
✅ Gemini finished.
Model: [model used]
Approval mode: [mode used]
What was done: [2-3 sentence plain English summary]

Want to continue, refine, or make additional changes?
```

Then wait for user direction.

---

## Session State to Preserve

```
GEMINI_BIN=        # resolved binary path
GEMINI_MODEL=      # chosen model
GEMINI_APPROVAL=   # approval mode flag(s)
LAST_PROMPT=       # last task prompt sent
```
