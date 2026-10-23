# Recommended packages

The tools the shell config expects. Every alias in `shared/aliases.zsh` is
guarded on the binary existing, so nothing breaks if you skip a line — the
alias just does not appear.

Installed on bbn-mbp today: `btop`, `ripgrep`, `jq` only. Everything else
below is a gap.

## Core — the aliases in shared/aliases.zsh depend on these

| Tool | Replaces | brew | apt |
|---|---|---|---|
| eza | `ls` | `eza` | `eza` |
| bat | `cat` | `bat` | `bat` (binary is `batcat`) |
| git-delta | `diff`, git pager | `git-delta` | `git-delta` |
| duf | `df` | `duf` | `duf` |
| dust | `du` | `dust` | — (cargo) |
| procs | `ps` | `procs` | — (cargo) |
| btop | `top` | `btop` | `btop` |
| fd | `find` | `fd` | `fd-find` (binary is `fdfind`) |
| ripgrep | `grep` | `ripgrep` | `ripgrep` |
| tldr | `man` | `tldr` | `tldr` |

The set actually adopted is in `Brewfile`: **eza, bat, fzf, ripgrep,
jq, gh**. The rest are listed there commented out — uncomment to adopt one,
and its alias appears on the next shell.

```bash
brew bundle --file=Brewfile
```

## Shell integrations — wired up in shared/zshrc.common

| Tool | What |
|---|---|
| zoxide | `z <partial>` jumps to a frecent directory |
| fzf | Ctrl-R history search, Ctrl-T file search |
| direnv | per-directory env, auto-loaded on cd |
| atuin | history in SQLite, searchable, optionally synced |
| mise | one version manager for node/python/go |

All optional, all commented out in the Brewfile.

> **Node uses fnm, not mise.** fnm reads `.nvmrc` and is installed. mise only
> pays off when python and go versions also need managing per project.

## Worth having

| Tool | What |
|---|---|
| lazygit | full-screen git UI; faster than the alias set for anything non-trivial |
| gh | GitHub CLI — auth, PRs, key upload |
| jq / yq | JSON / YAML processors |
| httpie | `http GET example.com` — curl with sane defaults |
| hyperfine | benchmark a command properly, with warmup and stats |
| watchexec | re-run a command when files change |
| gping | ping with a graph |
| trash | `trash file` — undoable `rm` (macOS) |
| uv | fast Python package manager, replaces pip/pipx |

All optional except `gh` and `jq`, which are adopted.

## oh-my-zsh custom plugins

Three plugins in `plugins=` are not bundled and must be cloned:

```bash
ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone https://github.com/zsh-users/zsh-autosuggestions        "$ZC/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting    "$ZC/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-completions            "$ZC/plugins/zsh-completions"
git clone https://github.com/zsh-users/zsh-history-substring-search "$ZC/plugins/zsh-history-substring-search"
```

The rest (`git`, `docker`, `npm`, `z`, `extract`, `command-not-found`) ship
with oh-my-zsh.
