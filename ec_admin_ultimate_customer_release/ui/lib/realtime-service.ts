/**
 * EC Admin Ultimate - Real-Time Data Service
 * Centralized service for smooth, optimized real-time updates across ALL pages
 * Prevents flickering, unnecessary re-renders, and ensures data consistency
 */

import { useEffect, useState, useRef, useCallback } from 'react';

// ============================================================================
// TYPES
// ============================================================================

export interface RealtimeConfig {
  endpoint: string;
  interval?: number; // milliseconds (default: 5000)
  enabled?: boolean;
  onError?: (error: Error) => void;
  transform?: (data: any) => any;
}

// ============================================================================
// SMART DATA FETCHER - Prevents unnecessary re-renders
// ============================================================================

export function useRealtimeData<T>(
  config: RealtimeConfig,
  initialData?: T
): { data: T | undefined; loading: boolean; error: Error | null; refetch: () => Promise<void> } {
  const {
    endpoint,
    interval = 5000,
    enabled = true,
    onError,
    transform
  } = config;

  const [data, setData] = useState<T | undefined>(initialData);
  const [loading, setLoading] = useState(!initialData);
  const [error, setError] = useState<Error | null>(null);
  const isMountedRef = useRef(true);
  const isInitialLoadRef = useRef(true);
  const lastDataRef = useRef<string>('');

  const fetchData = useCallback(async () => {
    if (!enabled) return;

    try {
      // Don't show loading on refresh, only on initial load
      if (isInitialLoadRef.current) {
        setLoading(true);
      }

      // @ts-ignore - NUI callback
      const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
      const response = await fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      const result = await response.json();

      if (!isMountedRef.current) return;

      // Transform data if transformer provided
      const finalData = transform ? transform(result) : result;

      // SMART UPDATE: Only update if data actually changed (prevents flicker)
      const dataString = JSON.stringify(finalData);
      if (dataString !== lastDataRef.current) {
        lastDataRef.current = dataString;
        setData(finalData);
        setError(null);
      }

      isInitialLoadRef.current = false;
    } catch (err) {
      if (!isMountedRef.current) return;

      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      
      if (onError) {
        onError(error);
      } else {
        console.warn(`[Realtime] Failed to fetch ${endpoint}:`, error);
      }
    } finally {
      if (isMountedRef.current && isInitialLoadRef.current) {
        setLoading(false);
      }
    }
  }, [endpoint, enabled, transform, onError]);

  // Setup realtime updates
  useEffect(() => {
    isMountedRef.current = true;

    // Initial fetch
    fetchData();

    // Setup interval for continuous updates
    const intervalId = setInterval(fetchData, interval);

    return () => {
      isMountedRef.current = false;
      clearInterval(intervalId);
    };
  }, [fetchData, interval]);

  return { data, loading, error, refetch: fetchData };
}

// ============================================================================
// BATCH DATA FETCHER - Fetch multiple endpoints simultaneously
// ============================================================================

export function useRealtimeBatch<T extends Record<string, any>>(
  configs: Record<keyof T, RealtimeConfig>,
  interval: number = 5000
): { data: T; loading: boolean; errors: Record<string, Error | null>; refetch: () => Promise<void> } {
  const [data, setData] = useState<T>({} as T);
  const [loading, setLoading] = useState(true);
  const [errors, setErrors] = useState<Record<string, Error | null>>({});
  const isMountedRef = useRef(true);
  const isInitialLoadRef = useRef(true);
  const lastDataRef = useRef<Record<string, string>>({});

  const fetchAll = useCallback(async () => {
    if (isInitialLoadRef.current) {
      setLoading(true);
    }

    const results: Partial<T> = {};
    const newErrors: Record<string, Error | null> = {};

    await Promise.all(
      Object.entries(configs).map(async ([key, config]) => {
        if (!config.enabled) return;

        try {
          // @ts-ignore
          const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
          const response = await fetch(`https://${resourceName}/${config.endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
          });

          const result = await response.json();
          const finalData = config.transform ? config.transform(result) : result;

          // Smart update - only if changed
          const dataString = JSON.stringify(finalData);
          if (dataString !== lastDataRef.current[key]) {
            lastDataRef.current[key] = dataString;
            results[key as keyof T] = finalData;
          } else {
            results[key as keyof T] = data[key as keyof T];
          }

          newErrors[key] = null;
        } catch (err) {
          const error = err instanceof Error ? err : new Error(String(err));
          newErrors[key] = error;
          
          if (config.onError) {
            config.onError(error);
          } else {
            console.warn(`[Realtime Batch] Failed to fetch ${config.endpoint}:`, error);
          }
        }
      })
    );

    if (isMountedRef.current) {
      setData(prev => ({ ...prev, ...results }));
      setErrors(newErrors);
      isInitialLoadRef.current = false;
      setLoading(false);
    }
  }, [configs, data]);

  useEffect(() => {
    isMountedRef.current = true;

    fetchAll();

    const intervalId = setInterval(fetchAll, interval);

    return () => {
      isMountedRef.current = false;
      clearInterval(intervalId);
    };
  }, [fetchAll, interval]);

  return { data, loading, errors, refetch: fetchAll };
}

// ============================================================================
// POLLING MANAGER - Fine-grained control over polling
// ============================================================================

export class PollingManager {
  private intervals: Map<string, NodeJS.Timeout> = new Map();
  private callbacks: Map<string, () => Promise<void>> = new Map();

  register(key: string, callback: () => Promise<void>, interval: number = 5000) {
    // Clear existing if any
    this.unregister(key);

    // Store callback
    this.callbacks.set(key, callback);

    // Execute immediately
    callback();

    // Setup interval
    const intervalId = setInterval(callback, interval);
    this.intervals.set(key, intervalId);
  }

  unregister(key: string) {
    const intervalId = this.intervals.get(key);
    if (intervalId) {
      clearInterval(intervalId);
      this.intervals.delete(key);
    }
    this.callbacks.delete(key);
  }

  unregisterAll() {
    this.intervals.forEach(intervalId => clearInterval(intervalId));
    this.intervals.clear();
    this.callbacks.clear();
  }

  async refresh(key: string) {
    const callback = this.callbacks.get(key);
    if (callback) {
      await callback();
    }
  }

  async refreshAll() {
    await Promise.all(
      Array.from(this.callbacks.values()).map(callback => callback())
    );
  }
}

// Global polling manager instance
export const globalPollingManager = new PollingManager();

// ============================================================================
// CLEANUP HOOK - Ensures proper cleanup on unmount
// ============================================================================

export function useCleanup(callback: () => void) {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  useEffect(() => {
    return () => callbackRef.current();
  }, []);
}

// ============================================================================
// DEBOUNCED FETCH - Prevents excessive API calls
// ============================================================================

export function useDebouncedFetch<T>(
  fetchFn: () => Promise<T>,
  delay: number = 1000
): [T | undefined, boolean, () => void] {
  const [data, setData] = useState<T>();
  const [loading, setLoading] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout>();

  const debouncedFetch = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    timeoutRef.current = setTimeout(async () => {
      setLoading(true);
      try {
        const result = await fetchFn();
        setData(result);
      } catch (err) {
        console.error('[Debounced Fetch] Error:', err);
      } finally {
        setLoading(false);
      }
    }, delay);
  }, [fetchFn, delay]);

  useEffect(() => {
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, []);

  return [data, loading, debouncedFetch];
}

// ============================================================================
// EXPORT UTILITIES
// ============================================================================

export default {
  useRealtimeData,
  useRealtimeBatch,
  PollingManager,
  globalPollingManager,
  useCleanup,
  useDebouncedFetch
};
