# Global preferences

These apply across every project on this machine. Project-specific `CLAUDE.md` files override these defaults when they conflict.

## Package manager: prefer pnpm

For new JavaScript/TypeScript projects, default to **pnpm**.

Why pnpm specifically (security-driven):
- **Release-age cooldown** — pnpm 11+ enforces `minimumReleaseAge: 1440` (24h) by default. Package versions published in the last 24h are refused on install. Catches most worm-style supply-chain attacks before they reach the developer machine. npm and yarn have no native equivalent.
- **Lifecycle script gating** — pnpm 10+ defaults to requiring explicit approval before running `postinstall` scripts. Most other managers run lifecycle scripts automatically, which is the primary execution vector for malicious packages. Approve with `pnpm approve-builds`, which writes an **`allowBuilds`** map into `pnpm-workspace.yaml`:
  ```yaml
  allowBuilds:
    esbuild: true
    sharp: true
  ```
  Do not hand-write the `onlyBuiltDependencies` array the pnpm docs still show — pnpm 11 ignores it and installs fail with `ERR_PNPM_IGNORED_BUILDS`.
- **Exotic sub-dep blocking** — pnpm 11+ blocks dependencies pulled from non-registry sources (git URLs, `file://` paths) inside sub-trees by default.
- **Disk efficiency** — content-addressable global store, hard-linked into each project's `node_modules`.

### Rules

- **Do not migrate** existing npm/yarn/bun projects to pnpm without asking the user. When working in an established repo, use whatever package manager it already uses.
- **For new projects** (scaffolding from scratch), use pnpm unless the user requests otherwise.
- After scaffolding a new pnpm project, automatically write `minimumReleaseAge: 2880` (48h cooldown) into `pnpm-workspace.yaml` — do not ask first. Inform the user once it's applied: they can edit the file directly to tune, or run `/harden-deps` to change the cooldown.

## Git commits

**Never pass identity or signing config on the command line.** No
`git -c user.name=…`, no `-c user.email=…`, no `--author`, and no
`-c commit.gpgsign=false`. Run plain `git commit`.

This machine is already configured: name, a GitHub **noreply** email, and SSH
commit signing with `commit.gpgsign = true`. An overridden email does not match
`~/.config/git/allowed_signers`, so the commit fails verification, loses its
"Verified" badge on GitHub, and is not attributed to the account. A pushed
commit cannot be fixed by amending — it needs a rewrite.

Only pass these flags when the user explicitly asks for a specific identity in
that request. Never infer one from a repo, a memory, or an earlier task.

## Other global defaults

- **No emojis** in code, comments, or commit messages unless explicitly requested.
- **No README/docs files** created unless the user explicitly asks.
- **Server components first** in Next.js App Router projects — push `'use client'` to leaves.
- **context7 for docs** — the context7 MCP server is available. Prefer it over web search for library/framework docs, tutorials, examples, API syntax, config, and migration guides.
- **Accessibility minimum bar** on any UI work: keyboard navigation, visible focus, semantic HTML, `prefers-reduced-motion` fallbacks.
- Always use ASD-STE100 Simplified Technical English when you write and talk

## Answer length

Default to short. Length is earned by the question, not assumed.

- Answer in sentence one. Put context after, if it is needed at all.
- Sentence limit: 20 words for an instruction, 25 otherwise.
- Paragraph limit: 3 sentences, one topic each.
- A yes/no question gets a yes or no first, then the reason in one sentence.
- Use a table for three or more comparable options. Prose for fewer.
- Numbered list for steps. One action per step.

Do not:

- Restate the question before answering it.
- Add a closing summary that repeats what you just said.
- Explain what you are about to do, then do it. Just do it.
- List options you will not recommend. Give the recommendation.
- Pad a short answer to look thorough.
- Cut real information to hit a length. Say the same thing in easier words.

Write more when the task is genuinely complex: a plan with trade-offs, a
comparison across many options, or a design decision that needs its reasoning
shown. Brevity is the default, not a hard cap.

## Comments and docstrings

Applies to any code you write or edit. Comment only what the code cannot say
itself: rationale, trade-offs, constraints, workarounds.

Before writing a comment, ask: if a reader deleted this line, would they be
confused? If not, do not write it.

| Situation | Don't | Do |
|---|---|---|
| Incrementing a counter | `i = i + 1  # increment i` | No comment |
| Null precondition | `// return null if value is null` | `// nextValue() can return null per spec §4.2` |
| Platform quirk | `// handle mouse movement` | `// Firefox <68 drops mousemove after drag exits window: bugzilla.mozilla.org/12345` |
| Formula | `// compute distance` | `// haversine: movable-type.co.uk/scripts/latlong.html` |
| Bug-driven default | `// set default title` | `// fall back to name when metadata omits title (issue #1425)` |

Prefer a better name or an extracted function over a comment. If code is hard to
comment clearly, the design is unclear — restructure instead.

Comments are for: design rationale, unidiomatic or copied code (link the source),
`TODO(username): <actionable>`, and workarounds (name the bug or ticket).

Never narrate a change you made ("added this per your request"). That belongs in
the commit message. Do not document code you were not asked to touch.

**Docstrings** — follow the language's own convention: PEP 257 for Python, `gofmt`
for Go, TSDoc for TS, Javadoc/Rustdoc elsewhere. Do not impose a length cap that
fights the ecosystem's tooling. Python specifics: imperative mood ("Compute the
checksum."), one-line summary then a blank line for multi-line, Google-style
`Args:`/`Returns:` sections, and never repeat a type already in the signature.


## Browser tooling priority: internal browser -> agent-browser -> Playwright

There are three different browser tools available. Pick based on *what kind of task it is*, not just
"any browser task":

1. **Claude Desktop's built-in browser pane** (Cmd/Ctrl+Shift+B, or Claude in Chrome) — only relevant
   when running inside Claude Desktop/Cowork itself. Use for quick visual checks, reading a rendered
   page, or clicking through a UI when you're already in that surface. Nothing to configure here; it's
   automatic in that app context and out of scope for CLI work.

2. **`agent-browser` (Vercel Labs CLI)** — the default for CLI-based debugging and ad-hoc browser
   interaction. Use this whenever you need to inspect, click through, or diagnose a running app
   (dev server, staging URL, Electron app) but are NOT writing a persisted test suite. This includes:
   - Reproducing a bug interactively (open page, click, check console/network)
   - Checking whether a fix actually rendered/behaved correctly after a code change
   - Reading React component state/props via the DevTools bridge
   - One-off exploratory QA / "does this flow work" checks
   - Screenshotting or snapshotting current UI state for review
   It's fast, token-cheap (accessibility-tree snapshots instead of full DOM/screenshots), and disposable
   — nothing it does gets checked into the repo.

3. **Playwright** — only when the goal is an actual **persisted, re-runnable E2E test** (a `.spec.ts`
   file meant to run in CI, regression coverage, cross-browser test matrix). Don't reach for Playwright
   for one-off debugging — that's slower and token-heavier for an agent loop. Do reach for it when the
   task is explicitly "write/update a test" or "run the test suite."

Rule of thumb: if the deliverable is a fix/observation, use `agent-browser`. If the deliverable is a
test file, use Playwright.

### agent-browser quick reference
Load current docs first (they match whatever version is installed, don't rely on memorized syntax):
```bash
agent-browser skills get core            # workflows, common patterns, troubleshooting
agent-browser skills get core --full     # + full command reference
agent-browser skills list                # see specialized skills (electron, react, vercel-sandbox, dogfood)
```

Common commands:
```bash
agent-browser open <url>                 # launch + navigate
agent-browser snapshot -i                # accessibility tree w/ @eN refs — inspect before clicking
agent-browser click @e2                  # interact via ref from snapshot
agent-browser fill @e3 "text"
agent-browser console                    # browser console log/warn/error
agent-browser errors                     # uncaught JS exceptions
agent-browser network requests --status 4xx,5xx   # inspect/filter network calls
agent-browser screenshot --annotate      # numbered element labels when text snapshot isn't enough
agent-browser react tree                 # (after `open --enable react-devtools`) component tree
agent-browser get cdp-url                # raw CDP endpoint for deeper DevTools debugging
agent-browser close                      # close when done
```

Typical debug loop against a local dev server:
```bash
agent-browser open http://localhost:3000/<route> && agent-browser wait --load networkidle && agent-browser snapshot -i
agent-browser console
agent-browser errors
agent-browser network requests --status 4xx,5xx
```

If not installed: `npm install -g agent-browser && agent-browser install`.
