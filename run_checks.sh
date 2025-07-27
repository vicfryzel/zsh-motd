#!/bin/zsh

# --- MOTD Periodic Runner ---
# This script is intended to be run by cron on a cadence.
# Its only job is to run the checks and update their state files.
# It should be completely silent.

# 1. Determine the dotfiles directory.
if [[ -z "$MOTD_DOTFILES_DIR" ]]; then
  export MOTD_DOTFILES_DIR="${HOME}/dotfiles"
fi

# 2. Source the user's config to get all MOTD variables.
if [[ -f "$MOTD_DOTFILES_DIR/zsh/.zshrc" ]]; then
  source "$MOTD_DOTFILES_DIR/zsh/.zshrc"
fi

# 3. Find and run the checks based on the configured order.
CHECKS_DIR="$MOTD_DOTFILES_DIR/zsh-plugins/zsh-motd/checks"

# Run the cron check first to ensure it's always up-to-date.
if [[ -x "$CHECKS_DIR/cron.sh" ]]; then
  ("$CHECKS_DIR/cron.sh")
fi

for check_name in "${MOTD_CHECKS[@]}"; do
  if [[ "$check_name" == "cron" ]]; then continue; fi
  local check_script="$CHECKS_DIR/${check_name}.sh"
  if [[ -x "$check_script" ]]; then
    ("$check_script")
  fi
done 