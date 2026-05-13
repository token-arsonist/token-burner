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
