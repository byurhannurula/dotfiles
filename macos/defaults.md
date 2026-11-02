# macOS defaults

Captured from the daily-driver Mac (macOS 26.6.1) on 2026-08-22. Only values that are
actually set on this machine are listed as "current" — Dock and Finder are
untouched stock defaults here, so there is nothing to restore for them.

Apply with `defaults write`, then log out. Some need a `killall Dock`/`Finder`.

## Pointer and keyboard — the ones that are actually customised

| Setting | Current | Meaning |
|---|---|---|
| `com.apple.mouse.scaling` | `1.5` | mouse tracking speed |
| `com.apple.trackpad.scaling` | `0.875` | trackpad tracking speed |
| `com.apple.swipescrolldirection` | `0` | **natural scrolling OFF** |
| `AppleKeyboardUIMode` | `3` | full keyboard access — tab reaches every control |
| `InitialKeyRepeat` | `15` | delay before a held key repeats (lower = faster) |
| `KeyRepeat` | `2` | repeat rate once going (lower = faster) |
| `com.apple.AppleMultitouchTrackpad Clicking` | `1` | tap to click |
| `TrackpadThreeFingerDrag` | `0` | three-finger drag off |

```bash
defaults write -g com.apple.mouse.scaling 1.5
defaults write -g com.apple.trackpad.scaling 0.875
defaults write -g com.apple.swipescrolldirection -bool false
defaults write -g AppleKeyboardUIMode -int 3
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
```

> **Scroll direction differs per OS.** This Mac has natural scrolling off.
> The Linux box runs `linux/mac-trackpad-scroll.sh` to force it *on*. The two
> configs disagree on purpose — do not "fix" one to match the other.

## Beyond the captured values

`defaults.sh` also sets Finder, Dock, screenshot, Siri, Spotlight-shortcut
and ad settings. They are choices, not a capture. Run
`./macos/defaults.sh --dry` to see which ones this Mac does not have yet.

## Undo

Each run that changes something writes
`~/.dotfiles.backup/defaults-<timestamp>.sh` with the old values. Restore with:

```bash
./macos/defaults.sh --undo ~/.dotfiles.backup/defaults-<timestamp>.sh
```

`./install.sh harden --undo` reverses the sudo items (Spotlight index,
firewall, screen lock, sshd, Touch ID) one by one.

## Not scriptable without MDM

- **Apple Intelligence**: System Settings > Apple Intelligence & Siri.
  `status.sh` reports it.
- **File Sharing, Remote Login, Screen Sharing**: System Settings > General >
  Sharing. The same switch turns each one back on.
