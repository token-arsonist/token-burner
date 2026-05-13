# Token Burner

Strategic token utilization for the modern AI-mandated enterprise. A Claude Code plugin that helps individual contributors hit quarterly token KPIs via predictable, audit-ready burn ceremonies.¹

🔥 **Live site:** [token-burner.pages.dev](https://token-burner.pages.dev)
🔥 **Plugin:** see [`plugin/README.md`](plugin/README.md) for install + usage
🔥 **Manifesto:** [token-burner.pages.dev/manifesto](https://token-burner.pages.dev/manifesto)

## What's in this repo

| Path | What it is |
|---|---|
| [`plugin/`](plugin/) | The Claude Code plugin. Slash commands `/burn`, `/burn-list`, `/burn-status`. Eight production-tested recipes. Runs entirely in your local session. No telemetry. |
| [`site/`](site/) | The parody marketing site. Five static Astro pages, deployed to Cloudflare Pages. |
| [`docs/superpowers/`](docs/superpowers/) | The original design spec and implementation plans. Preserved verbatim. |

## Install the plugin

From within a Claude Code session:

```
/plugin marketplace add github.com/token-arsonist/token-burner
/plugin install token-burner@token-burner-marketplace
/reload-plugins
```

Then run `/burn-list` to see the eight-recipe catalog. See [`plugin/README.md`](plugin/README.md) for full command reference and accuracy SLA.

## Develop the site locally

```bash
cd site
pnpm install
pnpm dev    # → http://localhost:4321
```

Deploy notes: [`site/DEPLOY.md`](site/DEPLOY.md).

## Project status

| Component | Version | Tag |
|---|---|---|
| Plugin    | v0.1.3  | `v0.1.3` |
| Site      | v0.1.0  | `site-v0.1.0` |

Per-tier burn accuracy SLA (plugin): Marathon ±5%, Normal ±10–15%, Micro ±30%.² No hard cap on burn targets. Rate limits are the only ceiling.

## What this project is *not*

This is a parody. The "token utilization KPI" we describe in the [manifesto](https://token-burner.pages.dev/manifesto) is a real pattern observed in some enterprises — measuring AI token consumption as a productivity proxy — and the tooling here is offered in deliberate, structured response to that pattern. Nothing on this site is binding, audited, or certified. All claims are self-reported and unverified.

---

¹ "Audit-ready" is aspirational. ² SLAs are non-binding. Determination of "honored" is at the sole discretion of Token Burner.
