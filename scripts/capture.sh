#!/usr/bin/env bash
# =============================================================================
# capture.sh v2 — snapshot this Mac into reproducible, committable state
# =============================================================================
#   ./capture.sh            → capture-YYYYMMDD_HHMMSS/ + capture-latest symlink
#
# Safe to run repeatedly. Never copies private keys — those belong in sops.
# =============================================================================

set -uo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # repo root

OUT="capture-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

say() { printf '\033[0;34m→\033[0m %s\n' "$1"; }
ok()  { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
skip(){ printf '\033[0;33m–\033[0m %s\n' "$1"; }
warn(){ printf '\033[0;31m!\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------------------
# 1. Homebrew — Brewfile is the source of truth; the .nix files are for pasting
# ---------------------------------------------------------------------------
if command -v brew &>/dev/null; then
  say "Homebrew"

  # Brewfile captures taps + formulae + casks + vscode + mas in one restorable
  # file. `brew bundle install --file=Brewfile` rebuilds everything.
  brew bundle dump --file="$OUT/Brewfile" --force --describe &>/dev/null \
    && ok "Brewfile ($(grep -c '^' "$OUT/Brewfile") entries)"

  # v2 FIX: taps were captured but never emitted in Nix form
  {
    echo "# --- paste into homebrew.taps ---"
    brew tap | sed 's/.*/  "&"/'
  } > "$OUT/brew-taps.nix.txt"

  # v2 FIX: separate tap-qualified formulae (a/b/c) from plain ones.
  # Tap formulae like hashicorp/tap/terraform do NOT exist in nixpkgs under
  # that name — they must stay in Homebrew or be mapped by hand.
  brew leaves --installed-on-request 2>/dev/null | sort > "$OUT/.leaves"
  {
    echo "# --- plain formulae: candidates for environment.systemPackages ---"
    echo "# verify each:  nix search nixpkgs <name>"
    grep -v '/' "$OUT/.leaves" | sed 's/^/  /'
  } > "$OUT/brew-formulae.nix.txt"
  {
    echo "# --- TAP-QUALIFIED: keep these in homebrew.brews, not nixpkgs ---"
    grep '/' "$OUT/.leaves" | sed 's/.*/  "&"/'
  } > "$OUT/brew-tap-formulae.nix.txt"
  rm -f "$OUT/.leaves"

  {
    echo "# --- paste into homebrew.casks ---"
    brew list --cask 2>/dev/null | sed 's/.*/  "&"/'
  } > "$OUT/brew-casks.nix.txt"

  ok "$(($(grep -c '^' "$OUT/brew-formulae.nix.txt")-2)) plain formulae, \
$(($(grep -c '^' "$OUT/brew-tap-formulae.nix.txt")-1)) tap formulae, \
$(($(grep -c '^' "$OUT/brew-casks.nix.txt")-1)) casks, \
$(brew tap | wc -l | tr -d ' ') taps"
else
  skip "Homebrew not installed"
fi

# ---------------------------------------------------------------------------
# 2. Mac App Store
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Detection is receipt-based, NOT `mas list`.
#
# `mas list` reads Spotlight metadata. With Spotlight indexing disabled (as it
# is here — Raycast instead), it returns nothing no matter how long you wait.
#
# Every App Store app has Contents/_MASReceipt/receipt. That's on disk and
# needs no index. The bundle ID from Info.plist then resolves to the numeric
# App Store ID via Apple's public lookup API (one HTTPS call per app).
# ---------------------------------------------------------------------------
say "Mac App Store (via receipts — Spotlight not required)"
: > "$OUT/.mas-raw"
while IFS= read -r receipt; do
  app="${receipt%/Contents/_MASReceipt}"
  name=$(basename "$app" .app)
  bid=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
        "$app/Contents/Info.plist" 2>/dev/null)
  printf '%s\t%s\n' "$name" "${bid:-}" >> "$OUT/.mas-raw"
done < <(find /Applications /Applications/Utilities -maxdepth 4 -type d -name '_MASReceipt' 2>/dev/null)

NFOUND=$(grep -c . "$OUT/.mas-raw" 2>/dev/null || echo 0)
if [ "$NFOUND" -gt 0 ]; then
  ok "$NFOUND App Store apps found on disk"
  { echo "# --- paste into homebrew.masApps ---"
    echo "# resolved from _MASReceipt + Apple lookup API"
  } > "$OUT/mas.nix.txt"
  : > "$OUT/mas-unresolved.txt"

  while IFS=$'\t' read -r name bid; do
    id=""
    if [ -n "$bid" ]; then
      id=$(curl -s --max-time 8 \
        "https://itunes.apple.com/lookup?bundleId=${bid}&entity=macSoftware" \
        2>/dev/null | sed -n 's/.*"trackId":\([0-9]*\).*/\1/p' | head -1)
    fi
    if [ -n "$id" ]; then
      printf '  "%s" = %s;\n' "$name" "$id" >> "$OUT/mas.nix.txt"
    else
      printf '%-30s %s\n' "$name" "${bid:-<no bundle id>}" >> "$OUT/mas-unresolved.txt"
    fi
  done < "$OUT/.mas-raw"

  NOK=$(grep -c '=' "$OUT/mas.nix.txt" || echo 0)
  ok "$NOK resolved to App Store IDs"
  if [ -s "$OUT/mas-unresolved.txt" ]; then
    warn "$(grep -c . "$OUT/mas-unresolved.txt") unresolved (offline, or app delisted):"
    sed 's/^/    /' "$OUT/mas-unresolved.txt"
    warn "  look these up manually, or re-run with a working connection"
  fi
else
  skip "no App Store apps found"
fi
rm -f "$OUT/.mas-raw"

command -v mas &>/dev/null || warn "mas not installed — needed at RESTORE time: brew install mas"

# ---------------------------------------------------------------------------
# 3. Claude Code — v2 ADDITION
# ---------------------------------------------------------------------------
# Config, skills, commands, agents and MCP servers. Excludes conversation
# history, caches and anything with credentials.
# ---------------------------------------------------------------------------
if [ -d "$HOME/.claude" ]; then
  say "Claude Code"
  mkdir -p "$OUT/claude"
  # Your own content — always keep
  for item in CLAUDE.md settings.json commands agents output-styles skills; do
    [ -e "$HOME/.claude/$item" ] && cp -Rp "$HOME/.claude/$item" "$OUT/claude/" 2>/dev/null
  done
  # Plugins: keep the MANIFEST (which plugins you have), drop the payload.
  # plugins/cache + plugins/marketplaces are cloned repos — 13MB, and fully
  # re-downloadable on a fresh machine. No reason to commit them.
  if [ -d "$HOME/.claude/plugins" ]; then
    mkdir -p "$OUT/claude/plugins"
    find "$HOME/.claude/plugins" -maxdepth 1 -name '*.json' \
      -exec cp -p {} "$OUT/claude/plugins/" \; 2>/dev/null
  fi
  # Skills can contain cloned repos too — strip VCS and dependency dirs
  find "$OUT/claude" \( -name .git -o -name node_modules -o -name .venv \) \
    -type d -prune -exec rm -rf {} + 2>/dev/null
  # .claude.json holds MCP server definitions AND oauth tokens — strip the creds
  if [ -f "$HOME/.claude.json" ] && command -v jq &>/dev/null; then
    jq 'del(.oauthAccount, .userID, .primaryApiKey)
        | with_entries(select(.key | test("Token|Key|secret"; "i") | not))' \
      "$HOME/.claude.json" > "$OUT/claude/claude.json.sanitised" 2>/dev/null \
      && ok "claude.json sanitised (tokens stripped)"
  fi
  # NOT copied: projects/ todos/ history.jsonl statsig/ shell-snapshots/
  ok "settings, skills, commands, agents"
else
  skip "~/.claude not found"
fi

# ---------------------------------------------------------------------------
# 4. Dotfiles + XDG config — v2: broader sweep, with exclusions
# ---------------------------------------------------------------------------
say "Dotfiles"
mkdir -p "$OUT/dotfiles"
for f in .zshrc .zshenv .zprofile .zlogin .profile .bashrc .bash_profile \
         .gitconfig .gitignore-global .gitmessage \
         .p10k.zsh .tmux.conf .editorconfig .curlrc .wgetrc .inputrc \
         .vimrc .ideavimrc .default-npm-packages .nvmrc .tool-versions; do
  [ -f "$HOME/$f" ] && cp "$HOME/$f" "$OUT/dotfiles/$f"
done

# .npmrc / .netrc contain auth tokens — record the KEYS, redact the VALUES
for f in .npmrc .netrc; do
  [ -f "$HOME/$f" ] && sed -E 's/(=|password |token ).*/\1<REDACTED>/' \
    "$HOME/$f" > "$OUT/dotfiles/$f.redacted"
done

# v2 FIX: Ghostty lives in one of two places on macOS depending on version
say "Ghostty"
GHOSTTY_FOUND=0
for p in "$HOME/.config/ghostty" \
         "$HOME/Library/Application Support/com.mitchellh.ghostty"; do
  if [ -e "$p" ]; then
    mkdir -p "$OUT/dotfiles/ghostty"
    cp -R "$p/"* "$OUT/dotfiles/ghostty/" 2>/dev/null
    ok "found at $p"; GHOSTTY_FOUND=1
  fi
done
[ "$GHOSTTY_FOUND" = 0 ] && skip "no Ghostty config found (still using defaults?)"

# ---------------------------------------------------------------------------
# ~/.config — ALLOWLIST, not denylist.
#
# v2.1 FIX: the previous denylist copied 689MB / 101k files, because SDK caches
# (azle, yarn, opencode) live under ~/.config and rsync's --max-size only caps
# individual files, not the total. An allowlist can't explode like that.
#
# Anything not listed is still considered, but only if it's genuinely small —
# so new tools get picked up automatically without dragging in a cache.
# ---------------------------------------------------------------------------
# TWO TIERS:
#   dotfiles/config/  CORE — hand-picked, safe to commit without thinking
#   review/config/    everything else — parked, gitignored, listed in REVIEW.md
#                     with ORIGINAL mtimes so stale junk is obvious
say "~/.config"
if [ -d "$HOME/.config" ]; then
  mkdir -p "$OUT/dotfiles/config" "$OUT/review/config"

  # Real config for tools you actually configure. Deliberately short.
  CORE="nvim starship.toml atuin bat lazygit tmux karabiner zellij helix \
        wezterm alacritty kitty direnv delta k9s"

  for item in $CORE; do
    [ -e "$HOME/.config/$item" ] && cp -Rp "$HOME/.config/$item" "$OUT/dotfiles/config/" 2>/dev/null
  done

  # gh + git: keep the config, never the credentials
  for t in gh git; do
    [ -d "$HOME/.config/$t" ] && { cp -Rp "$HOME/.config/$t" "$OUT/dotfiles/config/" 2>/dev/null
      rm -f "$OUT/dotfiles/config/$t/hosts.yml" "$OUT/dotfiles/config/$t/credentials"; }
  done

  # zed: settings + keymap only
  if [ -d "$HOME/.config/zed" ]; then
    mkdir -p "$OUT/dotfiles/config/zed"
    for f in settings.json keymap.json tasks.json; do
      [ -f "$HOME/.config/zed/$f" ] && cp -p "$HOME/.config/zed/$f" "$OUT/dotfiles/config/zed/"
    done
  fi

  # ---- everything else → review/, with a dated manifest -------------------
  {
    echo "# ~/.config — needs review"
    echo
    echo "Not copied into dotfiles/. Decide per entry:"
    echo "  KEEP  → add its name to CORE in capture.sh"
    echo "  DROP  → rm -rf ~/.config/<name>   (it's stale project junk)"
    echo
    echo "Sorted oldest first — anything you haven't touched in a year is"
    echo "almost certainly leftover from a finished project."
    echo
    printf '%-24s %10s %8s  %s\n' "NAME" "SIZE" "FILES" "LAST MODIFIED"
    printf '%-24s %10s %8s  %s\n' "----" "----" "-----" "-------------"
  } > "$OUT/review/REVIEW.md"

  for p in "$HOME/.config"/*; do
    n=$(basename "$p")
    [ -e "$OUT/dotfiles/config/$n" ] && continue
    case "$n" in ghostty|sops|op) continue ;; esac   # handled / private

    if [ -d "$p" ]; then
      sz=$(du -sk "$p" 2>/dev/null | cut -f1); fc=$(find "$p" -type f 2>/dev/null | wc -l | tr -d ' ')
      mt=$(find "$p" -type f -print0 2>/dev/null | xargs -0 stat -f '%m' 2>/dev/null | sort -rn | head -1)
    else
      sz=1; fc=1; mt=$(stat -f '%m' "$p" 2>/dev/null)
    fi
    [ -n "${mt:-}" ] && when=$(date -r "$mt" '+%Y-%m-%d') || when="(empty)"

    if [ "${sz:-0}" -lt 1024 ] && [ "${fc:-0}" -lt 50 ]; then
      cp -Rp "$p" "$OUT/review/config/" 2>/dev/null
      tag=""
    else
      tag="   ← CACHE, not copied"
    fi
    printf '%-24s %9sK %8s  %s%s\n' "$n" "$sz" "$fc" "$when" "$tag" \
      >> "$OUT/review/REVIEW.md.tmp"
  done
  sort -k4 "$OUT/review/REVIEW.md.tmp" 2>/dev/null >> "$OUT/review/REVIEW.md"
  rm -f "$OUT/review/REVIEW.md.tmp"

  find "$OUT/dotfiles/config" "$OUT/review/config" \
    \( -name '*.sqlite*' -o -name '*.log' -o -name 'keys.txt' -o -name '*.age' \) \
    -delete 2>/dev/null

  ok "core: $(find "$OUT/dotfiles/config" -type f | wc -l | tr -d ' ') files ($(du -sh "$OUT/dotfiles/config" 2>/dev/null | cut -f1))"
  ok "review: $(ls "$OUT/review/config" 2>/dev/null | wc -l | tr -d ' ') entries → see review/REVIEW.md"
fi

# ---------------------------------------------------------------------------
# 5. SSH — v2 FIX: public keys ARE safe to commit
# ---------------------------------------------------------------------------
say "SSH"
mkdir -p "$OUT/dotfiles/ssh"
[ -f "$HOME/.ssh/config" ]      && cp "$HOME/.ssh/config"      "$OUT/dotfiles/ssh/"
[ -f "$HOME/.ssh/known_hosts" ] && cp "$HOME/.ssh/known_hosts" "$OUT/dotfiles/ssh/"
cp "$HOME"/.ssh/*.pub "$OUT/dotfiles/ssh/" 2>/dev/null   # public = publishable

# List private keys by NAME only, so you know what to put into sops
{
  echo "# Private keys present on this machine."
  echo "# NOT copied. Put each into secrets/secrets.yaml via: sops secrets/secrets.yaml"
  for k in "$HOME"/.ssh/id_*; do
    [ -f "$k" ] && [[ "$k" != *.pub ]] && echo "  $(basename "$k")"
  done
} > "$OUT/dotfiles/ssh/PRIVATE-KEYS-TODO.txt"
ok "config, known_hosts, $(ls "$OUT/dotfiles/ssh"/*.pub 2>/dev/null | wc -l | tr -d ' ') public keys (private keys listed only)"

# ---------------------------------------------------------------------------
# 6. Editors
# ---------------------------------------------------------------------------
say "Editors"
for ed in code cursor windsurf zed; do
  command -v "$ed" &>/dev/null && "$ed" --list-extensions > "$OUT/$ed-extensions.txt" 2>/dev/null \
    && ok "$ed: $(grep -c '^' "$OUT/$ed-extensions.txt") extensions"
done
for app in Code Cursor; do
  D="$HOME/Library/Application Support/$app/User"
  [ -d "$D" ] && { mkdir -p "$OUT/dotfiles/$app"
    cp "$D/settings.json" "$D/keybindings.json" "$OUT/dotfiles/$app/" 2>/dev/null
    [ -d "$D/snippets" ] && cp -R "$D/snippets" "$OUT/dotfiles/$app/" 2>/dev/null; }
done

# ---------------------------------------------------------------------------
# 7. macOS defaults
# ---------------------------------------------------------------------------
say "macOS defaults"
defaults read > "$OUT/defaults-all.txt" 2>/dev/null
defaults read NSGlobalDomain > "$OUT/defaults-global.txt" 2>/dev/null
# v2: added the apps you actually run
for d in com.apple.dock com.apple.finder com.apple.screencapture \
         com.apple.AppleMultitouchTrackpad com.apple.Terminal \
         com.apple.controlcenter com.apple.menuextra.clock com.apple.spaces \
         com.brave.Browser \
         com.raycast.macos com.crisp.tiles eu.exelban.Stats \
         pro.betterdisplay.BetterDisplay com.mitchellh.ghostty \
         com.tailscale.ipn.macsys com.superduper.hiddenbar; do
  defaults read "$d" > "$OUT/defaults-${d##*.}.txt" 2>/dev/null || rm -f "$OUT/defaults-${d##*.}.txt"
done
ok "$(ls "$OUT"/defaults-*.txt | wc -l | tr -d ' ') domains"

# ---------------------------------------------------------------------------
# 8. Background jobs — v2 ADDITION (easy to forget, breaks silently)
# ---------------------------------------------------------------------------
say "Background jobs"
{
  echo "=== ~/Library/LaunchAgents ==="
  ls -1 "$HOME/Library/LaunchAgents" 2>/dev/null
  echo
  echo "=== crontab ==="
  crontab -l 2>/dev/null || echo "(none)"
  echo
  echo "=== brew services ==="
  brew services list 2>/dev/null || echo "(none)"
} > "$OUT/background-jobs.txt"
[ -d "$HOME/Library/LaunchAgents" ] && \
  { mkdir -p "$OUT/LaunchAgents"; cp "$HOME/Library/LaunchAgents"/*.plist "$OUT/LaunchAgents/" 2>/dev/null; }
ok "launch agents, crontab, brew services"

# ---------------------------------------------------------------------------
# 9. Toolchains
# ---------------------------------------------------------------------------
say "Toolchains"
{
  for c in node npm pnpm yarn bun deno python3 ruby go rustc cargo java swift docker podman; do
    command -v "$c" &>/dev/null && printf '%-10s %s\n' "$c" "$("$c" --version 2>&1 | head -1)"
  done
  echo; echo "--- nvm node versions ---"
  [ -d "$HOME/.nvm/versions/node" ] && { ls "$HOME/.nvm/versions/node"
    echo "  disk: $(du -sh "$HOME/.nvm" 2>/dev/null | cut -f1)"; }
  echo; echo "--- global npm ---"
  command -v npm &>/dev/null && npm ls -g --depth=0 2>/dev/null | tail -n +2
  echo; echo "--- pnpm global ---"
  command -v pnpm &>/dev/null && pnpm ls -g --depth=0 2>/dev/null | tail -n +2
  echo; echo "--- cargo ---"
  [ -f "$HOME/.cargo/.crates.toml" ] && grep -oE '^"[^ ]+' "$HOME/.cargo/.crates.toml" | tr -d '"'
  echo; echo "--- pipx ---"
  command -v pipx &>/dev/null && pipx list --short
  echo; echo "--- fvm (flutter) ---"
  command -v fvm &>/dev/null && fvm list 2>/dev/null
  echo; echo "--- sdkman/jenv ---"
  ls "$HOME/.sdkman/candidates" 2>/dev/null
} > "$OUT/toolchains.txt" 2>&1
ok "toolchains captured"

# ---------------------------------------------------------------------------
# 10. Unmanaged apps
# ---------------------------------------------------------------------------
say "Unmanaged /Applications"
{
  echo "# Apps NOT installed via brew cask."
  echo "# For each, check:  brew search --cask <name>"
  echo "# If a cask exists, add it to homebrew.nix and reinstall via brew."
  echo
  comm -23 \
    <(ls /Applications | grep '\.app$' | sed 's/\.app$//' | sort -u) \
    <(brew list --cask 2>/dev/null | while read -r c; do
        brew info --cask "$c" 2>/dev/null | grep -oE '[^/]+\.app' | sed 's/\.app$//'
      done | sort -u)
} > "$OUT/unmanaged-apps.txt" 2>/dev/null
ok "listed"

# ---------------------------------------------------------------------------
# 11. Disk report — v2 ADDITION (you're tight on space)
# ---------------------------------------------------------------------------
say "Disk"
{
  echo "=== free space ==="; df -h / | tail -1
  echo; echo "=== big offenders ==="
  for d in "$HOME/.nvm" "$HOME/Library/Caches" "$HOME/Library/Developer" \
           "$HOME/.docker" "$HOME/.gradle" "$HOME/.cargo" "$HOME/.npm" \
           "$HOME/Library/pnpm" "/nix"; do
    [ -e "$d" ] && printf '%-40s %s\n' "$d" "$(du -sh "$d" 2>/dev/null | cut -f1)"
  done
  echo; echo "=== brew ==="; brew --cache 2>/dev/null | xargs du -sh 2>/dev/null
} > "$OUT/disk-report.txt" 2>&1
ok "see disk-report.txt"

# ---------------------------------------------------------------------------
# 12. System facts
# ---------------------------------------------------------------------------
{
  echo "LocalHostName:  $(scutil --get LocalHostName)"
  echo "ComputerName:   $(scutil --get ComputerName)"
  echo "username:       $(whoami)"
  echo "arch:           $(uname -m)   → nix system: $([ "$(uname -m)" = arm64 ] && echo aarch64-darwin || echo x86_64-darwin)"
  echo "macOS:          $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  echo "shell:          $SHELL"
  echo "xcode CLT:      $(xcode-select -p 2>/dev/null)"
  echo "rosetta:        $(/usr/bin/pgrep -q oahd && echo installed || echo absent)"
} > "$OUT/system.txt"

ln -sfn "$OUT" capture-latest

# ---------------------------------------------------------------------------
# Size guard — a capture is config, not data. If it's big, something leaked in.
# ---------------------------------------------------------------------------
SZ_K=$(du -sk "$OUT" | cut -f1)
SZ_H=$(du -sh "$OUT" | cut -f1)
echo
if [ "$SZ_K" -gt 51200 ]; then          # >50MB
  warn "capture is $SZ_H — too big, something cache-like got copied:"
  du -sh "$OUT"/* "$OUT"/dotfiles/* 2>/dev/null | sort -rh | head -8 | sed 's/^/    /'
  warn "  add the offender to the skip logic before committing"
else
  ok "Done → $OUT/  ($SZ_H)"
fi
echo
grep -q 'mas' <<<"$(command -v mas)" || warn "install mas and re-run to capture App Store apps"
echo "Review: unmanaged-apps.txt, background-jobs.txt, disk-report.txt,"
echo "        dotfiles/ssh/PRIVATE-KEYS-TODO.txt"
