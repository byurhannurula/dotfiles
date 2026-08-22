#!/usr/bin/env bash
# =============================================================================
# sync.sh — refresh this repo so it isn't stale when you need it
# =============================================================================
# The one command to run every few months, or before wiping the machine:
#
#   ./sync.sh              capture → drift report → show diff → ask to commit
#   ./sync.sh --auto       same, but commit + push without asking
#   ./sync.sh --dry        capture + report only, change nothing
#
# This repo is a BOOTSTRAP tool. It only has to be current enough that
# "clone + rebuild" rebuilds this machine. That's what this keeps true.
# =============================================================================

set -uo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # repo root

MODE="ask"
case "${1:-}" in
  --auto) MODE="auto" ;;
  --dry)  MODE="dry" ;;
  -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
esac

bold() { printf '\n\033[1;36m▸ %s\033[0m\n' "$1"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------------------
bold "1/5  Capturing current machine state"
./scripts/capture.sh | tail -8

# ---------------------------------------------------------------------------
bold "2/5  Checking drift against the Nix config"
./scripts/drift.sh | sed 's/^/  /'

# ---------------------------------------------------------------------------
bold "3/5  Pruning old captures (keeping newest 3)"
# Captures are ~1MB each, mostly the defaults dump. No reason to keep dozens.
# NOTE: not `mapfile` — macOS ships bash 3.2, which doesn't have it.
OLD=()
while IFS= read -r _l; do OLD+=("$_l"); done \
  < <(ls -1dt capture-2* 2>/dev/null | tail -n +4)
if [ "${#OLD[@]}" -gt 0 ] && [ "$MODE" != "dry" ]; then
  printf '  removing %s old captures\n' "${#OLD[@]}"
  rm -rf "${OLD[@]}"
else
  ok "nothing to prune"
fi

# ---------------------------------------------------------------------------
bold "4/5  Repo diff"
if [ -z "$(git status --porcelain)" ]; then
  ok "no changes — repo is already current"
  exit 0
fi

git status --short | sed 's/^/  /'
echo
echo "  --- summary of edits to tracked files ---"
git diff --stat | sed 's/^/  /'

if [ "$MODE" = "dry" ]; then
  echo
  warn "--dry: stopping here, nothing committed"
  exit 0
fi

# ---------------------------------------------------------------------------
bold "5/5  Commit"

# Safety: never commit a private key or a decrypted secret, whatever happens.
LEAK=$(git status --porcelain | awk '{print $2}' | grep -E '(^|/)(id_[a-z0-9]+|keys\.txt|.*\.agekey)$' || true)
if [ -n "$LEAK" ]; then
  warn "REFUSING TO COMMIT — private key material staged:"
  echo "$LEAK" | sed 's/^/    /'
  warn "add these to .gitignore and re-run"
  exit 1
fi

MSG="chore: sync machine state $(date +%Y-%m-%d)

$(./scripts/drift.sh 2>/dev/null | grep -E '^\s+\+' | head -20)"

if [ "$MODE" = "ask" ]; then
  echo
  read -rp "  Commit and push? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { warn "skipped — changes left in working tree"; exit 0; }
fi

git add -A
git commit -q -m "$MSG"
ok "committed"

if git remote get-url origin &>/dev/null; then
  if git push -q 2>/dev/null; then ok "pushed"; else warn "push failed — commit is local"; fi
else
  warn "no remote configured — commit is local only"
  warn "  a bootstrap repo you can't clone isn't a bootstrap repo:"
  warn "  git remote add origin git@github.com:byurhannurula/dotfiles.git"
fi

echo
ok "Done. Repo now reflects this machine."
