import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://token-burner.pages.dev',
  output: 'static',
  build: {
    inlineStylesheets: 'auto',
  },
});
