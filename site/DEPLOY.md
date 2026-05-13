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
