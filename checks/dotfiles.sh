#!/bin/zsh

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/motd"
JSON_FILE="$STATE_DIR/dotfiles.json"
mkdir -p "$STATE_DIR"

if ! command -v jq &> /dev/null; then exit 1; fi

DOTFILES_DIR="${MOTD_DOTFILES_DIR:-$HOME/dotfiles}"
cd "$DOTFILES_DIR" || exit

local parts=()
# 1. Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
  parts+=("uncommitted changes")
fi

# 2. Check for commits ahead of remote
local ahead_count
ahead_count=$(git rev-list --count @{u}..HEAD 2>/dev/null)
ahead_count=${ahead_count:-0}
if (( ahead_count > 0 )); then
  parts+=("$ahead_count commits ahead")
fi

# 3. Check for commits behind remote
if command -v gh &> /dev/null && gh auth status >/dev/null 2>&1; then
    local REPO_PATH
    REPO_PATH=$(git remote get-url origin | sed -E 's/.*github.com[:\/](.*)\.git/\1/')
    local DEFAULT_BRANCH
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@' 2>/dev/null)
    if [[ -n "$DEFAULT_BRANCH" ]]; then
      local REMOTE_SHA
      REMOTE_SHA=$(gh api "repos/$REPO_PATH/branches/$DEFAULT_BRANCH" --jq .commit.sha 2>/dev/null)
      local LOCAL_REMOTE_SHA
      LOCAL_REMOTE_SHA=$(git rev-parse "origin/$DEFAULT_BRANCH" 2>/dev/null)
      if [[ -n "$REMOTE_SHA" && "$REMOTE_SHA" != "$LOCAL_REMOTE_SHA" ]]; then
          parts+=("updates available")
      fi
    fi
fi

# --- Message Construction ---
local ok=true
local message="Dotfiles are up to date."
if (( ${#parts[@]} > 0 )); then
  ok=false
  message="Dotfiles: ${(j:, :)parts}."
fi

jq -n --argjson ok "$ok" --arg msg "$message" \
  '{"ok": $ok, "message": $msg}' > "$JSON_FILE" 