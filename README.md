# Automated macOS Setup

Single command batteries-included macOS development machine setup: shell, terminal, editor, git, and some useful apps. Everything is **idempotent**, you can re-run it any time to update your machine with the latest config.

## Using it

### Quick start

```sh
git clone https://github.com/lowski/macos-setup.git
cd macos-setup
./setup.sh
```

That's it. `setup.sh` installs the bare minimum to get Ansible running, then hands off to the playbook.

> **Mac App Store apps:** sign in to the App Store first — Slack and Magnet install via `mas`, which requires an active session.
>
> **Setting the default login shell:** disabled by default. If you want fish as your login shell, run with `--ask-become-pass` since `chsh` needs sudo.

### What you get

| Role | What it sets up |
|------|-----------------|
| `utilities` | Raycast, 1Password + CLI (casks), Magnet (App Store) |
| `shell` | fish shell, ghostty terminal, eza, zoxide, fisher plugins, custom functions |
| `git` | git + gh (Homebrew), managed `~/.gitconfig` block (identity left to you) |
| `editor` | Cursor & Zed (casks), Claude Code CLI, synced Cursor settings/keybindings/extensions, Zed keymap |
| `productivity` | Superhuman (cask), Slack (App Store) |

After the first run, set your git identity (intentionally not managed for you):

```sh
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

### Re-running

The playbook is safe to run any time — it reconciles your machine back to this configuration without side effects:

```sh
ansible-playbook site.yml
```

---

## Working on the project

For changing what this repo installs or how it's structured.

### How it works

```
setup.sh ──▶ Homebrew ──▶ pipx ──▶ ansible ──▶ ansible-playbook site.yml
```

The bootstrap chain in `setup.sh` is strictly linear and runs before any Ansible task. From there, `site.yml` maps `localhost` to a list of roles — read it as a table of contents.

- **`setup.sh`** — bootstrap only (Homebrew → pipx → ansible). Idempotent; skips anything already installed.
- **`site.yml`** — the playbook. Lists the roles to apply.
- **`roles/`** — one role per *goal*, not per install mechanism. Each role ([`utilities`](roles/utilities), [`shell`](roles/shell), [`git`](roles/git), [`editor`](roles/editor), [`productivity`](roles/productivity)) owns its install, config, and files so a capability can be added or removed as a unit.

### Customizing

Package and plugin lists live in each role's `defaults/main.yml` — edit those, not the task files. For example, to add a Homebrew formula to the shell, append to `shell_formulae` in `roles/shell/defaults/main.yml`.

### Capturing live config back into the repo

The `editor` role syncs Cursor config in both directions. To pull your *current* Cursor settings, keybindings, and extension list back into the repo:

```sh
ansible-playbook site.yml --tags capture
```

This rewrites `roles/editor/files/cursor/` from the live install so the repo stays the single source of truth.

### Conventions

- **Group by goal, never by mechanism.** A role is a capability (`shell`, `git`), not a tool (`homebrew`, `dotfiles`). Roles freely mix brew, casks, templates, and `defaults write` to achieve their goal.
- **Data separate from logic.** Generic logic lives in `tasks/`; the lists you edit often live in `defaults/main.yml`.
- **Idempotency via modules.** Prefer real modules (`homebrew`, `copy`, `lineinfile`) over `shell`/`command`; guard any unavoidable shell with `creates:` / `when:` / `changed_when:`.
- **No bootstrap roles.** The Xcode CLT → brew → pipx → ansible chain is guaranteed by `setup.sh`. Roles should assume these are installed.
- **Never commit credentials, keys, or env files.**
