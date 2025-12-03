/**
 * Runtime Configuration
 * Provides environment-specific configuration for the application
 */

export interface RuntimeConfig {
  apiBaseUrl: string;
  isNUI: boolean;
  isDevelopment: boolean;
  serverType: 'host' | 'customer';
  cityName?: string;
  publicIp?: string;
  framework?: string;
}

/**
 * Get runtime configuration based on environment
 */
export function getRuntimeConfig(): RuntimeConfig {
  // Check if running in NUI (FiveM environment)
  const isNUI = typeof (window as any).GetParentResourceName !== 'undefined';
  
  // Check if running in development mode
  const isDevelopment = import.meta.env.DEV;
  
  // Determine server type
  // Priority:
  // 1. Port 3019 = Host web dashboard (all APIs + all cities)
  // 2. Port 8080 = Customer web dashboard (their city only)
  // 3. NUI = In-game menu (will be determined by server)
  const port = window.location.port;
  const isPort3019 = port === '3019';
  const isPort8080 = port === '8080' || port === '8081' || port === '8082'; // Customer web ports
  
  let serverType: 'host' | 'customer' = 'customer';
  
  if (isPort3019) {
    serverType = 'host';
  } else if (isPort8080) {
    serverType = 'customer';
  } else if (isNUI) {
    // Will be determined by server via EC_HOST_STATUS message
    serverType = 'customer'; // Default
  }
  
  return {
    apiBaseUrl: getApiBaseUrl(),
    isNUI,
    isDevelopment,
    serverType,
    cityName: 'Demo City',
    publicIp: '127.0.0.1',
    framework: 'qb-core'
  };
}

/**
 * Get API base URL based on environment
 */
export function getApiBaseUrl(): string {
  // In NUI mode, use relative paths
  if (typeof (window as any).GetParentResourceName !== 'undefined') {
    return `https://${(window as any).GetParentResourceName()}/`;
  }
  
  // In development, use local API
  if (import.meta.env.DEV) {
    return 'http://localhost:30120/';
  }
  
  // In production, use relative paths
  return '/';
}

/**
 * Check if running in NUI environment
 */
export function isNUIEnvironment(): boolean {
  return typeof (window as any).GetParentResourceName !== 'undefined';
}

/**
 * Post message to NUI
 */
export function postNUI<T = any>(event: string, data?: any): Promise<T> {
  return new Promise((resolve, reject) => {
    if (!isNUIEnvironment()) {
      console.warn('Not in NUI environment, using mock response');
      resolve({} as T);
      return;
    }

    fetch(`https://${(window as any).GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data || {}),
    })
      .then((response) => response.json())
      .then(resolve)
      .catch(reject);
  });
}