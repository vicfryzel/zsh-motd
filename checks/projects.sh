#!/bin/zsh

# Path to the state file
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/projects.json"

# Ensure the state directory exists
mkdir -p "$STATE_DIR"

if ! command -v jq &> /dev/null; then exit 1; fi

# Use the user-configured projects directory, or default to ~/src
PROJECTS_DIR="${MOTD_PROJECTS_DIR:-$HOME/src}"

# Find repositories with uncommitted changes
dirty_repos=$(find "$PROJECTS_DIR" -type d -name ".git" | while read gitdir; do
  repo_path=$(dirname "$gitdir")
  if [[ -n $(git -C "$repo_path" status --porcelain) ]]; then
    echo "$repo_path"
  fi
done)

ok=true
message="Project repositories are clean."
if [[ -n "$dirty_repos" ]]; then
  ok=false
  message="You have uncommitted changes in project repositories:\n$(echo "$dirty_repos" | sed 's/^/    /')"
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 