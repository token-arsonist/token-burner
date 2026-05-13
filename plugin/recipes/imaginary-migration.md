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
