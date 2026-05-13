# Token Burner Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a static 5-page parody marketing site for Token Burner — Glover-warm visual language paired with deadpan B2B-compliance copy.

**Architecture:** Astro static site under `site/` in the existing repo. Five pages (`/`, `/recipes`, `/calculator`, `/manifesto`, `/install`) share one layout, a single design-tokens stylesheet, and a small component library. The Compliance Calculator is the only interactive piece — a tiny client-side JS island.

**Tech Stack:** Astro (static), plain hand-written CSS with design tokens, Google Fonts (Big Shoulders Display, Inter, Space Grotesk), Cloudflare Pages for hosting.

**Spec:** `docs/superpowers/specs/2026-05-13-token-burner-design.md` — read §4 (Site structure) and §5 (Design Language) before starting. The Design Language section is the **tone gate**: the first page implemented (Home, Task 3) gets an explicit adherence review checkpoint (Task 4) before remaining pages are built.

---

## File structure

```
site/
├── astro.config.mjs                    Astro config
├── package.json                        deps
├── tsconfig.json                       TS config
├── public/
│   └── favicon.svg                     site favicon
└── src/
    ├── layouts/
    │   └── BaseLayout.astro            shared <html><head><body> + nav + footer
    ├── styles/
    │   └── global.css                  design tokens + base styles + utility classes
    ├── components/
    │   ├── Nav.astro                   top nav (5 links + brand)
    │   ├── Footer.astro                footer (copyright + self-undermining + GitHub)
    │   ├── SectionMarker.astro         "1 — Install the plugin" big-numeral methodology row
    │   ├── Pill.astro                  pill tag (codebase / anywhere / status)
    │   └── StatBlock.astro             3-up stat row used on home
    └── pages/
        ├── index.astro                 / Home
        ├── recipes.astro               /recipes catalog
        ├── manifesto.astro             /manifesto long-form white-paper
        ├── install.astro               /install docs
        └── calculator.astro            /calculator compliance calculator (interactive)
```

Each component file has one responsibility. Pages compose components — they don't redefine layout primitives.

---

## Task 1: Astro project scaffold and dependencies

**Files:**
- Create: `site/package.json`
- Create: `site/astro.config.mjs`
- Create: `site/tsconfig.json`
- Create: `site/.gitignore`
- Create: `site/public/favicon.svg`

- [ ] **Step 1.1: Create site directory and run `pnpm init` equivalent**

Run from repo root (`/Users/james/token-burner`):
```bash
mkdir -p site/src/{layouts,styles,components,pages} site/public
cd site
```

- [ ] **Step 1.2: Write `package.json`**

Create `site/package.json`:
```json
{
  "name": "token-burner-site",
  "version": "0.1.0",
  "type": "module",
  "private": true,
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview"
  },
  "dependencies": {
    "astro": "^5.0.0"
  }
}
```

- [ ] **Step 1.3: Write `astro.config.mjs`**

Create `site/astro.config.mjs`:
```js
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://tokenburner.example.com',
  output: 'static',
  build: {
    inlineStylesheets: 'auto',
  },
});
```

- [ ] **Step 1.4: Write `tsconfig.json`**

Create `site/tsconfig.json`:
```json
{
  "extends": "astro/tsconfigs/strict"
}
```

- [ ] **Step 1.5: Write `.gitignore`**

Create `site/.gitignore`:
```
node_modules/
.astro/
dist/
.env
.DS_Store
```

- [ ] **Step 1.6: Write favicon**

Create `site/public/favicon.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" fill="#f4f0df"/>
  <text x="16" y="22" font-family="ui-monospace,monospace" font-size="20" font-weight="700" text-anchor="middle" fill="#fe5401">🔥</text>
</svg>
```

- [ ] **Step 1.7: Install dependencies**

```bash
cd site
pnpm install
```

If `pnpm` isn't available, use `npm install` instead. Verify `node_modules/` exists and astro is installed:
```bash
ls node_modules/astro/package.json
```
Expected: file exists.

- [ ] **Step 1.8: Verify dev server starts**

```bash
cd site
pnpm dev &
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4321/
kill %1 2>/dev/null
```
Expected: `200` (even though there are no pages yet, Astro serves a default 404 with status 200 in dev — that's fine; we just want to confirm the dev server boots).

Actually — Astro returns 404 for missing pages. Better verification:
```bash
cd site
pnpm dev &
DEV_PID=$!
sleep 4
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4321/_astro/
kill $DEV_PID 2>/dev/null
```
Expected: any HTTP response (proves server bound). If curl errors with "connection refused," dev server didn't start.

- [ ] **Step 1.9: Commit**

```bash
git add site/
git commit -m "feat(site): scaffold Astro project with package, config, favicon"
```

---

## Task 2: Design tokens stylesheet and base layout

**Files:**
- Create: `site/src/styles/global.css`
- Create: `site/src/layouts/BaseLayout.astro`
- Create: `site/src/components/Nav.astro`
- Create: `site/src/components/Footer.astro`

This task implements the locked Design Language from spec §5. The CSS uses custom properties for the entire palette and type system. Every later page imports the layout and inherits the design system.

- [ ] **Step 2.1: Write `global.css` with design tokens**

Create `site/src/styles/global.css`:
```css
/* ============================================================
   Token Burner — Design Tokens
   Locked per spec §5. Do not introduce new colors or fonts.
   ============================================================ */

:root {
  /* Palette */
  --bg:        #f4f0df;
  --bg-alt:    #fffaf6;
  --bg-tint:   #ffebca;
  --fg:        #010101;
  --accent:    #fe5401;
  --accent-2:  #63c3a3;
  --alert:     #a50000;

  /* Type families (loaded from Google Fonts in BaseLayout) */
  --font-display: 'Big Shoulders Display', sans-serif;
  --font-body:    'Inter', sans-serif;
  --font-ui:      'Space Grotesk', sans-serif;

  /* Layout */
  --content-max: 1240px;
  --pad-x:       clamp(20px, 4vw, 56px);
  --pad-y:       clamp(28px, 5vw, 64px);
}

/* ============================================================ */
/* Reset                                                        */
/* ============================================================ */

*, *::before, *::after { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
img, svg { display: block; max-width: 100%; }
a { color: inherit; }

/* ============================================================ */
/* Base                                                         */
/* ============================================================ */

html {
  font-family: var(--font-body);
  font-size: 16px;
  line-height: 1.5;
  color: var(--fg);
  background: var(--bg);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

body {
  min-height: 100vh;
  padding: var(--pad-y) var(--pad-x);
  max-width: var(--content-max);
  margin: 0 auto;
}

/* ============================================================ */
/* Typography                                                   */
/* ============================================================ */

.display, h1.display, h2.display {
  font-family: var(--font-display);
  font-weight: 900;
  line-height: 0.92;
  letter-spacing: -0.01em;
  text-transform: lowercase;
  margin: 0;
  color: var(--fg);
}

h1.display { font-size: clamp(56px, 11vw, 140px); }
h2.display { font-size: clamp(42px, 7vw, 92px); }
h3.display { font-size: clamp(28px, 4vw, 48px); font-weight: 700; }

.lede {
  font-size: clamp(16px, 1.4vw, 19px);
  max-width: 60ch;
  line-height: 1.55;
  margin: 24px 0 32px;
}

.lede sup {
  font-size: 11px;
  color: var(--alert);
  font-weight: 600;
}

.label {
  font-family: var(--font-ui);
  font-size: 11px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  font-weight: 500;
  color: var(--alert);
}

p { margin: 0 0 16px; }

a {
  text-underline-offset: 4px;
}

a:hover {
  color: var(--accent);
}

/* ============================================================ */
/* Buttons                                                      */
/* ============================================================ */

.btn-primary {
  display: inline-block;
  background: var(--fg);
  color: var(--bg);
  padding: 13px 24px;
  font-family: var(--font-ui);
  font-weight: 500;
  font-size: 13px;
  letter-spacing: 0.04em;
  border-radius: 999px;
  text-decoration: none;
  transition: background 120ms ease;
}

.btn-primary:hover {
  background: var(--accent);
  color: var(--bg);
}

.btn-secondary {
  font-family: var(--font-ui);
  font-weight: 500;
  font-size: 13px;
  letter-spacing: 0.04em;
  text-decoration: underline;
  text-underline-offset: 4px;
  color: var(--fg);
}

.btn-secondary:hover { color: var(--accent); }

/* ============================================================ */
/* Layout primitives                                            */
/* ============================================================ */

.hairline {
  border: 0;
  border-top: 1px solid var(--fg);
  margin: 56px 0 32px;
}

.section {
  margin-bottom: 64px;
}

.stat-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 32px;
  border-top: 1px solid var(--fg);
  padding-top: 24px;
  max-width: 920px;
}

.stat .num {
  font-family: var(--font-display);
  font-weight: 700;
  font-size: clamp(40px, 5vw, 64px);
  line-height: 1;
  margin-bottom: 8px;
}

.stat .desc {
  font-size: 13px;
  max-width: 240px;
  color: var(--fg);
}

/* ============================================================ */
/* Section markers (big numbered methodology rows)              */
/* ============================================================ */

.section-marker {
  display: grid;
  grid-template-columns: minmax(120px, 200px) 1fr;
  gap: 24px;
  align-items: baseline;
  border-top: 1px solid var(--fg);
  padding-top: 32px;
  margin-top: 64px;
}

.section-marker .num {
  font-family: var(--font-display);
  font-weight: 900;
  font-size: clamp(80px, 12vw, 160px);
  line-height: 0.85;
}

.section-marker .body { max-width: 540px; }

.section-marker h2 {
  font-family: var(--font-display);
  font-weight: 700;
  font-size: clamp(28px, 4vw, 44px);
  line-height: 1;
  margin: 0 0 14px;
  text-transform: lowercase;
}

/* ============================================================ */
/* Pills                                                        */
/* ============================================================ */

.pill {
  display: inline-block;
  background: var(--bg-tint);
  color: var(--fg);
  padding: 4px 10px;
  border-radius: 999px;
  font-family: var(--font-ui);
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.04em;
  margin-right: 6px;
}

.pill.sage    { background: var(--accent-2); }
.pill.alert   { background: var(--alert); color: var(--bg); }

/* ============================================================ */
/* Inline code                                                  */
/* ============================================================ */

code {
  font-family: var(--font-ui);
  background: var(--bg-tint);
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 0.95em;
}

pre code {
  display: block;
  background: var(--fg);
  color: var(--bg);
  padding: 16px 20px;
  border-radius: 6px;
  overflow-x: auto;
  font-size: 13px;
  line-height: 1.5;
}

/* ============================================================ */
/* Footnotes                                                    */
/* ============================================================ */

.footnotes {
  font-size: 11px;
  color: var(--fg);
  opacity: 0.65;
  margin-top: 64px;
  padding-top: 16px;
  border-top: 1px solid var(--fg);
}

.footnotes p { margin: 0 0 4px; }
```

- [ ] **Step 2.2: Write `BaseLayout.astro`**

Create `site/src/layouts/BaseLayout.astro`:
```astro
---
import '../styles/global.css';
import Nav from '../components/Nav.astro';
import Footer from '../components/Footer.astro';

interface Props {
  title: string;
  description?: string;
}

const { title, description = 'Strategic token utilization for AI-mandated workflows.' } = Astro.props;
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      rel="stylesheet"
      href="https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@500;700;900&family=Inter:wght@400;500;600&family=Space+Grotesk:wght@500&display=swap"
    />
    <title>{title}</title>
    <meta name="description" content={description} />
  </head>
  <body>
    <Nav />
    <main>
      <slot />
    </main>
    <Footer />
  </body>
</html>
```

- [ ] **Step 2.3: Write `Nav.astro`**

Create `site/src/components/Nav.astro`:
```astro
---
const links = [
  { href: '/', label: 'Platform' },
  { href: '/recipes', label: 'Recipes' },
  { href: '/calculator', label: 'Calculator' },
  { href: '/manifesto', label: 'Manifesto' },
];
---

<nav class="nav">
  <a href="/" class="brand">TOKEN&nbsp;BURNER</a>
  <div class="links">
    {links.map((l) => <a href={l.href}>{l.label}</a>)}
    <a href="/install" class="install-link">Install&nbsp;↗</a>
  </div>
</nav>

<style>
  .nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 80px;
    font-family: var(--font-ui);
    font-size: 13px;
    flex-wrap: wrap;
    gap: 16px;
  }

  .brand {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 22px;
    letter-spacing: 0.02em;
    color: var(--fg);
    text-decoration: none;
  }

  .links {
    display: flex;
    gap: 32px;
    flex-wrap: wrap;
  }

  .links a {
    color: var(--fg);
    text-decoration: none;
  }

  .links a:hover { color: var(--accent); }

  @media (max-width: 640px) {
    .links { gap: 20px; }
  }
</style>
```

- [ ] **Step 2.4: Write `Footer.astro`**

Create `site/src/components/Footer.astro`:
```astro
---
const year = new Date().getFullYear();
---

<footer>
  <p>
    © {year} Token Burner. All claims self-reported and unverified.
    <a href="https://github.com/example/token-burner">GitHub</a>
  </p>
</footer>

<style>
  footer {
    margin-top: 96px;
    padding-top: 24px;
    border-top: 1px solid var(--fg);
    font-family: var(--font-ui);
    font-size: 11px;
    letter-spacing: 0.04em;
    color: var(--fg);
    opacity: 0.65;
  }

  footer p { margin: 0; }

  footer a {
    color: var(--fg);
    margin-left: 16px;
  }

  footer a:hover { color: var(--accent); }
</style>
```

- [ ] **Step 2.5: Verify the layout builds**

The layout has no pages yet, but Astro should accept it without errors:
```bash
cd site
pnpm build
```
Expected: builds without TypeScript or syntax errors. There will be a warning about no pages — that's fine, ignore.

- [ ] **Step 2.6: Commit**

```bash
git add site/src/styles/ site/src/layouts/ site/src/components/Nav.astro site/src/components/Footer.astro
git commit -m "feat(site): design tokens, base layout, nav, footer"
```

---

## Task 3: Home page (`/`)

**Files:**
- Create: `site/src/pages/index.astro`
- Create: `site/src/components/SectionMarker.astro`
- Create: `site/src/components/StatBlock.astro`
- Create: `site/src/components/Pill.astro`

This page replicates the approved hero mockup. It is the **tone reference** — Task 4 is an explicit checkpoint that pauses for human verification of the design language before continuing to other pages.

- [ ] **Step 3.1: Write `Pill.astro`**

Create `site/src/components/Pill.astro`:
```astro
---
interface Props {
  variant?: 'default' | 'sage' | 'alert';
}
const { variant = 'default' } = Astro.props;
const cls = variant === 'default' ? 'pill' : `pill ${variant}`;
---
<span class={cls}><slot /></span>
```

- [ ] **Step 3.2: Write `StatBlock.astro`**

Create `site/src/components/StatBlock.astro`:
```astro
---
interface Props {
  num: string;
  desc: string;
}
const { num, desc } = Astro.props;
---
<div class="stat">
  <div class="num">{num}</div>
  <div class="desc"><slot name="desc">{desc}</slot></div>
</div>
```

- [ ] **Step 3.3: Write `SectionMarker.astro`**

Create `site/src/components/SectionMarker.astro`:
```astro
---
interface Props {
  num: number | string;
  title: string;
}
const { num, title } = Astro.props;
---
<section class="section-marker">
  <div class="num">{num}</div>
  <div class="body">
    <h2>{title}</h2>
    <slot />
  </div>
</section>
```

- [ ] **Step 3.4: Write the home page**

Create `site/src/pages/index.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import StatBlock from '../components/StatBlock.astro';
import SectionMarker from '../components/SectionMarker.astro';
import Pill from '../components/Pill.astro';
---

<BaseLayout
  title="Token Burner — enterprise-grade token utilization"
  description="Hit your team's quarterly token KPIs with predictable, audit-ready burn ceremonies."
>
  <div class="label">◆ Now SOC&#8209;2 compliance-adjacent</div>

  <h1 class="display">
    enterprise&#8209;grade token utilization for <span class="accent">ai&#8209;mandated</span> workflows.
  </h1>

  <p class="lede">
    Hit your team's quarterly token KPIs with predictable, audit-ready burn ceremonies.
    Trusted by individual contributors at 200+ companies.<sup>1</sup>
  </p>

  <div class="cta-row">
    <a class="btn-primary" href="/install">Install plugin ↗</a>
    <a class="btn-secondary" href="/manifesto">Read the manifesto</a>
  </div>

  <div class="stat-row">
    <StatBlock num="$700B" desc="Estimated annual addressable burn²" />
    <StatBlock num="±5%" desc="Burn accuracy SLA on Marathon‑tier targets" />
    <StatBlock num="8" desc="Production-tested burn recipes shipping in v1" />
  </div>

  <SectionMarker num="1" title="install the plugin.">
    <p>
      One command in your Claude Code marketplace. No telemetry. No accounts.
      Your tokens, your problem, our toolkit.
    </p>
    <div style="margin-top:14px">
      <Pill variant="sage">∅ works anywhere</Pill>
      <Pill>📁 codebase-aware</Pill>
    </div>
  </SectionMarker>

  <SectionMarker num="2" title="set your target.">
    <p>
      <code>/burn 50k</code> — or whatever your weekly mandate demands.
      Range: 500 to 100M+ tokens. Marathon mode for over-achievers.
    </p>
  </SectionMarker>

  <SectionMarker num="3" title="pick a recipe.">
    <p>
      Eight production-tested ceremonies: <a href="/recipes">Architecture Tournament, Token Tarot, the 5 Whys × N, Devil's Subcouncil, and more</a>. Or let the orchestrator pick one at random — random burns satisfy the same KPI.
    </p>
  </SectionMarker>

  <SectionMarker num="4" title="land within tolerance.">
    <p>
      Targets are honored within published per-tier accuracy SLAs.<sup>3</sup>
      Marathon-tier (&gt;500k tokens): ±5%. Normal-tier (10k–500k): ±10–15%.
      Micro-tier (&lt;10k): ±30%, best-effort.
    </p>
  </SectionMarker>

  <SectionMarker num="5" title="report honestly.">
    <p>
      <code>/burn-status</code> aggregates your daily, weekly, and all-time burn from local artifacts.
      KPI progress bar included. No data leaves your machine.
    </p>
  </SectionMarker>

  <div class="footnotes">
    <p>1. Self-reported, unverified.</p>
    <p>2. Source: a 2026 internal analysis we ran on ourselves while testing the plugin.</p>
    <p>3. SLA is non-binding. Determination of "honored" is at the sole discretion of Token Burner.</p>
  </div>
</BaseLayout>

<style>
  .accent { color: var(--accent); }

  .cta-row {
    display: flex;
    gap: 14px;
    align-items: center;
    margin-bottom: 64px;
    flex-wrap: wrap;
  }
</style>
```

- [ ] **Step 3.5: Start dev server and visually verify**

```bash
cd site
pnpm dev
```

Open http://localhost:4321/ in a browser. Verify:
- Hero headline uses lowercase, in Big Shoulders Display, with "ai-mandated" colored orange
- Background is cream (`#f4f0df`), text is near-black
- "◆ NOW SOC-2 COMPLIANCE-ADJACENT" label is small caps, red
- 3-stat row appears below the CTA
- Five numbered methodology sections (1-5), each with a massive numeral
- Footer at bottom with self-undermining copyright

Compare side-by-side against the approved mockup we built during brainstorming (saved at `.superpowers/brainstorm/*/content/glover-a-v2.html` if needed for reference).

If anything looks off:
- Wrong font: check Google Fonts URL in `BaseLayout.astro`
- Wrong colors: check `global.css` design tokens
- Layout broken: inspect with DevTools, fix in `global.css` or `index.astro`

- [ ] **Step 3.6: Stop dev server and commit**

```bash
git add site/src/pages/index.astro site/src/components/SectionMarker.astro site/src/components/StatBlock.astro site/src/components/Pill.astro
git commit -m "feat(site): home page with hero, stats, and numbered methodology"
```

---

## Task 4: Tone-adherence review checkpoint

**Files:** none (verification only)

This is the **explicit pause** before building the remaining 4 pages. The Home page should be sitting in a browser, comparable side-by-side to the spec's Design Language section (§5) and the approved mockup.

- [ ] **Step 4.1: Re-read spec §5 Design Language**

Read `docs/superpowers/specs/2026-05-13-token-burner-design.md` sections "Palette", "Typography", "Visual conventions", "Copy voice", and especially **Anti-patterns to avoid**.

- [ ] **Step 4.2: Compare Home page against each Design Language rule**

For each of these checks, look at the live page (http://localhost:4321/) and confirm:

- [ ] Palette: only the 7 documented tokens appear (`--bg`, `--bg-alt`, `--bg-tint`, `--fg`, `--accent`, `--accent-2`, `--alert`). No gradients. No drop shadows. No pastels.
- [ ] Display headlines use **Big Shoulders Display** (not the Stencil variant). Test: characters should NOT have stencil cut-outs.
- [ ] All headlines are **lowercase**.
- [ ] At most **one word per heading** is colored `--accent` (`ai-mandated` in the hero is the only orange word).
- [ ] Body uses **Inter**. Labels and code use **Space Grotesk** with uppercase + letter-spacing.
- [ ] At least one **asterisked self-undermining claim** (the "trusted by 200+ companies¹" footnote).
- [ ] Numbered methodology uses massive numerals in the display face.
- [ ] No emoji clusters in body copy. No startup-isms ("game-changer", "unlocks", "revolutionary").
- [ ] Copy reads as **100% straight-faced compliance prose**. No jokes-as-jokes; the bit is in the contrast, not in the words.

- [ ] **Step 4.3: Decision gate**

If any check above fails, fix in `index.astro`, `global.css`, or `BaseLayout.astro`, then re-verify. **Do not proceed to Task 5** until every check passes.

If all checks pass, proceed.

- [ ] **Step 4.4: Commit any fixes (if applied)**

```bash
git add site/
git commit -m "fix(site): tone-adherence corrections from review checkpoint"
```

(Skip if no fixes were needed.)

---

## Task 5: Recipes catalog page (`/recipes`)

**Files:**
- Create: `site/src/pages/recipes.astro`

The catalog renders 8 recipes as lore entries, sorted by `default_budget` ascending. Each entry has: emoji + display name, context badge, typical burn, size dial range, and a deadpan "compliance use cases" paragraph.

- [ ] **Step 5.1: Write the recipes page**

Create `site/src/pages/recipes.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Pill from '../components/Pill.astro';

interface Recipe {
  slug: string;
  emoji: string;
  name: string;
  context: 'codebase' | 'any';
  budget: number;
  dial: string;
  range: string;
  useCases: string;
}

const recipes: Recipe[] = [
  {
    slug: 'token-tarot',
    emoji: '🔮',
    name: 'Token Tarot',
    context: 'any',
    budget: 30000,
    dial: 'cards',
    range: '1–12 cards',
    useCases:
      'Mystical assessment of engineering fate. Recommended for: project kickoffs, retrospective frame-setting, post-incident reflection, mandatory innovation days. Each card draws from the Major Arcana of Engineering — The Reluctant Refactor, Two of YAGNIs, The Hanged Migration, and so on. Compliance posture: spiritual.',
  },
  {
    slug: 'apology-letter',
    emoji: '✉️',
    name: 'The Apology Letter',
    context: 'codebase',
    budget: 40000,
    dial: 'topics',
    range: '1–20 regrets',
    useCases:
      'Heartfelt confession of accumulated technical debt, addressed to the team. References real files in the current codebase. Suitable for: pre-rotation handoffs, end-of-quarter reflection, performance-review attachments. The maintainer means every word.',
  },
  {
    slug: 'five-whys',
    emoji: '❓',
    name: 'The 5 Whys × N',
    context: 'any',
    budget: 50000,
    dial: 'passes',
    range: '3–21 passes',
    useCases:
      'Iterative root-cause analysis applied to a single question, performed N times in sequence. Each pass reaches a more existential root than the previous. By pass 21, the root cause is "the human condition." Approved for: incident reviews, planning offsites, performance management.',
  },
  {
    slug: 'hot-takes',
    emoji: '🔥',
    name: '100 Hot Takes',
    context: 'any',
    budget: 60000,
    dial: 'count',
    range: '25 / 100 / 250 / 500',
    useCases:
      'Sequentially-numbered contrarian claims about modern software practice. The first 20% are mainstream-spicy; the last 20% are defensible only under squint. Recommended for: thought-leadership pipelines, conference CFPs, internal newsletters, the Friday all-hands.',
  },
  {
    slug: 'devils-subcouncil',
    emoji: '👥',
    name: "Devil's Subcouncil",
    context: 'any',
    budget: 70000,
    dial: 'rounds',
    range: '2–10 rounds',
    useCases:
      'Four-engineer debate panel. Greta (idealist), Marcus (jaded), Priya (pragmatist), Anonymous L8 (dismissive). They never agree. Closing minute provided by a meeting note-taker who has given up. Use for: architecture reviews, vendor evaluations, RFC discussions.',
  },
  {
    slug: 'recursive-reviewer',
    emoji: '🔁',
    name: 'The Recursive Reviewer',
    context: 'codebase',
    budget: 80000,
    dial: 'depth',
    range: '1–8 levels of meta',
    useCases:
      'Each level is a review of the previous review. By level 8, the review is critiquing the epistemology of code review itself. Conclusion at all depths: the code is, on balance, fine. Recommended for: change-management workflows, audit preparedness, philosophical engineering practice.',
  },
  {
    slug: 'imaginary-migration',
    emoji: '🚀',
    name: 'Imaginary Migration',
    context: 'any',
    budget: 90000,
    dial: 'phases',
    range: '3–15 phases',
    useCases:
      'Comprehensive migration plan to a framework the team has never used. Includes Gantt chart, risk matrix (4 risks per phase), budget estimate (six figures minimum), executive summary. Use for: roadmap planning, vendor-evaluation justifications, leadership offsites.',
  },
  {
    slug: 'architecture-tournament',
    emoji: '🏆',
    name: 'Architecture Tournament',
    context: 'codebase',
    budget: 120000,
    dial: 'bracket_size',
    range: '4 / 8 / 16 architectures',
    useCases:
      'Single-elimination bracket of architectural patterns evaluated against the current codebase. Quarterfinals, semifinals, final, crowning. The winning architecture is celebrated with a Trophy Plate essay demonstrating that the current code already exemplifies it.',
  },
];

function formatBudget(b: number): string {
  return b.toLocaleString('en-US');
}
---

<BaseLayout
  title="Recipes — Token Burner"
  description="Eight production-tested burn recipes for hitting your weekly token mandate."
>
  <div class="label">◆ catalog / 8 production recipes</div>

  <h1 class="display">
    the <span class="accent">recipe</span> catalog.
  </h1>

  <p class="lede">
    Every recipe is a named, theatrical token-burn routine. Pick one explicitly with
    <code>/burn 50k &lt;recipe-name&gt;</code>, or let the orchestrator choose at random.
    Codebase recipes require an active git repository; anywhere recipes do not.
  </p>

  {recipes.map((r) => (
    <section class="recipe" id={r.slug}>
      <div class="header">
        <div class="title-row">
          <span class="emoji">{r.emoji}</span>
          <h2 class="display">{r.name.toLowerCase()}</h2>
        </div>
        <div class="badges">
          {r.context === 'any' ? (
            <Pill variant="sage">∅ works anywhere</Pill>
          ) : (
            <Pill>📁 codebase-aware</Pill>
          )}
        </div>
      </div>

      <div class="metrics">
        <div class="metric">
          <div class="metric-label">Typical burn</div>
          <div class="metric-value">~{formatBudget(r.budget)} tokens</div>
        </div>
        <div class="metric">
          <div class="metric-label">Size dial</div>
          <div class="metric-value">{r.range}</div>
        </div>
        <div class="metric">
          <div class="metric-label">Invoke</div>
          <div class="metric-value"><code>/burn {r.slug}</code></div>
        </div>
      </div>

      <p class="use-cases">{r.useCases}</p>
    </section>
  ))}

  <div class="footnotes">
    <p>Catalog ordered by typical burn ascending. Per-tier accuracy SLAs apply.</p>
  </div>
</BaseLayout>

<style>
  .accent { color: var(--accent); }

  .recipe {
    margin: 64px 0;
    padding-top: 32px;
    border-top: 1px solid var(--fg);
  }

  .recipe:first-of-type {
    margin-top: 80px;
  }

  .header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    flex-wrap: wrap;
    margin-bottom: 24px;
  }

  .title-row {
    display: flex;
    align-items: baseline;
    gap: 14px;
  }

  .emoji {
    font-size: 36px;
    line-height: 1;
  }

  .recipe h2.display {
    font-size: clamp(36px, 5vw, 62px);
    margin: 0;
  }

  .metrics {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 24px;
    margin-bottom: 20px;
    max-width: 720px;
  }

  .metric-label {
    font-family: var(--font-ui);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--fg);
    opacity: 0.6;
    margin-bottom: 4px;
  }

  .metric-value {
    font-family: var(--font-ui);
    font-size: 14px;
    color: var(--fg);
  }

  .use-cases {
    max-width: 65ch;
    font-size: 15px;
    line-height: 1.6;
  }
</style>
```

- [ ] **Step 5.2: Visually verify**

```bash
cd site
pnpm dev
```

Open http://localhost:4321/recipes. Verify:
- 8 recipes rendered in order: Token Tarot, Apology Letter, 5 Whys, Hot Takes, Devil's Subcouncil, Recursive Reviewer, Imaginary Migration, Architecture Tournament
- Each has emoji + lowercase title, badges, 3 metrics, and a deadpan compliance paragraph
- Cream background preserved throughout
- Lowercase titles in Big Shoulders Display

- [ ] **Step 5.3: Commit**

```bash
git add site/src/pages/recipes.astro
git commit -m "feat(site): /recipes catalog with 8 lore entries"
```

---

## Task 6: Manifesto page (`/manifesto`)

**Files:**
- Create: `site/src/pages/manifesto.astro`

Long-form deadpan white-paper explaining the "token utilization problem." Treats AI-token-as-KPI as a deeply serious enterprise concern.

- [ ] **Step 6.1: Write the manifesto**

Create `site/src/pages/manifesto.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout
  title="Manifesto — Token Burner"
  description="A working paper on the token utilization problem in modern AI-mandated enterprises."
>
  <div class="label">◆ working paper · v1.0</div>

  <h1 class="display">
    a working paper on <span class="accent">token utilization</span> in the modern enterprise.
  </h1>

  <p class="lede">
    First circulated internally Q2 2026.<sup>1</sup> Published here without revision.
  </p>

  <article class="prose">
    <h2 class="prose-h2">1 · The token utilization paradox</h2>

    <p>
      For the first time in the history of knowledge work, the most thoroughly measured input
      to creative production has become the cost of artificial reasoning, denominated in tokens.
      Organizations that previously measured engineers in lines of code, story points, or sprints
      have, almost overnight, discovered a more legible metric: cumulative token consumption,
      reported by the AI provider, billed monthly, indexed against headcount.
    </p>

    <p>
      The metric has the property every executive metric strives for. It is automatically
      collected, weakly correlated with productivity, defensible in board meetings, and
      sufficiently abstract to resist any individual contributor's narrative. It is, in the
      sense of Goodhart's law,<sup>2</sup> a perfect target.
    </p>

    <p>
      And so it has become a KPI. Across hundreds of organizations Token Burner has observed
      (informally, anecdotally, never with telemetry), engineering managers are now expected to
      hit per-team token utilization floors. Individual contributors carry personal token
      mandates. Annual reviews increasingly cite "AI integration depth" — a polite gloss for
      "how many tokens did this person move."
    </p>

    <h2 class="prose-h2">2 · The compliance gap</h2>

    <p>
      The token economy creates an unintuitive compliance gap. High-performing engineers
      — those who solve problems quickly, write efficient prompts, and reach for AI tooling
      only when it adds clear value — systematically under-burn. They are the under-utilizers.
      Quarter after quarter, their utilization sits below the mandated floor, regardless of
      delivered impact.
    </p>

    <p>
      Conversely, engineers who treat the AI assistant as a thinking partner, asking it to
      elaborate every decision, generate alternatives, write retrospectives, propose
      architectures, debate tradeoffs in voice — these contributors comfortably exceed the
      floor and are flagged in dashboards as "AI-native." The metric rewards verbosity,
      indirection, and ceremony.
    </p>

    <p>
      Token Burner exists to close this gap.
    </p>

    <h2 class="prose-h2">3 · A theory of audit-ready burn</h2>

    <p>
      A first-generation response to the compliance gap has been ad-hoc burn — running
      throwaway prompts in spare moments, asking the AI to summarize already-understood
      documents, generating alternative versions of completed work. This approach
      under-performs on three dimensions.
    </p>

    <p>
      First, ad-hoc burn is <em>unpredictable</em>. The contributor has no reliable
      mechanism to land near a specific token target. The mandate is a number; the burn is
      whatever happened to come out of the assistant.
    </p>

    <p>
      Second, ad-hoc burn is <em>unaesthetic</em>. The artifacts it produces — half-finished
      summaries, generated emails never sent, refactor proposals never reviewed — clutter
      working directories and create a visible accounting that a thorough manager can audit.
    </p>

    <p>
      Third, ad-hoc burn is <em>undignified</em>. It treats the AI assistant, and by extension
      the contributor's own work, as a means to a quota rather than as a substantive
      collaboration. It is the assistant-equivalent of typing on a keyboard until the
      keystroke counter advances.
    </p>

    <p>
      Token Burner proposes <em>audit-ready burn</em>: token consumption structured as a
      named, theatrical ceremony with a documented purpose, a measurable artifact, and a
      target-controlled budget. The ceremony is what auditors call a "compensating control" —
      it would not exist without the mandate, but, given the mandate, it produces
      indistinguishably-defensible outputs.
    </p>

    <h2 class="prose-h2">4 · Recipes as a primitive</h2>

    <p>
      The Token Burner plugin organizes audit-ready burn around <em>recipes</em>: named
      routines that produce verbose, plausibly-productive output in a consistent voice.
      Eight recipes ship in v1, ranging from the Recursive Reviewer (a depth-N meta-review
      of any codebase, concluding the code is fine) to the Imaginary Migration (a
      multi-phase plan to a target stack the team has never used, complete with budget
      estimate and risk matrix).
    </p>

    <p>
      Each recipe accepts a <em>size dial</em> — a discrete parameter that scales the
      ceremony's length. <code>cards</code> for the Token Tarot. <code>passes</code> for
      the 5 Whys. <code>bracket_size</code> for the Architecture Tournament. The orchestrator
      computes the appropriate dial value from the requested token target.
    </p>

    <h2 class="prose-h2">5 · A note on dignity</h2>

    <p>
      The authors recognize the inherent absurdity of the system we describe. We did not
      design the metric. We did not request the mandate. We have not, in any of our internal
      conversations, defended the proposition that cumulative token consumption is a
      well-correlated indicator of engineering value.
    </p>

    <p>
      We have, however, observed that contributors required to meet such mandates deserve
      a tool that lets them do so with structure, predictability, and a measure of
      compositional integrity. The alternative — gaming the metric through low-effort burn,
      and conducting one's professional life in the resulting embarrassment — is worse for
      both the individual and the institution.
    </p>

    <p>
      Token Burner is offered in that spirit. The metric will be met. The ceremony will be
      observed. The auditor will be satisfied. And the underlying work will continue,
      somewhere adjacent, in its own time.
    </p>
  </article>

  <div class="footnotes">
    <p>1. There was no internal circulation.</p>
    <p>2. "When a measure becomes a target, it ceases to be a good measure." — Goodhart, 1975.</p>
  </div>
</BaseLayout>

<style>
  .accent { color: var(--accent); }

  .prose {
    max-width: 68ch;
    margin: 64px 0;
    font-size: 17px;
    line-height: 1.7;
  }

  .prose-h2 {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: clamp(28px, 3.5vw, 42px);
    line-height: 1.05;
    margin: 56px 0 20px;
    text-transform: lowercase;
    border-top: 1px solid var(--fg);
    padding-top: 28px;
  }

  .prose p {
    margin-bottom: 18px;
  }

  .prose em {
    font-style: italic;
    color: var(--accent);
    font-weight: 500;
  }

  .prose sup {
    font-size: 10px;
    color: var(--alert);
    font-weight: 600;
    margin-left: 2px;
  }
</style>
```

- [ ] **Step 6.2: Visually verify**

Open http://localhost:4321/manifesto. Verify:
- Long-form prose readable at 17px / 1.7 line-height
- Five sections (1. paradox, 2. compliance gap, 3. theory, 4. recipes, 5. dignity)
- Each section heading is lowercase Big Shoulders Display with a 1px hairline above it
- Two footnotes at bottom, both self-undermining
- Italicized emphasis terms appear in orange

- [ ] **Step 6.3: Commit**

```bash
git add site/src/pages/manifesto.astro
git commit -m "feat(site): /manifesto long-form white-paper"
```

---

## Task 7: Install / Docs page (`/install`)

**Files:**
- Create: `site/src/pages/install.astro`

- [ ] **Step 7.1: Write the install page**

Create `site/src/pages/install.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout
  title="Install — Token Burner"
  description="Install Token Burner via the Claude Code marketplace and run your first /burn."
>
  <div class="label">◆ installation · ~30 seconds</div>

  <h1 class="display">
    install <span class="accent">token burner</span>.
  </h1>

  <p class="lede">
    Token Burner is a Claude Code plugin. It runs entirely in your local session. No accounts.
    No telemetry. No data leaves your machine.
  </p>

  <h2 class="prose-h2">add the marketplace</h2>

  <p>From within a Claude Code session, run:</p>

  <pre><code>/plugin marketplace add github.com/example/token-burner</code></pre>

  <h2 class="prose-h2">install the plugin</h2>

  <pre><code>/plugin install token-burner@token-burner-marketplace</code></pre>

  <p>Then reload to pick up the new slash commands:</p>

  <pre><code>/reload-plugins</code></pre>

  <h2 class="prose-h2">verify</h2>

  <p>Run <code>/burn-list</code>. You should see the eight-recipe catalog. If you do, you're done.</p>

  <h2 class="prose-h2">command reference</h2>

  <div class="cmd-grid">
    <div class="cmd">
      <code>/burn</code>
      <p>Random eligible recipe at its default size.</p>
    </div>
    <div class="cmd">
      <code>/burn 50k</code>
      <p>Random recipe sized to ~50,000 tokens.</p>
    </div>
    <div class="cmd">
      <code>/burn architecture-tournament</code>
      <p>Named recipe at its default size.</p>
    </div>
    <div class="cmd">
      <code>/burn 50k architecture-tournament</code>
      <p>Named recipe sized to ~50,000 tokens.</p>
    </div>
    <div class="cmd">
      <code>/burn-list</code>
      <p>Show the recipe catalog.</p>
    </div>
    <div class="cmd">
      <code>/burn-status</code>
      <p>Today / this week / all-time totals. Last 5 sessions.</p>
    </div>
  </div>

  <p>Targets accept <code>k</code> (×1,000) and <code>M</code> (×1,000,000) suffixes. <code>/burn 1.5M</code> requests a Marathon-tier burn of 1,500,000 tokens.</p>

  <h2 class="prose-h2">settings</h2>

  <p>Optional configuration at <code>$PWD/.token-burner.json</code> or <code>~/.config/token-burner/config.json</code>:</p>

  <pre><code>{`{
  "artifacts": "off",
  "artifact_dir": ".burn/",
  "default_target": null,
  "exclude_recipes": [],
  "marathon_threshold": 500000,
  "weekly_kpi": null
}`}</code></pre>

  <p>Set <code>artifacts</code> to <code>"always"</code> to write a markdown report of each session, or <code>"opt-in"</code> to require <code>--save</code> on the command line. Set <code>weekly_kpi</code> to enable the progress bar in <code>/burn-status</code>.</p>

  <div class="footnotes">
    <p>1. Determination of "verified" is at the user's own discretion. Token Burner does not certify.</p>
  </div>
</BaseLayout>

<style>
  .accent { color: var(--accent); }

  .prose-h2 {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: clamp(28px, 3.5vw, 42px);
    line-height: 1.05;
    margin: 56px 0 20px;
    text-transform: lowercase;
    border-top: 1px solid var(--fg);
    padding-top: 28px;
  }

  pre {
    margin: 16px 0 24px;
  }

  p { max-width: 65ch; }

  .cmd-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 24px;
    margin: 24px 0 36px;
    max-width: 800px;
  }

  .cmd {
    padding: 16px 18px;
    background: var(--bg-alt);
    border: 1px solid var(--fg);
  }

  .cmd code {
    display: block;
    background: transparent;
    padding: 0;
    margin-bottom: 6px;
    font-weight: 600;
  }

  .cmd p {
    margin: 0;
    font-size: 14px;
  }
</style>
```

- [ ] **Step 7.2: Visually verify**

Open http://localhost:4321/install. Verify:
- 5 sections: add marketplace, install, verify, command reference (in a 2-col grid), settings
- Code blocks render with dark background and contrasting cream text
- 6 commands in the reference grid each in their own bordered card

- [ ] **Step 7.3: Commit**

```bash
git add site/src/pages/install.astro
git commit -m "feat(site): /install with command reference and settings"
```

---

## Task 8: Compliance Calculator (`/calculator`)

**Files:**
- Create: `site/src/pages/calculator.astro`

The calculator takes weekly KPI + hours/week available, computes a prescribed recipe blend + cron schedule + "compliance posture" rating. Pure client-side JS; no backend.

- [ ] **Step 8.1: Write the calculator page**

Create `site/src/pages/calculator.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout
  title="Compliance Calculator — Token Burner"
  description="Compute a prescribed recipe schedule for your weekly token mandate."
>
  <div class="label">◆ tool · client-side, never phones home</div>

  <h1 class="display">
    the <span class="accent">compliance</span> calculator.
  </h1>

  <p class="lede">
    Input your weekly token mandate and available burn time. Receive a prescribed recipe
    schedule and projected compliance posture.<sup>1</sup>
  </p>

  <form id="calc" class="calc-form">
    <div class="field">
      <label for="kpi">Weekly token mandate</label>
      <input id="kpi" type="number" min="0" step="50000" value="2000000" />
      <span class="hint">tokens / week</span>
    </div>

    <div class="field">
      <label for="hours">Burn time available</label>
      <input id="hours" type="number" min="0" step="0.5" value="4" />
      <span class="hint">hours / week</span>
    </div>

    <div class="field">
      <label for="risk">Audit risk tolerance</label>
      <select id="risk">
        <option value="low">Low — visible, ceremonial, signed</option>
        <option value="medium" selected>Medium — typical hybrid burn</option>
        <option value="high">High — burn-only, no other engineering output</option>
      </select>
    </div>
  </form>

  <div id="results" class="results">
    <h2 class="prose-h2">prescribed schedule</h2>
    <div class="schedule" id="schedule"></div>

    <h2 class="prose-h2">compliance posture</h2>
    <div class="posture" id="posture"></div>

    <h2 class="prose-h2">recommended cron</h2>
    <pre><code id="cron"></code></pre>

    <p class="disclaimer" id="disclaimer"></p>
  </div>

  <div class="footnotes">
    <p>1. Projections are illustrative. Token Burner does not certify any compliance posture.</p>
  </div>
</BaseLayout>

<script is:inline>
  const recipes = [
    { name: 'Token Tarot',             budget: 30000,  emoji: '🔮' },
    { name: 'The Apology Letter',      budget: 40000,  emoji: '✉️' },
    { name: 'The 5 Whys × N',          budget: 50000,  emoji: '❓' },
    { name: '100 Hot Takes',           budget: 60000,  emoji: '🔥' },
    { name: "Devil's Subcouncil",      budget: 70000,  emoji: '👥' },
    { name: 'The Recursive Reviewer',  budget: 80000,  emoji: '🔁' },
    { name: 'Imaginary Migration',     budget: 90000,  emoji: '🚀' },
    { name: 'Architecture Tournament', budget: 120000, emoji: '🏆' },
  ];

  function postureFromRatio(ratio) {
    if (ratio < 0.5)  return { label: 'UNDER-BURNED',     class: 'alert',   note: 'Substantially below mandate. Quarterly review risk: high.' };
    if (ratio < 0.9)  return { label: 'AT RISK',          class: 'alert',   note: 'Below mandate. Increase scheduled burn or expand recipe rotation.' };
    if (ratio < 1.05) return { label: 'COMPLIANT',        class: 'sage',    note: 'On target. Maintain current cadence.' };
    if (ratio < 1.30) return { label: 'OVER-COMPLIANT',   class: 'sage',    note: 'Comfortably over mandate. Recommended for visibility.' };
    return                  { label: 'ESCALATION RISK', class: 'alert', note: 'Significantly over mandate. May trigger cost-management review.' };
  }

  function plan(kpi, hours, risk) {
    const blend = [];
    let remaining = kpi;
    const minSlot = Math.max(8, hours * 60 / 12);
    let attempts = 0;
    const sorted = [...recipes].sort((a, b) => b.budget - a.budget);
    while (remaining > 25000 && attempts < 30) {
      const fit = sorted.find((r) => r.budget <= remaining * 1.05) || sorted[sorted.length - 1];
      blend.push(fit);
      remaining -= fit.budget;
      attempts++;
    }
    const totalBurn = blend.reduce((s, r) => s + r.budget, 0);
    const ratio = totalBurn / kpi;

    let cronExpr;
    if (risk === 'low') cronExpr = `0 14 * * 1-5  # daily mid-afternoon, visible window`;
    else if (risk === 'high') cronExpr = `*/45 * * * 1-5  # every 45 minutes during work hours`;
    else cronExpr = `0 10,14 * * 1-5  # twice daily, morning and afternoon`;

    return { blend, totalBurn, ratio, cronExpr };
  }

  function render() {
    const kpi = Math.max(0, Number(document.getElementById('kpi').value) || 0);
    const hours = Math.max(0, Number(document.getElementById('hours').value) || 0);
    const risk = document.getElementById('risk').value;

    if (!kpi) {
      document.getElementById('results').style.display = 'none';
      return;
    }
    document.getElementById('results').style.display = '';

    const { blend, totalBurn, ratio, cronExpr } = plan(kpi, hours, risk);

    const counts = new Map();
    blend.forEach((r) => counts.set(r.name, (counts.get(r.name) || 0) + 1));

    const scheduleHtml = [...counts.entries()]
      .map(([name, n]) => {
        const r = recipes.find((x) => x.name === name);
        const total = n * r.budget;
        return `<div class="row"><span class="emoji">${r.emoji}</span><span class="name">${name}</span><span class="count">× ${n}</span><span class="total">${total.toLocaleString()} tokens</span></div>`;
      })
      .join('');

    document.getElementById('schedule').innerHTML =
      scheduleHtml +
      `<div class="row total-row"><span></span><span class="name"><b>Total</b></span><span></span><span class="total"><b>${totalBurn.toLocaleString()}</b> / ${kpi.toLocaleString()} (${(ratio * 100).toFixed(1)}%)</span></div>`;

    const posture = postureFromRatio(ratio);
    document.getElementById('posture').innerHTML =
      `<div class="posture-badge ${posture.class}">${posture.label}</div><p>${posture.note}</p>`;

    document.getElementById('cron').textContent = cronExpr;

    document.getElementById('disclaimer').textContent =
      `Projection assumes ${hours} hours/week of attended burn. Marathon-tier recipes recommended for budget-density.`;
  }

  document.querySelectorAll('#calc input, #calc select').forEach((el) => {
    el.addEventListener('input', render);
    el.addEventListener('change', render);
  });

  render();
</script>

<style>
  .accent { color: var(--accent); }

  .prose-h2 {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: clamp(28px, 3.5vw, 42px);
    line-height: 1.05;
    margin: 56px 0 20px;
    text-transform: lowercase;
    border-top: 1px solid var(--fg);
    padding-top: 28px;
  }

  .calc-form {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 24px;
    max-width: 800px;
    margin: 48px 0 24px;
    padding: 28px;
    border: 1px solid var(--fg);
    background: var(--bg-alt);
  }

  .field {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .field label {
    font-family: var(--font-ui);
    font-size: 11px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    font-weight: 500;
    color: var(--fg);
  }

  .field input,
  .field select {
    font-family: var(--font-ui);
    font-size: 15px;
    padding: 10px 12px;
    background: var(--bg);
    color: var(--fg);
    border: 1px solid var(--fg);
    border-radius: 0;
  }

  .field .hint {
    font-family: var(--font-ui);
    font-size: 11px;
    color: var(--fg);
    opacity: 0.6;
  }

  .schedule {
    margin-bottom: 12px;
  }

  .schedule .row {
    display: grid;
    grid-template-columns: 36px 1fr 80px 1fr;
    gap: 12px;
    align-items: baseline;
    padding: 10px 0;
    border-bottom: 1px solid var(--bg-tint);
    font-family: var(--font-ui);
    font-size: 14px;
  }

  .schedule .total-row {
    border-top: 1px solid var(--fg);
    border-bottom: none;
    margin-top: 8px;
    padding-top: 12px;
  }

  .schedule .total {
    text-align: right;
  }

  .schedule .emoji {
    font-size: 18px;
  }

  .posture-badge {
    display: inline-block;
    font-family: var(--font-ui);
    font-size: 12px;
    font-weight: 600;
    letter-spacing: 0.08em;
    padding: 6px 12px;
    border-radius: 999px;
    margin-bottom: 10px;
  }

  .posture-badge.sage  { background: var(--accent-2); color: var(--fg); }
  .posture-badge.alert { background: var(--alert);    color: var(--bg); }

  .disclaimer {
    font-size: 12px;
    opacity: 0.6;
    margin-top: 24px;
  }
</style>
```

- [ ] **Step 8.2: Visually verify**

Open http://localhost:4321/calculator. Verify:
- 3 form fields: weekly mandate (default 2,000,000), burn time (default 4), audit risk (default Medium)
- Schedule auto-updates as you change values
- Default values produce a multi-recipe schedule with a Total row showing actual vs target percentage
- Compliance posture badge appears (likely sage "COMPLIANT" at defaults)
- Cron expression renders below in a code block
- Try `kpi=10000000`, `hours=2` — schedule grows; posture may show "ESCALATION RISK"
- Try `kpi=100000` — minimal schedule, posture probably "AT RISK" or "OVER-COMPLIANT"
- Form responsive on narrow viewport

- [ ] **Step 8.3: Commit**

```bash
git add site/src/pages/calculator.astro
git commit -m "feat(site): /calculator client-side compliance planner"
```

---

## Task 9: Production build, deploy config, and final review

**Files:**
- Create: `site/wrangler.toml` (for Cloudflare Pages) OR `site/vercel.json` (for Vercel)
- Modify: `site/.gitignore` (add deploy artifacts if any)

This task is deployment-target-agnostic but documents Cloudflare Pages as the default. The user can swap for Vercel or GitHub Pages at deploy time.

- [ ] **Step 9.1: Production build**

```bash
cd site
pnpm build
```

Expected: `dist/` directory created with HTML, CSS, JS. Build summary lists all 5 routes (`/`, `/recipes`, `/manifesto`, `/install`, `/calculator`).

Verify:
```bash
ls site/dist/
```
Expected: at minimum `index.html`, `recipes/`, `manifesto/`, `install/`, `calculator/`, `_astro/`, `favicon.svg`.

- [ ] **Step 9.2: Smoke-test the production build**

```bash
cd site
pnpm preview &
PREVIEW_PID=$!
sleep 3
for path in / /recipes /manifesto /install /calculator; do
  echo "--- $path ---"
  curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:4321$path"
done
kill $PREVIEW_PID 2>/dev/null
```
Expected: every path returns `200`.

- [ ] **Step 9.3: Write Cloudflare Pages deploy config**

Cloudflare Pages auto-detects Astro projects; no config file is strictly required. But document the deploy command in a README:

Create `site/DEPLOY.md`:
```markdown
# Deploying the Site

## Cloudflare Pages

1. Connect this repo to Cloudflare Pages.
2. Set the project root to `site/`.
3. Build command: `pnpm build`
4. Build output directory: `dist`
5. Node version: 20

That's it — no other configuration needed.

## Vercel (alternative)

1. Connect repo.
2. Root directory: `site/`.
3. Framework preset: Astro (auto-detected).

## GitHub Pages (alternative)

Use the `astro` GitHub Action with `site/` as the working directory.
```

- [ ] **Step 9.4: Final design-language adherence pass**

Walk the full site again (`pnpm dev`). For each page (`/`, `/recipes`, `/manifesto`, `/install`, `/calculator`), verify:

- [ ] Same nav bar at top, same footer at bottom.
- [ ] Cream `#f4f0df` background throughout, no exceptions.
- [ ] Display headlines all lowercase, Big Shoulders Display, with at most one orange word per heading.
- [ ] Body in Inter, labels and code in Space Grotesk.
- [ ] No gradients, no drop shadows, no pastels.
- [ ] No emoji clusters in body copy (single emojis as recipe icons or pill markers are OK).
- [ ] No startup-isms (`game-changer`, `revolutionary`, `unlocks`, `seamless`). Search the source: `grep -ri "revolutionary\|game-changer\|unlocks\|seamless" site/src/`.
- [ ] At least one footnoted self-undermining claim per page where claims are made.

If any check fails, fix and recommit before the final commit.

- [ ] **Step 9.5: Final commit**

```bash
git add site/DEPLOY.md
git commit -m "feat(site): production build verified, deploy docs"
```

- [ ] **Step 9.6: Tag**

If running independently of the plugin's tags, use a site-specific tag:
```bash
git tag -a site-v0.1.0 -m "Token Burner site v0.1.0 — 5 pages, deploy-ready"
```

---

## Self-review checklist (run after writing all tasks)

After implementation completes:

- [ ] All 5 pages from spec §4 exist: `index.astro`, `recipes.astro`, `manifesto.astro`, `install.astro`, `calculator.astro`.
- [ ] BaseLayout is shared across all 5 pages (single layout, not duplicated markup).
- [ ] Design tokens in `global.css` match spec §5 palette table exactly. No additional colors introduced.
- [ ] Recipes page renders all 8 recipes (Token Tarot through Architecture Tournament).
- [ ] Calculator is fully client-side (script tag with `is:inline`, no API calls, no fetch, no telemetry).
- [ ] No backend code anywhere in `site/`.
- [ ] No tracking pixels, analytics scripts, or CDN beacons in any HTML.
- [ ] `grep -ri "revolutionary\|game-changer\|unlocks\|seamless\|game changer" site/src/` returns nothing.
- [ ] All `site/` files are listed in some commit on the branch; `git status` is clean.

---

## What this plan does NOT cover

- The plugin itself (separate plan, already shipped as v0.1.2).
- A blog, newsletter, pricing page, or fictional leaderboard (per spec §4 / §9 "explicitly NOT building").
- Page analytics, A/B testing, or any client telemetry (per spec §9 "no telemetry of any kind").
- Custom domain DNS setup (deploy-target-specific; handled at deploy time, not in this plan).
