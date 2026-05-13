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
