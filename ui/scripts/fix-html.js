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
  // Read the built index.html
  let html = fs.readFileSync(indexPath, 'utf8');
  
  // Find the actual built asset files
  const files = fs.readdirSync(assetsDir);
  const jsFile = files.find(f => f.startsWith('index-') && f.endsWith('.js'));
  const cssFile = files.find(f => f.startsWith('index-') && f.endsWith('.css'));
  
  if (!jsFile || !cssFile) {
    console.error('[Fix HTML] ERROR: Could not find built assets!');
    console.error(`[Fix HTML] JS: ${jsFile}, CSS: ${cssFile}`);
    process.exit(1);
  }
  
  console.log(`[Fix HTML] Found JS: ${jsFile}`);
  console.log(`[Fix HTML] Found CSS: ${cssFile}`);
  
  // Create the correct HTML
  const fixedHtml = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <base href="./">
    <title>EC Admin Ultimate</title>
    <script type="module" crossorigin src="./assets/${jsFile}"></script>
    <link rel="stylesheet" crossorigin href="./assets/${cssFile}">
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>`;
  
  // Write the fixed HTML
  fs.writeFileSync(indexPath, fixedHtml, 'utf8');
  
  console.log('[Fix HTML] ✅ index.html fixed successfully');
  console.log(`[Fix HTML] JS:  ./assets/${jsFile}`);
  console.log(`[Fix HTML] CSS: ./assets/${cssFile}`);
  
} catch (error) {
  console.error('[Fix HTML] ERROR:', error.message);
  process.exit(1);
}
