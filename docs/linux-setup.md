# dotfiles

Config + one-shot setup for the `dev` box: a remote dev environment that you
reach over Tailscale and drive from a laptop or a phone. The setup scripts are
split into small modules so you can run what you want, when you want, and re-run
only the piece that broke.

```
setup-dev.sh            driver — asks y/N before each module
setup/common.sh         helpers + shared config (colors, sudo keepalive)
setup/0N-name.sh        one module per concern, each runs standalone
*.dotfiles              the config, installed by module 10
aliases.zsh             your aliases, auto-sourced by oh-my-zsh
```

Run:

```bash
./setup-dev.sh                        # ask before every step
./setup-dev.sh --github you@x.com     # pass flags, still asks per step
./setup-dev.sh -y                     # everything, no prompts
bash setup/05-zsh.sh                  # a single module, by hand
```

Changed files are replaced from this repo (old versions go to
`~/.dotfiles.backup`). Nothing is pulled from the Mac.

---

## What each module installs

### 01 — hostname
Sets the machine hostname (`--hostname NAME`) in `/etc/hostname` and `/etc/hosts`.

### 02 — base packages
Apt full-upgrade + the everyday toolbelt, then enables unattended security
upgrades.

| package | why |
|---|---|
| zsh, git, curl, wget, gnupg, ca-certificates, openssh-server | the stack everything else sits on |
| tmux, vim, neovim, nano, less | editors + terminal multiplexer |
| htop, btop, ncdu, tree, jq | system/dir/JSON inspection |
| ripgrep, fd-find, bat, fzf | modern grep/find/cat/fuzzy-find |
| build-essential, python3, python3-pip, python3-venv, pipx | compile + Python tooling |
| unzip, zip, rsync, git-lfs | archives, sync, large files |
| dnsutils, iputils-ping, netcat, traceroute, nmap, net-tools | network debugging |
| xclip, xdotool | clipboard + X automation |
| smartmontools, unattended-upgrades | disk health + auto security patches |

After install, symlinks `bat`→`batcat` and `fd`→`fdfind` (Ubuntu's renamed
versions) so dotfiles can call the real names.

### 03 — tools your dotfiles depend on
These are the ones the dotfiles actually call. If one is missing, `ls`/`git`
error or silently degrade — this module is what keeps the shell config honest.

| tool | your dotfile calls it as | what it replaces |
|---|---|---|
| eza | `ls` (zshrc.linux: `eza --icons`) | ls |
| bat | `cat` (via `~/.local/bin/bat`) | cat |
| duf | `df` | df |
| du-dust | `du` (binary `dust`) | du |
| procs | `ps` | ps |
| btop | `top` (module 02) | top |
| fd (fdfind) | `find` | find |
| ripgrep | `grep` | grep |
| fzf | interactive fuzzy find | |
| zoxide | `cd` (via `z`) | cd |
| atuin | shell history (synced, searchable) | history |
| direnv | per-directory env | |
| git-delta | git's `core.pager` — git **refuses to run** if it's absent | git pager |
| tldr | man pages | man |
| httpie | `http` | curl |

Note: `git-delta` is non-negotiable — your `.gitconfig` sets it as the pager,
so a missing binary breaks every git command. `dust`, `procs` and `delta`
come from the `03` loop; anything the apt repos don't ship is warned about and
needs a GitHub release or `cargo install`.

### 04 — GitHub CLI
`gh` from GitHub's apt repo (for auth, keys, PRs).

### 05 — zsh + oh-my-zsh
Installs oh-my-zsh (keeps your `.zshrc`), the autosuggestions and
syntax-highlighting plugins, and sets the default shell to zsh. Prompt stays
`robbyrussell` (ships with oh-my-zsh; no framework installed on purpose).

### 06 — Node runtime
nvm + the latest `NODE_MAJOR` (default 22) + pnpm via corepack. nvm rather
than apt so global npm installs need no sudo.

### 07 — CLI agents
The reason the box exists.

| agent | install | what |
|---|---|---|
| Claude Code | `npm i -g @anthropic-ai/claude-code` | Anthropic's terminal agent |
| opencode | `curl -fsSL https://opencode.ai/install` | open-source terminal agent |
| herdr | `curl -fsSL https://herdr.dev/install.sh` | agent runtime that owns the terminals — sessions survive reboot, reattach from any device |
| pi | `npm i -g @earendil-works/pi-coding-agent` | minimal terminal coding harness; extensions/skills/themes via `pi install` |

⚠️ herdr is young and owns your terminals — tmux is kept as the fallback.

### 08 — Tailscale
Installs the tailscale client. **Not connected here** — run
`sudo tailscale up --ssh` once so the box is reachable over the tailnet
without exposing any port. RustDesk (module 18) works over the same tailnet.

### 09 — GitHub SSH key + commit signing
One ed25519 key per machine, used for both GitHub auth and commit signing
(no GPG). Generates `~/.ssh/id_ed25519_github`, wires up `~/.ssh/config`,
`allowed_signers`, and signs commits/tags. Needs `--github EMAIL`. If `gh` is
logged in the key is uploaded as both an auth and a signing key — **must be
added twice**, they're separate lists.

### 10 — dotfiles from this repo
Copies `.zshrc .zshrc.linux .zprofile .gitconfig .bashrc .bash_profile
.profile .gitignore_global` into `~`, and `aliases.zsh` into
`~/.oh-my-zsh/custom/` (omz auto-sources everything there). Previous versions
land in `~/.dotfiles.backup`. Re-asserts commit signing if module 09 ran first.

### 11 — never sleep
Masks sleep/suspend/hibernate and ignores the lid — an always-on box.
XFCE's Power Manager still needs "everything Never" by hand.

### 12 — Ghostty (default terminal)
Installs Ghostty (Ubuntu 26.04+ ships it in universe; falls back to the
mkasberg PPA) and makes it the default terminal for XFCE and
`x-terminal-emulator`. Writes a minimal `~/.config/ghostty/config`
(JetBrainsMono Nerd Font + Catppuccin). Ctrl+C stays SIGINT.

### 13 — Mac-style keys everywhere (Toshy)
The Cmd-everywhere solution. App-aware: Cmd+C copies in the browser/editor and
becomes Ctrl+Shift+C inside a terminal (Ctrl+C is never touched). Cmd+Tab
switches windows, Cmd+C/V/X/A work globally. Also sets F-keys to F1–F12
(`hid_apple fnmode=2`) and installs an autostart entry
(`~/.local/bin/scroll-natural.sh`) that re-applies **Mac-style natural trackpad
scrolling** at every login — XFCE's own mouse toggle otherwise reverts at the
next session. Needs a logout.

### 14 — VS Code
From Microsoft's apt repo. Settings come via **Settings Sync**, never a copied
`settings.json`.

### 15 — desktop
JetBrainsMono Nerd Font (needed by `eza --icons` or every listing shows a tofu
box), Yaru/Papirus themes, Inter, and XFCE font rendering/compositor tweaks.

### 16 — trackpad gestures
libinput-gestures: 3-finger swipe to switch workspaces. Group membership
applies next login.

### 17 — Docker CE
For running risky things in isolation, with log rotation in `daemon.json`.
Docker group applies to new logins. Containers are **not** a hard security
boundary.

### 18 — RustDesk
Screen sharing over the tailnet. Tailnet only — never exposed.

---

## Could add later (not installed)

Ideas worth considering for a remote + AI box. Nothing here is installed yet.

**Remote access & sessions**
- `mosh` — SSH that survives network changes; the laptop's network drops don't
  kill your session. Best for phone driving.
- `tmate` — instant pair-session URLs (SSH into someone's terminal, no port
  config).
- `zellij` — tmux alternative, better UX for multiple agents.
- tmux-resurrect + tmux-continuum — auto-restore tmux sessions after reboot.
- `autossh` / `sshuttle` — persistent tunnels / VPN-over-SSH.
- `headscale` — self-hosted Tailscale coordination server if you ever want to
  stop depending on Tailscale's SaaS.

**Notifications (for long builds & agent blocked/idle)**
- `gotify` or `ntfy` — push the phone when a build finishes or an agent is
  blocked (herdr's docs suggest exactly this).

**Monitoring / health**
- `netdata` or `glances` — dashboard you can view over the tailnet.
- `sysstat` (sar/iostat/mpstat) — historical CPU/disk stats.
- `nvtop` — GPU monitoring (only if it has a GPU).
- `lm-sensors` — temps/fan speeds.

**Backup & secrets**
- `restic` — encrypted backups (local or to a remote).
- `age` + `sops` — simple file encryption; `git-crypt` if you want secrets
  transparently in git.

**Security (belt-and-braces on a tailnet-only box)**
- `ufw` — firewall, allow only the tailnet interface (Tailscale wires itself
  in, but the extra rule is cheap).
- `fail2ban` — throttle brute-force on SSH.

**Dev tooling**
- `mise` — one tool to manage node/python/go versions (nvm alternative).
- `uv` — the fast Python package manager (works with pipx too).
- `ruff` (lint/format) — useful for agents writing Python.
- `watchexec` / `entr` — re-run commands when files change.
- `hyperfine` — benchmark commands.
- `gdu` — faster `ncdu`.
- `yq` — YAML's `jq`.
- `jless` — JSON pager.
- `hexyl` — hex viewer.
- `yazi` — modern terminal file manager.
- `fastfetch` — system info at login.
- `jj` (jujutsu) — a VCS that plays better with stacked commits.
- `podman` — rootless, daemonless Docker replacement; if Docker ever feels too
  heavy on this 8GB box, podman does most of the same without the always-on
  daemon. Worth trying before uninstalling Docker.

**Local AI**
- `ollama` — run local models for offline/private AI work.
- `llama.cpp` — if you want raw GGUF inference.

**Terminal niceties**
- `tealdeer` (tlrc) — faster tldr client.
- `viddy` — `watch` with better output.
- `chafa` — images in the terminal.
- `w3m` / `lynx` — terminal browsers for reading docs.
- `aria2` — fast parallel downloads.
- `gping` — graph pings.

**Remote VS Code**
- `code-server` — VS Code in the browser, served over the tailnet.
- Tailscale `serve`/`funnel` — publish a local port to the tailnet with zero
  config (needs no extra package).
