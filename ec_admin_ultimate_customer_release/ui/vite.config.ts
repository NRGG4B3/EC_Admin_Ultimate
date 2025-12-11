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
    emptyOutDir: true,  // Clean dist folder before build
    sourcemap: false,
    minify: 'esbuild',  // Faster than terser
    rollupOptions: {
      input: path.resolve(__dirname, './index.html'),  // Explicit entry point
      output: {
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: (assetInfo) => {
          // Preserve public folder structure for images
          if (assetInfo.name && assetInfo.name.includes('public/')) {
            const publicPath = assetInfo.name.replace(/^.*public\//, '');
            return publicPath;
          }
          return 'assets/[name]-[hash].[ext]';
        },
        manualChunks: undefined,  // Disable manual chunking to prevent circular deps
      },
    },
    chunkSizeWarningLimit: 2000,  // Increase warning limit
    copyPublicDir: true,  // Copy public directory to dist
  },
  
  publicDir: 'public',  // Specify public directory

  server: {
    port: 3000,
    strictPort: false,
    open: false,
  },
});