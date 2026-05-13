import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://tokenburner.example.com',
  output: 'static',
  build: {
    inlineStylesheets: 'auto',
  },
});
