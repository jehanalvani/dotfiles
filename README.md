# dotfiles

Environment config and dotfiles, kept consistent across machines.

Uses the [bare git repo technique](https://www.atlassian.com/git/tutorials/dotfiles) — no symlinks, no extra tooling. Files are tracked directly from `$HOME` using a `config` alias.

Personal identity, employer-specific config, and private host entries live in a companion private repo (`dotfiles-private`) that layers on top via `.local` includes.

---

## What's included

| File | Purpose |
|------|---------|
| `.zshrc`, `.zprofile`, `.aliases` | Shell config |
| `.gitconfig` | Global git config + credential helpers. Identity via `~/.gitconfig.local` (private) |
| `.ssh/config` | SSH config skeleton. Private hosts via `~/.ssh/config.local` (private) |
| `.claude/credential-helper.sh` | Claude Code API key helper (1Password-backed, per-directory) |
| `.claude/statusline-command.sh` | Claude Code status line — model, context %, account (color-coded), git branch, dir, session cost |

Account colors are defined in `~/.claude/statusline-colors.sh` (private overlay) — the script works without it, just without color branding.

---

## New machine setup

### 1. Clone public dotfiles

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

### 3. Clone private overlay (personal machines only)

```sh
git clone git@github.com:jehanalvani/dotfiles-private $HOME/.dotfiles-private
bash ~/.dotfiles-private/install.sh
```

### 4. Install dependencies

```sh
brew install glab
gh auth setup-git          # GitHub HTTPS credential helper
```

### 5. Claude Code API key helper

Per-project API keys live in `.claude/auth-keys.json` within each project directory:

```json
{
  "key": "op://Vault/Item/credential",
  "op_account": "account.1password.com"
}
```

For directories without a local `auth-keys.json`, the global `~/.claude/api-accounts.json` is used as fallback (provided by the private overlay). An empty `key` falls back to Claude Pro OAuth.

To verify a directory's key resolves correctly:

```sh
bash ~/.claude/credential-helper.sh --test
```

---

## Day-to-day usage

```sh
config status
config add ~/.some/new/file
config commit -m "Add some config"
config push
```
