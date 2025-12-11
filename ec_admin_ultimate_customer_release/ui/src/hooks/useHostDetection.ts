/**
 * Hook to detect if running in HOST mode
 * Host mode can be:
 * 1. Web dashboard on port 3019 (api.ecbetasolutions.com:3019)
 * 2. In-game menu on host city (detected from server)
 */

import { useState, useEffect } from 'react';
import { isNUIEnvironment } from '../runtime-config';

export interface HostStatus {
  isHost: boolean;
  mode: 'web-dashboard' | 'in-game' | 'unknown';
  webAccess: boolean; // True if accessed via web browser (not in-game)
  loading: boolean;
}

export function useHostDetection(): HostStatus {
  const [status, setStatus] = useState<HostStatus>({
    isHost: false,
    mode: 'unknown',
    webAccess: false,
    loading: true,
  });

  useEffect(() => {
    async function detectHostMode() {
      const port = window.location.port;
      const isNUI = isNUIEnvironment();
      
      // Check 1: Running on port 3019 = Host web dashboard (NRG only)
      if (port === '3019') {
        console.log('[Host Detection] Port 3019 - HOST WEB DASHBOARD MODE');
        setStatus({
          isHost: true,
          mode: 'web-dashboard',
          webAccess: true,
          loading: false,
        });
        return;
      }

      // Check 2: Running on port 8080/8081/8082 = Customer web dashboard
      if (port === '8080' || port === '8081' || port === '8082') {
        console.log('[Host Detection] Port 8080 - CUSTOMER WEB DASHBOARD MODE');
        setStatus({
          isHost: false,
          mode: 'web-dashboard',
          webAccess: true,
          loading: false,
        });
        return;
      }

      // Check 3: Running in NUI (in-game) - ask server if we're host
      if (isNUI) {
        console.log('[Host Detection] Running in NUI - checking with server...');
        
        // Listen for host status from server
        window.addEventListener('message', (event) => {
          if (event.data.type === 'EC_HOST_STATUS') {
            const isHost = event.data.isHost === true;
            console.log(`[Host Detection] Server says isHost: ${isHost}`);
            
            setStatus({
              isHost,
              mode: 'in-game',
              webAccess: false,
              loading: false,
            });
          }
        });

        // Request host status from server
        setTimeout(() => {
          // If no response after 2 seconds, assume customer
          if (status.loading) {
            console.log('[Host Detection] No response from server - assuming CUSTOMER');
            setStatus({
              isHost: false,
              mode: 'in-game',
              webAccess: false,
              loading: false,
            });
          }
        }, 2000);

        return;
      }

      // Check 4: Development mode or other web access
      console.log('[Host Detection] Not NUI, not known port - checking /api/mode/detect...');
      
      try {
        const response = await fetch('/api/mode/detect');
        const data = await response.json();
        
        console.log('[Host Detection] Mode detection response:', data);
        
        setStatus({
          isHost: data.isHost === true || data.mode === 'host',
          mode: 'web-dashboard',
          webAccess: true,
          loading: false,
        });
      } catch (error) {
        console.error('[Host Detection] Failed to detect mode:', error);
        // Default to customer mode
        setStatus({
          isHost: false,
          mode: 'unknown',
          webAccess: true,
          loading: false,
        });
      }
    }

    detectHostMode();
  }, []);

  return status;
}