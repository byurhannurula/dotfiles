# Research: dotfiles, CLI tooling, macOS provisioning, secrets

Compiled 2026-08-22. Four parallel research passes, cross-checked against this
machine where a claim was testable. Findings that contradict popular advice are
marked and were verified locally rather than taken from search results.

---

## Verdict up front

**Keep the current setup.** The research consistently landed on: this repo
already implements, in plain bash, the patterns the big frameworks sell. Two
machines is below the scale where templating pays for itself.

Worth doing, in order of value per effort:

1. Install the gitleaks pre-commit hook — **it is not installed** (see §4.1)
2. Delete the nvm block — mise already replaces it, ~200ms per shell (§2.2)
3. Homebrew 6 tap-trust — re-dump the Brewfile so trust annotations are written (§3.2)
5. Add a drift command — the one real gap in a copy-based setup (§1.3)

---

## 1. Dotfiles management

### 1.1 The tools

| Tool | Stars | Last push | Stores as | Secrets |
|---|---|---|---|---|
| [chezmoi](https://github.com/twpayne/chezmoi) | 21.3k | 2026-08-20 | **real files** | age, GPG, 1Password, Bitwarden, pass |
| [dotbot](https://github.com/anishathalye/dotbot) | 8.0k | 2026-07-12 | symlinks | none |
| [yadm](https://github.com/yadm-dev/yadm) | 6.4k | 2026-04-13 | files | GPG, git-crypt |
| [GNU Stow](https://github.com/aspiers/stow) | 1.1k | 2025-12-03 | symlinks | none |
| [rcm](https://github.com/thoughtbot/rcm) | 3.3k | 2025-05-23 | symlinks | none |
| [home-manager](https://github.com/nix-community/home-manager) | 10.3k | 2026-08-22 | store symlinks | sops-nix, agenix |

Comparison matrix: https://www.chezmoi.io/comparison-table/ (written by chezmoi's
author, but fair to competitors).

rcm has had no push in ~15 months — effectively maintenance-only.

### 1.2 Copy-not-symlink narrows the field

That choice rules out Stow, dotbot and rcm outright — they are symlink farms by
design. It is also the strongest argument *for* chezmoi if this ever migrates:
chezmoi is the only mature tool that deploys real files, and you can stop using
it at any time with the files left in place.

The cost is source-state indirection. You edit `~/.zshrc`, then `chezmoi add`
it, and files in the source dir carry mangled names (`dot_zshrc`, `private_`,
`executable_`). One step becomes two.

**Do not migrate.** Revisit only on a third machine, or if secrets ever need to
live in the repo.

Avoid [mackup](https://github.com/lra/mackup) despite 15.3k stars — its
symlink-into-iCloud model
[broke on macOS Sonoma+](https://adamtaylor.me/posts/sonoma-breaks-symlinks).

### 1.3 Worth stealing

- **A drift command.** The genuine gap in a copy-based setup: there is currently
  no way to see what has diverged between `~` and the repo. A `diff -r` wrapper
  closes it.
- **`brew bundle cleanup`** to make the Brewfile authoritative rather than
  descriptive.
- **[xdg-ninja](https://github.com/b3nj5m1n/xdg-ninja)** (3.4k) — finds programs
  cluttering `$HOME` and tells you how to move them to XDG paths.

### 1.4 Repos and reading

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) — 31.5k,
  **last real commit April 2024**. `.macos` is still the reference everyone
  copies but predates Sequoia and Tahoe. A menu to copy from, not a script to run.
- [holman/dotfiles](https://github.com/holman/dotfiles) — topical organisation:
  one dir per tool, any `*.zsh` auto-sourced. Worth stealing the convention.
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) — best-in-class
  `.local` override pattern.
- [geerlingguy/mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook)
  — the Ansible approach, CI-tested on GitHub Actions macOS runners.
- [webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles) — the
  maintained index.

Articles:
- [Anish Athalye — Managing Your Dotfiles](https://www.anishathalye.com/2014/08/03/managing-your-dotfiles/)
  — still the best statement of the principles.
- [Bas Nijholt — Open-sourcing my dotfiles](https://www.nijho.lt/post/dotfiles/)
  (Apr 2025) — the most relevant recent post: cross-platform macOS+Linux,
  refined over 10+ machines.
- [Dries Vints — Getting started with dotfiles](https://driesvints.com/blog/getting-started-with-dotfiles/)

---

## 2. CLI tooling and zsh

### 2.1 Three corrections to common advice

**Theme: staying on `robbyrussell`.** Powerlevel10k and starship were both
tested previously and rejected. For the record, since the advice circulates
widely: p10k is *not* archived (last commit 2026-08-15), and starship is
*slower* than p10k, not faster —
[zsh-bench](https://github.com/romkatv/zsh-bench) measures 354% command lag vs
19%, because starship forks a binary on every prompt. Neither applies here.

**The nvm advice was wrong for this machine.** The research said to delete nvm
because mise replaces it. But mise is *not installed* — it is commented out in
the Brewfile, so the `mise activate` line was dead and nvm was doing all the
work. There are real `.nvmrc` files across five projects. Deleting nvm would
have broken Node.

Resolved by making nvm lazy instead: stub functions for `nvm`/`node`/`npm`/`npx`
that load on first use. Startup 1.37s → 0.31s, and `.nvmrc` auto-switching on
`cd` now works, which the eager version never did.

**mise is not needed.** Its value is managing Python/Go/Ruby alongside Node.
Node-only with `.nvmrc` is exactly what nvm already does well.

### 2.2 Priority changes

1. Delete the nvm block from `shared/zshrc.common`. Most of the available win.
2. Cache the eval hooks — five `eval "$(tool init zsh)"` calls fork five
   subprocesses per shell. [evalcache](https://github.com/mroth/evalcache) or
   [zsh-defer](https://github.com/romkatv/zsh-defer).
3. Fix the arrow-key bindings. `'^[[A'`/`'^[[B'` break in application cursor
   mode; use `"${terminfo[kcuu1]}"` / `"${terminfo[kcud1]}"`.
4. Consider dropping `setopt CORRECT` — it misfires on project-local binaries
   and interferes with agent-driven workflows.

### 2.3 Framework

zsh-bench normalised first-prompt lag: **ohmyzsh 187%**, zim 122%, prezto 97%,
hand-rolled 10%. Plugin managers (zinit, zcomet) reach ~10%.

This config is not the worst case — `robbyrussell` is cheap and only 10 plugins
load. Fix nvm first; migrate only if still unhappy.

If migrating: [antidote](https://github.com/mattmc3/antidote) (1.8k, native zsh,
static plugin file, plain-text list) is closest to the current explicit style.

### 2.4 Tools worth adding

| Tool | Replaces | Why |
|---|---|---|
| [difftastic](https://github.com/Wilfred/difftastic) | delta, for review | Structural AST diff — a moved function shows as *moved*, not 40 changed lines |
| [yazi](https://github.com/sxyazi/yazi) | ranger, Finder | Async file manager, image previews in-terminal |
| [just](https://github.com/casey/just) | Makefile | Per-project command runner without Make's tab/phony traps |
| [lazydocker](https://github.com/jesseduffield/lazydocker) | `docker ps` loops | lazygit's sibling; you run OrbStack |
| [sd](https://github.com/chmln/sd) | `sed -i` | Fixes the macOS `sed -i ''` vs GNU `sed -i` split that bites dual-OS setups |
| [carapace](https://github.com/carapace-sh/carapace-bin) | — | Completions for 1000+ CLIs incl. `az`, `gh`, `terraform` |
| [gum](https://github.com/charmbracelet/gum) | — | Would make `install.sh` interactive for ~5 lines |

```bash
brew install difftastic yazi just lazydocker sd carapace
```

**Context-dependent:** [jj](https://github.com/jj-vcs/jj) (Git-compatible VCS —
but no LFS or submodules, likely rules it out for Flutter),
[dive](https://github.com/wagoodman/dive), [glow](https://github.com/charmbracelet/glow),
[k9s](https://github.com/derailed/k9s) if you actually run Kubernetes.

**Skip:** television (fzf already deeply integrated), gitui (have lazygit),
ctop (dead since 2024, lazydocker supersedes), macchina (dead), navi/cheat
(redundant with tldr + an agent in the terminal),
[thefuck](https://github.com/nvbn/thefuck) (dead since 2024 despite 97.7k stars).

`xh` is a better move than posting/slumber/atac — same syntax as httpie, ~10x
faster startup.

### 2.5 Plugins

- [fzf-tab](https://github.com/Aloxaf/fzf-tab) — replaces zsh's completion menu
  with fzf. Highest-impact plugin here. Must load after `compinit` and before
  syntax-highlighting.
- [fzf-git.sh](https://github.com/junegunn/fzf-git.sh) — `Ctrl-G Ctrl-B` for
  branches, `Ctrl-G Ctrl-H` for hashes, with previews.
- [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) —
  nags when you type a command that has an alias. Good for actually using the
  aliases file.
- [zsh-abbr](https://github.com/olets/zsh-abbr) — fish-style abbreviations that
  expand inline, so history records the real command.

---

## 3. macOS provisioning

### 3.1 defaults: three distinct failure modes

This is what most guides get wrong.

**(a) cfprefsd caching.** macOS routes preferences through a daemon that caches
in memory. Writing a plist directly does not propagate. Always use `defaults`,
then `killall` the owning process.

**(b) The key writes, but nothing consumes it.** The silent majority.
`defaults write` returns 0, the value lands, and the feature no longer exists.
**A zero exit status is not confirmation.**

**(c) Hard write failures.** `Could not write domain`. Widely blamed on SIP —
that is imprecise. The dominant cause is the terminal lacking a TCC grant.
Grant your terminal **Full Disk Access** before running a defaults script.

Verified on this machine: the Finder domain is writable, and `defaults.sh`
contains no dead Dashboard/iTunes/Safari keys. Only `ApplePressAndHoldEnabled`
is on the unreliable list — and disabling it kills the accent-character picker,
so it is a real tradeoff rather than a pure win.

Worth adding a read-back assertion, since exit codes cannot detect mode (b).

**Requires manual GUI configuration** — a permanent gap, not a temporary one:
TCC grants (screen recording, accessibility, input monitoring, full disk
access), login items ([SMAppService](https://developer.apple.com/forums/thread/766489)
since Ventura), hot corners, iCloud/Apple ID/Touch ID/FileVault.

Best-maintained reference: https://macos-defaults.com/ (per-setting pages with
screenshots).

### 3.2 Homebrew 6.0.0 — the actionable one

[Release notes](https://brew.sh/2026/06/11/homebrew-6.0.0/). Running 6.0.18 here.

**Tap trust is now mandatory** for third-party taps. Verified: a fresh
`brew bundle dump` writes 6 `trusted` annotations that the current Brewfile
lacks. Since the Brewfile carries 10 taps including `adembc/tap`,
`hashicorp/tap`, `metafab/tap` and `ngrok/ngrok`, re-dump on a working machine
and diff before committing.

Also: the `homebrew/bundle` tap is deprecated — bundle is core now.

Other useful flags:
- `brew bundle check || brew bundle install` — the idiomatic guard
- `brew bundle dump --describe` — records why each entry exists
- `brew leaves --installed-on-request` — better audit start than `dump`
- `--adopt` — a migration aid, not a steady-state flag; adoption does not
  always yield normal update behaviour
  ([#20967](https://github.com/Homebrew/brew/issues/20967))

**mas caveat:** it cannot install an app the Apple ID has never purchased. First
acquisition must happen in the GUI, which makes `mas` lines non-reproducible on
a fresh account. Keep them segregated and non-fatal.

### 3.3 Beyond bash

Honest framing: at two machines, most alternatives are a downgrade.

| Approach | Worth it when |
|---|---|
| bash + Brewfile | 1–3 machines, single admin. **Current position.** |
| [chezmoi](https://www.chezmoi.io/) | One repo across macOS *and* Debian with per-OS differences |
| [Ansible](https://github.com/geerlingguy/mac-dev-playbook) | 3+ machines, or you manage others' |
| [nix-darwin](https://github.com/nix-darwin/nix-darwin) | Rollback and bit-reproducibility, weeks of investment |
| [Devbox](https://github.com/jetify-com/devbox) | Per-*project* envs — orthogonal to provisioning |

**On nix-darwin:** it did improve. It moved to a proper org with multiple
maintainers, `system.defaults` now covers dock/finder/trackpad with typed
options, and `CustomUserPreferences` is a freeform escape hatch. But casks still
delegate to Homebrew, TCC is still untouchable, and the learning curve is
unchanged. Abandoning it was well-founded — Nix's monolithic evaluation model
means the whole config re-evaluates on any change
([discussion](https://jade.fyi/blog/use-nix-less/)). Don't go back for two machines.

### 3.4 Window management

**[AeroSpace](https://github.com/nikitabobko/AeroSpace)** (22.6k) is the pick for
a scripted setup: public Accessibility API only, so it **never requires
disabling SIP**; its own virtual workspaces avoid the sluggish macOS Spaces
animation; single TOML file. Still labelled public beta.

**yabai has moved** — the canonical repo is now
[asmvik/yabai](https://github.com/asmvik/yabai), not koekeishiya's. Update any
pinned URL. Choose it only if you need native Spaces integration.

**[Karabiner-Elements](https://karabiner-elements.pqrs.org/)** remains the only
serious remapper and is active, but needs a system extension approved by hand.
**skhd is dormant** (no push since Apr 2024); the active successor is
[skhd.zig](https://github.com/jackielii/skhd.zig). If you adopt AeroSpace you
probably need neither — its TOML handles bindings natively.

---

## 4. Secrets, scanning, bash, SSH

### 4.1 The gitleaks hook is not installed

Verified: `.git/hooks/` holds only `.sample` files, `core.hooksPath` is unset,
and this branch has no `.githooks/` directory — that exists only on `nix`. The
binary is present (8.30.1) and manual scans are clean, but **nothing runs
automatically.**

`.git/hooks/` is not tracked by git, so a hook committed to the repo is invisible
until something installs it. For a repo whose entire purpose is machine
bootstrap, hook installation belongs in `install.sh`.

```sh
#!/bin/sh
command -v gitleaks >/dev/null 2>&1 || { echo "gitleaks missing — skipping" >&2; exit 0; }
gitleaks git --staged --redact --no-banner --verbose || {
  echo "gitleaks blocked this commit. Fix, or annotate with '# gitleaks:allow'." >&2
  exit 1
}
```

`--redact` keeps the secret out of terminal scrollback. Note v8.19.0 deprecated
`detect`/`protect` in favour of `gitleaks git` / `dir` / `stdin`.

**GitHub push protection does not replace this.** It only catches partner
patterns — vendor tokens with recognisable shapes. It will not catch an SSH
private key, a `.env`, or a generic high-entropy string, which is exactly the
dotfiles risk profile. It also fires at push, when the secret is already in
local history.

gitleaks vs [trufflehog](https://github.com/trufflesecurity/trufflehog): the
distinguishing feature is trufflehog's **live credential verification** — it
tells you whether a found secret still works. Worth a one-off history sweep;
gitleaks alone is right for the pre-commit gate.

### 4.2 Secrets — decided: nothing in the repo

No secrets live here, and none will. SSH keys are copied by hand once per
machine from Bitwarden. **No `bw` CLI integration** — a shell function that
unlocks a vault to fetch tokens is more moving parts than the problem needs
for a single operator.

The SOPS/age rejection was also right, and worth recording so it is not
revisited. Encrypted-secrets-in-git solves a team/GitOps problem: several
people needing the same secret reproducibly in CI. A single operator gets a
bootstrap paradox instead — the age key that decrypts everything must itself
reach a fresh machine, which means a password manager. So you run Bitwarden
*plus* SOPS *plus* age where Bitwarden alone suffices. That extra layer is
what stalled the nix-darwin attempt.

Worth knowing but not adopting: Bitwarden now ships a native SSH agent, so
private keys can stay in the vault and never touch disk
([docs](https://bitwarden.com/help/ssh-agent/)). Revisit only if manual key
copying becomes annoying across more machines.

### 4.3 bash 3.2 — measured, not assumed

Tested against `/bin/bash` 3.2.57 on this machine. Several widely-repeated
claims are wrong.

**Works in 3.2, contrary to common belief:** `set -euo pipefail` (frequently
claimed to be bash 4+ — it is not), `arr+=(x)`, `${arr[@]:1}`, `printf -v`,
`[[ =~ ]]`, `local -r`, `trap ERR`.

**Genuinely absent:** `declare -A` (4.0), `${var^^}`/`${var,,}` (4.0), `mapfile`
(4.0), `declare -n` (4.3), `globstar` (4.0), `inherit_errexit` (4.4),
`&>>` (4.0), `wait -n` (4.3).

**The trap that matters:** `declare -A` fails *while silently corrupting data*.
Bash 3.2 makes an indexed array instead, arithmetic-evaluates every key to 0,
and every entry collides at index 0. With stderr redirected there is no warning.
`set -e` will not save you — the failed `declare` does not stop the script.

Also: under `set -u`, `"${arr[@]}"` on an *empty* array is an unbound-variable
error in 3.2 (fixed in 4.4). The portable idiom is `"${a[@]+"${a[@]}"}"`.

**On omitting `set -e`:** the current `set -uo pipefail` is a defensible choice,
not an oversight. `set -e` does not fire inside `if`/`while` conditions, on the
left of `&&`/`||`, in negated commands, or reliably in subshells — and the fix
(`inherit_errexit`) is 4.4+. Meanwhile it *does* fire on things an installer
expects to fail: `grep` finding nothing, `xcode-select -p` on a fresh Mac.
[Google's guide](https://google.github.io/styleguide/shellguide.html) does not
mandate it either.

Worth adding for visibility:

```bash
trap 'printf "\033[0;31m✗\033[0m failed at line %s\n" "$LINENO" >&2' ERR
```

One Google rule verified here: **never combine `local` with command
substitution** — `local v=$(false)` gives rc=0 because `$?` reflects `local`.
Split it: `local w; w=$(false)`.

Missing tooling: `brew install shfmt bats-core`.

### 4.4 SSH

- **ed25519 unconditionally.** Immune to the weak-RNG failure mode that plagued
  ECDSA.
- **One key per machine.** Blast radius: a lost laptop is revoked by deleting one
  public key. GitHub accepts unlimited keys.
- **Skip SSH certificate authorities** — real value for fleets, overkill for four keys.
- **YubiKey is the highest-value upgrade available.** FIDO2-backed keys make the
  private key physically unexportable; malware cannot steal it.
  ```bash
  ssh-keygen -t ed25519-sk -O resident -O verify-required -C "yubikey-5c"
  ```
  `-O resident` means `ssh-keygen -K` recovers it onto a fresh machine — your
  SSH identity travels on your keyring rather than in a vault.
  [Yubico guide](https://developers.yubico.com/SSH/Securing_git_with_SSH_and_FIDO2.html)
- **SSH commit signing over GPG.** Reuses the key you already have; no keyring,
  no expiry management, no `gpg-agent` breakage. Already configured here
  (`gpg.format ssh`, `allowedSignersFile`).

---

## Sources

Grouped links appear inline above. The indexes worth bookmarking:

- [awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)
- [chezmoi comparison table](https://www.chezmoi.io/comparison-table/)
- [macos-defaults.com](https://macos-defaults.com/)
- [Homebrew Bundle docs](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [zsh-bench](https://github.com/romkatv/zsh-bench)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Bitwarden CLI reference](https://bitwarden.com/help/cli/)
