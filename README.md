<div align="center">

# dotfiles

Shell, editor, agent and macOS config for my Macs and a Linux dev box.
One repo, linked into `~`, kept in sync with git.

[![ci](https://github.com/byurhannurula/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/byurhannurula/dotfiles/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)
![zsh](https://img.shields.io/badge/zsh-F15A24?logo=zsh&logoColor=white)
![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?logo=homebrew&logoColor=black)
![Claude Code](https://img.shields.io/badge/Claude_Code-D97757?logo=claude&logoColor=white)

</div>

<!-- screenshot: .github/assets/terminal.png -->

## Quick start

```bash
git clone git@github.com:byurhannurula/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh            # asks before each group, defaults to no
./install.sh status     # what this machine has, compared with the repo
./install.sh harden     # macOS security settings (sudo, asks each)
```

`install.sh` finds macOS or Linux from `uname` and picks the right files.
Other options: `-y` accepts every group, `--hostname my-mac` sets the hostname.

## How it stays in sync

Config files in `~` are **symlinks into this repo**. The repo is the live
config, so:

1. Change a setting on one machine. The change is now a git change.
2. Commit and push it.
3. `git pull` on the other machine. The change is live at once.

Read the diff before you pull, because nothing stands between a pull and
your shell.

- **Machine-only values** go in files that are not in the repo:
  `~/.gitconfig.local` (work email, another signing key) and `~/.zshrc.local`.
- **Backups:** anything that `install.sh` replaces moves to
  `~/.dotfiles.backup/<timestamp>/`. Nothing is deleted.
- **Copies, not links:** the Obsidian settings, because they live in a synced
  vault. The macOS system settings and `harden.sh` files are also copies,
  because they need sudo.
- **Broken links:** some apps save by replacing the file, which breaks the
  link. `./install.sh status` reports any file that should be a link.

## Layout

```
install.sh            setup: asks before each group
status.sh             read-only report: system, tools, security, links
Brewfile              macOS base: CLI, dev tools, work-safe apps
Brewfile.personal     macOS extras: chat, media, 3D printing, homelab
shared/               config for both systems
  zshrc.common          shell core: oh-my-zsh, history, options, integrations
  aliases.zsh           aliases and functions
  .gitconfig .zprofile .zshenv
  opencode/             opencode agent config
macos/
  .zshrc                PATH and Homebrew; sources zshrc.common
  aliases.macos.zsh     defaults, lsof, brew, Rosetta
  defaults.sh           system settings (--dry to preview)
  harden.sh sshd/       FileVault, firewall, Touch ID sudo, sshd keys-only
  ghostty/ vscode/ zed/ btop/ obsidian/
linux/
  .zshrc                PATH and clipboard shims; sources zshrc.common
  aliases.linux.zsh     apt, systemd, ss
  packages.txt          apt packages
  input/                gestures, Mac-style keys, natural scrolling
claude/                 CLAUDE.md, settings.json, statusline, hooks/
docs/                   linux-setup.md
```

Older config (fish, iTerm, the old VS Code setup, every earlier `.zshrc`) is
on the [`legacy`](../../tree/legacy) branch. The nix-darwin attempt is on
[`nix`](../../tree/nix).

## What install.sh does, in order

Each step needs the ones before it on a fresh machine.

| # | Group | Does | Time |
|---|---|---|---|
| 1 | macOS defaults | Finder, Dock, pointer, text input, screenshots | fast |
| 2 | hostname | all three macOS names, or `hostnamectl` | fast |
| 3 | packages | Brewfile or packages.txt, then (asked again) Brewfile.personal; node LTS through fnm | **20–40 min** |
| 4 | Dock contents | the apps in `macos/dock.txt`, in order | fast |
| 5 | oh-my-zsh | the framework, 3 plugins, optional `chsh` | ~1 min |
| 6 | shell config | links `.zshrc`, `.zshrc.common`, aliases, git | fast |
| 7 | app config | links Ghostty, VS Code, Zed, btop; copies Obsidian | fast |
| 8 | VS Code extensions | from `macos/vscode/extensions.txt` | ~2 min |
| 9 | AI agents | links Claude and opencode config, then checks both CLIs | ~2 min |

On a new Mac it first installs the Xcode Command Line Tools (a GUI installer,
so it waits for you), then Homebrew. With no terminal, as in CI or a pipe,
it declines every group and does not hang.

## What gets installed

### Shell tooling

Installed: `eza` (ls), `bat` (cat), `btop` (top), `ripgrep`, `fzf`, `jq`, `gh`.
Ready but commented out in the Brewfile: `git-delta`, `fd`, `zoxide`, `direnv`,
`lazygit`, `trash`. Remove the `#` and run `brew bundle`. The alias or hook
activates in the next shell.

- Every alias checks that its tool is installed, so the same file works on a
  machine that has none of them.
- Aliases that change a real command (`ls`→eza, `cat`→bat, `cp -i`) apply only
  when a person is at a terminal. Scripts, CI and AI agents get the plain
  commands: eza and bat reject flags like `ls -ltr` and `cat -v`, and `cp -i`
  fails with no terminal.
- `grep` is not aliased to `rg`, because `rg -r` means `--replace`.

### Node

[fnm](https://github.com/Schniz/fnm) reads `.nvmrc`. `cd` into a project and
it switches the version; `cd` out and it goes back to the default.

```bash
fnm install 22        # add a version
fnm default 24        # used by scripts and shells outside a project
fnm ls                # what is installed
```

fnm replaced nvm, which added about 1 s to every shell opened in a project.
npm has a 2-day release cooldown (`min-release-age`), and pnpm has its own.

### AI agents

- **CLIs:** `claude-code` and `opencode`.
- **Apps:** Claude, opencode-desktop, superwhisper and ollama.
- **Login:** each agent logs in on first run. No API key is in this repo.

Claude Code permissions (`claude/settings.json`):

- **Deny:** reading secrets (`.env`, keys, `~/.ssh`, `~/.aws`), editing shell
  and Claude config in `~`, and `git push`.
- **Ask:** edits to the linked config in this repo, `npx`, and `gh api`
  write calls.
- **Allow:** common read-only commands.
- **Hook:** `claude/hooks/git-readonly.py` approves read-only `git -C <dir> …`
  commands, which permission rules cannot match safely.
- **Modes:** `acceptEdits` is the default, and bypass mode is off.

### CLI

| Group | Packages |
|---|---|
| Core | git, tree, wget, parallel, shellcheck, betterleaks, xmlstarlet, mas, dockutil, agent-browser, ansible |
| Build | cmake, python@3.11, fnm, go, deno, pnpm, argon2 |
| Mobile | cocoapods, fvm, gradle |
| Cloud | podman, azure-cli, cloudflared, terraform, stripe |
| Media | ffmpeg, graphicsmagick, poppler |
| Misc | redis, watchman, mprocs, mole, otel-gui |

### Apps

| Group | Apps |
|---|---|
| Browsers | Brave, Chrome, Firefox, Helium |
| Editors | VS Code, Zed, Ghostty, JetBrains Mono |
| Dev | OrbStack, TablePlus, MongoDB Compass, DBeaver, Cyberduck, ngrok, Android platform tools, Temurin, tflint |
| Productivity | Raycast, Obsidian, Raindrop, Paseo, Tiles, HiddenBar, AltTab, Marta, AppCleaner, The Unarchiver, drawio, Jotter |
| System | BetterDisplay, MonitorControl, Stats, coconutBattery, Flux, YubiKey Authenticator, Tailscale |
| Media | VLC |

`Brewfile.personal` is asked about separately, so a work Mac can skip it:

| Group | Apps |
|---|---|
| Comms | Discord, Telegram, Viber |
| Media | IPTVnator, calibre, Transmission, Tinycast, yt-dlp |
| 3D and imaging | BambuStudio, OrcaSlicer, OpenSCAD, RPi Imager, balenaEtcher |
| Homelab | hidapi, minicom, nut, smartmontools, telnet, Home Assistant, AnyDesk, Firebird |

### Turning apps on and off

Put `#` in front of a Brewfile line to turn it off, or remove the `#` to turn
it on. Then:

```bash
git pull && brew bundle          # add --file=Brewfile.personal if used
cat Brewfile Brewfile.personal | brew bundle cleanup --file=-   # installed, not listed
```

A `#` stops future installs. It does not uninstall.

### Install by hand

| App | Why |
|---|---|
| Numbers, Pages, Xcode | App Store: `mas` needs a signed-in account (lines are in the Brewfile, commented) |
| Whisper Lite | my own app |
| Screendrop, SafeNet, CuaDriver | not in brew |
| herdr, pi | not in brew; the Brewfile has the commands |

## Security

`./install.sh harden` is for a Mac with no MDM. It checks each item first and
asks only about what is not in place:

| Item | Why |
|---|---|
| FileVault | Nothing else stores the recovery key, so save it in your password manager. |
| Firewall and stealth mode | No reply to probes on office and public Wi-Fi. |
| Touch ID for `sudo` | Uses `/etc/pam.d/sudo_local`, which macOS updates keep. |
| sshd keys only | No passwords, no root, only your user. It is checked with `sshd -t` and removed if the check fails. |

Turn on Screen Sharing and Remote Login by hand (System Settings > General >
Sharing), and only while you need them. Use them over Tailscale.
`./install.sh status` shows if they are on.

Secrets are never in this repo. SSH keys and passwords are in Bitwarden. The
pre-commit hook and CI scan every commit with
[betterleaks](https://github.com/betterleaks/betterleaks).

## macOS settings

`macos/defaults.sh` applies these. `./macos/defaults.sh --dry` shows each change
and touches nothing. It compares each value first, so `--dry` is also a drift
report. Log out for the keyboard and trackpad settings to take effect.

<details>
<summary><b>All settings</b></summary>

*Captured* values were read from my Mac. The others are chosen defaults.

#### Text input

All five are on by default and break code. Smart quotes change `"` to a
curly pair, smart dashes change `--` to an em dash, and autocorrect rewrites
identifiers.

| Setting | Value |
|---|---|
| `NSAutomaticQuoteSubstitutionEnabled` | false |
| `NSAutomaticDashSubstitutionEnabled` | false |
| `NSAutomaticSpellingCorrectionEnabled` | false |
| `NSAutomaticCapitalizationEnabled` | false |
| `NSAutomaticPeriodSubstitutionEnabled` | false |

To get autocorrect back in one app:

```bash
defaults write md.obsidian NSAutomaticSpellingCorrectionEnabled -bool true
```

#### Pointer and keyboard

| Setting | Value | Effect |
|---|---|---|
| `com.apple.mouse.scaling` | 1.5 | mouse speed *(captured)* |
| `com.apple.trackpad.scaling` | 0.875 | trackpad speed *(captured)* |
| `com.apple.swipescrolldirection` | false | natural scrolling off *(captured)* |
| `AppleKeyboardUIMode` | 3 | Tab moves to every control |
| `InitialKeyRepeat` | 15 | delay before a held key repeats |
| `KeyRepeat` | 2 | repeat rate |
| `ApplePressAndHoldEnabled` | false | key repeat instead of the accent picker |
| `AppleMultitouchTrackpad Clicking` | true | tap to click |
| `TrackpadThreeFingerDrag` | false | three-finger drag off *(captured)* |

#### Finder

| Setting | Value | Effect |
|---|---|---|
| `AppleShowAllFiles` | true | show dotfiles |
| `AppleShowAllExtensions` | true | show every file extension |
| `ShowPathbar` / `ShowStatusBar` | true | path and status bars |
| `FXPreferredViewStyle` | `Nlsv` | list view |
| `FXEnableExtensionChangeWarning` | false | no warning when you change an extension |
| `_FXSortFoldersFirst` | true | folders above files |
| `FXDefaultSearchScope` | `SCcf` | search the current folder |
| `_FXShowPosixPathInTitle` | true | full path in the title bar |
| `DSDontWriteNetworkStores` | true | no `.DS_Store` on network shares |
| `DSDontWriteUSBStores` | true | no `.DS_Store` on USB drives |

#### Dock

| Setting | Value | Effect |
|---|---|---|
| `autohide` | true | hidden until you point at it |
| `autohide-delay` | 0 | shows at once |
| `autohide-time-modifier` | 0 | no slide animation |
| `expose-animation-duration` | 0.1 | faster Mission Control |
| `tilesize` | 48 | icon size |
| `show-recents` | false | no recent apps |
| `mru-spaces` | false | Spaces keep their order |

Dock contents are in `macos/dock.txt`, applied by `macos/dock.sh`.

#### Screenshots

| Setting | Value |
|---|---|
| `location` | `~/Desktop/Screenshots` |
| `type` | png |
| `disable-shadow` | true |
| `show-thumbnail` | false |

#### System

| Setting | Value | Effect |
|---|---|---|
| `controlcenter BatteryShowPercentage` | true | battery percentage (needs `-currentHost`) |
| `NSDisableAutomaticTermination` | true | macOS does not quit idle apps |
| `CrashReporter DialogType` | none | no crash dialogs |
| `NSDocumentSaveNewDocumentsToCloud` | false | save to disk, not iCloud |
| `NSNavPanelExpandedStateForSaveMode` | true | save panel opens expanded |
| `PMPrintingExpandedStateForPrint` | true | print panel opens expanded |

#### Not set, on purpose

- **`LSQuarantine`** stays on. It is the "downloaded from the internet" check,
  a real malware guard. The `unquarantine` alias handles the occasional
  unnotarised binary.
- **`pmset` sleep settings** suit an always-on box, not a laptop.
- **Hot corners, privacy permissions, login items:** macOS has no script
  method for these.
- **Screensaver password:** the key is gone on Tahoe. Use
  `sysadminctl -screenLock immediate -password -`.
- **`killall cfprefsd`** can lose writes that are still in its cache.

A `defaults write` that returns 0 does not prove the setting works. Many keys
still write to a plist that nothing reads. If a setting does nothing, check
it in System Settings.

</details>

## zsh

`shared/zshrc.common` is the shell core. `macos/.zshrc` and `linux/.zshrc` add
only what is different. The theme is `robbyrussell`.

| Plugin | Gives you |
|---|---|
| `git` | about 150 aliases: `gst`, `gco`, `gd`, `gl` |
| `z` | `z dotfi` goes to a directory you use often |
| `extract` | `x file.anything` unpacks any archive |
| `command-not-found` | shows the package for a missing command |
| `zsh-completions` | completions for tools that have none |
| `zsh-autosuggestions` | grey suggestion from history; `→` accepts |
| `zsh-syntax-highlighting` | an invalid command turns red (loads last) |

The first four come with oh-my-zsh. Step 5 clones the other three.

Aliases are in three files: `shared/aliases.zsh`, `macos/aliases.macos.zsh` and
`linux/aliases.linux.zsh`. A command such as `ports` or `killport` that works
differently on each system is in each OS file, and only one file loads.

A terminal opened at `$HOME` starts in `~/dev`. Editor and agent shells open
in their project, so they do not change directory.

<details>
<summary><b>Linux</b></summary>

`linux/packages.txt` lists the apt packages: base tools, editors, eza, bat,
fd, ripgrep, fzf, Python, network tools, and xclip. Linux uses the same zsh
and oh-my-zsh as the Mac.

`linux/input/` does what BetterTouchTool does on a Mac:

| Need | Tool |
|---|---|
| Trackpad gestures | [libinput-gestures](https://github.com/bulletmark/libinput-gestures): 3-finger workspace swipe, 4-finger overview |
| Cmd+C / Cmd+V everywhere | [Toshy](https://github.com/RedBearAK/toshy): Ctrl+C still stops a command in a terminal |
| Natural scrolling | `mac-trackpad-scroll.sh`, started at login |
| Window snapping | XFCE (Super + arrows) |

The `input` group applies only at the next login, so gestures do not work
until then. Toshy needs a logout. See `linux/input/README.md` and
`docs/linux-setup.md`.

</details>

<details>
<summary><b>Obsidian</b></summary>

Obsidian keeps its settings inside the vault, so they install into
`$OBSIDIAN_VAULT` (default `~/Documents/obsidian/bbn`).

Tracked: appearance, hotkeys, graph, daily notes, templates, the plugin lists,
CSS snippets and the theme manifest. Not tracked: plugin code and
`theme.css`. Obsidian downloads them again when you first open the vault.

</details>

## CI

`.github/workflows/ci.yml` runs on push, on pull requests and every week.

| Job | Runner | Does |
|---|---|---|
| `lint` | ubuntu | shellcheck, `zsh -n` on every shell file, betterleaks |
| `linux` | ubuntu | `./install.sh -y` two times, link check, silent login shell, `.nvmrc` switch |
| `macos` | macos | Brewfile parse, `--dry` runs, formulae install, the same checks as Linux |

- **Two install runs:** the second run must also pass. This proves that a
  run can be repeated.
- **Silent login shell:** `zsh -lic exit` must write nothing to stderr. This
  finds broken rc files that nothing else shows.
- **No casks on macOS:** about 50 GUI apps would exceed the time limit, and
  that would test Homebrew, not this repo.

## Credits

Built on:
- [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)
- the [zsh-users](https://github.com/zsh-users) plugins
- [fnm](https://github.com/Schniz/fnm)
- [Homebrew](https://brew.sh)
- [betterleaks](https://github.com/betterleaks/betterleaks)
- [Ghostty](https://ghostty.org)

References for the macOS settings and the layout:
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) and its `.macos`
- [macos-defaults.com](https://macos-defaults.com)
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)
- [awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)

## License

[MIT](LICENSE)
