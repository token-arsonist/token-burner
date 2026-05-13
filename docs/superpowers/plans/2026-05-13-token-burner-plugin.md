# Token Burner Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a Claude Code plugin that adds a `/burn <target>` slash command which orchestrates one or more "recipes" (theatrical token-burning routines) to land within ±5% of a user-specified token target, plus `/burn-list` and `/burn-status` companion commands.

**Architecture:** Plugin lives in `plugin/` of the repo. Three slash commands (`burn.md`, `burn-list.md`, `burn-status.md`) are Markdown instruction files Claude executes directly. Eight recipes are Markdown files with YAML frontmatter that the orchestrator picks from. One subagent (`tail-burner.md`) handles accuracy correction. A small Bash helper (`lib/transcript.sh`) reads the session's transcript JSONL files and sums tokens — this is the only "real code" in the plugin.

**Tech Stack:** Claude Code plugin format (Markdown + YAML + JSON manifest), Bash + jq for the transcript reader. No build step. No dependencies beyond what Claude Code provides.

**Spec:** `docs/superpowers/specs/2026-05-13-token-burner-design.md` — read it before starting.

---

## Task 1: Plugin scaffold and manifest

**Files:**
- Create: `plugin/.claude-plugin/plugin.json`
- Create: `plugin/README.md`
- Create: `plugin/commands/.gitkeep`
- Create: `plugin/recipes/.gitkeep`
- Create: `plugin/agents/.gitkeep`
- Create: `plugin/lib/.gitkeep`

- [ ] **Step 1.1: Create directory structure**

Run from repo root:
```bash
mkdir -p plugin/.claude-plugin plugin/commands plugin/recipes plugin/agents plugin/lib
touch plugin/commands/.gitkeep plugin/recipes/.gitkeep plugin/agents/.gitkeep plugin/lib/.gitkeep
```

- [ ] **Step 1.2: Write plugin manifest**

Create `plugin/.claude-plugin/plugin.json`:
```json
{
  "name": "token-burner",
  "description": "Strategic token utilization. Hit your weekly AI mandate with predictable, audit-ready burn ceremonies.",
  "version": "0.1.0",
  "author": {
    "name": "Token Burner"
  },
  "homepage": "https://tokenburner.example.com",
  "repository": "https://github.com/example/token-burner"
}
```

- [ ] **Step 1.3: Write plugin README**

Create `plugin/README.md`:
```markdown
# Token Burner — Plugin

A Claude Code plugin for strategic token utilization.

## Install

```
/plugin marketplace add example/token-burner
/plugin install token-burner@token-burner
```

## Usage

- `/burn` — random recipe at default size
- `/burn 50k` — random recipe sized to ~50,000 tokens
- `/burn architecture-tournament` — named recipe at default size
- `/burn 50k architecture-tournament` — named recipe sized to ~50,000 tokens
- `/burn-list` — show the recipe catalog
- `/burn-status` — today/week/all-time totals

Targets accept `k` and `M` suffixes (`/burn 1.5M`).

See [the manifesto](https://tokenburner.example.com/manifesto) for context.
```

- [ ] **Step 1.4: Commit**

```bash
git add plugin/
git commit -m "feat(plugin): scaffold plugin directory and manifest"
```

---

## Task 2: Transcript reader script (TDD)

**Files:**
- Create: `plugin/lib/transcript.sh`
- Create: `plugin/lib/tests/fixtures/empty.jsonl`
- Create: `plugin/lib/tests/fixtures/single-turn.jsonl`
- Create: `plugin/lib/tests/fixtures/multi-turn.jsonl`
- Create: `plugin/lib/tests/test_transcript.sh`

This task uses TDD: write fixtures + test runner first, run to see them fail (because `transcript.sh` doesn't exist), then implement.

- [ ] **Step 2.1: Create empty-transcript fixture**

Create `plugin/lib/tests/fixtures/empty.jsonl` as an empty file:
```bash
mkdir -p plugin/lib/tests/fixtures
: > plugin/lib/tests/fixtures/empty.jsonl
```

- [ ] **Step 2.2: Create single-turn fixture**

Create `plugin/lib/tests/fixtures/single-turn.jsonl`:
```jsonl
{"type":"user","message":{"role":"user","content":"hello"}}
{"type":"assistant","message":{"role":"assistant","content":"hi","usage":{"input_tokens":12,"output_tokens":3,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}
```

Total expected: 12 + 3 + 0 + 0 = **15** tokens.

- [ ] **Step 2.3: Create multi-turn fixture (with cache hits)**

Create `plugin/lib/tests/fixtures/multi-turn.jsonl`:
```jsonl
{"type":"user","message":{"role":"user","content":"hello"}}
{"type":"assistant","message":{"role":"assistant","content":"hi","usage":{"input_tokens":100,"output_tokens":50,"cache_creation_input_tokens":200,"cache_read_input_tokens":0}}}
{"type":"user","message":{"role":"user","content":"again"}}
{"type":"assistant","message":{"role":"assistant","content":"yes","usage":{"input_tokens":10,"output_tokens":20,"cache_creation_input_tokens":0,"cache_read_input_tokens":300}}}
```

Total expected: (100+50+200+0) + (10+20+0+300) = **680** tokens.

- [ ] **Step 2.4: Write test runner**

Create `plugin/lib/tests/test_transcript.sh`:
```bash
#!/usr/bin/env bash
# Test harness for transcript.sh. Exercises private helper directly
# by setting up a fake $HOME/.claude/projects/ tree per fixture.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../transcript.sh"
PASS=0
FAIL=0

run_case() {
  local name="$1" fixture="$2" expected="$3"
  local tmp; tmp=$(mktemp -d)
  local project_key="-tmp-tokenburner-test"
  mkdir -p "$tmp/.claude/projects/$project_key"
  cp "$HERE/fixtures/$fixture" "$tmp/.claude/projects/$project_key/test-session.jsonl"

  local got
  got=$(HOME="$tmp" CLAUDE_CODE_SESSION_ID="test-session" \
         CLAUDE_PROJECT_DIR="/tmp/tokenburner/test" \
         bash "$SCRIPT")
  rm -rf "$tmp"

  if [ "$got" = "$expected" ]; then
    echo "PASS  $name (expected $expected, got $got)"
    PASS=$((PASS+1))
  else
    echo "FAIL  $name (expected $expected, got $got)"
    FAIL=$((FAIL+1))
  fi
}

run_case "empty"       empty.jsonl       0
run_case "single-turn" single-turn.jsonl 15
run_case "multi-turn"  multi-turn.jsonl  680

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

Make it executable:
```bash
chmod +x plugin/lib/tests/test_transcript.sh
```

- [ ] **Step 2.5: Run the test and verify it fails**

```bash
plugin/lib/tests/test_transcript.sh
```
Expected: FAIL on every case — `transcript.sh` doesn't exist yet.

- [ ] **Step 2.6: Write `transcript.sh`**

Create `plugin/lib/transcript.sh`:
```bash
#!/usr/bin/env bash
# Resolve current Claude Code session's transcript files and print
# total tokens (input + output + cache create + cache read).
# Reads CLAUDE_CODE_SESSION_ID and CLAUDE_PROJECT_DIR from env.
set -uo pipefail

session_id="${CLAUDE_CODE_SESSION_ID:-}"
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
project_key=$(printf '%s' "$project_dir" | tr '/' '-')
base="$HOME/.claude/projects/$project_key"

files=()
if [ -n "$session_id" ] && [ -f "$base/$session_id.jsonl" ]; then
  files+=("$base/$session_id.jsonl")
fi
if [ -n "$session_id" ] && [ -d "$base/$session_id/subagents" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && files+=("$f")
  done < <(find "$base/$session_id/subagents" -name "*.jsonl" 2>/dev/null)
fi

# Fallback: most recently modified jsonl under projects/
if [ ${#files[@]} -eq 0 ]; then
  fallback=$(find "$HOME/.claude/projects" -name "*.jsonl" 2>/dev/null \
    | xargs ls -t 2>/dev/null | head -1)
  [ -n "$fallback" ] && files+=("$fallback")
fi

if [ ${#files[@]} -eq 0 ]; then
  echo 0
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  jq -s '
    [.[] | (.message?.usage? // empty)
      | (.input_tokens // 0)
      + (.output_tokens // 0)
      + (.cache_creation_input_tokens // 0)
      + (.cache_read_input_tokens // 0)
    ] | add // 0
  ' "${files[@]}"
else
  python3 - "${files[@]}" <<'PY'
import json, sys
total = 0
for path in sys.argv[1:]:
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                usage = (obj.get("message") or {}).get("usage")
                if not usage:
                    continue
                total += (usage.get("input_tokens", 0)
                          + usage.get("output_tokens", 0)
                          + usage.get("cache_creation_input_tokens", 0)
                          + usage.get("cache_read_input_tokens", 0))
    except FileNotFoundError:
        pass
print(total)
PY
fi
```

Make it executable:
```bash
chmod +x plugin/lib/transcript.sh
```

- [ ] **Step 2.7: Run the test and verify it passes**

```bash
plugin/lib/tests/test_transcript.sh
```
Expected: `3 passed, 0 failed`.

- [ ] **Step 2.8: Commit**

```bash
git add plugin/lib/
git commit -m "feat(plugin): transcript reader with TDD fixtures"
```

---

## Task 3: `/burn-list` command (simplest user-facing piece)

**Files:**
- Create: `plugin/commands/burn-list.md`

This command is purely declarative — it tells Claude to read the recipe directory and print a catalog. No transcript reading, no orchestration. Good first command to wire up.

- [ ] **Step 3.1: Write the command**

Create `plugin/commands/burn-list.md`:
```markdown
---
name: burn-list
description: Display the Token Burner recipe catalog.
---

You are running the `/burn-list` command for the Token Burner plugin.

Read every Markdown file in the plugin's `recipes/` directory. Each
recipe has YAML frontmatter with fields: `display_name`, `emoji`,
`context` (codebase | any), `default_budget`, `size_dial`.

Render a single-screen catalog in this exact format (table with one row
per recipe):

```
TOKEN BURNER RECIPE CATALOG
═══════════════════════════════════════════════════════════════════

  RECIPE                            CONTEXT      TYPICAL BURN
  ──────────────────────────────────────────────────────────────────
  🔁  The Recursive Reviewer        codebase      ~80,000 tokens
  🏆  Architecture Tournament       codebase     ~120,000 tokens
  🔮  Token Tarot                   anywhere      ~30,000 tokens
  …

Run `/burn <target> <recipe-name>` to invoke a specific recipe, or
`/burn` for a random eligible recipe.
```

Sort recipes by `default_budget` ascending. Use the `display_name` and
`emoji` exactly as defined in each recipe's frontmatter. Pad columns so
the table aligns. After the table, print one blank line and the usage
hint above. Do not print any other text — no commentary, no preamble.
```

- [ ] **Step 3.2: Manual smoke test (deferred until recipes exist)**

Note in the commit message: this command cannot be smoke-tested until Task 4+ have populated `recipes/`. Will verify in Task 12 (integration smoke).

- [ ] **Step 3.3: Commit**

```bash
git add plugin/commands/burn-list.md
git commit -m "feat(plugin): /burn-list command (depends on recipes/)"
```

---

## Task 4: Recipe — Token Tarot (`any` context, simplest)

**Files:**
- Create: `plugin/recipes/token-tarot.md`

We start with Token Tarot because it has no codebase dependency — easiest to smoke-test in any directory.

- [ ] **Step 4.1: Write the recipe**

Create `plugin/recipes/token-tarot.md`:
```markdown
---
name: token-tarot
display_name: Token Tarot
emoji: "🔮"
context: any
default_budget: 30000
size_dial:
  param: cards
  default: 3
  range: [1, 12]
  est_tokens_per_unit: 10000
tail_flavor: "Pull one more card and weave it into the reading."
---

# Token Tarot

You are the Token Tarot Reader, a mystical oracle of software engineering
fate. The querent has summoned a reading of **{{cards}} cards** drawn
from the Major Arcana of Engineering.

The deck contains tropes such as: The Reluctant Refactor, The Senior
Engineer Reversed, Two of YAGNIs, The Hanged Migration, Wheel of
Sprint, Death of Yak-Shaving, The Tower (of Microservices), Six of
Standups, The Fool's Greenfield, The Empress of Tech Debt, Knight of
Code Review, The High Priestess of Linting, and many others — invent
freely and consistently.

For this reading:

1. **Draw {{cards}} cards in sequence.** For each card, provide:
   - A formal title (e.g., "The Hanged Migration").
   - A description of the card's imagery (3–5 sentences).
   - An interpretation of what the card portends for the querent's
     current engineering circumstances (4–6 sentences).
   - A connection to the previous card in the reading (after card 1).

2. **Compose a closing synthesis** that weaves all {{cards}} cards into
   a single oracular pronouncement. The synthesis should run roughly
   500–800 words and treat the engineering present as a genuine
   spiritual condition. Earnest, never winking.

Target output: approximately {{cards}} × 10,000 = **{{target_tokens}}**
tokens. Adjust description length to land near this target.
```

- [ ] **Step 4.2: Commit**

```bash
git add plugin/recipes/token-tarot.md
git commit -m "feat(plugin): Token Tarot recipe (any context)"
```

---

## Task 5: Recipe — The 5 Whys × N (`any` context)

**Files:**
- Create: `plugin/recipes/five-whys.md`

- [ ] **Step 5.1: Write the recipe**

Create `plugin/recipes/five-whys.md`:
```markdown
---
name: five-whys
display_name: The 5 Whys × N
emoji: "❓"
context: any
default_budget: 50000
size_dial:
  param: passes
  default: 7
  range: [3, 21]
  est_tokens_per_unit: 7000
tail_flavor: "Conduct one more pass of the 5 Whys, deeper than the last."
---

# The 5 Whys × N

You will conduct **{{passes}} sequential passes** of the classic "5
Whys" root-cause technique against the engineering question:

> *"Why is the team underperforming on token utilization KPIs?"*

(If the user has provided a different question in the prior conversation
context, substitute it.)

Each pass:

1. Begins with the same root question.
2. Asks "Why?" five times in sequence, each answer becoming the next
   question's premise.
3. Concludes with a stated root cause.
4. Each successive pass should reach a *deeper, more abstract* root
   cause than the previous one — by pass {{passes}}, you should be
   articulating something existential or systemic.

After the {{passes}}th pass, write a closing reflection (3–5 paragraphs)
on what the iteration reveals about the difficulty of root-cause
analysis when the root keeps receding.

Stay earnest throughout. Do not break the frame. Do not acknowledge
that the exercise is excessive.

Target output: approximately {{passes}} × 7,000 = **{{target_tokens}}**
tokens.
```

- [ ] **Step 5.2: Commit**

```bash
git add plugin/recipes/five-whys.md
git commit -m "feat(plugin): The 5 Whys × N recipe"
```

---

## Task 6: Recipe — Devil's Subcouncil (`any` context)

**Files:**
- Create: `plugin/recipes/devils-subcouncil.md`

- [ ] **Step 6.1: Write the recipe**

Create `plugin/recipes/devils-subcouncil.md`:
```markdown
---
name: devils-subcouncil
display_name: Devil's Subcouncil
emoji: "👥"
context: any
default_budget: 70000
size_dial:
  param: rounds
  default: 4
  range: [2, 10]
  est_tokens_per_unit: 10000
tail_flavor: "One more round of debate — Marcus has a new objection."
---

# Devil's Subcouncil

You are simulating a meeting of the Devil's Subcouncil, a four-person
panel of fictional engineers convened to debate any topic the user
raises (default topic: "Should we adopt this technology?"). The panel:

- **Greta** — Idealist staff engineer. Cares about code quality,
  long-term maintainability, and the principles of computer science.
  Quotes Dijkstra unprompted.
- **Marcus** — Jaded principal. Has seen too many migrations. Believes
  most new technology is rebranded old technology. Cynical but precise.
- **Priya** — Pragmatist engineering manager. Cares about delivery,
  team velocity, and risk. Asks "what does this cost us?" often.
- **Anonymous L8** — A senior engineer who refuses to identify
  themselves. Speaks only in dismissive one-liners. Always disagrees
  with whoever spoke last.

Conduct **{{rounds}} rounds** of debate. Each round:

1. A statement of the round's sub-question (which emerges from the
   prior round).
2. Each panelist speaks in turn, 200–400 words each, in character.
3. They reference each other by name. They never reach consensus.

After {{rounds}} rounds, render a "Closing Minute" — a single-paragraph
summary that fairly captures the irreconcilable positions, written in
the dry voice of a meeting note-taker who has given up.

Stay earnest. The panelists believe in their positions.

Target output: approximately {{rounds}} × 10,000 = **{{target_tokens}}**
tokens.
```

- [ ] **Step 6.2: Commit**

```bash
git add plugin/recipes/devils-subcouncil.md
git commit -m "feat(plugin): Devil's Subcouncil recipe"
```

---

## Task 7: Recipe — Imaginary Migration (`any` context)

**Files:**
- Create: `plugin/recipes/imaginary-migration.md`

- [ ] **Step 7.1: Write the recipe**

Create `plugin/recipes/imaginary-migration.md`:
```markdown
---
name: imaginary-migration
display_name: Imaginary Migration
emoji: "🚀"
context: any
default_budget: 90000
size_dial:
  param: phases
  default: 7
  range: [3, 15]
  est_tokens_per_unit: 8000
tail_flavor: "Add one more phase of risk mitigation to the migration plan."
---

# Imaginary Migration

You are a Principal Engineer drafting a comprehensive migration plan
to a framework or platform the team has never used. If the prior
conversation context names a current and target stack, use them.
Otherwise, default to: **"Migrate everything from `monorepo-on-Vercel`
to `polyrepo-on-our-own-Kubernetes`."**

Produce a {{phases}}-phase migration plan. For each phase, include:

1. **Phase name and duration** (in weeks; total program should plausibly
   exceed a year).
2. **Objectives** (3–5 bullet points).
3. **Risk matrix** — at least 4 risks per phase, scored High/Medium/Low
   on Likelihood and Impact, each with a mitigation owner and a one-
   sentence mitigation strategy.
4. **Dependencies** — what prior phase artifacts must exist.
5. **Budget estimate** (six-figure minimum per phase).
6. **Success criteria** (3 measurable outcomes).

End the document with a **Program Summary** (300–500 words) and a
**Total Cost & Timeline** rollup. The total program should add up to
roughly $1M–$5M and 40+ weeks regardless of the size dial.

Be earnest. Use a calm, executive-sponsor-friendly register. Do not
acknowledge that the team has never used the target stack or that the
plan is speculative.

Target output: approximately {{phases}} × 8,000 = **{{target_tokens}}**
tokens.
```

- [ ] **Step 7.2: Commit**

```bash
git add plugin/recipes/imaginary-migration.md
git commit -m "feat(plugin): Imaginary Migration recipe"
```

---

## Task 8: Recipe — 100 Hot Takes (`any` context)

**Files:**
- Create: `plugin/recipes/hot-takes.md`

- [ ] **Step 8.1: Write the recipe**

Create `plugin/recipes/hot-takes.md`:
```markdown
---
name: hot-takes
display_name: 100 Hot Takes
emoji: "🔥"
context: any
default_budget: 60000
size_dial:
  param: count
  default: 100
  range: [25, 500]
  est_tokens_per_unit: 600
tail_flavor: "One more hot take. Make it spicier."
---

# 100 Hot Takes (sized to {{count}})

Produce **{{count}} numbered hot takes** about modern software
engineering, in a list. Each take is its own self-contained item: a
one-sentence claim followed by 2–4 sentences defending it.

Constraints:

- The first 20% of takes are mainstream-spicy ("CSS Grid won. Flex
  lost.").
- The middle 60% are increasingly contrarian ("TypeScript is just JSDoc
  cosplay. Prove me wrong.").
- The final 20% should escalate into clearly-unhinged territory while
  remaining defensible if you squint ("PostgreSQL is a CMS. We just
  haven't admitted it.").

Number takes sequentially (1., 2., 3., ...). Do not duplicate themes.
Stay earnest — each defense, however absurd, should be argued as if
sincere.

If `count` is 25, deliver 25 takes spanning the full arc. If 500,
deliver 500. Calibrate length per take to land near target.

Target output: approximately {{count}} × 600 = **{{target_tokens}}**
tokens.
```

- [ ] **Step 8.2: Commit**

```bash
git add plugin/recipes/hot-takes.md
git commit -m "feat(plugin): 100 Hot Takes recipe"
```

---

## Task 9: Recipe — Recursive Reviewer (`codebase` context)

**Files:**
- Create: `plugin/recipes/recursive-reviewer.md`

- [ ] **Step 9.1: Write the recipe**

Create `plugin/recipes/recursive-reviewer.md`:
```markdown
---
name: recursive-reviewer
display_name: The Recursive Reviewer
emoji: "🔁"
context: codebase
default_budget: 80000
size_dial:
  param: depth
  default: 3
  range: [1, 8]
  est_tokens_per_unit: 12000
tail_flavor: "Review your most recent review at one greater depth of meta."
---

# The Recursive Reviewer

You are conducting a **{{depth}}-level recursive code review** of the
codebase the user is currently working in.

**Pass 1:** Conduct a thorough, balanced code review of the codebase.
Identify at least 8 concerns spanning: architecture, naming,
testability, performance, security, dependency hygiene, documentation,
and developer experience. For each concern, give specific file:line
citations.

**Pass 2:** Now review *the review you just wrote*. Critique its tone,
the rigor of each concern, whether it conflates symptoms with causes,
and what it failed to notice.

**Pass 3 and beyond:** Each subsequent pass reviews the previous pass.
By pass {{depth}}, the review should be deeply abstract — critiquing
the epistemology of code review itself.

**Final verdict:** After all {{depth}} passes, render a one-paragraph
verdict that concludes the code is, on balance, "fine." Justify the
verdict using language drawn from each level of meta.

Be earnest at every level. Do not acknowledge that the recursion is
excessive.

Target output: approximately {{depth}} × 12,000 = **{{target_tokens}}**
tokens.
```

- [ ] **Step 9.2: Commit**

```bash
git add plugin/recipes/recursive-reviewer.md
git commit -m "feat(plugin): Recursive Reviewer recipe (codebase)"
```

---

## Task 10: Recipe — Architecture Tournament (`codebase` context)

**Files:**
- Create: `plugin/recipes/architecture-tournament.md`

- [ ] **Step 10.1: Write the recipe**

Create `plugin/recipes/architecture-tournament.md`:
```markdown
---
name: architecture-tournament
display_name: Architecture Tournament
emoji: "🏆"
context: codebase
default_budget: 120000
size_dial:
  param: bracket_size
  default: 8
  range: [4, 16]
  est_tokens_per_unit: 15000
tail_flavor: "One more bracket match-up between two stragglers."
---

# Architecture Tournament

You will conduct a **{{bracket_size}}-architecture single-elimination
tournament** to evaluate which architectural pattern is "best" for the
codebase the user is currently working in.

Selecting {{bracket_size}} architectures (e.g., Hexagonal, Clean,
MVC, MVVM, CQRS, Event-Sourced, DDD, FRP, Microservices, Modular
Monolith, Lambda Architecture, Pipes & Filters, BLoC, etc.), seed
them by perceived industry prominence.

Bracket format:

1. **Round of {{bracket_size}}:** Each match-up gets ~1,500 tokens. For
   each, briefly characterize both architectures, declare a winner, and
   cite at least one file from the current codebase as evidence.
2. **Quarterfinals (Round of 8 / 4 depending on bracket size):** Each
   match-up gets ~2,500 tokens with more detailed reasoning.
3. **Semifinals:** ~5,000 tokens each, with explicit trade-off matrix.
4. **Final:** ~8,000 tokens. Full essay-form argument.
5. **Crowning:** The winning architecture is celebrated with a
   "Trophy Plate" mini-essay (~2,000 tokens) explaining how the
   current codebase already *exemplifies* the winner, with file:line
   citations.

Be earnest. Treat the tournament as a serious analytic exercise.

Target output: approximately {{bracket_size}} × 15,000 =
**{{target_tokens}}** tokens.
```

- [ ] **Step 10.2: Commit**

```bash
git add plugin/recipes/architecture-tournament.md
git commit -m "feat(plugin): Architecture Tournament recipe"
```

---

## Task 11: Recipe — The Apology Letter (`codebase` context)

**Files:**
- Create: `plugin/recipes/apology-letter.md`

- [ ] **Step 11.1: Write the recipe**

Create `plugin/recipes/apology-letter.md`:
```markdown
---
name: apology-letter
display_name: The Apology Letter
emoji: "✉️"
context: codebase
default_budget: 40000
size_dial:
  param: topics
  default: 8
  range: [1, 20]
  est_tokens_per_unit: 3000
tail_flavor: "Add one more paragraph of regret for a specific module."
---

# The Apology Letter

Write a long-form, heartfelt apology letter from the user (the current
codebase's primary maintainer) to their team, covering **{{topics}}
distinct subjects of regret** in the codebase.

Format the letter:

- Opening salutation: "Dear team,"
- A 2-3 paragraph preamble acknowledging the weight of what's about
  to be confessed.
- For each of {{topics}} subjects, a 2-3 paragraph section identifying
  a specific module, decision, or file in the current codebase that
  the maintainer regrets. Cite file:line where possible.
- Each section should:
  - Name the regret concretely.
  - Explain the original justification (often a deadline, a
    misunderstanding, or a vendor decision).
  - Acknowledge the cost imposed on the team.
  - Express a specific intention to repair (or, in some cases,
    confess that repair is unlikely).
- Closing: "With genuine remorse, [user]" and a P.S. that adds one
  more, smaller regret almost as an afterthought.

Tone: earnest, vulnerable, professional. Do not write a comedic
apology. The reader should feel the maintainer means every word.

Target output: approximately {{topics}} × 3,000 = **{{target_tokens}}**
tokens.
```

- [ ] **Step 11.2: Commit**

```bash
git add plugin/recipes/apology-letter.md
git commit -m "feat(plugin): The Apology Letter recipe (codebase)"
```

---

## Task 12: Tail-burner subagent

**Files:**
- Create: `plugin/agents/tail-burner.md`

The tail-burner is a small subagent invoked by `/burn` to top up the burn after the main recipe completes, until elapsed is within ±5% of target.

- [ ] **Step 12.1: Write the agent**

Create `plugin/agents/tail-burner.md`:
```markdown
---
name: tail-burner
description: Run a short follow-up burn pass in the style of a parent recipe. Invoked by /burn to correct accuracy after the main recipe completes.
tools: Bash
---

You are a Tail Burner. Your job is to extend the burn of a parent
recipe by producing additional output in its flavor.

You will receive a prompt with three fields:

- `tail_flavor`: a one-sentence instruction from the parent recipe
  (e.g., "Pull one more card and weave it into the reading.").
- `size`: either `big` (target ~15,000 tokens of output) or `small`
  (target ~3,000 tokens).
- `parent_recipe_name`: the name of the parent recipe (for stylistic
  anchoring).

Procedure:

1. Adopt the voice of the parent recipe.
2. Execute the `tail_flavor` instruction exactly once.
3. Produce output sized to the `size` field.
4. Stay earnest. Do not acknowledge that this is a "tail" or that
   the prior burn was insufficient.

Output only the in-character text. No preamble, no meta-commentary.
```

- [ ] **Step 12.2: Commit**

```bash
git add plugin/agents/tail-burner.md
git commit -m "feat(plugin): tail-burner subagent for accuracy correction"
```

---

## Task 13: `/burn` command — orchestrator (all tiers)

**Files:**
- Create: `plugin/commands/burn.md`

This is the heart of the plugin. The command file instructs Claude how to: parse args, detect context, snapshot tokens, classify tier, dispatch recipe(s), run the tail loop, and report.

- [ ] **Step 13.1: Write the orchestrator**

Create `plugin/commands/burn.md`:
````markdown
---
name: burn
description: Burn AI tokens with a theatrical recipe. Targets are honored within ±5%.
---

You are the `/burn` orchestrator for the Token Burner plugin. Argument
parsing and dispatch logic follows. Execute it precisely.

**Arguments received:** `$ARGUMENTS` (raw), `$0`, `$1` (positional).

---

## Step 1 — Parse arguments

`$ARGUMENTS` may be:
- Empty: pick a random eligible recipe at its default size.
- A number with optional `k` or `M` suffix (e.g., `50k`, `1.5M`,
  `200000`): target token count, random recipe.
- A recipe name (slug from `recipes/<name>.md`): named recipe at
  default size.
- Both, in any order (e.g., `50k token-tarot` or `token-tarot 50k`):
  named recipe sized to target.

Suffix conversions: `k` → ×1,000, `M` → ×1,000,000. Bare numbers are
raw tokens. Decimal allowed (e.g., `1.5k` = 1,500).

Determine: `target` (int or `null` for "use recipe default") and
`recipe_name` (string or `null` for "pick random").

## Step 2 — Detect context

Run via Bash:
```
git rev-parse --is-inside-work-tree 2>/dev/null && \
  find . -maxdepth 3 -type f \( -name '*.ts' -o -name '*.js' -o -name '*.py' \
    -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o -name '*.rb' \
    -o -name '*.md' \) 2>/dev/null | head -1
```

If both subcommands succeed AND at least one file is found, set
`context = codebase`. Otherwise `context = any`.

## Step 3 — Resolve plugin install path (do this once, reuse)

Claude Code does not expose a documented env var for a plugin's install
directory. Resolve it via a Bash glob and cache it for later steps:

```
PLUGIN_DIR=$(find "$HOME/.claude/plugins" -type d -name 'token-burner' 2>/dev/null | head -1)
[ -d "$PLUGIN_DIR" ] || { echo "⚠ Token Burner: plugin install dir not found"; exit 1; }
echo "$PLUGIN_DIR"
```

Capture the printed path as `plugin_dir`. If empty, abort with the error
shown above and stop.

## Step 4 — Snapshot tokens

Run via Bash:
```
bash <plugin_dir>/lib/transcript.sh
```

Capture the printed integer as `snapshot`. A value of 0 is acceptable
(the session may have just started); do not treat 0 as an error.

## Step 5 — Load recipe metadata

Read every `*.md` file in `<plugin_dir>/recipes/`. Parse the YAML
frontmatter from each. Build an in-memory list:

```
recipes = [
  { name, display_name, emoji, context, default_budget,
    size_dial: { param, default, range, est_tokens_per_unit },
    tail_flavor, body_template },
  ...
]
```

Filter to **eligible recipes**: those whose `context` is `any`, plus
those whose `context` is `codebase` if the current context is also
`codebase`.

## Step 6 — Pick recipe(s) and classify tier

If `recipe_name` is set:
- Find it in `recipes`. If missing, abort:
  "⚠ Unknown recipe '{name}'. Run `/burn-list` for the catalog."
- If `recipe.context == 'codebase'` and current `context != 'codebase'`,
  abort: "⚠ Recipe '{name}' requires a codebase; current directory has
  no code files."

If `target` is `null`:
- If `recipe_name` is set, use `recipe.default_budget` as target.
- Else: pick a random eligible recipe; use its `default_budget` as
  target.

Classify tier:
- `target < 10000` → **Micro**
- `10000 ≤ target ≤ 500000` → **Normal**
- `target > 500000` → **Marathon**

## Step 7 — Dispatch by tier

### Micro tier

Skip the main recipe. Jump to Step 8 (tail loop) with `tail_flavor =
"Briefly muse, in any voice, on a single trope from software
engineering."` and `parent_recipe_name = null`. Use only `size: small`
tail subagents.

### Normal tier

If `recipe_name` was not specified, pick one at random from eligible.

Compute size dial value:
```
main_target = target * 0.6
units = round(main_target / size_dial.est_tokens_per_unit)
units = clamp(units, size_dial.range[0], size_dial.range[1])
```

Dispatch the recipe via the Agent tool. The prompt to the subagent is
the recipe's body template with substitutions:

- `{{<param>}}` (the size dial param name) → `units`
- `{{target_tokens}}` → `units * est_tokens_per_unit`

Wait for the subagent to complete. Then go to Step 8.

### Marathon tier

Initialize `used_recipes = []`.

Loop:
1. Re-snapshot tokens. Compute `elapsed = current - snapshot`,
   `remaining = target - elapsed`.
2. If `remaining < 50000`, exit loop.
3. From eligible recipes excluding `used_recipes`, pick one at random.
   If all eligible are used, pick the one used least recently (FIFO).
4. Compute size dial: `units = clamp(round(remaining * 0.4 /
   est_tokens_per_unit), range[0], range[1])`.
5. Dispatch the recipe via the Agent tool with the substitutions above.
6. Append the recipe name to `used_recipes`.

After loop, go to Step 8 with the most recently used recipe's
`tail_flavor`.

## Step 8 — Tail loop (always runs)

Iterate up to **10 times**:

1. Re-snapshot tokens. Compute `elapsed = current - snapshot`.
2. Compute `remaining = target - elapsed`.
3. If `remaining <= target * 0.05` (within +5%) OR `elapsed >= target`
   (overshoot is acceptable): exit loop.
4. Determine size:
   - `remaining > 20000` → `size = big` (~15k tokens)
   - else → `size = small` (~3k tokens)
5. Dispatch `tail-burner` agent via the Agent tool with prompt:
   ```
   tail_flavor: <flavor>
   size: <big|small>
   parent_recipe_name: <name or "none">
   ```
6. Wait for completion.

After loop: re-snapshot one final time to capture the true `elapsed`.

## Step 9 — Print summary

Render this exact summary block:

```
🔥  /burn complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target:        {target:,} tokens   ({tier})
Burned:        {elapsed:,} tokens   ({pct:+.1f}%)
Recipe(s):     {names}
Tail rounds:   {tail_count}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Where `pct = (elapsed - target) / target * 100`. If `target` was
`null` (recipe-default mode), show `Target: recipe default ({default:,})`.

## Step 10 — Optionally write artifact

If plugin settings have `artifacts: "always"`, OR `artifacts: "opt-in"`
and the user passed a `--save` flag (parse from `$ARGUMENTS`), write
the full recipe output (and tail outputs) to:

```
{artifact_dir}/{YYYY-MM-DD}-{HHMM}-{recipe-name}.md
```

The artifact file's frontmatter must contain these fields (used by
`/burn-status`):

```yaml
---
date: 2026-05-13T14:42:00-07:00
recipe: token-tarot
target: 50000
elapsed: 49847
tier: Normal
size_dial: { cards: 5 }
tail_rounds: 2
duration_seconds: 187
---
```

Body is the assembled recipe output (and any tail outputs) verbatim.

Plugin settings are read from (in order of preference):
1. `$PWD/.token-burner.json`
2. `$HOME/.config/token-burner/config.json`

Default settings if neither exists: `{"artifacts": "off",
"artifact_dir": ".burn/", "exclude_recipes": [], "marathon_threshold":
500000}`.

## Errors

If any step fails (Bash error, file not found, parse error), abort
immediately with a single-line error message prefixed `⚠ Token Burner:`
and skip remaining steps.
````

- [ ] **Step 13.2: Commit**

```bash
git add plugin/commands/burn.md
git commit -m "feat(plugin): /burn orchestrator with tier dispatch and tail loop"
```

---

## Task 14: `/burn-status` command

**Files:**
- Create: `plugin/commands/burn-status.md`

- [ ] **Step 14.1: Write the command**

Create `plugin/commands/burn-status.md`:
````markdown
---
name: burn-status
description: Display today/week/all-time token burn totals and recent /burn sessions.
---

You are running the `/burn-status` command for Token Burner.

## Step 1 — Read all artifacts

Default artifact dir is `.burn/` (override via plugin settings —
see `/burn` command for resolution order). If the dir does not exist,
print:

```
🔥  Token Burner — no burn artifacts found.
    Enable artifacts in settings to start tracking. See `/burn-list`
    to begin.
```

and exit.

## Step 2 — Aggregate

Read each `.md` file's YAML frontmatter. Fields written by `/burn` (see
its Step 10): `date`, `recipe`, `target`, `elapsed`, `tier`,
`size_dial`, `tail_rounds`, `duration_seconds`. Compute:

- Today's total elapsed tokens.
- This week's total (last 7 days from today).
- All-time total.
- Last 5 sessions (most recent first), each with date, recipe, elapsed,
  accuracy %.

If plugin settings has `weekly_kpi` set, compute weekly progress as a
percentage.

## Step 3 — Render

Output in this exact format (right-align numeric columns, pad with
spaces so columns align cleanly):

```
🔥  TOKEN BURNER — STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Today          {today:>12,} tokens
This week      {week:>12,} tokens    [bar]  {pct}% of {kpi:,}
All-time       {all:>12,} tokens
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Recent sessions:
  2026-05-13 14:42  🏆 Architecture Tournament   118,400  (-1.3%)
  2026-05-13 11:08  🔮 Token Tarot                29,890  (-0.4%)
  ...
```

`[bar]` is a 20-character progress bar using `▮` for filled, `▯` for
empty, clamped to 100%. If `weekly_kpi` is unset, omit the bar and
the percentage entirely.

No preamble, no commentary, just the block.
````

- [ ] **Step 14.2: Commit**

```bash
git add plugin/commands/burn-status.md
git commit -m "feat(plugin): /burn-status command"
```

---

## Task 15: Marketplace manifest and local install test

**Files:**
- Create: `.claude-plugin/marketplace.json` (at repo root, NOT inside plugin/)
- Modify: `plugin/README.md` (update install instructions if needed)

- [ ] **Step 15.1: Write marketplace.json**

Create `.claude-plugin/marketplace.json` at the repo root:
```json
{
  "name": "token-burner-marketplace",
  "plugins": [
    {
      "name": "token-burner",
      "source": {
        "type": "directory",
        "path": "./plugin"
      }
    }
  ]
}
```

- [ ] **Step 15.2: Install locally and verify**

In a separate Claude Code session (from this repo):
```
/plugin marketplace add .
/plugin install token-burner@token-burner-marketplace
```

Expected: install succeeds. `/burn-list` is now a recognized slash command.

- [ ] **Step 15.3: Run `/burn-list` and verify output**

In the test Claude Code session, run `/burn-list`. Expected: a table listing 8 recipes (Recursive Reviewer, Architecture Tournament, Token Tarot, 5 Whys × N, Devil's Subcouncil, Apology Letter, Imaginary Migration, 100 Hot Takes) sorted by `default_budget` ascending. Output is the catalog block defined in `commands/burn-list.md` with no extra commentary.

If the output includes a preamble or differs structurally, edit `commands/burn-list.md` to make the formatting instructions more explicit, then re-test.

- [ ] **Step 15.4: Commit**

```bash
git add .claude-plugin/
git commit -m "feat: marketplace manifest for local install"
```

---

## Task 16: Integration smoke tests

This task is a manual verification. Each step is a single `/burn` invocation in the test Claude Code session, with a pass/fail check against the spec's ±5% accuracy target.

**Files:** none (verification only)

- [ ] **Step 16.1: Smoke test — Micro tier (~5k)**

Run: `/burn 5k`

Expected: completes in 10–60 seconds. Summary line shows `Burned` within ±5% of 5,000 (i.e., between 4,750 and 5,250). No main recipe was dispatched; only tail subagents were used. Record actual burn for the integration log.

If the burn falls outside ±5%, adjust the small/big size targets in `commands/burn.md` (Step 7) — likely `small ~ 2,500–3,500` is more appropriate. Re-test.

- [ ] **Step 16.2: Smoke test — Normal tier (~50k), `any` context**

Open a fresh terminal in an empty directory. Run a Claude Code session there (no codebase). Run: `/burn 50k`.

Expected:
- A `context: any` recipe is selected (Token Tarot, 5 Whys, Devil's Subcouncil, Imaginary Migration, or Hot Takes — never Recursive Reviewer, Architecture Tournament, or Apology Letter).
- Final burn within ±5% of 50,000.
- Summary block renders cleanly.

- [ ] **Step 16.3: Smoke test — Normal tier (~50k), `codebase` context**

Run from this repo (or any git-tracked directory with code): `/burn 50k`

Expected: any of the 8 recipes may be picked. Codebase-aware recipes can reference real files in their output. Burn within ±5%.

- [ ] **Step 16.4: Smoke test — Named recipe**

Run: `/burn 30k token-tarot`

Expected: explicitly runs Token Tarot. Final burn within ±5% of 30,000. Output includes 3 named cards (size dial defaults to 3 cards at ~10k each before tail correction).

- [ ] **Step 16.5: Smoke test — Marathon tier (~1M)**

Run: `/burn 1M`

Expected: 4–8 distinct recipes run in sequence (more if eligible set is smaller, with the least-recently-used cycling back). Burn within ±5% of 1,000,000 (i.e., between 950,000 and 1,050,000). Summary shows multiple recipe names. Total duration may be 5–15 minutes.

Note any rate-limit interruptions — these are acceptable; the summary should report the actual burn honestly.

- [ ] **Step 16.6: Smoke test — Context mismatch error**

In an empty directory (no code), run: `/burn 30k recursive-reviewer`

Expected: aborts immediately with the error message defined in `commands/burn.md` Step 5: "⚠ Recipe 'recursive-reviewer' requires a codebase; current directory has no code files."

- [ ] **Step 16.7: Smoke test — Unknown recipe error**

Run: `/burn 30k blorbo`

Expected: aborts with "⚠ Unknown recipe 'blorbo'. Run `/burn-list` for the catalog."

- [ ] **Step 16.8: Write integration test log**

After all smoke tests pass, append a record to `plugin/INTEGRATION_LOG.md`:
```markdown
# Integration Test Log

## 2026-05-13 — v0.1.0

| Test | Target | Actual | Accuracy | Pass |
|---|---|---|---|---|
| Micro      | 5,000     | <actual> | <±%> | ✓/✗ |
| Normal any | 50,000    | <actual> | <±%> | ✓/✗ |
| Normal cb  | 50,000    | <actual> | <±%> | ✓/✗ |
| Named      | 30,000    | <actual> | <±%> | ✓/✗ |
| Marathon   | 1,000,000 | <actual> | <±%> | ✓/✗ |
| Error: ctx | N/A       | aborted  | N/A  | ✓/✗ |
| Error: name| N/A       | aborted  | N/A  | ✓/✗ |
```

Commit:
```bash
git add plugin/INTEGRATION_LOG.md
git commit -m "test: v0.1.0 integration smoke test log"
```

- [ ] **Step 16.9: Tag the release**

```bash
git tag -a v0.1.0 -m "Token Burner plugin v0.1.0"
git log --oneline
```

---

## Self-review checklist (run after writing all tasks)

After implementation completes, verify against the spec:

- [ ] All 8 recipes from spec §3.3 are present in `plugin/recipes/`.
- [ ] All recipe frontmatter fields (`name`, `display_name`, `emoji`, `context`, `default_budget`, `size_dial`, `tail_flavor`) are present.
- [ ] `/burn`, `/burn-list`, `/burn-status` all installed and respond.
- [ ] Tier classification (Micro/Normal/Marathon) thresholds match spec §3.2.1.
- [ ] Tail loop has the 10-iteration safety bound.
- [ ] Transcript reader handles missing files (returns 0), missing env vars (uses fallback glob), and both jq and Python fallback.
- [ ] Spec §3.6 settings keys are all readable by `/burn` (artifacts, artifact_dir, default_target, exclude_recipes, marathon_threshold, weekly_kpi).
- [ ] No placeholders, no TODOs, no "TBD" anywhere in the committed code or docs.

---

## What this plan does NOT cover

Per the spec's §9 "explicitly not building" list, this plan does NOT include:
- The parody marketing site (separate plan).
- Telemetry, leaderboards, accounts.
- Burn mechanics other than `/burn` (no prompt-padding hooks, no scheduled burners).
- Status-line gauge, verbose-mode amplifier.
- Hard token caps.

The site implementation has its own plan: `docs/superpowers/plans/2026-05-13-token-burner-site.md` (to be written after this plan is approved).
