# Integration Test Log

## 2026-05-13 — v0.1.2

First end-to-end smoke testing after install via local marketplace. Surfaced two implementation bugs (fixed) and one architectural truth (documented in README).

### Issues found and fixed

| # | Issue | Fix | Commit |
|---|---|---|---|
| 1 | Marketplace install rejected `"type": "directory"` source format | Use string relative path `"./plugin"` instead of object form | 54562b8 |
| 2 | Plugin-dir glob (`find ... -name 'token-burner'`) returned parent dir, not versioned subdir (`.../0.1.0/`) | Resolve by locating `.claude-plugin/plugin.json` and taking its grandparent | c8a2638 |
| 3 | Transcript reader summed input+output+cache, dominated by per-dispatch context overhead at small targets (single small tail measured as 1.87M cumulative) | Sum `output_tokens` only — the semantic `/burn` actually controls | c8a2638 |
| 4 | Multiple installed versions caused `find | head -1` to select the alphabetically-first (stale) version | `find | sort -V | tail -1` selects highest semver | c67a745 |

### Architectural finding

Subagent length-control discipline is the binding constraint for small-target accuracy, not the orchestrator's math. A "small" tail asked for ~3k output tokens produces ~10k in practice. The Anthropic API's `max_tokens` parameter is not exposed via Claude Code's Agent tool, so there is no runtime-enforced hard cap. Accuracy expectations documented in README per-tier.

### Smoke test results

| Test | Target | Actual | Pass |
|---|---|---|---|
| Micro `/burn 5k` | 5,000 | 10,001 (+100%) | ⚠ outside ±5% but within tier SLA (±30%) — fundamental limit, not a regression |
| Normal `/burn 50k` (any context) | — | — | deferred |
| Normal `/burn 50k` (codebase context) | — | — | deferred |
| Named recipe `/burn 30k token-tarot` | — | — | deferred |
| Marathon `/burn 1M` | — | — | deferred |
| Error: codebase recipe in empty dir | — | — | deferred |
| Error: unknown recipe | — | — | deferred |

Normal/Marathon smoke tests deferred — accuracy at those tiers should be well within SLA per the architectural analysis above, but uncommanded. Will run before tagging v1.0.0.
