# dotfiles

Environment config and dotfiles, kept consistent across machines.

---

## How it works

Uses the [bare git repo technique](https://www.atlassian.com/git/tutorials/dotfiles): a git repo whose working tree is `$HOME` itself, tracked via a `config` alias. No symlinks, no extra tooling, no install framework — files live where the shell expects them.

```sh
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Public / private split

Most dotfiles tutorials end up either fully public (and full of personal details) or fully private (and useless as a reference). This repo solves that with a two-repo overlay pattern:

- **This repo** — generic and shareable. Shell config, tool setup, structural patterns. Safe to clone on any machine or show to anyone.
- **`dotfiles-private`** (private repo) — personal identity, employer config, private host entries. Layers on top via `.local` includes that each public file sources if present.

The key design principle: every file in this repo works standalone. The private overlay only adds — it never requires the public files to be aware of what's in it. Clone just this repo and you get a functional environment; clone both and you get the full personal setup.

The `.local` pattern is the seam:
- `.gitconfig` ends with `[include] path = ~/.gitconfig.local` — identity and per-employer `includeIf` blocks live there
- `.ssh/config` starts with `Include ~/.ssh/config.local` — private hosts, internal IPs, employer SSH aliases
- `statusline-command.sh` sources `~/.claude/statusline-colors.sh` if present — account color branding lives there

---

## What's included

| File | Purpose |
|------|---------|
| `.zshrc`, `.zprofile`, `.aliases` | Shell config |
| `.gitconfig` | Global git config + credential helpers. Identity via `~/.gitconfig.local` (private overlay) |
| `.ssh/config` | SSH config skeleton. Private hosts via `~/.ssh/config.local` (private overlay) |
| `.claude/credential-helper.sh` | Claude Code API key helper (1Password-backed, per-directory) |
| `.claude/statusline-command.sh` | Claude Code status line — model, context %, account (color-coded), git branch, dir, session cost |

---

## New machine setup

### 1. Clone

```sh
git clone --bare https://github.com/jehanalvani/dotfiles $HOME/.dotfiles
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
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
gh auth setup-git    # GitHub HTTPS credential helper
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
