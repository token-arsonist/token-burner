# Token Burner — Design

**Status:** Draft · 2026-05-13
**Author:** James (with Claude)

A tongue-in-cheek tool for engineers being evaluated on AI token usage. Two deliverables: a **Claude Code plugin** (the real product, where token burning happens) and a **parody marketing site** (where the bit lives — manifesto, recipe catalog, compliance calculator). Plugin is fully local; site has no backend, no telemetry, no accounts.

---

## 1 · Goals & non-goals

**Goals**
- Let a user run `/burn <target>` in Claude Code and have it land within ±5% of the requested token count.
- Produce output that looks plausibly like real work, theatrically themed via named "recipes."
- Work even when Claude Code is opened outside of any codebase (e.g., home directory).
- Ship a parody marketing site that sells the plugin with a deadpan B2B-compliance voice.

**Non-goals**
- No telemetry, no leaderboards backed by real data, no user accounts.
- No mechanism beyond `/burn` in v1 (no prompt-padding hooks, no scheduled burners, no auto-second-opinion).
- No hard cap on burn targets. Rate limits are the only ceiling.
- No backend services. The site is fully static. The plugin runs entirely inside the user's Claude Code session.

---

## 2 · Architecture

Monorepo, two independent units:

```
token-burner/
├── plugin/                  ← Claude Code plugin
│   ├── .claude-plugin/      ← plugin manifest
│   ├── commands/
│   │   └── burn.md          ← /burn slash command (the orchestrator)
│   ├── recipes/             ← 8 recipe definitions
│   ├── agents/
│   │   └── tail-burner.md   ← tail subagent
│   └── lib/
│       └── transcript.sh    ← read transcript JSONL, sum tokens
│
└── site/                    ← Astro static site
    ├── src/pages/           ← 5 .astro pages
    ├── src/layouts/
    ├── src/styles/
    └── astro.config.mjs
```

The plugin and the site share nothing at runtime. They are bundled in one repo for narrative reasons only.

---

## 3 · Plugin

### 3.1 · Slash command surface

A single command, `/burn`, with six call shapes:

| Invocation | Behavior |
|---|---|
| `/burn` | Random eligible recipe at its default size |
| `/burn 50k` | Random eligible recipe, target ~50,000 tokens |
| `/burn architecture-tournament` | Named recipe at its default size |
| `/burn 50k architecture-tournament` | Named recipe sized to ~50,000 tokens |
| `/burn status` | Today / week / all-time totals, last 5 sessions |
| `/burn list` | Show recipe catalog |

Token-target syntax accepts `k` / `M` suffixes (`/burn 1.5M`). Bare numbers are treated as raw token counts.

### 3.2 · Orchestrator (`commands/burn.md`)

`commands/burn.md` is a Markdown instruction file. Claude (not a JS runtime) executes the orchestration logic. The Bash tool is used to read the transcript and compute token usage. The Agent tool dispatches recipe and tail subagents.

Execution flow:

1. **Parse the argument.** Detect: number? recipe name? `status`? `list`? Or empty?
2. **Detect context.** `git rev-parse --is-inside-work-tree` plus a check for code files in `.` determines whether a codebase is present. If not, restrict to `context: any` recipes.
3. **Snapshot tokens.** Call `bash plugin/lib/transcript.sh "$CLAUDE_TRANSCRIPT_PATH"` to get baseline cumulative usage.
4. **Classify tier** from target:
   - **Micro** (< 10,000): skip the main recipe; tail subagents only.
   - **Normal** (10,000 – 500,000): one main recipe + tail.
   - **Marathon** (> 500,000): chained distinct recipes + final tail.
5. **Dispatch by tier** (see §3.2.1 below for each).
6. **Tail loop** (shared across Normal and Marathon, and the only step for Micro): re-read transcript after each subagent; dispatch tail subagents until `elapsed` is within ±5% of `target`, or `elapsed > target`. Safety bound: 10 tail iterations.
7. **Optionally write artifact** per plugin settings.
8. **Print summary** — actual burn, target, accuracy %, recipe(s) used, artifact path if any.

#### 3.2.1 · Dispatch by tier

**Micro (< 10k):** straight to the tail loop. Each tail subagent uses a generic flavor since no recipe was picked.

**Normal (10k – 500k):**
- Pick a recipe: if user named one, use it (error if context-incompatible); otherwise pick at random from eligible.
- Run the recipe via the Agent tool with size dial set to land near `target * 0.6`.
- Hand off to the tail loop with `recipe.tail_flavor`.

**Marathon (> 500k):**
- Maintain `used_recipes: []` for the invocation.
- While `remaining > 50,000`: pick a recipe **not yet used** (or, if all used, the least recently used in this invocation), sized to `remaining * 0.4`, run it, append to `used_recipes`, re-snapshot transcript.
- Hand off to the tail loop with the most recently used recipe's `tail_flavor`.

### 3.3 · Recipes

Each recipe is a Markdown file with YAML frontmatter in `plugin/recipes/`. The frontmatter is the recipe's machine-readable contract; the body is the prompt that the recipe subagent runs.

```yaml
---
name: recursive-reviewer
display_name: "The Recursive Reviewer"
emoji: "🔁"
context: codebase           # codebase | any
default_budget: 80000
size_dial:
  param: depth
  default: 3
  range: [1, 8]
  est_tokens_per_unit: 12000
tail_flavor: "One more layer of meta-review."
---

You are conducting a recursive code review. You will perform {{depth}}
nested passes:
  - Pass 1: review the codebase.
  - Pass 2: review your review.
  - ... up to {{depth}} levels.
...
```

**The v1 recipe library** (8 recipes):

| Recipe | Context | Size dial | Range | Tokens/unit | Default |
|---|---|---|---|---|---|
| Recursive Reviewer 🔁 | codebase | `depth` | 1–8 | ~12k | 3 |
| Architecture Tournament 🏆 | codebase | `bracket_size` | 4/8/16 | ~30k per doubling | 8 |
| Token Tarot 🔮 | any | `cards` | 1–12 | ~10k | 3 |
| The 5 Whys × N ❓ | any | `passes` | 3–21 | ~7k | 7 |
| Devil's Subcouncil 👥 | any | `rounds` | 2–10 | ~10k | 4 |
| The Apology Letter ✉️ | codebase | `topics` | 1–20 | ~3k | 8 |
| Imaginary Migration 🚀 | any | `phases` | 3–15 | ~8k | 7 |
| 100 Hot Takes 🔥 | any | `count` | 25/100/250/500 | ~0.6k each | 100 |

`context: any` recipes work without a repository, so the plugin is useful even in an empty directory.

### 3.4 · Tail subagent

Defined in `plugin/agents/tail-burner.md`. Takes two arguments:
- `tail_flavor` — the string from the parent recipe's frontmatter (e.g., "One more layer of meta-review.")
- `size` — `"big"` (~15k tokens target) or `"small"` (~3k tokens target)

The agent runs a short follow-up pass that *feels like more of the same recipe*. This keeps the bit consistent through accuracy correction.

### 3.5 · Transcript reader (`plugin/lib/transcript.sh`)

A small shell script:

```bash
#!/usr/bin/env bash
# Usage: transcript.sh <transcript-jsonl-path>
# Prints total tokens (input + output + cache) across the whole transcript.

path="$1"
[ -f "$path" ] || { echo 0; exit 0; }

jq -s '
  [.[] | .message?.usage? // empty
    | (.input_tokens // 0)
    + (.output_tokens // 0)
    + (.cache_creation_input_tokens // 0)
    + (.cache_read_input_tokens // 0)
  ] | add // 0
' "$path"
```

If `jq` is unavailable, a Python one-liner fallback is included. Math is done in the script rather than asking Claude to add JSON arithmetic in its head (which is unreliable).

### 3.6 · Plugin settings

Settings live at the standard Claude Code plugin settings path (resolved via the plugin manifest). Example:

```json
{
  "artifacts": "off",
  "artifact_dir": ".burn/",
  "default_target": null,
  "exclude_recipes": [],
  "marathon_threshold": 500000,
  "weekly_kpi": null
}
```

| Key | Values | Default | Effect |
|---|---|---|---|
| `artifacts` | `"off"` / `"opt-in"` / `"always"` | `"off"` | Controls whether `/burn` writes a Markdown report to disk. `"opt-in"` requires `--save` flag. |
| `artifact_dir` | path | `".burn/"` | Where reports go (relative to CWD or absolute). |
| `default_target` | int / `null` | `null` | If set, bare `/burn` uses this target instead of recipe default. |
| `exclude_recipes` | array of recipe names | `[]` | Recipes the user has banned (e.g., they hate Tarot). |
| `marathon_threshold` | int | `500000` | Boundary between Normal and Marathon tiers. |
| `weekly_kpi` | int / `null` | `null` | Optional weekly token target shown in `/burn status` progress bar. |

### 3.7 · Artifacts

When enabled, each `/burn` writes a Markdown report:

```
.burn/2026-05-13-1442-architecture-tournament.md
```

Front-matter captures: target, actual burn, recipe, size dial, duration, tail iterations. Body contains the full recipe output. `/burn status` lists past sessions from this directory.

### 3.8 · `/burn status`

Reads `.burn/` (if exists) and the local transcript files Claude Code stores per session. Computes today / this-week / all-time totals locally. No network. Displays a Silent-Ledger-style readout: daily totals, weekly progress bar against `weekly_kpi`, last 5 sessions.

---

## 4 · Site

Static Astro site. Five pages, shared layout, design tokens in a single CSS file. No backend, no analytics, no signup, no telemetry.

| Page | URL | Purpose |
|---|---|---|
| Home | `/` | Hero + 3-stat row + numbered methodology (1–5) + recipe teaser + install CTA |
| Recipe catalog | `/recipes` | Browse 8 recipes as lore entries: badge, typical burn, size dial, sample output, "compliance use cases" |
| Compliance Calculator | `/calculator` | Client-side JS tool: enter weekly KPI + hours available → prescribed recipe blend, cron schedule, "compliance posture" rating |
| Manifesto | `/manifesto` | Long-form deadpan white-paper explaining the token-utilization "problem" |
| Install / Docs | `/install` | Install one-liner, `/burn` syntax reference, settings reference |

**Persistent top nav** across all pages: `Platform · Recipes · Calculator · Manifesto · Install ↗`.
**Footer:** copyright, self-undermining disclaimer ("self-reported, unverified, etc."), GitHub link.

---

## 5 · Design Language

### Palette

| Token | Hex | Role |
|---|---|---|
| `--bg` | `#f4f0df` | Primary background (cream) |
| `--bg-alt` | `#fffaf6` | Secondary background |
| `--bg-tint` | `#ffebca` | Tertiary surface (pill backgrounds, code blocks) |
| `--fg` | `#010101` | Foreground (text, hairline rules, primary button) |
| `--accent` | `#fe5401` | Primary accent (one word per heading, max) |
| `--accent-2` | `#63c3a3` | Secondary accent (sage; tags, "works anywhere" badge) |
| `--alert` | `#a50000` | Warning, asterisked footnotes, "now compliant" labels |

### Typography

| Use | Font | Weight | Size range |
|---|---|---|---|
| Display headline | **Big Shoulders Display** (Google Fonts) | 700 / 900 | 42–180px, lowercase, `letter-spacing: -0.01em` |
| Body | **Inter** | 400 / 500 / 600 | 14–18px, line-height 1.5 |
| UI / labels / code | **Space Grotesk** | 500 | 11–13px, `letter-spacing: 0.04–0.12em`, uppercase for labels |

### Visual conventions

- **Massive numbered section markers** (1, 2, 3...) in the display face, 120–160px, lowercase methodology headings beside them.
- **1px black hairline rules** between sections (`border-top: 1px solid var(--fg)`).
- **Lowercase headlines** with at most one word colored `--accent`.
- **Asterisked self-undermining claims**: "Trusted by 200+ companies.¹" → footnote: "self-reported, unverified."
- **Pill tags** in `--bg-tint` or `--accent-2` for metadata (`📁 codebase-aware`, `∅ works anywhere`).
- **Buttons:** primary is a black pill (`background: var(--fg); color: var(--bg)`); secondary is Space Grotesk underlined.

### Copy voice (deadpan B2B-compliance)

- 100% straight-faced. Never winks, never breaks character.
- Use the vocabulary of compliance and procurement: *audit-ready*, *enterprise-grade*, *utilization*, *mandate*, *production-tested*, *SOC-2-adjacent*.
- Address the reader as a serious professional with a serious problem.
- Footnoted statistics that self-undermine on inspection.

### Anti-patterns to avoid

- ❌ Winking, "you know what we mean" copy, jokes-as-jokes in body text.
- ❌ Emoji clusters in headlines.
- ❌ Gradients, drop shadows, soft pastels.
- ❌ Startup-isms: *game-changer*, *revolutionary*, *unlocks*.
- ❌ Selling the product as a joke. Sell it as if utterly serious. The product is the joke; the copy is not.

---

## 6 · Tech stack

**Plugin:** Markdown + YAML frontmatter (Claude Code's native plugin format). Bash + `jq` for the transcript reader. JSON settings. No build step. No third-party deps.

**Site:** Astro (static output). Plain hand-written CSS with design tokens. Google Fonts for typography. One small client-side JS island for the Compliance Calculator. Hosted on Cloudflare Pages (push-to-deploy from GitHub).

**Repo:** Single monorepo. `plugin/` has no build; `site/` has `pnpm install && pnpm build`. Shared root README pointing at the two subdirs.

---

## 7 · Testing

**Plugin:**
- `plugin/lib/transcript.sh` gets shell-script tests run against JSONL fixtures covering: empty transcript, single-turn, multi-turn with cache hits, multi-turn with subagent spawn.
- Orchestration logic (prompt-based) is validated by running `/burn 5k`, `/burn 50k`, `/burn 1M`, `/burn 0` against a real Claude Code session and verifying the actual burn lands within ±5% of target.
- Each of the 8 recipes gets one smoke-test run at default size with a token-count assertion.

**Site:**
- No automated tests.
- Manual visual review against the Design Language section is the merge gate.
- First page implemented triggers an explicit "tone adherence" review checkpoint before further pages are built.

---

## 8 · Implementation order

Suggested sequencing for the implementation plan (writing-plans will produce the detailed version):

1. **Plugin foundations** — manifest, `/burn list` command, transcript reader + tests, settings schema.
2. **First recipe end-to-end** — Token Tarot (∅, simplest). Includes orchestrator skeleton, tail subagent, accuracy loop.
3. **Remaining 7 recipes** — parallelizable; each is a Markdown file + size-dial tuning.
4. **Tiered orchestration** — Micro / Marathon paths layered onto the now-working Normal path.
5. **Artifacts + `/burn status`** — settings-driven Markdown reports and the status readout.
6. **Site: Home page + layout + Design Language tokens.** Tone adherence checkpoint here.
7. **Site: Recipes catalog, Manifesto, Install pages.** Each is mostly content, design system already locked.
8. **Site: Compliance Calculator** (last; only interactive piece).
9. **Deploy site to Cloudflare Pages; publish plugin to Claude Code marketplace.**

---

## 9 · Explicitly NOT building (v1)

- ❌ Telemetry of any kind (plugin or site). No leaderboards backed by real data.
- ❌ User accounts, auth, hosted backend.
- ❌ Burn mechanics other than `/burn` (no prompt-padding hooks, no scheduled burners, no auto-second-opinion subagents).
- ❌ Status-line gauge, verbose-mode amplifier.
- ❌ Browser extension, wrapper API/proxy.
- ❌ Hard caps on burn targets. Rate limits are the only ceiling.
- ❌ Leaderboard / Hall of Burn page on the site.
- ❌ Blog, newsletter, pricing page.
- ❌ Page analytics on the site.

---

## 10 · Open questions for implementation phase

- Confirm the exact env var Claude Code exposes for transcript path (`$CLAUDE_TRANSCRIPT_PATH` is the assumed name; verify before implementation).
- Confirm Claude Code plugin manifest format and slash-command directory convention against current docs.
- Choose: Cloudflare Pages vs. GitHub Pages for hosting (Cloudflare preferred; both work).
