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
