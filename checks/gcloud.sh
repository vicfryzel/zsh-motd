#!/bin/zsh

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/gcloud.json"
mkdir -p "$STATE_DIR"

if ! command -v jq &> /dev/null; then exit 1; fi

ok=true
message="Google Cloud is authenticated."
if command -v gcloud &> /dev/null; then
    if ! gcloud auth print-access-token --quiet >/dev/null 2>&1; then
        ok=false
        message="Google Cloud auth is required. Run 'gcloud auth login'."
    fi
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 