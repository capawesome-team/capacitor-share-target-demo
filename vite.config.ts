import { defineConfig } from 'vite';

export default defineConfig({
  root: './src',
  build: {
    outDir: '../dist',
    minify: false,
    emptyOutDir: true,
  },
  server: {
    allowedHosts: ['recommendations-tourism-ver-contrary.trycloudflare.com'],
  },
});
