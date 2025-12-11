import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import '../styles/globals.css';
import { fetchNui, initializeNUI } from '../components/nui-bridge';

// CRITICAL: Mark as NUI mode for FiveM
declare global {
  interface Window {
    __NUI_MODE__: boolean;
    invokeNative?: any;
    GetParentResourceName?: any;
  }
}

// Initialize NUI bridge and fetchNui
initializeNUI();
if (typeof window !== 'undefined') {
  (window as any).fetchNui = fetchNui;
  console.log('[EC Admin UI] fetchNui initialized globally');
}

// Set NUI mode flag
window.__NUI_MODE__ = true;
console.log('[EC Admin UI] Starting initialization...');

// Detect FiveM NUI environment
const isFiveM = typeof window.invokeNative === 'function' || window.GetParentResourceName !== undefined;

if (isFiveM) {
  document.body.classList.add('ec-fivem-root');
  console.log('[EC Admin UI] FiveM environment detected');
}

// Handle visibility messages from FiveM client
window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.type) return;

  if (data.type === 'EC_SET_VISIBILITY') {
    const open = !!data.open;
    if (isFiveM) {
      document.body.classList.toggle('ec-menu-open', open);
      document.body.classList.toggle('ec-menu-closed', !open);
      console.log(`[EC Admin UI] Visibility: ${open ? 'OPEN' : 'CLOSED'}`);
    }
  }
});

// Mount React app
try {
  console.log('[EC Admin UI] Mounting React app...');
  const el = document.getElementById('root');
  if (!el) {
    throw new Error('#root element not found');
  }
  
  const root = createRoot(el);
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
  
  document.body.setAttribute('data-ready', '1');
  console.log('[EC Admin UI] ✓ React app mounted successfully');
} catch (error) {
  console.error('[EC Admin UI] Mount failed:', error);
  document.body.innerHTML = `
    <div style="position:fixed;inset:0;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:16px;background:#0b0f14;color:#ff6b6b;font-family:system-ui;padding:24px;text-align:center">
      <h1 style="font-size:24px;margin:0">EC Admin UI Failed to Load</h1>
      <p style="margin:0;color:#a7b3c2">${error instanceof Error ? error.message : 'Unknown error'}</p>
      <p style="margin:0;color:#6c7a8a;font-size:12px">Check F8 console for details</p>
    </div>
  `;
}