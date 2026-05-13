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
