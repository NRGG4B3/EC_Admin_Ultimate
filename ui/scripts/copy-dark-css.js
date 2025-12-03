// Copy dark mode CSS files to dist/assets after build
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const projectRoot = path.join(__dirname, '..');
const distAssetsDir = path.join(projectRoot, 'dist', 'assets');
const stylesDir = path.join(projectRoot, 'styles');
const assetsDir = path.join(projectRoot, 'assets');

// Ensure dist/assets exists
if (!fs.existsSync(distAssetsDir)) {
  fs.mkdirSync(distAssetsDir, { recursive: true });
  console.log('✓ Created dist/assets directory');
}

// Files to copy
const filesToCopy = [
  { src: 'ec-dark-fixes.css', dest: 'ec-dark-fixes.css' },
  { src: '_ec-dark-hotfix.css', dest: '_ec-dark-hotfix.css' }
];

filesToCopy.forEach(({ src, dest }) => {
  const destPath = path.join(distAssetsDir, dest);
  
  // Try assets folder first, then styles folder
  let srcPath = path.join(assetsDir, src);
  if (!fs.existsSync(srcPath)) {
    srcPath = path.join(stylesDir, src);
  }
  
  if (fs.existsSync(srcPath)) {
    fs.copyFileSync(srcPath, destPath);
    console.log(`✓ Copied ${src} to dist/assets/${dest}`);
  } else {
    // Strict mode: do not generate placeholders in production builds
    console.error(`✗ Required dark-mode CSS missing: ${src}. Aborting copy.`);
    process.exitCode = 1;
  }
});

console.log('✓ Dark mode CSS files processed successfully');
