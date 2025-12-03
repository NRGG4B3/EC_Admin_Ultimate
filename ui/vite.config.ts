import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  
  base: './',  // CRITICAL: Use relative paths for FiveM NUI
  
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },

  build: {
    outDir: 'dist',
    emptyOutDir: false,  // Don't delete everything in case script runs twice
    sourcemap: false,
    minify: 'esbuild',  // Faster than terser
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]',
        manualChunks: undefined,  // Disable manual chunking to prevent circular deps
      },
    },
    chunkSizeWarningLimit: 2000,  // Increase warning limit
  },

  server: {
    port: 3000,
    strictPort: false,
    open: false,
  },
});