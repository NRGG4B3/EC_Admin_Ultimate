// API Service - All real data calls (no mocks)
// Handles authentication, error handling, and data fetching

const API_BASE = '/api';
const POLL_INTERVAL = 15000; // 15 seconds

interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

class APIService {
  private token: string | null = null;
  private pollIntervals: Map<string, NodeJS.Timeout> = new Map();

  constructor() {
    // Get token from localStorage
    this.token = localStorage.getItem('ec_admin_token');
  }

  private async fetchAPI<T>(endpoint: string, options: RequestInit = {}): Promise<APIResponse<T>> {
    try {
      const headers: HeadersInit = {
        'Content-Type': 'application/json',
        ...options.headers,
      };

      if (this.token) {
        headers['Authorization'] = `Bearer ${this.token}`;
      }

      const response = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers,
      });

      if (response.status === 401) {
        throw new Error('Unauthorized - Please log in');
      }

      if (response.status === 403) {
        throw new Error('Access denied - Insufficient permissions');
      }

      if (response.status === 429) {
        throw new Error('Rate limited - Please wait before trying again');
      }

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || errorData.error || `HTTP ${response.status}`);
      }

      const data = await response.json();
      return { success: true, data };

    } catch (error) {
      console.error(`API Error [${endpoint}]:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  // ============================================
  // METRICS
  // ============================================

  async getPlayerMetrics() {
    return this.fetchAPI<{
      playersOnline: number;
      totalPlayers: number;
      newToday: number;
      avgPlaytime: number;
      topPlayers: Array<{
        id: number;
        name: string;
        playtime: number;
        lastSeen: string;
      }>;
    }>('/metrics/players');
  }

  async getEconomyMetrics() {
    return this.fetchAPI<{
      totalCash: number;
      totalBank: number;
      avgWealth: number;
      transactions24h: number;
      economyHealth: number;
      suspiciousTransactions: number;
      topRichest: Array<{
        id: number;
        name: string;
        cash: number;
        bank: number;
        total: number;
      }>;
    }>('/metrics/economy');
  }

  async getSystemMetrics() {
    return this.fetchAPI<{
      cpu: number;
      memory: number;
      uptime: number;
      tps: number;
      players: number;
      resources: number;
      entities: number;
      vehicles: number;
      networkIn: number;
      networkOut: number;
    }>('/metrics/system');
  }

  async getStaffMetrics() {
    return this.fetchAPI<{
      totalStaff: number;
      onlineStaff: number;
      totalActions24h: number;
      activeBans: number;
      activeWarnings: number;
      topAdmins: Array<{
        id: number;
        name: string;
        actions: number;
        rank: string;
      }>;
    }>('/metrics/staff');
  }

  // ============================================
  // PLAYERS
  // ============================================

  async searchPlayers(query: string) {
    return this.fetchAPI<Array<{
      id: number;
      name: string;
      identifier: string;
      online: boolean;
      lastSeen: string;
    }>>(`/players/search?q=${encodeURIComponent(query)}`);
  }

  async getPlayer(playerId: number) {
    return this.fetchAPI<{
      id: number;
      name: string;
      identifier: string;
      job: string;
      gang: string;
      cash: number;
      bank: number;
      online: boolean;
      playtime: number;
      lastSeen: string;
      position: { x: number; y: number; z: number };
      warnings: number;
      bans: number;
    }>(`/players/${playerId}`);
  }

  async getOnlinePlayers() {
    return this.fetchAPI<Array<{
      id: number;
      name: string;
      identifier: string;
      job: string;
      ping: number;
    }>>('/players/online');
  }

  // ============================================
  // ADMIN ACTIONS
  // ============================================

  async kickPlayer(playerId: number, reason: string) {
    return this.fetchAPI('/admin/kick', {
      method: 'POST',
      body: JSON.stringify({ playerId, reason }),
    });
  }

  async warnPlayer(playerId: number, reason: string) {
    return this.fetchAPI('/admin/warn', {
      method: 'POST',
      body: JSON.stringify({ playerId, reason }),
    });
  }

  async banPlayer(playerId: number, reason: string, duration?: number) {
    return this.fetchAPI('/admin/ban', {
      method: 'POST',
      body: JSON.stringify({ playerId, reason, duration }),
    });
  }

  async unbanPlayer(banId: number) {
    return this.fetchAPI(`/admin/unban/${banId}`, {
      method: 'POST',
    });
  }

  async revivePlayer(playerId: number) {
    return this.fetchAPI('/admin/revive', {
      method: 'POST',
      body: JSON.stringify({ playerId }),
    });
  }

  async bringPlayer(playerId: number) {
    return this.fetchAPI('/admin/bring', {
      method: 'POST',
      body: JSON.stringify({ playerId }),
    });
  }

  async gotoPlayer(playerId: number) {
    return this.fetchAPI('/admin/goto', {
      method: 'POST',
      body: JSON.stringify({ playerId }),
    });
  }

  async setJob(playerId: number, job: string, grade: number) {
    return this.fetchAPI('/admin/setjob', {
      method: 'POST',
      body: JSON.stringify({ playerId, job, grade }),
    });
  }

  async giveItem(playerId: number, item: string, amount: number) {
    return this.fetchAPI('/admin/giveitem', {
      method: 'POST',
      body: JSON.stringify({ playerId, item, amount }),
    });
  }

  async removeItem(playerId: number, item: string, amount: number) {
    return this.fetchAPI('/admin/removeitem', {
      method: 'POST',
      body: JSON.stringify({ playerId, item, amount }),
    });
  }

  // ============================================
  // VEHICLES
  // ============================================

  async spawnVehicle(playerId: number, model: string) {
    return this.fetchAPI('/admin/spawnvehicle', {
      method: 'POST',
      body: JSON.stringify({ playerId, model }),
    });
  }

  async deleteVehicle(playerId: number) {
    return this.fetchAPI('/admin/deletevehicle', {
      method: 'POST',
      body: JSON.stringify({ playerId }),
    });
  }

  async repairVehicle(playerId: number) {
    return this.fetchAPI('/admin/repairvehicle', {
      method: 'POST',
      body: JSON.stringify({ playerId }),
    });
  }

  async refuelVehicle(playerId: number) {
    return this.fetchAPI('/admin/refuelvehicle', {
      method: 'POST',
      body: JSON.stringify({ playerId }),
    });
  }

  // ============================================
  // BANS & WARNINGS
  // ============================================

  async getBans(page: number = 1) {
    return this.fetchAPI<{
      bans: Array<{
        id: number;
        playerId: number;
        playerName: string;
        identifier: string;
        reason: string;
        bannedBy: string;
        bannedAt: string;
        expiresAt?: string;
        active: boolean;
      }>;
      total: number;
      page: number;
      perPage: number;
    }>(`/admin/bans?page=${page}`);
  }

  async getWarnings(page: number = 1) {
    return this.fetchAPI<{
      warnings: Array<{
        id: number;
        playerId: number;
        playerName: string;
        reason: string;
        warnedBy: string;
        warnedAt: string;
      }>;
      total: number;
      page: number;
      perPage: number;
    }>(`/admin/warnings?page=${page}`);
  }

  // ============================================
  // LOGS
  // ============================================

  async getAdminLogs(page: number = 1) {
    return this.fetchAPI<{
      logs: Array<{
        id: number;
        adminId: number;
        adminName: string;
        action: string;
        targetId?: number;
        targetName?: string;
        details: string;
        timestamp: string;
      }>;
      total: number;
      page: number;
      perPage: number;
    }>(`/logs/admin?page=${page}`);
  }

  // ============================================
  // HOST CONTROLS
  // ============================================

  async toggleWebUI(enabled: boolean) {
    return this.fetchAPI('/host/toggle-webui', {
      method: 'POST',
      body: JSON.stringify({ enabled }),
    });
  }

  async toggleAPI(enabled: boolean) {
    return this.fetchAPI('/host/toggle-api', {
      method: 'POST',
      body: JSON.stringify({ enabled }),
    });
  }

  async getHostStatus() {
    return this.fetchAPI<{
      webUIEnabled: boolean;
      apiEnabled: boolean;
      customerServers: number;
      totalPlayers: number;
      apiRequests24h: number;
    }>('/host/status');
  }

  // ============================================
  // POLLING
  // ============================================

  startPolling(key: string, callback: () => void, interval: number = POLL_INTERVAL) {
    // Clear existing interval if any
    this.stopPolling(key);

    // Run immediately
    callback();

    // Set up interval
    const intervalId = setInterval(callback, interval);
    this.pollIntervals.set(key, intervalId);
  }

  stopPolling(key: string) {
    const intervalId = this.pollIntervals.get(key);
    if (intervalId) {
      clearInterval(intervalId);
      this.pollIntervals.delete(key);
    }
  }

  stopAllPolling() {
    this.pollIntervals.forEach((intervalId) => clearInterval(intervalId));
    this.pollIntervals.clear();
  }
}

// Singleton instance
export const apiService = new APIService();

// React hook for easy access
export function useAPIService() {
  return apiService;
}
