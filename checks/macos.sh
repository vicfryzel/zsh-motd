#!/bin/zsh

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/macos.json"
mkdir -p "$STATE_DIR"

if ! command -v jq &> /dev/null; then exit 1; fi

ok=true
message="macOS is up to date."
if ! softwareupdate -l 2>&1 | grep -q "No new software available."; then
  ok=false
  message="System software updates are available."
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 