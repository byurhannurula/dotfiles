#!/usr/bin/env bash
# =============================================================================
# drift.sh — what's on this Mac that the repo doesn't know about?
# =============================================================================
# Built for a capture-driven workflow: install whatever you want, whenever you
# want, then run this occasionally to fold the changes back into the repo.
#
#   ./drift.sh           report only  ← the pre-flight check before a rebuild
#   ./drift.sh --fix     append missing casks/brews into machines/bbn/homebrew.nix
#
# WITH cleanup = "zap" / "uninstall", the "installed but not declared" list is
# literally the list of apps the next rebuild will DELETE. Read it before you
# rebuild. That's the debloat workflow:
#
#     brew install --cask <anything>   ... test freely, all week
#     ./drift.sh                       ... see the removal list
#     <add keepers to homebrew.nix>
#     rebuild                          ... everything else swept
#
# --fix is the OPPOSITE action: it declares everything, so nothing gets
# removed. Only use it when adopting a machine, not during a clean-up.
# =============================================================================

set -uo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # repo root

FIX=0
[ "${1:-}" = "--fix" ] && FIX=1

HB="machines/bbn/homebrew.nix"
PK="machines/bbn/packages.nix"

red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
yellow(){ printf '\033[0;33m%s\033[0m\n' "$1"; }
head2() { printf '\n\033[1;34m── %s ─────────────────────────────\033[0m\n' "$1"; }

[ -f "$HB" ] || { red "not found: $HB (run from the repo root)"; exit 1; }

# What will the next rebuild actually do to undeclared apps?
CLEANUP=$(grep -oE 'cleanup\s*=\s*"[a-z]+"' "$HB" | head -1 | grep -oE '"[a-z]+"' | tr -d '"')
CLEANUP=${CLEANUP:-none}
case "$CLEANUP" in
  zap)       VERDICT="WILL BE REMOVED on next rebuild (incl. their settings/data)" ;;
  uninstall) VERDICT="WILL BE UNINSTALLED on next rebuild (data kept)" ;;
  *)         VERDICT="not declared (cleanup=none, so nothing will be removed)" ;;
esac
printf '\n  homebrew.onActivation.cleanup = \033[1m%s\033[0m\n' "$CLEANUP"

# ---------------------------------------------------------------------------
# Casks
# ---------------------------------------------------------------------------
head2 "Homebrew casks"
comm -23 \
  <(brew list --cask 2>/dev/null | sort) \
  <(grep -oE '^\s*"[a-z0-9@._-]+"' "$HB" | tr -d ' "' | sort) \
  > /tmp/drift-casks

if [ -s /tmp/drift-casks ]; then
  if [ "$CLEANUP" = none ]; then
    yellow "$(wc -l < /tmp/drift-casks | tr -d ' ') installed but $VERDICT:"
  else
    red "$(wc -l < /tmp/drift-casks | tr -d ' ') casks $VERDICT:"
  fi
  sed 's/^/    ✗ /' /tmp/drift-casks
  echo
  echo "    → keep one? add it to $HB"
  echo "    → happy to lose them all? just rebuild"
else
  green "in sync — nothing to remove"
fi

# Declared but missing — only matters if you rebuilt on a fresh machine
comm -13 \
  <(brew list --cask 2>/dev/null | sort) \
  <(grep -oE '^\s*"[a-z0-9@._-]+"' "$HB" | tr -d ' "' | sort) \
  > /tmp/drift-casks-missing
if [ -s /tmp/drift-casks-missing ]; then
  yellow "declared but NOT installed (will install on next rebuild):"
  sed 's/^/    - /' /tmp/drift-casks-missing
fi

# ---------------------------------------------------------------------------
# Formulae
# ---------------------------------------------------------------------------
head2 "Homebrew formulae (top-level)"
brew leaves --installed-on-request 2>/dev/null | sort > /tmp/drift-leaves
{ grep -oE '^\s+[a-z0-9@._-]+$' "$PK" | tr -d ' '
  grep -oE '^\s*"[a-z0-9@/._-]+"' "$HB" | tr -d ' "'; } | sort -u > /tmp/drift-declared

comm -23 /tmp/drift-leaves /tmp/drift-declared > /tmp/drift-brews
if [ -s /tmp/drift-brews ]; then
  yellow "installed but NOT declared ($(wc -l < /tmp/drift-brews | tr -d ' ')):"
  while read -r f; do
    if [[ "$f" == */* ]]; then
      printf '    + %-34s (tap formula → homebrew.brews)\n' "$f"
    else
      printf '    + %-34s (try: nix search nixpkgs %s)\n' "$f" "$f"
    fi
  done < /tmp/drift-brews
else
  green "in sync"
fi

# ---------------------------------------------------------------------------
# Taps
# ---------------------------------------------------------------------------
head2 "Taps"
comm -23 <(brew tap | sort) \
         <(grep -A20 'taps = \[' "$HB" | grep -oE '"[a-z0-9/._-]+"' | tr -d '"' | sort) \
  > /tmp/drift-taps
[ -s /tmp/drift-taps ] && { yellow "not declared:"; sed 's/^/    + /' /tmp/drift-taps; } || green "in sync"

# ---------------------------------------------------------------------------
# macOS defaults
# ---------------------------------------------------------------------------
head2 "macOS defaults"
if [ -f capture-latest/defaults-all.txt ]; then
  defaults read > /tmp/drift-defaults-now 2>/dev/null
  N=$(diff <(sort capture-latest/defaults-all.txt) <(sort /tmp/drift-defaults-now) 2>/dev/null | grep -c '^[<>]')
  if [ "$N" -gt 0 ]; then
    yellow "$N lines changed since last capture. To see what:"
    echo "    diff capture-latest/defaults-all.txt <(defaults read) | less"
    echo "  Anything you care about → machines/bbn/macos.nix"
  else
    green "no change since last capture"
  fi
else
  yellow "no capture-latest/ — run ./capture.sh first"
fi

# ---------------------------------------------------------------------------
# Dotfiles that Nix generates — did you hand-edit any?
# ---------------------------------------------------------------------------
head2 "Nix-managed dotfiles"
CLOBBER=0
for f in .zshrc .gitconfig .config/ghostty/config; do
  p="$HOME/$f"
  if [ -e "$p" ] && [ ! -L "$p" ]; then
    yellow "  $f is a real file, not a symlink → hand-edited, changes will be LOST on rebuild"
    CLOBBER=1
  fi
done
[ "$CLOBBER" = 0 ] && green "all symlinks into the nix store (as expected)"

# ---------------------------------------------------------------------------
# Disk
# ---------------------------------------------------------------------------
head2 "Disk"
printf '  free on /       %s\n' "$(df -h / | tail -1 | awk '{print $4}')"
[ -d /nix ] && printf '  /nix            %s\n' "$(du -sh /nix 2>/dev/null | cut -f1)"
[ -d "$HOME/.nvm" ] && printf '  ~/.nvm          %s  (%s node versions)\n' \
  "$(du -sh "$HOME/.nvm" 2>/dev/null | cut -f1)" \
  "$(ls "$HOME/.nvm/versions/node" 2>/dev/null | wc -l | tr -d ' ')"
G=$(darwin-rebuild --list-generations 2>/dev/null | wc -l | tr -d ' ')
[ "$G" -gt 0 ] && printf '  nix generations %s  (gc keeps 30d — see common.nix)\n' "$G"

# ---------------------------------------------------------------------------
# --fix: append the missing entries
# ---------------------------------------------------------------------------
if [ "$FIX" = 1 ]; then
  head2 "Applying --fix"
  cp "$HB" "$HB.bak"

  if [ -s /tmp/drift-casks ]; then
    # insert before the closing bracket of the casks list
    python3 - "$HB" /tmp/drift-casks <<'PY'
import sys, re
path, add = sys.argv[1], sys.argv[2]
new = [l.strip() for l in open(add) if l.strip()]
src = open(path).read()
block = "\n      # --- added by drift.sh ---\n" + "".join(f'      "{c}"\n' for c in new)
src = re.sub(r'(casks = \[.*?)(\n    \];)', lambda m: m.group(1) + block + m.group(2),
             src, count=1, flags=re.S)
open(path, "w").write(src)
print(f"  added {len(new)} casks")
PY
  fi

  if [ -s /tmp/drift-brews ]; then
    grep '/' /tmp/drift-brews > /tmp/drift-tapbrews
    if [ -s /tmp/drift-tapbrews ]; then
      python3 - "$HB" /tmp/drift-tapbrews <<'PY'
import sys, re
path, add = sys.argv[1], sys.argv[2]
new = [l.strip() for l in open(add) if l.strip()]
src = open(path).read()
block = "\n      # --- added by drift.sh ---\n" + "".join(f'      "{c}"\n' for c in new)
src = re.sub(r'(brews = \[.*?)(\n    \];)', lambda m: m.group(1) + block + m.group(2),
             src, count=1, flags=re.S)
open(path, "w").write(src)
print(f"  added {len(new)} tap formulae")
PY
    fi
    grep -v '/' /tmp/drift-brews > /tmp/drift-plain
    [ -s /tmp/drift-plain ] && {
      yellow "  plain formulae NOT auto-added — decide nixpkgs vs homebrew yourself:"
      sed 's/^/      /' /tmp/drift-plain; }
  fi

  echo
  green "  $HB updated (backup: $HB.bak)"
  echo "  Review with: git diff $HB"
  echo "  Then:        rbdiff   # see what would change"
fi

echo
