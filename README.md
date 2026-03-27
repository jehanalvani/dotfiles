# dotfiles

Environment config and dotfiles, kept consistent across machines.

---

## Boy why you doing all this you're doing too much

Well, maybe. But if you work in a technical job and in Unix-based systems, over the years the accumulation of little tips and tricks in your dotfiles becomes so personalized that not having them feels like rock-climbing with one arm tied behind your back. Maybe I can make it up the rock face, but it'd be a hell of a lot easier if I had both arms. When i read of about the [bare git repo technique](https://www.atlassian.com/git/tutorials/dotfiles), it clicked. I could make my personal IP portable. And I've been improving it ever since.

The goal has always been to minimize the amount of time it takes for me to get started on a new machine, be it personal or otherwise, and to do so securely. In the most recent version, I've added `~/.claude` config with API helpers to allow for folder-based seperation of my various Claude contexts - work and personal. If you don't need all of this, fork it and take what you want. I hope it's useful.

---

## How it works

Uses the [bare git repo technique](https://www.atlassian.com/git/tutorials/dotfiles): a git repo whose working tree is `$HOME` itself, tracked via a `config` alias. No symlinks, no extra tooling, no install framework — files live where the shell expects them.

```sh
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

```
  GitHub                          $HOME
  ┌─────────────────┐             ┌──────────────────────────────┐
  │  you/dotfiles   │──clone──▶   │  ~/.dotfiles/   (git only)   │
  │  (this repo)    │             │  ~/.zshrc                    │
  └─────────────────┘             │  ~/.gitconfig                │
                                  │  ~/.aliases                  │
                                  │  ~/.ssh/config               │
                                  │  ~/.claude/                  │
                                  └──────────────────────────────┘

  No symlinks. No install framework. Files just live where they always did.
  The only difference: `config status` instead of `git status`.
```

---

## Public / private split

Most dotfiles tutorials end up either fully public (and full of personal details) or fully private (and useless as a reference). This repo solves that with a two-repo overlay pattern:

- **This repo** — generic and shareable. Shell config, tool setup, structural patterns. Safe to clone on any machine or show to anyone.
- **`dotfiles-private`** (private repo) — personal identity, employer- or contract-related config, private host entries. Layers on top via `.local` includes that each public file sources if present.

```
  GitHub (public)              GitHub (private)
  ┌─────────────────┐          ┌──────────────────────┐
  │  you/dotfiles   │          │  you/dotfiles-private │
  │                 │          │                       │
  │  .zshrc         │          │  .gitconfig.local     │
  │  .gitconfig     │          │  .gitconfig-work      │
  │  .ssh/config    │          │  .ssh/config.local    │
  │  .aliases       │          │  statusline-colors.sh │
  │  statusline...  │          │  api-accounts.json    │
  │                 │          │                       │
  │  ← show anyone  │          │  ← never public       │
  └────────┬────────┘          └──────────┬────────────┘
           │                              │
           └──────────┬───────────────────┘
                      ▼
                   $HOME
```

The key design principle: every file in this repo works standalone. The private overlay only adds — it never requires the public files to be aware of what's in it. Clone just this repo and you get a functional environment; clone both and you get the full personal setup.

The `.local` pattern is the seam between them:

```
  .gitconfig                          .gitconfig.local  (private)
  ┌────────────────────────────┐      ┌───────────────────────────────┐
  │ [credential "github.com"]  │      │ [user]                        │
  │   helper = gh auth ...     │      │   name  = Your Name           │
  │                            │      │   email = you@personal.com    │
  │ [include]                  │      │                               │
  │   path = ~/.gitconfig.local│─────▶│ [includeIf "gitdir:~/work/"]  │
  └────────────────────────────┘      │   path = ~/.gitconfig-work    │
                                      └───────────────────────────────┘

  .ssh/config                         .ssh/config.local  (private)
  ┌────────────────────────────┐      ┌───────────────────────────────┐
  │ Include ~/.ssh/config.local│─────▶│ Host work-gitlab              │
  │                            │      │   HostName gitlab.com         │
  │ Host github.com            │      │                               │
  │   IdentityFile ~/.ssh/...  │      │ host *.local                  │
  │                            │      │   User yourname               │
  │ Host *                     │      └───────────────────────────────┘
  │   IdentityAgent 1password  │
  └────────────────────────────┘
```

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

```
  1. Clone public          2. Clone private          3. Done
  ─────────────────        ──────────────────        ──────────────────
  git clone --bare         git clone                 config checkout
  .../dotfiles             .../dotfiles-private      install.sh
  ~/.dotfiles              ~/.dotfiles-private
                                │
                                └── install.sh creates symlinks
                                    for all .local files
```

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
