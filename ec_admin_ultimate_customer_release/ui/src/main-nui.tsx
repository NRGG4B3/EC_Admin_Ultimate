/**
 * NUI Entry Point (In-City F2 Menu)
 * This ONLY loads the admin panel for in-game use
 */

import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'  // Fixed: Should be ./App.tsx not ../App.tsx
import '../styles/globals.css'
import './global-error-handler'  // Import global error handler (auto-setup)

// Mark as NUI mode
window.__NUI_MODE__ = true;

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)

// NUI-specific message handling
window.addEventListener('message', (event) => {
  const data = event.data;
  
  // Handle NUI visibility
  if (data.action === 'setVisible') {
    const root = document.getElementById('root');
    if (root) {
      root.style.display = data.visible ? 'block' : 'none';
    }
  }
});

// Add global type declaration
declare global {
  interface Window {
    __NUI_MODE__: boolean;
  }
}