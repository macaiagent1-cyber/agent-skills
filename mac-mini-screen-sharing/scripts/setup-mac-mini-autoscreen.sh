#!/usr/bin/env bash
set -euo pipefail

HOST_IP="${MAC_MINI_IP:-192.168.40.23}"
HOST_NAME="${MAC_MINI_HOST:-AI-Mac-mini.local}"
USER_NAME="${MAC_MINI_USER:-iam}"
KEYCHAIN_SERVICE_IP="codex.mac-mini-screen-sharing.${HOST_IP}"
KEYCHAIN_SERVICE_HOST="codex.mac-mini-screen-sharing.${HOST_NAME}"

echo "This stores the Mac mini password in your MacBook login Keychain."
echo "It does not write the password to this folder or to chat."
echo
read -rsp "Mac mini password for ${USER_NAME}@${HOST_IP}: " MINI_PASS
echo

if [[ -z "${MINI_PASS}" ]]; then
  echo "No password entered; aborting." >&2
  exit 1
fi

echo "Checking SSH access..."
ssh -o BatchMode=yes -o ConnectTimeout=5 "${USER_NAME}@${HOST_IP}" 'true'

echo "Setting Mac mini Screen Sharing to registered-user access..."
printf '%s\n' "${MINI_PASS}" | ssh -T "${USER_NAME}@${HOST_IP}" \
  'sudo -S -p "" /bin/sh -c "defaults write /Library/Preferences/com.apple.RemoteManagement ScreenSharingReqPermEnabled -bool false && launchctl kickstart -k system/com.apple.screensharing"'

echo "Saving password in local Keychain for the launcher..."
security add-generic-password -a "${USER_NAME}" -s "${KEYCHAIN_SERVICE_IP}" -w "${MINI_PASS}" -U >/dev/null
security add-generic-password -a "${USER_NAME}" -s "${KEYCHAIN_SERVICE_HOST}" -w "${MINI_PASS}" -U >/dev/null

unset MINI_PASS

echo "Setup complete. Future launches can run start-mac-mini-screen-sharing.sh"
