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
