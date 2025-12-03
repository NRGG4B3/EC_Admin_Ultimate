// Quick test to verify all imports work
console.log('Testing React imports...');

try {
  // Test 1: React
  const React = await import('react');
  console.log('✓ React import successful, version:', React.version);
  
  // Test 2: React-DOM
  const ReactDOM = await import('react-dom/client');
  console.log('✓ React-DOM import successful');
  console.log('✓ createRoot:', typeof ReactDOM.createRoot);
  
  // Test 3: Check if we can create a root
  const div = document.createElement('div');
  const root = ReactDOM.createRoot(div);
  console.log('✓ createRoot() works!');
  
  console.log('\n✅ ALL IMPORTS WORKING!\n');
  console.log('If this test passed, the build should work.');
  console.log('Run: npm run build');
  
} catch (error) {
  console.error('\n❌ IMPORT FAILED:\n', error);
  console.log('\nThis means:');
  console.log('1. Dependencies not installed, OR');
  console.log('2. Wrong React version');
  console.log('\nFix: npm install --force');
}
