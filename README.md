# dotfiles
Environment config and dot files that I like to keep consistent between systems.

Uses the [bare git repo technique](https://www.atlassian.com/git/tutorials/dotfiles) — no symlinks, no extra tooling. Files are tracked directly from `$HOME` using a `config` alias.

---

## What's included

| File | Purpose |
|------|---------|
| `.zshrc`, `.zprofile`, `.aliases` | Shell config |
| `.gitconfig` | Global git identity + per-directory includes |
| `.gitconfig-macrohealth` | MacroHealth git identity + GitLab credential helper |
| `.ssh/config` | SSH host entries (GitHub, GitLab, local hosts) |
| `.claude/credential-helper.sh` | Claude Code API key helper (1Password-backed, per-directory) |
| `.claude/api-accounts.json` | Directory → Anthropic account mapping |
| `.claude/settings.json` | Claude Code global settings |
| `.claude/statusline-command.sh` | Claude Code status line — model, context %, account (color-coded by org), git branch, dir, session cost |

---

## New machine setup

### 1. Clone

```sh
git clone --bare https://github.com/jehanalvani/dotfiles $HOME/.dotfiles
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

### 2. Checkout

```sh
config checkout
config config --local status.showUntrackedFiles no
```

If checkout fails due to existing files, back them up first:

```sh
mkdir -p ~/.config-backup && \
config checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | \
xargs -I{} sh -c 'mkdir -p ~/.config-backup/$(dirname {}) && mv $HOME/{} ~/.config-backup/{}'
config checkout
```

### 3. Install dependencies

```sh
brew install glab
gh auth setup-git          # GitHub HTTPS credential helper
glab auth login --hostname gitlab.com  # GitLab auth (pipe PAT from 1Password)
```

### 4. Claude Code API key helper

Per-project API keys live in `.claude/auth-keys.json` within each project directory:

```json
{
  "key": "op://Vault/Item/credential",
  "op_account": "account.1password.com"
}
```

For directories without a local `auth-keys.json`, the global `~/.claude/api-accounts.json` is used as fallback. An empty `key` falls back to Claude Pro OAuth.

To verify a directory's key resolves correctly:

```sh
bash ~/.claude/credential-helper.sh --test
```

### 5. SSH key for GitLab

Generate a MacroHealth-specific key, store it in 1Password (Employee vault), and add the public key to gitlab.com:

```sh
ssh-keygen -t ed25519 -C "jehan.alvani@macrohealth.com" -f ~/.ssh/macrohealth_gitlab_ed25519 -N ""
# Store private key in 1Password, then:
rm ~/.ssh/macrohealth_gitlab_ed25519
cat ~/.ssh/macrohealth_gitlab_ed25519.pub | pbcopy  # paste into gitlab.com → Preferences → SSH Keys
```

---

## Day-to-day usage

```sh
config status
config add ~/.some/new/file
config commit -m "Add some config"
config push
```
