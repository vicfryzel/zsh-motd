#!/bin/zsh

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/ssh.json"
mkdir -p "$STATE_DIR"

if ! command -v jq &> /dev/null; then exit 1; fi

ok=true
message="SSH agent is configured."
ssh-add -l >/dev/null 2>&1
if [[ "$?" -eq 1 ]]; then
  ok=false
  message="SSH agent has no identities. Run 'ssh-add'."
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 