import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    minify: 'esbuild',
    target: 'es2022',
    cssMinify: true,
    reportCompressedSize: true,
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
  },
  server: {
    port: 43123,
    host: '127.0.0.1',
  },
  preview: {
    port: 43123,
    host: '127.0.0.1',
  },
});
