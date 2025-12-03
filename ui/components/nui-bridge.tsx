// EC Admin Ultimate - NUI Communication Bridge
// Handles all communication between React UI and FiveM Lua backend
import { useEffect, useCallback, useRef, useState } from 'react';

// LiveData interface matching App.tsx
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
    time: number;
    severity?: string;
  }>;
  aiAnalytics?: {
    totalDetections: number;
    criticalThreats: number;
    highRiskAlerts: number;
    mediumRiskAlerts: number;
    lowRiskAlerts: number;
    aiConfidence: number;
    modelsActive: number;
    threatPredictionAccuracy: number;
    topRiskyPlayers: Array<{
      id: string;
      name: string;
      riskScore: number;
      threatLevel: string;
      lastActivity: number;
    }>;
    detectionCategories: Array<{
      category: string;
      count: number;
      trend: number;
    }>;
    behaviorPatterns: Array<{
      pattern: string;
      frequency: number;
      riskLevel: number;
      confidence: number;
    }>;
  };
  economy?: {
    totalTransactions: number;
    cashFlow: number;
    bankFlow: number;
    averageWealth: number;
    economyHealth: number;
    suspiciousTransactions: number;
  };
  performance?: {
    frameRate: number;
    scriptTime: number;
    entityCount: number;
    vehicleCount: number;
    playerLoad: number;
  };
}

// NUI Message Types
interface NUIMessage {
  type: string;
  data?: any;
}

// Check if running in FiveM NUI environment
export const isEnvBrowser = (): boolean => !(window as any).invokeNative;

// Send data to Lua client with timeout support
export async function fetchNui<T = any>(
  eventName: string,
  data?: any,
  mockData?: T,
  timeoutMs: number = 3000 // Reduced to 3 second timeout for faster fallback
): Promise<T> {
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  };

  // If in browser (not FiveM), return mock data immediately
  if (isEnvBrowser()) {
    if (mockData) return mockData;
    return {} as T;
  }

  // Send to FiveM with timeout
  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : 'ec_admin_ultimate';

  try {
    // Create abort controller for timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

    const resp = await fetch(`https://${resourceName}/${eventName}`, {
      ...options,
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (!resp.ok) {
      console.warn(`[NUI] Request failed for ${eventName}: ${resp.statusText}`);
      if (mockData) return mockData;
      throw new Error('NUI request failed: ' + resp.statusText);
    }

    return await resp.json();
  } catch (error: any) {
    // If timeout or abort, return mock data if available - DON'T THROW
    if (error.name === 'AbortError') {
      console.warn(`[NUI] Request timeout for ${eventName} (${timeoutMs}ms), using fallback data`);
      if (mockData) return mockData;
      // Return empty object instead of throwing to prevent UI blocking
      return {} as T;
    }
    
    // For other errors, log and return fallback
    console.error(`[NUI] Request error for ${eventName}:`, error);
    if (mockData) return mockData;
    return {} as T;
  }
}

// Hook for NUI communication
export function useNuiEvent<T = any>(
  action: string,
  handler: (data: T) => void
) {
  const savedHandler = useRef(handler);

  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const eventListener = (event: MessageEvent<NUIMessage>) => {
      const { type, data } = event.data;

      if (type === action) {
        savedHandler.current(data);
      }
    };

    window.addEventListener('message', eventListener);
    return () => window.removeEventListener('message', eventListener);
  }, [action]);
}

// Hook for live data updates from server
export function useLiveData(initialData: LiveData) {
  const [liveData, setLiveData] = useState<LiveData>(initialData);

  // Listen for live data updates from Lua - THROTTLED TO PREVENT EXCESSIVE UPDATES
  const lastUpdateRef = useRef<number>(0);
  useNuiEvent<LiveData>('updateLiveData', useCallback((data) => {
    const now = Date.now();
    // Throttle updates to max once per second to prevent UI blocking
    if (now - lastUpdateRef.current > 1000) {
      console.log('[NUI Bridge] Received live data update from Lua', data);
      setLiveData(data);
      lastUpdateRef.current = now;
    }
  }, []));

  // Fetch real data periodically (works in both FiveM and Browser mode)
  useEffect(() => {
    const fetchRealData = async () => {
      try {
        // Import dynamically to avoid circular dependencies
        const { MetricsService } = await import('../lib/data-service');
        
        const [metrics, aiAnalytics, economy, performance, alerts] = await Promise.all([
          MetricsService.getServerMetrics(),
          MetricsService.getAIAnalytics(),
          MetricsService.getEconomyStats(),
          MetricsService.getPerformanceMetrics(),
          MetricsService.getAlerts()
        ]);

        setLiveData({
          ...metrics,
          aiAnalytics,
          economy,
          performance,
          alerts: Array.isArray(alerts) ? alerts : [] // SAFETY: Ensure alerts is always an array
        });
      } catch (error) {
        console.warn('[NUI Bridge] Failed to fetch real data, using fallback:', error);
      }
    };

    // Initial fetch
    fetchRealData();

    // Update every 15 seconds
    const interval = setInterval(fetchRealData, 15000);

    return () => clearInterval(interval);
  }, []);

  return liveData;
}

// Player Management Actions
export const PlayerActions = {
  kick: async (playerId: number, reason: string) => {
    return fetchNui('kickPlayer', { playerId, reason });
  },

  ban: async (playerId: number, reason: string, duration: number) => {
    return fetchNui('banPlayer', { playerId, reason, duration });
  },

  warn: async (playerId: number, reason: string) => {
    return fetchNui('warnPlayer', { playerId, reason });
  },

  teleport: async (playerId: number, coords?: { x: number; y: number; z: number }) => {
    return fetchNui('teleportPlayer', { playerId, coords });
  },

  teleportToPlayer: async (targetId: number) => {
    return fetchNui('teleportToPlayer', { targetId });
  },

  bringPlayer: async (playerId: number) => {
    return fetchNui('bringPlayer', { playerId });
  },

  freeze: async (playerId: number, frozen: boolean) => {
    return fetchNui('freezePlayer', { playerId, frozen });
  },

  setHealth: async (playerId: number, health: number) => {
    return fetchNui('setPlayerHealth', { playerId, health });
  },

  setArmor: async (playerId: number, armor: number) => {
    return fetchNui('setPlayerArmor', { playerId, armor });
  },

  revive: async (playerId: number) => {
    return fetchNui('revivePlayer', { playerId });
  },

  spectate: async (playerId: number) => {
    return fetchNui('spectatePlayer', { playerId });
  },

  giveMoney: async (playerId: number, amount: number, type: 'cash' | 'bank') => {
    return fetchNui('giveMoney', { playerId, amount, type });
  },

  removeMoney: async (playerId: number, amount: number, type: 'cash' | 'bank') => {
    return fetchNui('removeMoney', { playerId, amount, type });
  },

  giveItem: async (playerId: number, item: string, amount: number) => {
    return fetchNui('giveItem', { playerId, item, amount });
  },

  removeItem: async (playerId: number, item: string, amount: number) => {
    return fetchNui('removeItem', { playerId, item, amount });
  },

  setJob: async (playerId: number, job: string, grade: number) => {
    return fetchNui('setJob', { playerId, job, grade });
  },

  setGang: async (playerId: number, gang: string, grade: number) => {
    return fetchNui('setGang', { playerId, gang, grade });
  },

  sendMessage: async (playerId: number, message: string) => {
    return fetchNui('sendMessage', { playerId, message });
  },

  screenshot: async (playerId: number) => {
    return fetchNui('screenshotPlayer', { playerId });
  },
};

// Vehicle Management Actions
export const VehicleActions = {
  spawn: async (model: string, coords?: { x: number; y: number; z: number }) => {
    return fetchNui('spawnVehicle', { model, coords });
  },

  delete: async (vehicleId: number) => {
    return fetchNui('deleteVehicle', { vehicleId });
  },

  repair: async (vehicleId: number) => {
    return fetchNui('repairVehicle', { vehicleId });
  },

  flip: async (vehicleId: number) => {
    return fetchNui('flipVehicle', { vehicleId });
  },

  deleteAll: async () => {
    return fetchNui('deleteAllVehicles', {});
  },
};

// Server Management Actions
export const ServerActions = {
  announcement: async (message: string, duration: number) => {
    return fetchNui('serverAnnouncement', { message, duration });
  },

  kickAll: async (reason: string) => {
    return fetchNui('kickAll', { reason });
  },

  restartResource: async (resourceName: string) => {
    return fetchNui('restartResource', { resourceName });
  },

  stopResource: async (resourceName: string) => {
    return fetchNui('stopResource', { resourceName });
  },

  startResource: async (resourceName: string) => {
    return fetchNui('startResource', { resourceName });
  },

  executeCommand: async (command: string) => {
    return fetchNui('executeCommand', { command });
  },

  weatherChange: async (weather: string) => {
    return fetchNui('changeWeather', { weather });
  },

  timeChange: async (hour: number, minute: number) => {
    return fetchNui('changeTime', { hour, minute });
  },

  clearArea: async (coords: { x: number; y: number; z: number }, radius: number) => {
    return fetchNui('clearArea', { coords, radius });
  },

  createBackup: async () => {
    return fetchNui('createBackup', {});
  },

  restoreBackup: async (backupId: string) => {
    return fetchNui('restoreBackup', { backupId });
  },
};

// Data Fetching Actions
export const DataActions = {
  getPlayers: async () => {
    return fetchNui<any[]>('getPlayers', {}, []);
  },

  getPlayerDetails: async (playerId: number) => {
    return fetchNui('getPlayerDetails', { playerId });
  },

  getVehicles: async () => {
    return fetchNui<any[]>('getVehicles', {}, []);
  },

  getBans: async () => {
    return fetchNui<any[]>('getBans', {}, []);
  },

  getWarnings: async () => {
    return fetchNui<any[]>('getWarnings', {}, []);
  },

  getResources: async () => {
    return fetchNui<any[]>('getResources', {}, []);
  },

  getLogs: async (type: string, limit: number) => {
    return fetchNui<any[]>('getLogs', { type, limit }, []);
  },

  getBackups: async () => {
    return fetchNui<any[]>('getBackups', {}, []);
  },

  getWhitelist: async () => {
    return fetchNui<any[]>('getWhitelist', {}, []);
  },

  getEconomyStats: async () => {
    return fetchNui('getEconomyStats', {});
  },

  getPerformanceMetrics: async () => {
    return fetchNui('getPerformanceMetrics', {});
  },

  getAIDetections: async () => {
    return fetchNui<any[]>('getAIDetections', {}, []);
  },

  getAnticheatLogs: async () => {
    return fetchNui<any[]>('getAnticheatLogs', {}, []);
  },
};

// UI Control Actions
export const UIActions = {
  closeUI: () => {
    fetchNui('closeUI', {});
  },

  toggleCompact: (isCompact: boolean) => {
    fetchNui('toggleCompact', { isCompact });
  },

  playSound: (sound: string) => {
    fetchNui('playSound', { sound });
  },
};

// Export all actions as a single object
export const NUIActions = {
  Player: PlayerActions,
  Vehicle: VehicleActions,
  Server: ServerActions,
  Data: DataActions,
  UI: UIActions,
};

// Debug mode for browser testing
export const setDebugMode = (enabled: boolean) => {
  if (enabled) {
    console.log('[NUI Bridge] Debug mode enabled - Mock data will be used');
  }
};

// Initialize NUI bridge
export function initializeNUI() {
  if (isEnvBrowser()) {
    console.log('[NUI Bridge] Running in browser mode - Mock data enabled');
    return false;
  }

  console.log('[NUI Bridge] Running in FiveM mode - Real data enabled');

  // Send ready signal to Lua with proper error handling
  try {
    fetchNui('uiReady', {})
      .then(() => {
        console.log('[NUI Bridge] ✅ Handshake successful - Connected to FiveM');
      })
      .catch((error) => {
        console.error('[NUI Bridge] ⚠️ Handshake failed:', error);
        console.log('[NUI Bridge] Continuing anyway - UI will work with fallback data');
      });
  } catch (error) {
    console.error('[NUI Bridge] ⚠️ Failed to send ready signal:', error);
  }

  return true;
}