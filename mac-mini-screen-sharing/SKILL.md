---
name: mac-mini-screen-sharing
description: Start, reopen, verify, repair, or automate macOS Screen Sharing/VNC access from Kevin's MacBook to the AI Mac mini. Use when the user asks to screen share, start Screen Sharing, connect to the Mac mini, remote into desktop two, close and reopen Screen Sharing, make Mac mini Screen Sharing autonomous, or mentions "screen" or "screen sharing" in the Mac mini context.
---

# Mac Mini Screen Sharing

## Purpose

Use the proven autonomous Screen Sharing flow for Kevin's AI Mac mini. Do not ask for passwords in chat and do not store secrets in files.

Known target:

- Mac mini user: `iam`
- Preferred host: `AI-Mac-mini.local`
- Fallback IP: `192.168.40.23`
- Screen Sharing port: `5900`
- Keychain services:
  - `codex.mac-mini-screen-sharing.AI-Mac-mini.local`
  - `codex.mac-mini-screen-sharing.192.168.40.23`

## Start Screen Sharing

If the user wants the normal offline terminal command, it is:

```bash
screen-share
```

In a new zsh Terminal window, this also works:

```bash
screen share
```

Run the bundled launcher:

```bash
/Users/kdawg/.codex/skills/mac-mini-screen-sharing/scripts/start-mac-mini-screen-sharing.sh
```

The launcher checks reachability, opens `vnc://iam@AI-Mac-mini.local`, fills the registered-user login from Keychain, signs in, and reports whether a live `5900` connection exists.

The offline command wrapper lives at `/Users/kdawg/bin/screen-share`; the two-word `screen share` shortcut is a zsh function in `/Users/kdawg/.zshrc`.

After it runs, verify with:

```bash
lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | rg 'Screen.*192\.168\.40\.23:5900|Screen.*AI-Mac-mini'
```

For a visual proof, take a screenshot and inspect it. The job is not done if Screen Sharing is still sitting at the password dialog.

## If Setup Is Missing

If the launcher says no Keychain password exists, run the one-time setup in a local Terminal prompt:

```bash
/Users/kdawg/.codex/skills/mac-mini-screen-sharing/scripts/setup-mac-mini-autoscreen.sh
```

Have the user type the Mac mini `iam` password only into the Terminal prompt. Never ask them to paste it into chat. The setup stores the password in the MacBook login Keychain and sets the Mac mini to registered-user Screen Sharing so nobody has to click Accept downstairs.

Then run the launcher again and verify the live `5900` connection.

## Manual Fallback

If the launcher cannot automate the dialog, open registered-user Screen Sharing:

```bash
open 'vnc://iam@AI-Mac-mini.local'
```

Fallback:

```bash
open 'vnc://iam@192.168.40.23'
```

Use `As Registered User`, username `iam`, and the Mac mini account password. Do not use the "request permission" path when nobody is near the Mac mini.

## Health Checks

Check SSH and VNC reachability:

```bash
nc -G 2 -z AI-Mac-mini.local 22
nc -G 2 -z AI-Mac-mini.local 5900
```

Fallback by IP:

```bash
nc -G 2 -z 192.168.40.23 22
nc -G 2 -z 192.168.40.23 5900
```

Confirm the Mac mini setting:

```bash
ssh -o BatchMode=yes iam@192.168.40.23 'defaults read /Library/Preferences/com.apple.RemoteManagement ScreenSharingReqPermEnabled'
```

Expected value after setup is `0`.

More details live in `references/runbook.md`; read it only when troubleshooting.
