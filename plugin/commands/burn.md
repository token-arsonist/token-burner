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
