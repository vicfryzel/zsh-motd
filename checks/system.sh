#!/bin/zsh

# Paths
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/system.json"

# Ensure the state directory exists
mkdir -p "$STATE_DIR"

if ! command -v jq &> /dev/null; then exit 1; fi

# Threshold
THRESHOLD="${MOTD_DISK_THRESHOLD:-90}"

# Get disk usage for the root partition
# Use POSIX-compliant flags and awk for cross-platform compatibility
CURRENT_USAGE=$(df -P / | awk 'NR==2 {print $5}' | sed 's/%//')

ok=true
message="System disk space is OK."
if [[ "$CURRENT_USAGE" -gt "$THRESHOLD" ]]; then
  ok=false
  message="Low disk space on '/'. Usage: ${CURRENT_USAGE}%."
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 