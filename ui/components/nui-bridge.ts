/**
 * EC Admin Ultimate - NUI Bridge
 * Handles communication between React UI and FiveM Lua scripts
 * Works in both FiveM NUI mode and browser mode
 */

import { useState, useEffect } from 'react';

export interface LiveData {
  playersOnline: number;
  totalResources: number;
  cachedVehicles: number;
  serverTPS: number;
  memoryUsage: number;
  networkIn: number;
  networkOut: number;
  cpuUsage: number;
  uptime: number;
  lastRestart: number;
  activeEvents: number;
  database: {
    queries: number;
    avgResponseTime: number;
  };
  alerts: Array<{
    id: string;
    type: string;
    message: string;
    timestamp: number;
  }>;
}

/**
 * Check if running in browser environment (not FiveM NUI)
 */
export function isEnvBrowser(): boolean {
  return typeof window !== 'undefined' && (
    !(window as any).invokeNative ||
    (window as any).__NUI_MODE__ !== true ||
    window.location.protocol === 'http:' ||
    window.location.protocol === 'https:'
  );
}

/**
 * Check if running in FiveM NUI
 */
export function isFiveM(): boolean {
  return typeof window !== 'undefined' && (
    !!(window as any).invokeNative ||
    (window as any).__NUI_MODE__ === true
  );
}

/**
 * Get resource name from FiveM
 */
function getResourceName(): string {
  if (typeof window !== 'undefined' && (window as any).GetParentResourceName) {
    return (window as any).GetParentResourceName() || 'ec_admin_ultimate';
  }
  return 'ec_admin_ultimate';
}

/**
 * Fetch NUI callback (FiveM mode)
 */
export async function fetchNui<T = any>(
  eventName: string,
  data?: any,
  mockData?: T
): Promise<T> {
  // Browser mode: return mock data or make HTTP request
  if (isEnvBrowser()) {
    if (mockData !== undefined) {
      return Promise.resolve(mockData);
    }
    
    // Try to make HTTP request to local API
    try {
      const resourceName = getResourceName();
      const response = await fetch(`https://${resourceName}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: data ? JSON.stringify(data) : undefined,
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.warn(`[NUI Bridge] Fetch failed for ${eventName}:`, error);
      if (mockData !== undefined) {
        return mockData;
      }
      throw error;
    }
  }
  
  // FiveM mode: use NUI callback
  return new Promise<T>((resolve, reject) => {
    const resourceName = getResourceName();
    
    fetch(`https://${resourceName}/${eventName}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: data ? JSON.stringify(data) : undefined,
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        return response.json();
      })
      .then(data => resolve(data as T))
      .catch(error => {
        console.error(`[NUI Bridge] Error in ${eventName}:`, error);
        if (mockData !== undefined) {
          resolve(mockData);
        } else {
          reject(error);
        }
      });
  });
}

/**
 * Initialize NUI bridge
 */
export function initializeNUI(): void {
  if (typeof window === 'undefined') return;
  
  // Mark as NUI mode if in FiveM
  if (isFiveM()) {
    (window as any).__NUI_MODE__ = true;
    console.log('[NUI Bridge] Initialized in FiveM mode');
  } else {
    (window as any).__NUI_MODE__ = false;
    console.log('[NUI Bridge] Initialized in browser mode');
  }
}

/**
 * Live data hook for real-time updates
 */
export function useLiveData(initialData: LiveData): LiveData {
  const [data, setData] = useState<LiveData>(initialData);
  
  useEffect(() => {
    // Set up interval to fetch live data
    const interval = setInterval(async () => {
      try {
        const response = await fetchNui<{ success: boolean; data: LiveData }>('getLiveData', {}, initialData);
        if (response && response.success && response.data) {
          setData(response.data);
        } else if (response && (response as any).data) {
          setData((response as any).data);
        }
      } catch (error) {
        // Silently fail - keep existing data
        console.debug('[NUI Bridge] Failed to fetch live data:', error);
      }
    }, 5000); // Update every 5 seconds
    
    return () => clearInterval(interval);
  }, [initialData]);
  
  return data;
}

// Export types
export type { LiveData };
