/**
 * Post-build script to fix index.html references
 * Ensures the built HTML points to the actual asset files
 * ES Module version (for package.json with "type": "module")
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const distDir = path.join(__dirname, '../dist');
const indexPath = path.join(distDir, 'index.html');
const assetsDir = path.join(distDir, 'assets');

console.log('[Fix HTML] Fixing index.html asset references...');

try {
  // Check if dist folder exists
  if (!fs.existsSync(distDir)) {
    console.error('[Fix HTML] ERROR: dist folder does not exist!');
    console.error('[Fix HTML] Make sure vite build completed successfully.');
    process.exit(1);
  }
  
  // Check if index.html exists
  if (!fs.existsSync(indexPath)) {
    console.error('[Fix HTML] ERROR: index.html does not exist in dist folder!');
    process.exit(1);
  }
  
  // Check if assets folder exists
  if (!fs.existsSync(assetsDir)) {
    console.error('[Fix HTML] ERROR: assets folder does not exist!');
    process.exit(1);
  }
  
  // Read the built index.html
  let html = fs.readFileSync(indexPath, 'utf8');
  
  // Find the actual built asset files
  const files = fs.readdirSync(assetsDir);
  const jsFile = files.find(f => f.startsWith('index-') && f.endsWith('.js')) || 
                 files.find(f => f.endsWith('.js') && f.includes('main'));
  const cssFile = files.find(f => f.startsWith('index-') && f.endsWith('.css')) ||
                  files.find(f => f.endsWith('.css'));
  
  if (!jsFile) {
    console.error('[Fix HTML] ERROR: Could not find built JS file!');
    console.error(`[Fix HTML] Available files: ${files.join(', ')}`);
    process.exit(1);
  }
  
  if (!cssFile) {
    console.warn('[Fix HTML] WARNING: Could not find built CSS file, continuing without it...');
  }
  
  console.log(`[Fix HTML] Found JS: ${jsFile}`);
  console.log(`[Fix HTML] Found CSS: ${cssFile}`);
  
  // Create the correct HTML
  let fixedHtml = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <base href="./">
    <title>EC Admin Ultimate</title>
    <script type="module" crossorigin src="./assets/${jsFile}"></script>`;
  
  if (cssFile) {
    fixedHtml += `\n    <link rel="stylesheet" crossorigin href="./assets/${cssFile}">`;
  }
  
  fixedHtml += `
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>`;
  
  // Write the fixed HTML
  fs.writeFileSync(indexPath, fixedHtml, 'utf8');
  
  console.log('[Fix HTML] ✅ index.html fixed successfully');
  console.log(`[Fix HTML] JS:  ./assets/${jsFile}`);
  if (cssFile) {
    console.log(`[Fix HTML] CSS: ./assets/${cssFile}`);
  } else {
    console.log(`[Fix HTML] CSS: (not found, skipped)`);
  }
  
} catch (error) {
  console.error('[Fix HTML] ERROR:', error.message);
  process.exit(1);
}
