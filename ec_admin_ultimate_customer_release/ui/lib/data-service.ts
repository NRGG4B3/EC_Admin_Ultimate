/**
 * EC Admin Ultimate - Real Data Service
 * Provides unified data access for both FiveM and Web modes
 * Automatically switches between NUI calls and HTTP API calls
 */

import { fetchNui, isEnvBrowser } from '../components/nui-bridge';

// API Configuration
const API_BASE_URL = 'http://localhost:30120'; // Default, can be overridden
const API_REFRESH_INTERVAL = 15000; // 15 seconds

// Check if we're in web mode (not FiveM NUI)
export const isWebMode = () => isEnvBrowser();

/**
 * Universal fetch - works in both FiveM and Web modes
 */
async function universalFetch<T>(
  nuiEndpoint: string,
  httpEndpoint: string,
  data?: any,
  mockData?: T
): Promise<T> {
  if (isWebMode()) {
    // FIGMA/BROWSER MODE: Return mock data immediately if no backend is running
    if (mockData !== undefined) {
      console.log(`[DataService] Using mock data for ${httpEndpoint}`);
      return mockData;
    }
    
    // Web mode: Try HTTP API (only if no mock data provided)
    try {
      const response = await fetch(`${API_BASE_URL}${httpEndpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: data ? JSON.stringify(data) : undefined,
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.warn(`[DataService] HTTP fetch failed for ${httpEndpoint}:`, error);
      if (mockData !== undefined) return mockData;
      throw error;
    }
  } else {
    // FiveM mode: Use NUI bridge
    return fetchNui<T>(nuiEndpoint, data, mockData);
  }
}

/**
 * Real-time Metrics Service
 */
export const MetricsService = {
  /**
   * Get server metrics (players, TPS, memory, etc.)
   */
  getServerMetrics: async () => {
    return universalFetch(
      'getServerMetrics',
      '/admin/metrics',
      {},
      {
        playersOnline: 42,
        totalResources: 187,
        cachedVehicles: 156,
        serverTPS: 58,
        memoryUsage: 2847,
        networkIn: 124.5,
        networkOut: 89.3,
        cpuUsage: 34,
        uptime: Date.now() - (7 * 24 * 60 * 60 * 1000),
        lastRestart: Date.now() - (3 * 24 * 60 * 60 * 1000),
        activeEvents: 23,
        database: {
          queries: 1247,
          avgResponseTime: 12.4
        }
      }
    );
  },

  /**
   * Get AI analytics data
   */
  getAIAnalytics: async () => {
    return universalFetch(
      'getAIAnalytics',
      '/admin/ai/analytics',
      {},
      {
        totalDetections: 1247,
        criticalThreats: 3,
        highRiskAlerts: 12,
        mediumRiskAlerts: 34,
        lowRiskAlerts: 89,
        aiConfidence: 94.7,
        modelsActive: 7,
        threatPredictionAccuracy: 96.2,
        topRiskyPlayers: [], // MUST be an array
        detectionCategories: [], // MUST be an array
        behaviorPatterns: [] // MUST be an array
      }
    );
  },

  /**
   * Get economy statistics
   */
  getEconomyStats: async () => {
    return universalFetch(
      'getEconomyStats',
      '/admin/economy/stats',
      {},
      {
        totalTransactions: 8947,
        cashFlow: 547832,
        bankFlow: 1247569,
        averageWealth: 127450,
        economyHealth: 87.4,
        suspiciousTransactions: 23
      }
    );
  },

  /**
   * Get performance metrics
   */
  getPerformanceMetrics: async () => {
    return universalFetch(
      'getPerformanceMetrics',
      '/admin/performance/metrics',
      {},
      {
        frameRate: 58,
        scriptTime: 4.7,
        entityCount: 1247,
        vehicleCount: 156,
        playerLoad: 42
      }
    );
  },

  /**
   * Get system alerts
   */
  getAlerts: async () => {
    return universalFetch<Array<{
      id: string;
      type: string;
      message: string;
      time: number;
      severity?: string;
    }>>(
      'getAlerts',
      '/admin/alerts',
      {},
      []
    );
  }
};

/**
 * Player Management Service
 */
export const PlayerService = {
  /**
   * Get all online players
   */
  getPlayers: async () => {
    return universalFetch<Array<any>>(
      'getPlayers',
      '/admin/players',
      {},
      []
    );
  },

  /**
   * Get player details by ID
   */
  getPlayerDetails: async (playerId: number) => {
    return universalFetch(
      'getPlayerDetails',
      `/admin/players/${playerId}`,
      { playerId },
      {}
    );
  },

  /**
   * Search players
   */
  searchPlayers: async (query: string) => {
    return universalFetch<Array<any>>(
      'searchPlayers',
      '/admin/players/search',
      { query },
      []
    );
  },

  /**
   * Get player inventory
   */
  getPlayerInventory: async (playerId: number) => {
    return universalFetch<Array<any>>(
      'getPlayerInventory',
      `/admin/players/${playerId}/inventory`,
      { playerId },
      []
    );
  },

  /**
   * Get player vehicles
   */
  getPlayerVehicles: async (playerId: number) => {
    return universalFetch<Array<any>>(
      'getPlayerVehicles',
      `/admin/players/${playerId}/vehicles`,
      { playerId },
      []
    );
  }
};

/**
 * Moderation Service
 */
export const ModerationService = {
  /**
   * Get all bans
   */
  getBans: async () => {
    return universalFetch<Array<any>>(
      'getBans',
      '/admin/moderation/bans',
      {},
      []
    );
  },

  /**
   * Get all warnings
   */
  getWarnings: async () => {
    return universalFetch<Array<any>>(
      'getWarnings',
      '/admin/moderation/warnings',
      {},
      []
    );
  },

  /**
   * Get moderation logs
   */
  getModerationLogs: async (limit: number = 50) => {
    return universalFetch<Array<any>>(
      'getModerationLogs',
      '/admin/moderation/logs',
      { limit },
      []
    );
  },

  /**
   * Get recent actions
   */
  getRecentActions: async (limit: number = 20) => {
    return universalFetch<Array<any>>(
      'getRecentActions',
      '/admin/moderation/recent',
      { limit },
      []
    );
  }
};

/**
 * Server Management Service
 */
export const ServerService = {
  /**
   * Get all resources
   */
  getResources: async () => {
    return universalFetch<Array<any>>(
      'getResources',
      '/admin/server/resources',
      {},
      []
    );
  },

  /**
   * Get server logs
   */
  getLogs: async (type: string, limit: number = 100) => {
    return universalFetch<Array<any>>(
      'getLogs',
      '/admin/server/logs',
      { type, limit },
      []
    );
  },

  /**
   * Get backups
   */
  getBackups: async () => {
    return universalFetch<Array<any>>(
      'getBackups',
      '/admin/server/backups',
      {},
      []
    );
  },

  /**
   * Get whitelist
   */
  getWhitelist: async () => {
    return universalFetch<Array<any>>(
      'getWhitelist',
      '/admin/server/whitelist',
      {},
      []
    );
  }
};

/**
 * Vehicle Management Service
 */
export const VehicleService = {
  /**
   * Get all vehicles
   */
  getVehicles: async () => {
    return universalFetch<Array<any>>(
      'getVehicles',
      '/admin/vehicles',
      {},
      []
    );
  },

  /**
   * Get vehicle details
   */
  getVehicleDetails: async (vehicleId: number) => {
    return universalFetch(
      'getVehicleDetails',
      `/admin/vehicles/${vehicleId}`,
      { vehicleId },
      {}
    );
  }
};

/**
 * Jobs & Gangs Service
 */
export const JobsService = {
  /**
   * Get all jobs
   */
  getJobs: async () => {
    return universalFetch<Array<any>>(
      'getJobs',
      '/admin/jobs',
      {},
      []
    );
  },

  /**
   * Get all gangs
   */
  getGangs: async () => {
    return universalFetch<Array<any>>(
      'getGangs',
      '/admin/gangs',
      {},
      []
    );
  },

  /**
   * Get job members
   */
  getJobMembers: async (jobName: string) => {
    return universalFetch<Array<any>>(
      'getJobMembers',
      `/admin/jobs/${jobName}/members`,
      { jobName },
      []
    );
  },

  /**
   * Get gang members
   */
  getGangMembers: async (gangName: string) => {
    return universalFetch<Array<any>>(
      'getGangMembers',
      `/admin/gangs/${gangName}/members`,
      { gangName },
      []
    );
  }
};

/**
 * Host Control Service (for Host mode only)
 */
export const HostService = {
  /**
   * Toggle admin menu visibility
   */
  toggleAdminMenu: async (visible: boolean) => {
    return universalFetch(
      'host/toggleAdminMenu',
      '/host/admin-menu/toggle',
      { visible },
      { success: true }
    );
  },

  /**
   * Get admin menu status
   */
  getAdminMenuStatus: async () => {
    return universalFetch(
      'host/getAdminMenuStatus',
      '/host/admin-menu/status',
      {},
      { enabled: true }
    );
  },

  /**
   * Get customer servers
   */
  getCustomerServers: async () => {
    return universalFetch<Array<any>>(
      'host/getCustomerServers',
      '/host/customers/servers',
      {},
      []
    );
  },

  /**
   * Get API status
   */
  getAPIStatus: async () => {
    return universalFetch<Array<any>>(
      'host/getAPIStatus',
      '/host/apis/status',
      {},
      []
    );
  },

  /**
   * Get host stats
   */
  getHostStats: async () => {
    return universalFetch(
      'host/getHostStats',
      '/host/stats',
      {},
      {
        totalCustomers: 0,
        activeServers: 0,
        totalPlayers: 0,
        apiRequests24h: 0,
        avgResponseTime: 0,
        uptime: 0,
        bandwidthUsed: '0 GB',
        totalBans: 0,
        staffVerified: 0
      }
    );
  }
};

/**
 * Real-time data updater hook
 * Automatically fetches and updates data at specified intervals
 */
export class RealTimeDataUpdater {
  private intervals: Map<string, NodeJS.Timeout> = new Map();

  /**
   * Start auto-updating metrics
   */
  startMetricsUpdate(callback: (data: any) => void, interval: number = API_REFRESH_INTERVAL) {
    this.stopMetricsUpdate(); // Clear existing interval
    
    const update = async () => {
      try {
        const metrics = await MetricsService.getServerMetrics();
        const aiAnalytics = await MetricsService.getAIAnalytics();
        const economy = await MetricsService.getEconomyStats();
        const performance = await MetricsService.getPerformanceMetrics();
        const alerts = await MetricsService.getAlerts();

        callback({
          ...metrics,
          aiAnalytics,
          economy,
          performance,
          alerts
        });
      } catch (error) {
        console.error('[RealTimeDataUpdater] Failed to update metrics:', error);
      }
    };

    // Initial fetch
    update();

    // Set interval
    const intervalId = setInterval(update, interval);
    this.intervals.set('metrics', intervalId);
  }

  /**
   * Stop metrics update
   */
  stopMetricsUpdate() {
    const intervalId = this.intervals.get('metrics');
    if (intervalId) {
      clearInterval(intervalId);
      this.intervals.delete('metrics');
    }
  }

  /**
   * Start auto-updating player list
   */
  startPlayersUpdate(callback: (players: any[]) => void, interval: number = API_REFRESH_INTERVAL) {
    this.stopPlayersUpdate();
    
    const update = async () => {
      try {
        const players = await PlayerService.getPlayers();
        callback(players);
      } catch (error) {
        console.error('[RealTimeDataUpdater] Failed to update players:', error);
      }
    };

    update();
    const intervalId = setInterval(update, interval);
    this.intervals.set('players', intervalId);
  }

  /**
   * Stop players update
   */
  stopPlayersUpdate() {
    const intervalId = this.intervals.get('players');
    if (intervalId) {
      clearInterval(intervalId);
      this.intervals.delete('players');
    }
  }

  /**
   * Stop all updates
   */
  stopAll() {
    this.intervals.forEach((intervalId) => clearInterval(intervalId));
    this.intervals.clear();
  }
}

// Export singleton instance
export const dataUpdater = new RealTimeDataUpdater();

// Export all services
export const DataService = {
  Metrics: MetricsService,
  Player: PlayerService,
  Moderation: ModerationService,
  Server: ServerService,
  Vehicle: VehicleService,
  Jobs: JobsService,
  Host: HostService,
};