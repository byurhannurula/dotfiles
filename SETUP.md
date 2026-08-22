# Setup runbook

Bare metal → working Mac. Follow in order; each step assumes the previous one.

Budget ~1 hour, most of it waiting on downloads.

---

## Before you wipe

Two things must exist outside this repo, or you cannot recover:

| Thing | Where it must live |
|---|---|
| **age private key** (`keys.txt`) | 1Password / Bitwarden — **not** in this repo |
| **this repo, pushed to a remote** | GitHub. A repo you can't clone is not a backup |

Verify both right now:

```bash
git remote -v                                            # must show an origin
cat "$HOME/Library/Application Support/sops/age/keys.txt" # must exist
```

Then take a final snapshot:

```bash
make sync
```

---

## 1. macOS base

Sign in to iCloud and the **App Store** — `masApps` silently skips everything
if you're not signed in.

```bash
xcode-select --install
```

## 2. Nix

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

Creates a `/nix` APFS volume. No repartitioning — it shares free space with
the system volume. Open a new terminal afterwards.

```bash
nix --version    # confirm
```

## 3. Homebrew

Nix can't bootstrap this itself, and ~50 GUI apps come from it.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Third-party taps now need explicit trust, or their formulae are **silently
skipped**:

```bash
brew trust adembc/tap hashicorp/tap metafab/tap ngrok/ngrok terraform-linters/tap
```

## 4. Clone

```bash
mkdir -p ~/dev && git clone <your-remote> ~/dev/dotfiles && cd ~/dev/dotfiles
```

## 5. Restore the age key

**Before** the first rebuild — sops-nix fails without it.

```bash
mkdir -p "$HOME/Library/Application Support/sops/age"
# paste from your password manager:
vim "$HOME/Library/Application Support/sops/age/keys.txt"
chmod 600 "$HOME/Library/Application Support/sops/age/keys.txt"

# verify it decrypts
nix shell nixpkgs#sops -c sops -d secrets/secrets.yaml | head -3
```

If that errors, stop and fix it. Everything downstream depends on it.

## 6. First rebuild

```bash
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .
```

15–40 minutes. It will:

- install ~40 CLI tools into `/nix/store`
- install ~41 Homebrew casks and 8 App Store apps
- apply ~50 macOS defaults
- generate `.zshrc`, `.gitconfig`, Ghostty config
- decrypt SSH keys and tokens into place
- enable Touch ID for sudo

**If it fails partway**, nothing is broken — the old system is untouched until
the final step. Fix and re-run.

## 7. Verify

```bash
exec zsh          # pick up the new shell
make drift        # should report "in sync"
ssh -T git@github.com
gh auth status
```

## 8. Post-install (unavoidably manual)

- Sign in to apps (Slack, Discord, Raycast, TablePlus…)
- Raycast: import settings, set the hotkey
- Grant Full Disk Access / Accessibility where prompted
- `git config --global user.signingkey …` if you sign commits

---

## Day to day

```bash
make help
```

| Command | Does |
|---|---|
| `make rebuild` | apply config changes |
| `make diff` | preview what a rebuild would change |
| `make drift` | what's installed but not declared |
| `make rollback` | undo the last rebuild |
| `make sync` | capture + drift + commit |
| `make cleanup` | dry-run disk cleanup |

Enable the pre-commit secret scanner once per clone:

```bash
make hooks
```

## If a rebuild breaks the machine

Nothing is destructive. The previous generation is still on disk:

```bash
darwin-rebuild --list-generations
sudo darwin-rebuild --switch-generation <N>
```

Or `sudo darwin-rebuild --rollback` for the previous one.

## Common failures

| Symptom | Cause / fix |
|---|---|
| `error: attribute 'bbn' missing` | hostname ≠ `scutil --get LocalHostName`. Rename the machines/ folder or the Mac |
| sops "no key could decrypt" | `keys.txt` missing, wrong mode, or your public key isn't in `.sops.yaml` |
| casks silently absent | tap not trusted — see step 3 |
| `masApps` skipped | not signed in to the App Store |
| brew formula "not found" | it's a tap formula; it belongs in `homebrew.brews`, not `packages.nix` |
| `/nix` growing unbounded | GC config is in `common.nix`; `make cleanup` for the rest |
