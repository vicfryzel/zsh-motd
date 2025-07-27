#!/bin/zsh

# --- MOTD Update Function (User-facing) ---
motd_update() {
  echo "⚙️  Updating MOTD background agent..."
  
  if [[ -z "$MOTD_DOTFILES_DIR" ]]; then
    echo "MOTD Plugin Error: MOTD_DOTFILES_DIR is not set." >&2
    return 1
  fi

  local MOTD_LAST_COMMAND_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/motd/cron_last_installed_command"
  # The runner script is now part of the plugin itself.
  local runner_script_path="$MOTD_DOTFILES_DIR/zsh-plugins/zsh-motd/run_checks.sh"
  local cron_schedule="${MOTD_CRON_SCHEDULE:-*/15 * * * *}"
  # Redirect all output to /dev/null to prevent cron from sending mail.
  local cron_command="$cron_schedule MOTD_DOTFILES_DIR='$MOTD_DOTFILES_DIR' zsh $runner_script_path >/dev/null 2>&1"
  
  # Atomically update the crontab by removing the old entry and adding the new one.
  # The use of a unique comment identifier ensures we only remove the correct line.
  local cron_identifier="# ZSH_MOTD_PLUGIN"
  local cron_entry="$cron_command $cron_identifier"
  local new_crontab
  new_crontab=$( (crontab -l 2>/dev/null | grep -v "$cron_identifier"; echo "$cron_entry") )
  
  # Pipe the new crontab content to the crontab command and check for errors
  if ! echo "$new_crontab" | crontab - >/dev/null 2>&1; then
    echo -e "\n${COLOR_YELLOW}⚠️  Automatic cron job installation failed.${COLOR_NONE}"
    echo "This is common on modern macOS due to security permissions."
    echo "To fix this, please:"
    echo "  1. Go to System Settings > Privacy & Security > Full Disk Access."
    echo "  2. Enable access for your terminal application (e.g., Terminal, iTerm, Ghostty)."
    echo "  3. Rerun 'motd_update'."
    return 1
  fi
  
  mkdir -p "$(dirname "$MOTD_LAST_COMMAND_FILE")"
  # We store the command without the identifier for the cron check logic.
  echo "$cron_command" > "$MOTD_LAST_COMMAND_FILE"
  
  # Manually run the cron check to update its status immediately
  if [[ -x "$MOTD_DOTFILES_DIR/zsh-plugins/zsh-motd/checks/cron.sh" ]]; then
    ("$MOTD_DOTFILES_DIR/zsh-plugins/zsh-motd/checks/cron.sh")
  fi
  
  echo "✅  MOTD agent updated successfully. New status will appear on the next shell."
}

# --- Main MOTD Display Engine ---
motd_run() {
  # Create a sanitized, local scope for options. The `local_options` ensures
  # that any option changes are local to this function and automatically reverted.
  emulate -L zsh
  setopt local_options no_xtrace

  # Define a temp file and ensure it's cleaned up when the function exits.
  local temp_file="/tmp/motd_.$$.tmp"
  trap 'rm -f "$temp_file"' EXIT

  source "${${(%):-%x}:A:h}/lib/formatting.sh"
  local STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
  local MESSAGES=""
  local any_issues=false

  # --- Get Config ---
  local show_success="${MOTD_SHOW_SUCCESS:-true}"
  local success_emoji="${MOTD_SUCCESS_EMOJI:-✅}"
  local failure_emoji="${MOTD_FAILURE_EMOJI:-⚠️}"
  
  # --- Generic Rendering Loop ---
  for item in "${MOTD_CHECKS[@]}"; do
    if [[ $item == "cmd:"* ]]; then
      # It's a command to be executed directly.
      local command_to_run=${item#cmd:}
      eval "$command_to_run"
    else
      # It's a cached check name.
      local json_file="$STATE_DIR/${item}.json"
      if [[ ! -f "$json_file" ]]; then continue; fi

      # Use a temp file to avoid tracing on the command substitution.
      jq -j '.ok, "\u0000", .message' "$json_file" > "$temp_file" 2>/dev/null
      local output=$(cat "$temp_file")
      
      local is_ok=${output%%$'\0'*}
      local message=${output#*$'\0'}

      if [[ "$is_ok" == "false" ]]; then
        any_issues=true
        MESSAGES+="${COLOR_YELLOW}${failure_emoji} ${message}${COLOR_NONE}\n"
      elif [[ "$show_success" == "true" ]]; then
        MESSAGES+="${COLOR_GREEN}${success_emoji} ${message}${COLOR_NONE}\n"
      fi
    fi
  done

  # --- Final Display for cached checks ---
  if [[ -n "$MESSAGES" ]]; then
      echo -e "${MESSAGES%\\n}"
  elif [[ "$show_success" == "false" && "$any_issues" == "false" ]]; then
      echo "${COLOR_GREEN}${success_emoji} All systems clear.${COLOR_NONE}"
  fi
} 