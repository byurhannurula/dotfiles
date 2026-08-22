# Global preferences

These apply across every project on this machine. Project-specific `CLAUDE.md` files override these defaults when they conflict.

## Package manager: prefer pnpm

For new JavaScript/TypeScript projects, default to **pnpm**.

Why pnpm specifically (security-driven):
- **Release-age cooldown** — pnpm 11+ enforces `minimumReleaseAge: 1440` (24h) by default. Package versions published in the last 24h are refused on install. Catches most worm-style supply-chain attacks before they reach the developer machine. npm and yarn have no native equivalent.
- **Lifecycle script gating** — pnpm 10+ defaults to requiring an explicit `onlyBuiltDependencies` allowlist before running `postinstall` scripts. Most other managers run lifecycle scripts automatically, which is the primary execution vector for malicious packages.
- **Exotic sub-dep blocking** — pnpm 11+ blocks dependencies pulled from non-registry sources (git URLs, `file://` paths) inside sub-trees by default.
- **Disk efficiency** — content-addressable global store, hard-linked into each project's `node_modules`.

### Rules

- **Do not migrate** existing npm/yarn/bun projects to pnpm without asking the user. When working in an established repo, use whatever package manager it already uses.
- **For new projects** (scaffolding from scratch), use pnpm unless the user requests otherwise.
- After scaffolding a new pnpm project, automatically write `minimumReleaseAge: 2880` (48h cooldown) into `pnpm-workspace.yaml` — do not ask first. Inform the user once it's applied: they can edit the file directly to tune, or run `/harden-deps` to change the cooldown.

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