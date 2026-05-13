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
