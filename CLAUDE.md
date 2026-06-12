# CLAUDE.md

Automated macOS dev machine setup via Ansible.

## Structure

- `setup.sh` — bootstraps Homebrew → pipx → ansible, then Ansible playbooks handle everything else.
- `site.yml` — the playbook; maps `localhost` to a list of roles. Reads as a table of contents.
- `roles/` — one role per **goal/concern**, not per install mechanism.

## Roles

- **Group by goal, never by mechanism.** A role is a capability (`shell`, `git`, `editor`),
  not a tool (`homebrew`, `dotfiles`). Each role owns its install *and* config *and* files so
  one concern lives in one folder and can be added/removed as a unit. A role may freely mix
  mechanisms (brew, casks, templates, `defaults write`) to achieve its goal.
- **Separate data from logic.** Task files hold generic logic; the things you edit often
  (package lists, plugin lists) live in `defaults/main.yml` and are injected via templates/vars.
- **No bootstrap roles.** Xcode CLT → brew → pipx → ansible is a strictly linear chain that
  `setup.sh` guarantees before any task runs. Roles may assume brew/casks work; never re-assert
  the bootstrap chain in a playbook.
- **Idempotency via modules.** Prefer real modules (`homebrew`, `copy`, `lineinfile`, `user`)
  over `shell`/`command`. If `shell` is unavoidable, guard it (`creates:`, a `stat` + `when:`,
  or `changed_when:`).
- Roles needing sudo (e.g. setting the default login shell) require `--ask-become-pass`.

## Rules

- **Everything must be idempotent.** Scripts, tasks, and playbooks must be safe to re-run without side effects.
- `setup.sh` stays minimal — only what's needed to get Ansible running. Machine state belongs in playbooks.
- Validate shell scripts before committing: `bash -n setup.sh`

## Secrets

Never commit credentials, keys, or env files. `.gitignore` covers `*.pem*`, `*secret`, `*.env*`. Use Ansible Vault for sensitive values.
