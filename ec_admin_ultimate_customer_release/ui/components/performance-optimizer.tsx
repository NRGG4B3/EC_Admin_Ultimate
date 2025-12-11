// @ts-nocheck - Complex lazy loading with dynamic imports
import { memo, useMemo, useCallback, useRef, useEffect, useState } from 'react';
import { PageType } from '../src/types';

// Performance-optimized lazy loading with error boundaries
export class ComponentLoader {
  private static cache = new Map<string, Promise<any>>();
  private static loadedComponents = new Map<string, any>();

  static async loadComponent(componentName: string): Promise<any> {
    // Return cached component if already loaded
    if (this.loadedComponents.has(componentName)) {
      return this.loadedComponents.get(componentName);
    }

    // Return existing promise if loading
    if (this.cache.has(componentName)) {
      return this.cache.get(componentName);
    }

    // Create new loading promise
    const loadPromise = this.createLoadPromise(componentName);
    this.cache.set(componentName, loadPromise);

    try {
      const component = await loadPromise;
      this.loadedComponents.set(componentName, component);
      this.cache.delete(componentName); // Remove promise from cache
      return component;
    } catch (error) {
      this.cache.delete(componentName); // Remove failed promise
      throw error;
    }
  }

  private static createLoadPromise(componentName: string): Promise<any> {
    switch (componentName) {
      case 'dashboard':
        return import('../components/pages/dashboard').then(m => m.Dashboard);
      case 'players':
        return import('../components/pages/players').then(m => m.PlayersPage);
      case 'vehicles':
        return import('../components/pages/vehicles').then(m => m.VehiclesPage);
      case 'monitor':
        return import('../components/pages/monitor').then(m => m.MonitorPage);
      case 'ai-analytics':
        return import('../components/pages/ai-analytics').then(m => m.AIAnalyticsPage);
      case 'ai-detection':
        return import('../components/pages/ai-detection').then(m => m.AIDetectionPage);
      case 'anticheat':
        return import('./pages/anticheat-advanced').then(m => m.AnticheatsPage);
      case 'admin-abuse':
        return import('./pages/admin-abuse-advanced').then(m => m.AdminAbusePage);
      case 'jobs-gangs':
        return import('./pages/jobs-gangs').then(m => m.JobsGangsPage);
      case 'reports-logs':
        return import('./pages/reports-logs').then(m => m.ReportsLogsPage);
      case 'advanced-reports':
        return import('./pages/advanced-reports').then(m => m.AdvancedReportsPage);
      case 'inventory':
        return import('./pages/inventory').then(m => m.InventoryPage);
      case 'global-tools':
        return import('./pages/global-tools-complete').then(m => m.GlobalToolsPage);
      case 'settings':
        return import('./pages/settings').then(m => m.SettingsPage);
      case 'economy':
        return import('./pages/economy').then(m => m.EconomyPage);
      case 'bans-warnings':
        return import('./pages/bans-warnings').then(m => m.BansWarningsPage);
      case 'live-map':
        return import('./pages/live-map-complete').then(m => m.LiveMapPage);
      case 'backups':
        return import('./pages/backups-complete').then(m => m.BackupsPage);
      case 'security':
        return import('./pages/security-complete').then(m => m.SecurityPage);
      case 'performance':
        return import('./pages/performance-complete').then(m => m.PerformancePage);
      case 'communications':
        return import('./pages/communications-enhanced').then(m => m.CommunicationsPage);
      case 'events':
        return import('./pages/events-complete').then(m => m.EventsPage);
      case 'whitelist':
        return import('./pages/whitelist-enhanced').then(m => m.WhitelistPage);
      case 'resources':
        return import('./pages/resources-complete').then(m => m.ResourcesPage);
      case 'housing':
        return import('./pages/housing-optimized').then(m => m.HousingPage);
      case 'dev-tools':
        return import('./pages/dev-tools-advanced').then(m => m.DevToolsPage);
      default:
        return Promise.reject(new Error(`Unknown component: ${componentName}`));
    }
  }

  // Preload critical components
  static preloadCriticalComponents() {
    const criticalComponents = ['dashboard', 'players', 'vehicles', 'monitor'];
    criticalComponents.forEach(componentName => {
      // Use requestIdleCallback for non-blocking preloading
      if ('requestIdleCallback' in window) {
        requestIdleCallback(() => {
          this.loadComponent(componentName).catch(error => {
            console.warn(`Failed to preload ${componentName}:`, error);
          });
        });
      }
    });
  }

  // Clear cache (useful for development)
  static clearCache() {
    this.cache.clear();
    this.loadedComponents.clear();
  }
}

// Virtual scrolling hook for large lists
export function useVirtualScrolling<T = any,>(
  items: T[],
  containerHeight: number,
  itemHeight: number,
  overscan: number = 5
) {
  const scrollTop = useRef(0);
  const [visibleRange, setVisibleRange] = useState<[number, number]>([0, Math.min(items.length - 1, Math.ceil(containerHeight / itemHeight))]);

  const visibleItems = useMemo(() => {
    return items.slice(visibleRange[0], visibleRange[1] + 1);
  }, [items, visibleRange]);

  const handleScroll = useCallback((event: React.UIEvent<HTMLDivElement>) => {
    scrollTop.current = event.currentTarget.scrollTop;
    setVisibleRange([
      Math.max(0, Math.floor(scrollTop.current / itemHeight) - overscan),
      Math.min(items.length - 1, Math.ceil((scrollTop.current + containerHeight) / itemHeight) + overscan)
    ]);
  }, [items.length, containerHeight, itemHeight, overscan]);

  return {
    visibleItems,
    offsetY: visibleRange[0] * itemHeight,
    totalHeight: items.length * itemHeight,
    handleScroll
  };
}

// Optimized memoization hook
export function useOptimizedMemo<T>(
  factory: () => T,
  deps: React.DependencyList,
  isEqual?: (a: T, b: T) => boolean
): T {
  const ref = useRef<{ deps: React.DependencyList; value: T }>();

  const depsChanged = useMemo(() => {
    if (!ref.current) return true;
    if (deps.length !== ref.current.deps.length) return true;
    return deps.some((dep, index) => dep !== ref.current!.deps[index]);
  }, deps);

  if (depsChanged) {
    const newValue = factory();
    if (ref.current && isEqual && !isEqual(newValue, ref.current.value)) {
      ref.current = { deps, value: newValue };
    } else if (!ref.current || !isEqual) {
      ref.current = { deps, value: newValue };
    }
  }

  return ref.current!.value;
}

// Performance-optimized callback hook
export function useOptimizedCallback<T extends (...args: any[]) => any>(
  callback: T,
  deps: React.DependencyList
): T {
  const callbackRef = useRef<T>(callback);
  const depsRef = useRef<React.DependencyList>(deps);

  // Update callback if dependencies changed
  const depsChanged = useMemo(() => {
    if (deps.length !== depsRef.current.length) return true;
    return deps.some((dep, index) => dep !== depsRef.current[index]);
  }, deps);

  if (depsChanged) {
    callbackRef.current = callback;
    depsRef.current = deps;
  }

  return useCallback((...args: any[]) => {
    return callbackRef.current(...args);
  }, []) as T;
}

// Batch state updates for better performance
export function useBatchedUpdates() {
  const pendingUpdates = useRef<(() => void)[]>([]);
  const isUpdateScheduled = useRef(false);

  const batchUpdate = useCallback((updateFn: () => void) => {
    pendingUpdates.current.push(updateFn);

    if (!isUpdateScheduled.current) {
      isUpdateScheduled.current = true;
      
      if ('requestIdleCallback' in window) {
        requestIdleCallback(() => {
          const updates = pendingUpdates.current.splice(0);
          updates.forEach(update => update());
          isUpdateScheduled.current = false;
        });
      } else {
        setTimeout(() => {
          const updates = pendingUpdates.current.splice(0);
          updates.forEach(update => update());
          isUpdateScheduled.current = false;
        }, 0);
      }
    }
  }, []);

  return batchUpdate;
}

// Optimized image loading
export function useOptimizedImageLoader(src: string, fallback?: string) {
  const [imageState, setImageState] = useState<{
    src: string;
    loading: boolean;
    error: boolean;
  }>({
    src: fallback || '',
    loading: true,
    error: false
  });

  useEffect(() => {
    const img = new Image();
    
    img.onload = () => {
      setImageState({
        src,
        loading: false,
        error: false
      });
    };

    img.onerror = () => {
      setImageState({
        src: fallback || '',
        loading: false,
        error: true
      });
    };

    img.src = src;

    return () => {
      img.onload = null;
      img.onerror = null;
    };
  }, [src, fallback]);

  return imageState;
}

// Memory leak prevention hook
export function useCleanupEffect(effect: () => (() => void) | void, deps: React.DependencyList) {
  const cleanupRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    // Cleanup previous effect
    if (cleanupRef.current) {
      cleanupRef.current();
      cleanupRef.current = null;
    }

    // Run new effect
    const cleanup = effect();
    if (typeof cleanup === 'function') {
      cleanupRef.current = cleanup;
    }

    return () => {
      if (cleanupRef.current) {
        cleanupRef.current();
        cleanupRef.current = null;
      }
    };
  }, deps);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (cleanupRef.current) {
        cleanupRef.current();
      }
    };
  }, []);
}

// Initialize performance optimizations
export function initializePerformanceOptimizations() {
  // Preload critical components
  ComponentLoader.preloadCriticalComponents();

  // Add performance observer if available
  if ('PerformanceObserver' in window) {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (entry.entryType === 'measure' || entry.entryType === 'navigation') {
          console.log(`Performance: ${entry.name} took ${entry.duration}ms`);
        }
      }
    });

    try {
      observer.observe({ entryTypes: ['measure', 'navigation'] });
    } catch (e) {
      console.warn('Performance Observer not fully supported');
    }
  }

  return {
    ComponentLoader,
    cleanup: () => {
      ComponentLoader.clearCache();
    }
  };
}

import { useState } from 'react';