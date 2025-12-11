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
  if (typeof window === 'undefined') return false;
  
  // Check if GetParentResourceName exists (FiveM NUI indicator)
  // It can be a function or a property that returns a function
  const hasGetParentResourceName = typeof (window as any).GetParentResourceName === 'function' ||
    (typeof (window as any).GetParentResourceName !== 'undefined' && (window as any).GetParentResourceName);
  
  // Check for invokeNative (another FiveM indicator)
  const hasInvokeNative = typeof (window as any).invokeNative === 'function';
  
  // If either exists, we're in FiveM NUI mode, not browser
  if (hasGetParentResourceName || hasInvokeNative) {
    return false; // We're in FiveM, not browser
  }
  
  // Check for __NUI_MODE__ flag
  if ((window as any).__NUI_MODE__ === true) {
    return false; // We're in FiveM NUI mode
  }
  
  // Otherwise, we're in browser mode
  return true;
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
  // Always try to make the fetch call first - if we're in FiveM, it will work
  // If we're in browser, it will fail and we can fall back to mock data
  const resourceName = getResourceName();
  
  try {
    const response = await fetch(`https://${resourceName}/${eventName}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: data ? JSON.stringify(data) : undefined,
    });
    
    if (!response.ok) {
      // If we get a 404 or other error, and we have mock data, use it
      if (mockData !== undefined && response.status === 404) {
        console.warn(`[NUI Bridge] Callback ${eventName} not found (404), using mock data`);
        return Promise.resolve(mockData);
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    return await response.json();
  } catch (error) {
    // If fetch fails and we have mock data, use it
    if (mockData !== undefined) {
      console.warn(`[NUI Bridge] Fetch failed for ${eventName}, using mock data:`, error);
      return Promise.resolve(mockData);
    }
    
    // Check if we're actually in NUI mode
    const hasGetParentResourceName = typeof window !== 'undefined' && (
      typeof (window as any).GetParentResourceName === 'function' ||
      (typeof (window as any).GetParentResourceName !== 'undefined')
    );
    const hasInvokeNative = typeof window !== 'undefined' && typeof (window as any).invokeNative === 'function';
    const isNUI = hasGetParentResourceName || hasInvokeNative || (window as any).__NUI_MODE__ === true;
    
    if (isNUI) {
      // We're in NUI mode but fetch failed - this is a real error
      console.error(`[NUI Bridge] Error in ${eventName}:`, error);
      throw error;
    } else {
      // We're in browser mode and fetch failed - this is expected
      console.warn(`[NUI Bridge] Fetch failed for ${eventName} (browser mode):`, error);
      throw new Error('NUI bridge unavailable');
    }
  }
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
  
  // Make fetchNui available globally
  if (!(window as any).fetchNui) {
    (window as any).fetchNui = fetchNui;
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
