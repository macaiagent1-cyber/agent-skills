# Mac Mini Screen Sharing Runbook

Do not store passwords in this file.

## Known Machines

MacBook Air:

- Local user: `kdawg`
- Hostname: `Kevins-MacBook-Air.local`
- Observed LAN IP: `192.168.40.36`

Mac mini:

- SSH and Screen Sharing user: `iam`
- Hostname: `AI-Mac-mini.local`
- Computer name: `AI's Mac mini`
- Observed LAN IP: `192.168.40.23`
- Active LAN interface when recorded: `en1`

## Access

SSH:

```bash
ssh iam@AI-Mac-mini.local
ssh iam@192.168.40.23
```

Screen Sharing:

```bash
open 'vnc://iam@AI-Mac-mini.local'
open 'vnc://iam@192.168.40.23'
```

The `iam` account was observed as an admin and a member of:

- `com.apple.access_screensharing`
- `com.apple.access_ssh`
- `com.apple.access_remote_ae`

## Verified Autonomous Flow

1. The setup script prompts locally for the Mac mini password.
2. It stores that password in the MacBook login Keychain under the two Codex-specific service names.
3. It sets `ScreenSharingReqPermEnabled` to `0` on the Mac mini and restarts Screen Sharing.
4. The launcher opens Screen Sharing, fills the registered-user dialog, signs in, and confirms an established `5900` connection.

## Offline Commands

These work without Codex or internet as long as the MacBook and Mac mini are on
the same local network:

```bash
screen-share
screen share
```

`screen-share` is an executable at `/Users/kdawg/bin/screen-share`.
`screen share` is a zsh function in `/Users/kdawg/.zshrc` that calls the same
executable while preserving the normal `/usr/bin/screen` command for other
arguments.

Useful flags:

```bash
screen-share --info
screen-share --setup
screen-share --ssh
screen-share --manual
```

`--info` must not print the password. It should only report whether the password
is saved in Keychain.

Expected live connection pattern:

```text
192.168.40.36 -> 192.168.40.23:5900
```

## File Transfer Path

The MacBook had this share mounted when recorded:

```text
/Volumes/Data
```

It was mounted from:

```text
//Kevin%20De%20orellana@HQ01.local/Data
```

Use it as a bridge when needed:

```bash
cp /path/to/local/file /Volumes/Data/
```
