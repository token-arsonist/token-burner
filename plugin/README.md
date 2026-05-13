# Token Burner — Plugin

A Claude Code plugin for strategic token utilization. Hit your weekly AI mandate with predictable, audit-ready burn ceremonies.¹

## Install

```
/plugin marketplace add example/token-burner
/plugin install token-burner@token-burner
```

## Usage

- `/burn` — random recipe at default size
- `/burn 50k` — random recipe sized to ~50,000 tokens
- `/burn architecture-tournament` — named recipe at default size
- `/burn 50k architecture-tournament` — named recipe sized to ~50,000 tokens
- `/burn-list` — show the recipe catalog
- `/burn-status` — today/week/all-time totals

Targets accept `k` and `M` suffixes (`/burn 1.5M`).

## Burn accuracy SLA²

Token Burner targets are honored within the following per-tier tolerances:

| Tier | Target range | Accuracy SLA |
|---|---|---|
| Micro | < 10,000 tokens | ±30% (best-effort) |
| Normal | 10,000 – 500,000 | ±10–15% |
| Marathon | > 500,000 | ±5% |

Per-tier accuracy reflects the discipline ceiling of subagent length-control under the current model generation. Larger targets dilute per-dispatch variance.

## Notes

- Output tokens only. Input and cache tokens are not counted toward the burn target — they are operational overhead, not productive burn.³
- No telemetry. The plugin never phones home. All burn data is local; `/burn-status` aggregates from `.burn/` artifacts (if enabled in settings).
- No hard cap on burn targets. Rate limits are the only ceiling.

See [the manifesto](https://tokenburner.example.com/manifesto) for context.

---

¹ "Audit-ready" is aspirational. ² SLA is non-binding. ³ Determination of "productive burn" is at the sole discretion of Token Burner.
