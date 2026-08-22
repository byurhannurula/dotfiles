# dotfiles

Config and one-shot setup for a macOS daily driver and a Linux dev box.

Config files only. Setup scripts and machine captures live elsewhere and are
gitignored.

```
install.sh            the setup driver — asks before each group
shared/               config identical on both machines
  zshrc.common          shell core: oh-my-zsh, history, options, integrations
  aliases.zsh           aliases and functions, portable
  .gitconfig .zprofile  git and login-shell config
  opencode/             opencode agent config
macos/
  .zshrc                PATH and Homebrew; sources zshrc.common
  aliases.macos.zsh     defaults, lsof, brew, Rosetta
  Brewfile              41 formulae, 51 casks, 10 taps
  defaults.sh           system preferences
  ghostty/ vscode/ zed/ btop/
linux/
  .zshrc                PATH and clipboard shims; sources zshrc.common
  aliases.linux.zsh     apt, systemd, ss
  packages.txt          40 apt packages
claude/                 CLAUDE.md, settings.json, statusline
docs/                   packages.md, linux-setup.md
_legacy/                the previous repo and every earlier .zshrc
```

## Usage

```bash
git clone <this repo> ~/dev/dotfiles && cd ~/dev/dotfiles
./install.sh                    # ask before each group
./install.sh -y                 # accept everything
./install.sh --hostname bbn     # set the hostname non-interactively
```

Detects macOS or Linux from `uname` and picks the right files.

**Copies, never symlinks.** Edits in `~` stay local until you copy them back.
Anything replaced goes to `~/.dotfiles.backup/<timestamp>/`. Nothing is
deleted, and every group defaults to no.

## What it does, in order

Order matters on a fresh machine — each step depends on the ones before.

| # | Group | Does | Time |
|---|---|---|---|
| 1 | macOS defaults | Finder, Dock, pointer, screenshots | fast |
| 2 | hostname | all three macOS names, or `hostnamectl` | fast |
| 3 | packages | everything from the Brewfile / packages.txt | **20–40 min** |
| 4 | oh-my-zsh | the framework plus 4 plugins, optional `chsh` | ~1 min |
| 5 | shell config | `.zshrc`, `.zshrc.common`, aliases, git | fast |
| 6 | app config | ghostty, vscode, zed, btop | fast |
| 7 | vscode extensions | 18 extensions | ~2 min |
| 8 | AI agents | config, then install and verify claude + opencode | ~2 min |

Step 3 installs zsh, git, `code` and the GUI apps, so steps 4–8 all depend
on it. Step 1 runs first so no window opens with the wrong settings.

It bootstraps what a new Mac lacks: Xcode Command Line Tools (a GUI installer,
so it waits for you), Homebrew, and oh-my-zsh.

## What gets installed

### Shell tooling

Installed: `eza` `bat` `fzf` `ripgrep` `jq` `gh`

Every alias is guarded on the binary existing, so a missing tool leaves the
plain command alone.

18 more are listed commented in the Brewfile (`git-delta`, `duf`, `dust`,
`procs`, `fd`, `tldr`, `zoxide`, `direnv`, `atuin`, `mise`, `lazygit`, `yq`,
`httpie`, `hyperfine`, `watchexec`, `gping`, `trash`, `uv`). Uncomment one and
its alias appears on the next shell.

### AI agents

`opencode` and `claude-code` as CLIs; Claude desktop, opencode-desktop,
superwhisper and ollama as apps. Each authenticates on first run — no API key
is stored in this repo.

`herdr` and `pi` are not in brew; the Brewfile notes how to install them.

### CLI

| Group | Packages |
|---|---|
| Core | git, tree, wget, parallel, shellcheck, gitleaks, xmlstarlet, mas |
| Build | cmake, python@3.11, pnpm, openssl@1.1, argon2 |
| Mobile | cocoapods, fvm, gradle |
| Cloud | podman, azure-cli, cloudflared, terraform |
| Media | ffmpeg, graphicsmagick, poppler |
| Hardware | hidapi, minicom, nut, smartmontools, telnet |
| Misc | redis, watchman, mprocs, mole, lazyssh, otel-gui |

### Apps

| Group | Apps |
|---|---|
| Browsers | Brave, Chrome, Firefox |
| Editors | VS Code, Zed, Ghostty |
| Dev | OrbStack, TablePlus, MongoDB Compass, Cyberduck, ngrok, Android platform tools, Temurin 8/17/latest, tflint |
| Comms | Discord, Telegram, Viber |
| Productivity | Raycast, Obsidian, Raindrop, Paseo, Tiles, HiddenBar, AppCleaner, The Unarchiver, drawio, Jotter |
| Media | VLC, calibre, Transmission, IPTVnator |
| Hardware | BambuStudio, OrcaSlicer, RPi Imager, balenaEtcher, Silicon Labs VCP driver |
| System | BetterDisplay, MonitorControl, Stats, coconutBattery, Flux, AnyDesk, Home Assistant, YubiKey Authenticator |

### Linux

40 apt packages:

| Group | Packages |
|---|---|
| Base | zsh, git, curl, wget, gnupg, openssh-server, build-essential |
| Editors | tmux, vim, neovim, less |
| Inspection | htop, btop, ncdu, tree, jq |
| Shell tooling | eza, bat, fd-find, ripgrep, fzf |
| Python | python3, python3-pip, python3-venv, pipx |
| Network | dnsutils, ping, netcat, traceroute, nmap, net-tools |
| Desktop | xclip, xdotool |

Linux uses zsh and oh-my-zsh, same as the Mac. `.bashrc` is a fallback only.

## Not installed

Install these by hand:

| App | Why |
|---|---|
| Tailscale | App Store, in a `.localized` folder brew cannot match |
| Numbers, Pages, Xcode, Home Assistant | App Store — need `mas` and a signed-in account |
| Whisper Lite | your own app |
| Screendrop, SafeNet, BulsatcomTV, CuaDriver | not in brew |

`mas list` returns nothing on this machine because Spotlight indexing is off
and `mas` reads that index. The App Store lines in the Brewfile are commented
with their public IDs — verify with `mas search <name>` before relying on them.

## Secrets

None in this repo. SSH keys and passwords live in Bitwarden; each AI agent
authenticates on first run.

Raycast's `config.json` is deliberately excluded — it holds an access token
and no actual settings. Also excluded: `gh/hosts.yml` and `herdr/session.json`,
both of which carry live credentials.

## Day to day

```bash
./install.sh                    # re-run any group after editing a file
./macos/defaults.sh --dry       # preview system preference changes
brew bundle --file=macos/Brewfile          # packages only
brew bundle cleanup --file=macos/Brewfile  # what is installed but undeclared
```

To update the repo from the machine, copy the file back and commit — the
install direction is repo → `~`, never the reverse.

## Notes

- `shared/zshrc.common` holds everything identical between the two `.zshrc`
  files, so a shell fix is made once.
- `plugins=` must be set before `oh-my-zsh.sh` is sourced or the list is
  ignored. Both configs had that wrong before.
- PATH is one `path=()` block with `typeset -U`; re-sourcing cannot stack
  duplicates.
- macOS ships bash 3.2 and never updates it, so every script here is 3.2
  compatible: no associative arrays, no `mapfile`.
- Natural scrolling is **off** on the Mac and **on** on the Linux box. The two
  disagree deliberately; that setting cannot live in `shared/`.
