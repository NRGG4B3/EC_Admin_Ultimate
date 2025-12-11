/**
 * EC Admin Ultimate - Optimized Data Manager
 * 
 * Features:
 * - Instant data loading (no waiting)
 * - Smart caching (prevents redundant requests)
 * - Background refresh (no UI blocking)
 * - Optimistic updates (instant feedback)
 * - Automatic error recovery
 * - Memory efficient
 */

import { fetchNui } from '../components/nui-bridge';

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  isStale: boolean;
}

interface DataManagerConfig {
  cacheDuration: number;      // How long data is fresh (ms)
  staleDuration: number;       // How long to keep stale data (ms)
  refetchInterval?: number;    // Auto-refetch interval (ms)
  onUpdate?: (data: any) => void;
}

class DataManager {
  private cache = new Map<string, CacheEntry<any>>();
  private pendingRequests = new Map<string, Promise<any>>();
  private intervals = new Map<string, NodeJS.Timeout>();
  private listeners = new Map<string, Set<(data: any) => void>>();

  /**
   * Get data with smart caching
   * - Returns cached data instantly if available
   * - Fetches fresh data in background if stale
   * - Deduplicates concurrent requests
   */
  async get<T>(
    key: string,
    fetcher: () => Promise<T>,
    config: Partial<DataManagerConfig> = {}
  ): Promise<T> {
    const {
      cacheDuration = 5000,      // 5 seconds fresh
      staleDuration = 30000,     // 30 seconds stale
    } = config;

    const now = Date.now();
    const cached = this.cache.get(key);

    // Return cached data if still fresh
    if (cached && !this.isCacheExpired(cached, cacheDuration)) {
      return cached.data;
    }

    // Return stale data immediately, but fetch fresh in background
    if (cached && !this.isCacheExpired(cached, staleDuration)) {
      // Mark as stale
      cached.isStale = true;
      
      // Fetch fresh data in background
      this.backgroundRefresh(key, fetcher, config);
      
      // Return stale data for instant UI
      return cached.data;
    }

    // No cache or expired - fetch now
    return this.fetch(key, fetcher, config);
  }

  /**
   * Fetch data and cache it
   * - Deduplicates concurrent requests
   * - Updates all listeners
   */
  private async fetch<T>(
    key: string,
    fetcher: () => Promise<T>,
    config: Partial<DataManagerConfig> = {}
  ): Promise<T> {
    // Check if request is already pending
    const pending = this.pendingRequests.get(key);
    if (pending) {
      return pending;
    }

    // Create new request
    const request = fetcher()
      .then((data) => {
        // Cache the data
        this.cache.set(key, {
          data,
          timestamp: Date.now(),
          isStale: false
        });

        // Notify listeners
        this.notifyListeners(key, data);

        // Clear pending
        this.pendingRequests.delete(key);

        return data;
      })
      .catch((error) => {
        console.error(`[DataManager] Failed to fetch ${key}:`, error);
        
        // Clear pending
        this.pendingRequests.delete(key);
        
        // Return cached data if available, even if expired
        const cached = this.cache.get(key);
        if (cached) {
          return cached.data;
        }
        
        throw error;
      });

    this.pendingRequests.set(key, request);
    return request;
  }

  /**
   * Refresh data in background
   */
  private backgroundRefresh<T>(
    key: string,
    fetcher: () => Promise<T>,
    config: Partial<DataManagerConfig> = {}
  ): void {
    // Don't start multiple background fetches
    if (this.pendingRequests.has(key)) {
      return;
    }

    this.fetch(key, fetcher, config).catch(() => {
      // Ignore errors in background refresh
    });
  }

  /**
   * Subscribe to data updates
   */
  subscribe<T>(key: string, callback: (data: T) => void): () => void {
    if (!this.listeners.has(key)) {
      this.listeners.set(key, new Set());
    }

    this.listeners.get(key)!.add(callback);

    // Return unsubscribe function
    return () => {
      const listeners = this.listeners.get(key);
      if (listeners) {
        listeners.delete(callback);
        if (listeners.size === 0) {
          this.listeners.delete(key);
        }
      }
    };
  }

  /**
   * Notify all listeners of data update
   */
  private notifyListeners(key: string, data: any): void {
    const listeners = this.listeners.get(key);
    if (listeners) {
      listeners.forEach(callback => callback(data));
    }
  }

  /**
   * Start auto-refresh
   */
  startAutoRefresh<T>(
    key: string,
    fetcher: () => Promise<T>,
    interval: number,
    config: Partial<DataManagerConfig> = {}
  ): void {
    // Stop existing interval
    this.stopAutoRefresh(key);

    // Create new interval
    const intervalId = setInterval(() => {
      this.fetch(key, fetcher, config).catch(() => {
        // Ignore errors in auto-refresh
      });
    }, interval);

    this.intervals.set(key, intervalId);
  }

  /**
   * Stop auto-refresh
   */
  stopAutoRefresh(key: string): void {
    const interval = this.intervals.get(key);
    if (interval) {
      clearInterval(interval);
      this.intervals.delete(key);
    }
  }

  /**
   * Invalidate cache (force refetch)
   */
  invalidate(key: string): void {
    this.cache.delete(key);
  }

  /**
   * Clear all cache
   */
  clearCache(): void {
    this.cache.clear();
  }

  /**
   * Check if cache is expired
   */
  private isCacheExpired(entry: CacheEntry<any>, duration: number): boolean {
    return Date.now() - entry.timestamp > duration;
  }

  /**
   * Optimistic update - update cache immediately, fetch in background
   */
  optimisticUpdate<T>(key: string, updater: (current: T) => T): void {
    const cached = this.cache.get(key);
    if (cached) {
      const updated = updater(cached.data);
      this.cache.set(key, {
        data: updated,
        timestamp: Date.now(),
        isStale: false
      });
      this.notifyListeners(key, updated);
    }
  }

  /**
   * Get cached data without fetching
   */
  getCached<T>(key: string): T | null {
    const cached = this.cache.get(key);
    return cached ? cached.data : null;
  }

  /**
   * Cleanup - stop all intervals
   */
  cleanup(): void {
    this.intervals.forEach(interval => clearInterval(interval));
    this.intervals.clear();
    this.listeners.clear();
  }
}

// Singleton instance
export const dataManager = new DataManager();

// ==================== READY-TO-USE DATA FETCHERS ====================

/**
 * Get players with instant cache
 */
export async function getPlayers() {
  return dataManager.get(
    'players',
    async () => {
      try {
        const response = await fetchNui<any>('getPlayers', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch players:', error);
        return [];
      }
    },
    { cacheDuration: 3000, staleDuration: 15000 } // 3s fresh, 15s stale
  );
}

/**
 * Get server metrics with instant cache
 */
export async function getServerMetrics() {
  return dataManager.get(
    'serverMetrics',
    async () => {
      try {
        const response = await fetchNui<any>('getServerMetrics', {});
        return response || null;
      } catch (error) {
        console.error('[DataManager] Failed to fetch metrics:', error);
        return null;
      }
    },
    { cacheDuration: 2000, staleDuration: 10000 } // 2s fresh, 10s stale
  );
}

/**
 * Get vehicles with instant cache
 */
export async function getVehicles() {
  return dataManager.get(
    'vehicles',
    async () => {
      try {
        const response = await fetchNui<any>('getVehicles', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch vehicles:', error);
        return [];
      }
    },
    { cacheDuration: 5000, staleDuration: 20000 } // 5s fresh, 20s stale
  );
}

/**
 * Get bans with instant cache
 */
export async function getBans() {
  return dataManager.get(
    'bans',
    async () => {
      try {
        const response = await fetchNui<any>('getBans', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch bans:', error);
        return [];
      }
    },
    { cacheDuration: 10000, staleDuration: 30000 } // 10s fresh, 30s stale
  );
}

/**
 * Get warnings with instant cache
 */
export async function getWarnings() {
  return dataManager.get(
    'warnings',
    async () => {
      try {
        const response = await fetchNui<any>('getWarnings', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch warnings:', error);
        return [];
      }
    },
    { cacheDuration: 10000, staleDuration: 30000 } // 10s fresh, 30s stale
  );
}

/**
 * Get logs with instant cache
 */
export async function getLogs(type: string = 'all', limit: number = 100) {
  return dataManager.get(
    `logs_${type}_${limit}`,
    async () => {
      try {
        const response = await fetchNui<any>('getLogs', { type, limit });
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch logs:', error);
        return [];
      }
    },
    { cacheDuration: 5000, staleDuration: 20000 } // 5s fresh, 20s stale
  );
}

/**
 * Get resources with instant cache
 */
export async function getResources() {
  return dataManager.get(
    'resources',
    async () => {
      try {
        const response = await fetchNui<any>('getResources', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch resources:', error);
        return [];
      }
    },
    { cacheDuration: 5000, staleDuration: 20000 } // 5s fresh, 20s stale
  );
}

/**
 * Get economy stats with instant cache
 */
export async function getEconomyStats() {
  return dataManager.get(
    'economyStats',
    async () => {
      try {
        const response = await fetchNui<any>('getEconomyStats', {});
        return response || null;
      } catch (error) {
        console.error('[DataManager] Failed to fetch economy stats:', error);
        return null;
      }
    },
    { cacheDuration: 5000, staleDuration: 20000 } // 5s fresh, 20s stale
  );
}

/**
 * Get inventory data with instant cache
 */
export async function getInventoryData() {
  return dataManager.get(
    'inventoryData',
    async () => {
      try {
        const response = await fetchNui<any>('getInventoryData', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch inventory data:', error);
        return [];
      }
    },
    { cacheDuration: 5000, staleDuration: 20000 } // 5s fresh, 20s stale
  );
}

/**
 * Get housing data with instant cache
 */
export async function getHousingData() {
  return dataManager.get(
    'housingData',
    async () => {
      try {
        const response = await fetchNui<any>('getHousingData', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch housing data:', error);
        return [];
      }
    },
    { cacheDuration: 10000, staleDuration: 30000 } // 10s fresh, 30s stale
  );
}

/**
 * Get jobs data with instant cache
 */
export async function getJobsData() {
  return dataManager.get(
    'jobsData',
    async () => {
      try {
        const response = await fetchNui<any>('getJobsData', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch jobs data:', error);
        return [];
      }
    },
    { cacheDuration: 10000, staleDuration: 30000 } // 10s fresh, 30s stale
  );
}

/**
 * Get reports with instant cache
 */
export async function getReports() {
  return dataManager.get(
    'reports',
    async () => {
      try {
        const response = await fetchNui<any>('getReports', {});
        return response || [];
      } catch (error) {
        console.error('[DataManager] Failed to fetch reports:', error);
        return [];
      }
    },
    { cacheDuration: 5000, staleDuration: 20000 } // 5s fresh, 20s stale
  );
}

/**
 * Invalidate specific cache
 */
export function invalidateCache(key: string) {
  dataManager.invalidate(key);
}

/**
 * Invalidate all cache
 */
export function invalidateAllCache() {
  dataManager.clearCache();
}

/**
 * Subscribe to data updates
 */
export function subscribeToData<T>(key: string, callback: (data: T) => void): () => void {
  return dataManager.subscribe(key, callback);
}