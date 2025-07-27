#!/bin/zsh

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/github.json"
mkdir -p "$STATE_DIR"

if ! command -v jq &> /dev/null; then exit 1; fi

ok=true
message="GitHub is authenticated."
if command -v gh &> /dev/null; then
    if ! gh auth status >/dev/null 2>&1; then
        ok=false
        message="GitHub auth is required. Run 'gh auth login'."
    fi
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 