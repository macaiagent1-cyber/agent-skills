#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOST_IP="${MAC_MINI_IP:-192.168.40.23}"
HOST_NAME="${MAC_MINI_HOST:-AI-Mac-mini.local}"
USER_NAME="${MAC_MINI_USER:-iam}"
VNC_TARGET="${MAC_MINI_VNC_TARGET:-${HOST_NAME}}"
KEYCHAIN_SERVICE_IP="codex.mac-mini-screen-sharing.${HOST_IP}"
KEYCHAIN_SERVICE_HOST="codex.mac-mini-screen-sharing.${HOST_NAME}"

get_password() {
  security find-generic-password -a "${USER_NAME}" -s "${KEYCHAIN_SERVICE_HOST}" -w 2>/dev/null \
    || security find-generic-password -a "${USER_NAME}" -s "${KEYCHAIN_SERVICE_IP}" -w 2>/dev/null
}

PASS="$(get_password || true)"

if [[ -z "${PASS}" ]]; then
  echo "No Keychain password found for ${USER_NAME}@${HOST_NAME}."
  echo "Run ${SCRIPT_DIR}/setup-mac-mini-autoscreen.sh once, then retry."
  open "vnc://${USER_NAME}@${VNC_TARGET}"
  exit 2
fi

echo "Checking Mac mini reachability..."
if ! nc -G 2 -z "${HOST_IP}" 5900 >/dev/null 2>&1; then
  echo "Screen Sharing port is not reachable on ${HOST_IP}:5900." >&2
  exit 1
fi

echo "Opening Screen Sharing..."
open "vnc://${USER_NAME}@${VNC_TARGET}"

export MAC_MINI_SCREEN_PASS="${PASS}"
export MAC_MINI_SCREEN_USER="${USER_NAME}"

osascript <<'OSA'
set userName to system attribute "MAC_MINI_SCREEN_USER"
set passText to system attribute "MAC_MINI_SCREEN_PASS"

tell application "Screen Sharing" to activate

tell application "System Events"
  tell process "Screen Sharing"
    set frontmost to true
    repeat 60 times
      if exists window 1 then exit repeat
      delay 0.25
    end repeat

    delay 0.25

    try
      click radio button "As Registered User" of radio group 1 of window 1
    end try

    try
      click text field 1 of window 1
      keystroke "a" using command down
      keystroke userName
    end try

    try
      click text field 2 of window 1
      keystroke "a" using command down
      keystroke passText
    end try

    delay 0.2

    try
      click button "Sign In" of window 1
    end try
  end tell
end tell
OSA

unset MAC_MINI_SCREEN_PASS PASS

sleep 2
if lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | grep -E 'Screen.*:5900|Screen Sharing.*:5900' >/dev/null; then
  echo "Screen Sharing connection is active."
else
  echo "Screen Sharing was launched; connection not confirmed yet."
fi
