# macOS defaults

Captured from bbn-mbp (macOS 26.6.1) on 2026-08-22. Only values that are
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

## Not set on this machine

Dock, Finder, and screenshot settings are all stock. If you ever change them,
re-capture rather than guessing values here.
