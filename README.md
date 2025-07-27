# Zsh MOTD Plugin

A highly configurable, asynchronous "Message of the Day" (MOTD) plugin for Zsh. It performs various system checks in the background and displays a fast, cached status report when you open a new shell, ensuring no impact on your shell's startup time.

## Features

- **Asynchronous by Default:** All checks run on a cron schedule in the background. Your shell launch is never delayed by slow checks (e.g., network requests).
- **Highly Configurable:** Control which checks run, their order, the update frequency, and the visual output, all from your `.zshrc`.
- **Dynamic Content:** In addition to cached checks, you can run any arbitrary command (like an ASCII art banner) as part of your MOTD.
- **Self-Healing Cron Job:** The plugin automatically manages its own background agent via cron and will prompt you to update it if your configuration changes.
- **Extensible:** Adding new checks is as simple as creating a new script that outputs a standard JSON format.

## Dependencies

- `zsh`: The shell this plugin is built for.
- `jq`: Used to parse the JSON state files.
- `cron`: The background scheduler used to run the checks.

## Installation

There are two ways to install the plugin: via Zinit (recommended) or by sourcing it manually.

### With Zinit (Recommended)

This is the cleanest method if you are already using Zinit. It handles path management automatically.

1.  Place the `zsh-motd` directory inside a parent directory that you use for local Zinit plugins (e.g., `~/.config/zsh/zsh-plugins/`).
2.  Add the following line to your `.zshrc`, pointing to the **parent** directory:

```zsh
# Load the MOTD plugin from a local directory
zinit ice as"program"
zinit light your-local-plugins-dir/zsh-motd
```

### Manual Installation

This plugin is designed to be sourced directly from your `.zshrc` file.

1.  Clone this repository or place it in your dotfiles.
2.  Add the following to your `.zshrc`:

```zsh
# Source the MOTD plugin which defines the motd_run function.
if [[ -f "/path/to/your/dotfiles/zsh-plugins/zsh-motd/zsh-motd.plugin.zsh" ]]; then
  source "/path/to/your/dotfiles/zsh-plugins/zsh-motd/zsh-motd.plugin.zsh"
  # Run the display function.
  motd_run
fi
```

## Configuration

All configuration is done by setting environment variables in your `.zshrc` **before** you source the plugin.

### Main Configuration

- `MOTD_CRON_SCHEDULE`: Sets the cron schedule for the background runner.
  - **Default:** `"*/15 * * * *"` (Every 15 minutes)
  - **Example:** `export MOTD_CRON_SCHEDULE="*/5 * * * *"`

- `MOTD_DOTFILES_DIR`: The absolute path to your dotfiles repository.
  - **Required for:** The `dotfiles` check and for the plugin to find its runner script.
  - **Example:** `export MOTD_DOTFILES_DIR="$HOME/dotfiles"`

- `MOTD_PROJECTS_DIR`: The absolute path to the directory containing your project repositories.
  - **Required for:** The `projects` check.
  - **Example:** `export MOTD_PROJECTS_DIR="$HOME/src"`

- `MOTD_DISK_THRESHOLD`: The usage percentage at which the `system` check will show a warning.
  - **Default:** `90`
  - **Example:** `export MOTD_DISK_THRESHOLD=85`

### Check Configuration

- `MOTD_CHECKS`: An array that defines which checks to run and in what order they appear.
  - **Cached Checks:** Simply use the name of the check script (e.g., `"brew"`).
  - **Dynamic Commands:** Prefix any shell command with `"cmd:"` to have it run on every shell launch without caching.

  ```zsh
  # Example MOTD_CHECKS configuration
  export MOTD_CHECKS=(
    # Run a dynamic command to show a banner
    "cmd:figlet -l \$(hostname) | lolcat"
    "cmd:echo" # Adds a blank line

    # Run the cached checks
    "cron"
    "dotfiles"
    "projects"
    "brew"
    "macos"
    "system"
    "ssh"
    "github"
    "gcloud"
  )
  ```

### Rendering Configuration

- `MOTD_SHOW_SUCCESS`: Set to `"true"` to show messages for successful checks, or `"false"` to only show warnings.
  - **Default:** `"true"`
  - **Example:** `export MOTD_SHOW_SUCCESS="false"`

- `MOTD_SUCCESS_EMOJI`: The emoji to display for a successful check.
  - **Default:** `"✅"`
  - **Example:** `export MOTD_SUCCESS_EMOJI="👍"`

- `MOTD_FAILURE_EMOJI`: The emoji to display for a failed check or warning.
  - **Default:** `"⚠️"`
  - **Example:** `export MOTD_FAILURE_EMOJI="🚨"`

## Usage

### `motd_update`

This function installs or updates the background cron job. The plugin will automatically detect when your configuration has changed and prompt you to run this, but you can also run it manually at any time.

```sh
motd_update
```

## Available Checks

- `cron`: Checks if the cron job configuration is out of date.
- `dotfiles`: Checks for uncommitted changes, and commits ahead/behind the remote in your dotfiles repo.
- `projects`: Checks for uncommitted changes in any git repository within `MOTD_PROJECTS_DIR`.
- `brew`: Checks for pending Homebrew updates.
- `macos`: (macOS only) Checks for pending macOS software updates.
- `system`: Checks for low disk space.
- `ssh`: Checks if the SSH agent has any identities loaded.
- `github`: Checks if the `gh` CLI is authenticated.
- `gcloud`: Checks if the `gcloud` CLI is authenticated.

## License

[MIT](./LICENSE) 