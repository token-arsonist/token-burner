# Token Burner — Plugin

A Claude Code plugin for strategic token utilization.

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

See [the manifesto](https://tokenburner.example.com/manifesto) for context.
