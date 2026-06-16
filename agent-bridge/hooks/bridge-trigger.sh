#!/usr/bin/env bash
# agent-bridge auto-trigger (UserPromptSubmit hook).
# When the user's prompt is about cross-agent co-work, print a short nudge so Claude
# reaches for the agent-bridge skill / `bridge` command. Never blocks; always exit 0.
input=$(cat)
prompt=$(printf '%s' "$input" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("prompt",""))' 2>/dev/null)
if printf '%s' "$prompt" | grep -qiE 'codex|resume .*(session|chat)|session id|co-?work|in parallel|second opinion|delegate|peer review|ask (codex|gemini|kimi)|other agent|another agent|bridge|tap into.*session'; then
  echo "[agent-bridge] Cross-agent request detected — use the 'bridge' command (bridge codex|resume|read|list|mini|gemini|cloud) to talk to or co-work with other agents. Token-light, runs on their quota. Manual: ~/.agents/skills/agent-bridge/SKILL.md"
fi
exit 0
