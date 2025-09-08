import { defineConfig } from 'vite';

export default defineConfig({
  root: './src',
  build: {
    outDir: '../dist',
    minify: false,
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: './src/index.html',
        sw: './src/sw.js'
      },
      output: {
        entryFileNames: (chunkInfo) => {
          return chunkInfo.name === 'sw' ? 'sw.js' : 'assets/[name]-[hash].js';
        }
      }
    }
  },
  server: {
    allowedHosts: ['recommendations-tourism-ver-contrary.trycloudflare.com'],
  },
});
