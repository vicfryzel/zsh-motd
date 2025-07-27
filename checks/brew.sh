#!/bin/zsh

# Path to the state file
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/brew.json"

# Ensure the state directory exists
mkdir -p "$STATE_DIR"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    exit 1
fi

# Check if Homebrew is installed and in the PATH
if ! command -v brew &> /dev/null; then
  jq -n --argjson ok "true" --arg msg "Homebrew not found." \
    '{"ok": $ok, "message": $msg}' > "$JSON_FILE"
  exit 0
fi

ok=true
message="Homebrew is up to date."
if [[ -n "$(brew outdated -q)" ]]; then
  ok=false
  message="Homebrew has pending updates. Run 'brew upgrade'."
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 