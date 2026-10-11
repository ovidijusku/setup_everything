# setup_everything

Dev environment for a fresh Mac (Apple silicon). It covers zsh with oh-my-zsh, Homebrew, Python (uv), Node, Go, Ruby (rbenv), Docker, VS Code, git and SSH.

## On the new Mac

1. Get this folder onto the new Mac, either by AirDrop/USB or with `git clone` (git comes with the Xcode CLT; the installer will offer to install it).
2. Run:

   ```bash
   cd ~/Documents/setup_everything && ./install.sh
   ```

   The steps run in this order, and each one can be re-run on its own (`./install.sh <step> ...`):

   | Step       | What it does |
   |------------|--------------|
   | `xcode`    | Xcode Command Line Tools |
   | `brew`     | Homebrew + everything in `Brewfile` |
   | `ohmyzsh`  | Clones oh-my-zsh |
   | `link`     | Symlinks `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.gitconfig`, `~/.config/git/ignore`, `~/.ssh/config` and the VS Code `settings.json` to this repo. Any existing file is moved to `~/.dotfiles-backup/<timestamp>/` |
   | `ssh`      | Creates `~/.ssh/id_ed25519` (it asks for a passphrase) and adds it to the Keychain |
   | `gh`       | `gh auth login`, then uploads the key to GitHub for authentication **and** commit signing |
   | `runtimes` | Latest Python via `uv python install --default`, Ruby 3.3.4 via rbenv |
   | `vscode`   | Installs `vscode/extensions.txt` |
   | `claude`   | Copies Claude Code `settings.json` if none exists |

3. Open a new terminal window.

### Manual follow-ups

- Launch **Docker Desktop** once to accept its terms and install the CLI helpers.
- Sign in to Chrome (bookmarks sync), Discord, Signal (link to your phone) and Claude.
- Put machine-specific or secret env vars in `~/.zshrc.local`. It isn't tracked.

## Before you wipe the old Mac

- Push or copy any project folders you still need (`~/Documents`, `~/workspace`, …).
- Leave the old `id_rsa` key on GitHub as a **signing** key, so old commits stay "Verified". You can remove its authentication entry once the new Mac works.
- If you want your old shell history, copy `~/.zsh_history` across.

## Day-to-day

- **New Homebrew package:** add it to `Brewfile`, then `./install.sh brew`.
- **New VS Code extension:** add it to `vscode/extensions.txt`, then `./install.sh vscode`.
- **Python projects:** `uv init`, `uv add <pkg>`, `uv run …`; CLI tools via `uv tool install <pkg>`.
- Edits to `~/.zshrc` etc. are edits to this repo, because they're symlinks. Commit them.

## Deliberately left out

The old Mac had a defense/UAV-focused setup, and none of that was carried over: ArduPilot, PX4/ROS/OSRF taps, QGroundControl, Betaflight, ExpressLRS, VESC Tool, gcc-arm-none-eabi, OpenOCD, STM32/Cortex-Debug extensions, hackrf, dartsim, orocos-kdl, gstreamer, opencv, Qt/PyQt, the GCP KMS SSH (`gssh`/`gscp`) setup, `ov_docker`, Android SDK. Also left out:

- **Toolchains/infra:** pyenv, conda, MacPorts (already broken on this macOS), rustup, cmake/ccache/clang-format, awscli, gcloud, terraform, flyctl, Homebrew `openssh`.
- **Apps:** Slack, Zoom, ChatGPT, Ollama, Goose, Tailscale, ZeroTier, RustDesk, TeamViewer, VNC, Wireshark, LibreOffice, Grammarly, XQuartz, Vagrant, CoolTerm.

Any of these can be added back with one line in `Brewfile` (`brew "name"` or `cask "name"`).
