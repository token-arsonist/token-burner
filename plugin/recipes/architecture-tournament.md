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
