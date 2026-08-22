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
  mac-trackpad-scroll.sh  natural scrolling, re-applied at login
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
| 1 | macOS defaults | Finder, Dock, pointer, text input, screenshots | fast |
| 2 | hostname | all three macOS names, or `hostnamectl` | fast |
| 3 | packages | everything from the Brewfile / packages.txt | **20–40 min** |
| 4 | Dock contents | the apps in `macos/dock.txt`, in order | fast |
| 5 | oh-my-zsh | the framework plus 3 plugins, optional `chsh` | ~1 min |
| 6 | shell config | `.zshrc`, `.zshrc.common`, aliases, git | fast |
| 7 | app config | ghostty, vscode, zed, btop, obsidian | fast |
| 8 | vscode extensions | 18 extensions | ~2 min |
| 9 | AI agents | config, then install and verify claude + opencode | ~2 min |

Step 3 installs zsh, git, `code` and the GUI apps, so steps 4–9 all depend on
it — step 4 in particular skips any Dock app that is not installed yet. Step 1
runs first so no window opens with the wrong settings.

Every group asks `[y/N]` and defaults to no. Interactivity is detected from the
terminal, so piping or running in CI declines everything rather than hanging.

It bootstraps what a new Mac lacks: Xcode Command Line Tools (a GUI installer,
so it waits for you), Homebrew, and oh-my-zsh.

## What gets installed

### Shell tooling

Installed: `eza` (ls) `bat` (cat) `btop` (top) `ripgrep` (grep) `fzf` `jq` `gh`

Every alias is guarded on the binary existing, so a missing tool leaves the
plain command alone — the same file works on a machine that has none of them.

Six more are listed commented in the Brewfile: `git-delta`, `fd`, `zoxide`,
`direnv`, `lazygit`, `trash`. Each already has a guarded alias or hook waiting;
uncomment, run `brew bundle`, and it activates on the next shell.

### Node

`nvm`, loaded lazily: `nvm`, `node`, `npm` and `npx` are stub functions that
load the real thing on first use, so the shell starts in ~0.3s rather than
~1.4s. `.nvmrc` is honoured — `cd` into a project and it switches version
silently.

`mise` is deliberately not used. Its value is managing Python/Go/Ruby alongside
Node, and this is a Node-only machine.

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

Linux runs zsh and oh-my-zsh, exactly as the Mac does — there is no bash config
here. `mac-trackpad-scroll.sh` is installed to `~/.local/bin` with an autostart
entry, because XFCE reverts natural scrolling to libinput's default on every
login.

## macOS settings

Applied by `macos/defaults.sh`. Preview with `./macos/defaults.sh --dry`, which
prints every change and touches nothing. Log out for the keyboard and trackpad
settings to take effect.

Values marked *captured* were read from this machine; the rest are chosen
defaults.

### Text input

All five are **on by default and actively corrupt code** — smart quotes turn
`"` into a curly pair, smart dashes turn `--` into an em dash, and autocorrect
rewrites identifiers. Anything typed or pasted through a Cocoa text field is
affected.

| Setting | Value |
|---|---|
| `NSAutomaticQuoteSubstitutionEnabled` | false |
| `NSAutomaticDashSubstitutionEnabled` | false |
| `NSAutomaticSpellingCorrectionEnabled` | false |
| `NSAutomaticCapitalizationEnabled` | false |
| `NSAutomaticPeriodSubstitutionEnabled` | false |

Override per app if you want autocorrect back somewhere:

```bash
defaults write md.obsidian NSAutomaticSpellingCorrectionEnabled -bool true
```

### Pointer and keyboard

| Setting | Value | Effect |
|---|---|---|
| `com.apple.mouse.scaling` | 1.5 | mouse tracking speed *(captured)* |
| `com.apple.trackpad.scaling` | 0.875 | trackpad tracking speed *(captured)* |
| `com.apple.swipescrolldirection` | false | **natural scrolling off** *(captured)* |
| `AppleKeyboardUIMode` | 3 | tab reaches every control, not just text fields |
| `InitialKeyRepeat` | 15 | delay before a held key repeats |
| `KeyRepeat` | 2 | repeat rate once going |
| `ApplePressAndHoldEnabled` | false | key repeat instead of the accent picker |
| `AppleMultitouchTrackpad Clicking` | true | tap to click |
| `TrackpadThreeFingerDrag` | false | three-finger drag off *(captured)* |

### Finder

| Setting | Value | Effect |
|---|---|---|
| `AppleShowAllFiles` | true | show dotfiles |
| `AppleShowAllExtensions` | true | never hide a file extension |
| `ShowPathbar` / `ShowStatusBar` | true | path and status bars |
| `FXPreferredViewStyle` | `Nlsv` | list view everywhere |
| `FXEnableExtensionChangeWarning` | false | no nag when renaming `.txt` to `.md` |
| `_FXSortFoldersFirst` | true | folders above files |
| `FXDefaultSearchScope` | `SCcf` | search the current folder, not the whole Mac |
| `_FXShowPosixPathInTitle` | true | full path in the title bar |
| `DSDontWriteNetworkStores` | true | no `.DS_Store` on network shares |
| `DSDontWriteUSBStores` | true | no `.DS_Store` on USB drives |

### Dock

| Setting | Value | Effect |
|---|---|---|
| `autohide` | true | hidden until hovered |
| `autohide-delay` | 0 | appears immediately |
| `autohide-time-modifier` | 0 | instant slide (0.5 is *slower* than stock) |
| `expose-animation-duration` | 0.1 | faster Mission Control |
| `tilesize` | 48 | icon size |
| `show-recents` | false | no recent-apps section |
| `mru-spaces` | false | stop spaces reordering themselves |

Dock **contents** are separate — see `macos/dock.txt` and `macos/dock.sh`.

### Screenshots

| Setting | Value |
|---|---|
| `location` | `~/Desktop/Screenshots` |
| `type` | png |
| `disable-shadow` | true |
| `show-thumbnail` | false | no floating preview blocking the screen |

### System

| Setting | Value | Effect |
|---|---|---|
| `controlcenter BatteryShowPercentage` | true | battery percentage — needs `-currentHost` |
| `NSDisableAutomaticTermination` | true | macOS stops quitting idle apps |
| `CrashReporter DialogType` | none | no crash dialogs |
| `NSDocumentSaveNewDocumentsToCloud` | false | save to disk, not iCloud |
| `NSNavPanelExpandedStateForSaveMode` | true | save panel opens expanded |
| `PMPrintingExpandedStateForPrint` | true | print panel opens expanded |

### Deliberately not set

- **`LSQuarantine`** stays enabled. Disabling it removes the "downloaded from
  the internet" check, which is a real malware guard on a daily driver. The
  `unquarantine` alias handles the occasional unnotarised binary instead.
- **`pmset` sleep settings** — suit an always-on box, not a laptop.
- **Hot corners, TCC grants, login items** — Apple removed or never provided a
  scriptable path. These are permanently manual.
- **Screensaver password** (`com.apple.screensaver askForPassword`) — the key no
  longer exists on Tahoe. Use `sysadminctl -screenLock immediate -password -`.
- **`com.apple.menuextra.battery`** — a dead domain since Big Sur. The working
  key is `com.apple.controlcenter BatteryShowPercentage`, set above.
- **`killall cfprefsd`** — it is the preferences daemon, and killing it can drop
  writes still sitting in its cache.

`macos/defaults.sh` compares each value before writing, so `--dry` is a drift
report rather than a transcript: it prints `same:` for what already matches and
`set: old -> new` for what would change.

> `defaults write` returning 0 does **not** mean the setting took effect. Many
> keys still write cleanly to a plist that nothing reads any more. If a setting
> appears to do nothing, verify it in System Settings rather than trusting the
> exit code.

## zsh

`shared/zshrc.common` holds the shell core; `macos/.zshrc` and `linux/.zshrc`
add only what differs. Theme is `robbyrussell`.

| Plugin | Gives you |
|---|---|
| `git` | ~150 aliases — `gst`, `gco`, `gd`, `gl` |
| `z` | `z dotfi` jumps to a directory you visit often |
| `extract` | `x file.anything` unpacks any archive |
| `command-not-found` | suggests the package providing a missing command |
| `zsh-completions` | completions for tools that ship none |
| `zsh-autosuggestions` | greys in a suggestion from history; `→` accepts |
| `zsh-syntax-highlighting` | commands turn red when invalid — loads last |

The first four ship with oh-my-zsh. The last three are cloned by step 5.

Aliases are split three ways: `shared/aliases.zsh` (portable),
`macos/aliases.macos.zsh` (`defaults`, `lsof`, `brew`), and
`linux/aliases.linux.zsh` (`apt`, `systemd`, `ss`). Where both OSes need the
same idea with a different implementation — `ports`, `killport`, `localip` —
each file defines its own; only one is ever loaded.

A terminal opened at `$HOME` starts in `~/dev`. Editor and agent shells are
excluded, since they open in a project directory on purpose.

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

## Obsidian

Settings live inside the vault, not `~/Library`, so they install into
`$OBSIDIAN_VAULT` (default `~/Documents/obsidian-bbn`, overridable).

Tracked: appearance, hotkeys, graph, daily-notes, templates, the two plugin
lists, three CSS snippets, and the `mnml` theme manifest — 48K.

Not tracked: plugin code and `theme.css` (340K on its own). Obsidian
re-downloads both from `community-plugins.json` and the theme manifest when the
vault is first opened.

## Hooks and CI

### Pre-commit secret scan

`.githooks/pre-commit` runs [gitleaks](https://github.com/gitleaks/gitleaks)
against the staged diff and refuses the commit if it finds a secret. Enabled by
`install.sh`, or by hand:

```bash
git config core.hooksPath .githooks
```

That config step is the whole point: `.git/hooks/` is **not tracked by git**, so
a hook committed to a repo does nothing until something points git at it. This
repo went most of its life with the hook present in an old branch and never
active.

No husky, no `package.json` — `core.hooksPath` is native git and needs nothing
installed. If gitleaks is missing the hook warns and allows the commit rather
than blocking work; `git commit --no-verify` bypasses it in an emergency.

GitHub push protection is not a substitute. It only catches vendor tokens with
recognisable shapes, so it will miss an SSH private key, a `.env`, or any
high-entropy string — which is most of the dotfiles risk. It also fires at push,
by which point the secret is already in local history.

### GitHub Actions

`.github/workflows/ci.yml` runs on push, PR, and weekly.

| Job | Runner | Does |
|---|---|---|
| `lint` | ubuntu | shellcheck, `zsh -n` on every shell file, gitleaks |
| `linux` | ubuntu | `./install.sh -y`, then again for idempotence |
| `macos` | macos | Brewfile parses, both `--dry` runs, formulae install, idempotence |

Three things the workflow does deliberately:

- **Runs the installer twice.** A second run must succeed — that is what proves
  idempotence, and it is cheap given the copy-plus-backup design.
- **Asserts a silent login shell.** `zsh -lic exit` must print nothing to
  stderr. This catches broken rc files nothing else surfaces; it is how the
  `gc` alias collision was found.
- **Skips casks on macOS.** ~50 GUI apps would exceed the timeout and would be
  testing Homebrew rather than this repo. It also deletes the runner's
  preinstalled Firefox and Chrome first, since brew refuses to install a cask
  over an existing app.

The Homebrew **download** cache is cached; the Cellar deliberately is not.
Restoring a Cellar over the runner's own Homebrew leaves kegs
present-but-unregistered and breaks `brew bundle`. The weekly run skips the
cache entirely to simulate a genuinely fresh machine.

## Secrets

None in this repo. SSH keys and passwords live in Bitwarden; each AI agent
authenticates on first run.

Raycast's `config.json` is deliberately excluded — it holds an access token
and no actual settings. Also excluded: `gh/hosts.yml` and `herdr/session.json`,
both of which carry live credentials.

## Day to day

```bash
./install.sh                    # re-run any group after editing a file
git config core.hooksPath .githooks        # enable the secret scan once per clone
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
