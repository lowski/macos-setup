#!/usr/bin/env bash
#
# Bootstrap script for setting up a new macOS development machine.
#
# Installs the minimum needed to run the Ansible playbooks in this repo:
#   - Homebrew
#   - pipx    (via Homebrew)
#   - ansible (in an isolated environment via pipx)
#
# The script is idempotent: re-running it skips anything already installed.
#
# Usage: ./setup.sh

set -euo pipefail

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; }

# Locate the Homebrew prefix for the current architecture and make `brew`
# available in this shell session.
load_brew_shellenv() {
  local brew_path
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$brew_path" ]; then
      eval "$("$brew_path" shellenv)"
      return 0
    fi
  done
  return 1
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1 || load_brew_shellenv; then
    info "Homebrew is already installed ($(brew --version | head -n1))."
    return
  fi

  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! load_brew_shellenv; then
    error "Homebrew installation appears to have failed; 'brew' not found."
    exit 1
  fi
}

install_pipx() {
  if command -v pipx >/dev/null 2>&1; then
    info "pipx is already installed ($(pipx --version))."
  else
    info "Installing pipx via Homebrew..."
    brew install pipx
  fi

  # Ensure pipx's bin directory is on PATH (idempotent).
  pipx ensurepath
  export PATH="$HOME/.local/bin:$PATH"
}

install_ansible() {
  if command -v ansible >/dev/null 2>&1; then
    info "ansible is already installed ($(ansible --version | head -n1))."
  else
    info "Installing ansible via pipx..."
    pipx install --include-deps ansible
  fi
}

run_playbook() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  info "Running Ansible playbook..."
  ansible-playbook "${script_dir}/site.yml"
}

main() {
  install_homebrew
  install_pipx
  install_ansible
  run_playbook

  info "Setup complete."
}

main "$@"
