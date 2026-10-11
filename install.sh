#!/usr/bin/env bash
# Bootstrap a new Mac.
#
#   ./install.sh                 run every step, in order
#   ./install.sh link vscode     run only the named steps
#
# Every step is safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUBY_VERSION="3.3.4"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ALL_STEPS=(xcode brew ohmyzsh link ssh gh runtimes vscode claude)

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

load_brew() {
  if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
}

# link <path in repo> <target>: symlink, backing up whatever was there.
link() {
  local src="$REPO/$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then return; fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/"
    echo "  backed up $dst -> $BACKUP_DIR/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  linked $dst"
}

step_xcode() {
  if xcode-select -p >/dev/null 2>&1; then return; fi
  log "Installing Xcode Command Line Tools — click Install in the dialog"
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
}

step_brew() {
  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  load_brew
  log "Installing Brewfile packages"
  brew bundle --file="$REPO/Brewfile"
}

step_ohmyzsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then return; fi
  log "Installing oh-my-zsh"
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}

step_link() {
  log "Linking dotfiles"
  link zsh/zshrc          "$HOME/.zshrc"
  link zsh/zprofile       "$HOME/.zprofile"
  link zsh/zshenv         "$HOME/.zshenv"
  link git/gitconfig      "$HOME/.gitconfig"
  link git/ignore         "$HOME/.config/git/ignore"
  link vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  link ssh/config         "$HOME/.ssh/config"
}

step_ssh() {
  local key="$HOME/.ssh/id_ed25519"
  if [[ ! -f "$key" ]]; then
    log "Generating SSH key (used for GitHub auth and commit signing)"
    ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$key"
  fi
  ssh-add --apple-use-keychain "$key" 2>/dev/null || true
}

step_gh() {
  load_brew
  if ! gh auth status >/dev/null 2>&1; then
    log "Logging in to GitHub"
    gh auth login --web --git-protocol ssh --skip-ssh-key \
      --scopes admin:public_key,admin:ssh_signing_key
  fi
  log "Uploading SSH key to GitHub (auth + signing)"
  local pub="$HOME/.ssh/id_ed25519.pub" title
  title="$(scutil --get ComputerName)"
  gh ssh-key add "$pub" --title "$title" --type authentication 2>&1 || true
  gh ssh-key add "$pub" --title "$title (signing)" --type signing 2>&1 || true
}

step_runtimes() {
  load_brew
  log "Python: latest stable via uv (provides python/python3 in ~/.local/bin)"
  uv python install --default

  log "Ruby $RUBY_VERSION via rbenv"
  eval "$(rbenv init - bash)"
  rbenv install --skip-existing "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
}

step_vscode() {
  load_brew
  log "Installing VS Code extensions"
  local ext
  grep -Ev '^[[:space:]]*(#|$)' "$REPO/vscode/extensions.txt" | while read -r ext; do
    code --install-extension "$ext"
  done
}

step_claude() {
  if [[ -f "$HOME/.claude/settings.json" ]]; then return; fi
  log "Copying Claude Code settings"
  mkdir -p "$HOME/.claude"
  cp "$REPO/claude/settings.json" "$HOME/.claude/settings.json"
}

if [[ $# -eq 0 ]]; then steps=("${ALL_STEPS[@]}"); else steps=("$@"); fi
for s in "${steps[@]}"; do
  if ! declare -F "step_$s" >/dev/null; then
    echo "Unknown step: $s (valid: ${ALL_STEPS[*]})" >&2
    exit 1
  fi
done
load_brew
for s in "${steps[@]}"; do "step_$s"; done

log "Done. Open a new terminal window to load the new shell config."
