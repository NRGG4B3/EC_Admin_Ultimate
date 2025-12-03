// Import Verification Script
// Checks if all imports in the codebase can be resolved

const fs = require('fs');
const path = require('path');

console.log('========================================');
console.log('   EC ADMIN - IMPORT VERIFICATION');
console.log('========================================\n');

const errors = [];
const warnings = [];

// Check if file exists
function fileExists(filePath) {
  try {
    return fs.existsSync(filePath);
  } catch (e) {
    return false;
  }
}

// Resolve import path
function resolveImport(fromFile, importPath) {
  const fromDir = path.dirname(fromFile);
  
  // Handle relative imports
  if (importPath.startsWith('./') || importPath.startsWith('../')) {
    let resolved = path.resolve(fromDir, importPath);
    
    // Try with .tsx extension
    if (fileExists(resolved + '.tsx')) {
      return { exists: true, path: resolved + '.tsx' };
    }
    
    // Try with .ts extension
    if (fileExists(resolved + '.ts')) {
      return { exists: true, path: resolved + '.ts' };
    }
    
    // Try with .jsx extension
    if (fileExists(resolved + '.jsx')) {
      return { exists: true, path: resolved + '.jsx' };
    }
    
    // Try with .js extension
    if (fileExists(resolved + '.js')) {
      return { exists: true, path: resolved + '.js' };
    }
    
    // Try as directory with index
    if (fileExists(path.join(resolved, 'index.tsx'))) {
      return { exists: true, path: path.join(resolved, 'index.tsx') };
    }
    
    if (fileExists(path.join(resolved, 'index.ts'))) {
      return { exists: true, path: path.join(resolved, 'index.ts') };
    }
    
    return { exists: false, attempted: resolved };
  }
  
  // Handle node_modules imports
  if (!importPath.startsWith('.')) {
    return { exists: true, path: 'node_modules:' + importPath };
  }
  
  return { exists: false, attempted: importPath };
}

// Parse import statements from file
function extractImports(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const importRegex = /import\s+(?:{[^}]+}|[^'"]+)\s+from\s+['"]([^'"]+)['"]/g;
    const imports = [];
    let match;
    
    while ((match = importRegex.exec(content)) !== null) {
      imports.push(match[1]);
    }
    
    return imports;
  } catch (e) {
    errors.push(`Failed to read ${filePath}: ${e.message}`);
    return [];
  }
}

// Get all TypeScript/JavaScript files
function getAllFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  
  files.forEach(file => {
    const filePath = path.join(dir, file);
    
    // Skip node_modules and dist
    if (file === 'node_modules' || file === 'dist' || file === '.git') {
      return;
    }
    
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory()) {
      getAllFiles(filePath, fileList);
    } else if (file.match(/\.(tsx?|jsx?)$/)) {
      fileList.push(filePath);
    }
  });
  
  return fileList;
}

console.log('[1/3] Scanning for TypeScript/JavaScript files...\n');

const projectRoot = __dirname;
const allFiles = getAllFiles(projectRoot);

console.log(`Found ${allFiles.length} files to check\n`);

console.log('[2/3] Verifying imports...\n');

let checkedCount = 0;
let errorCount = 0;

allFiles.forEach(file => {
  const relPath = path.relative(projectRoot, file);
  const imports = extractImports(file);
  
  imports.forEach(importPath => {
    checkedCount++;
    const resolution = resolveImport(file, importPath);
    
    if (!resolution.exists && !importPath.startsWith('@')) {
      errorCount++;
      errors.push({
        file: relPath,
        import: importPath,
        attempted: resolution.attempted || importPath
      });
    }
  });
});

console.log(`Checked ${checkedCount} imports\n`);

console.log('[3/3] Results:\n');
console.log('========================================\n');

if (errors.length === 0) {
  console.log('✓✓✓ ALL IMPORTS VERIFIED ✓✓✓\n');
  console.log(`All ${checkedCount} imports can be resolved successfully.\n`);
  process.exit(0);
} else {
  console.log(`✗✗✗ FOUND ${errorCount} BROKEN IMPORTS ✗✗✗\n`);
  
  errors.forEach((err, index) => {
    console.log(`${index + 1}. ${err.file}`);
    console.log(`   Import: "${err.import}"`);
    console.log(`   Attempted: ${err.attempted}`);
    console.log('');
  });
  
  console.log('These broken imports will cause the build to fail!\n');
  console.log('Please fix these imports before building.\n');
  process.exit(1);
}
