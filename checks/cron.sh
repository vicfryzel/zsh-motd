#!/bin/zsh

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/cron.json"
mkdir -p "$STATE_DIR"

if ! command -v jq &> /dev/null; then exit 1; fi

LAST_COMMAND_FILE="$STATE_DIR/cron_last_installed_command"

# Determine the desired state from the user's config
desired_schedule="${MOTD_CRON_SCHEDULE:-*/15 * * * *}"
desired_runner_path="${MOTD_DOTFILES_DIR:-$HOME/dotfiles}/scripts/run_motd_checks.sh"
desired_command="$desired_schedule MOTD_DOTFILES_DIR='${MOTD_DOTFILES_DIR:-$HOME/dotfiles}' zsh $desired_runner_path"

# Read the current installed state
current_command=""
if [[ -f "$LAST_COMMAND_FILE" ]]; then
  current_command=$(cat "$LAST_COMMAND_FILE")
fi

# Compare and build the JSON output
ok=true
message="MOTD agent is up to date."
if [[ "$desired_command" != "$current_command" ]]; then
  ok=false
  message="MOTD configuration has changed. Run 'motd_update' to apply."
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 