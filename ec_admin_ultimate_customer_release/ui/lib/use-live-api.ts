/**
 * EC Admin Ultimate - Live API Hooks
 * React hooks for real-time data fetching
 * NO MOCK DATA - All data is live
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { apiClient, APIError } from './api-client';

interface UseQueryOptions {
  refetchInterval?: number;
  enabled?: boolean;
  onError?: (error: APIError) => void;
  onSuccess?: (data: any) => void;
}

interface QueryState<T> {
  data: T | null;
  isLoading: boolean;
  error: APIError | null;
  refetch: () => Promise<void>;
}

/**
 * Generic query hook for API data
 */
function useQuery<T>(
  queryFn: () => Promise<T>,
  options: UseQueryOptions = {}
): QueryState<T> {
  const {
    refetchInterval,
    enabled = true,
    onError,
    onSuccess
  } = options;

  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<APIError | null>(null);
  
  const isMountedRef = useRef(true);
  const intervalRef = useRef<NodeJS.Timeout>();

  const fetchData = useCallback(async () => {
    if (!enabled) return;

    try {
      setIsLoading(true);
      setError(null);
      
      const result = await queryFn();
      
      if (isMountedRef.current) {
        setData(result);
        onSuccess?.(result);
      }
    } catch (err) {
      const apiError = err instanceof APIError ? err : new APIError('Unknown error');
      
      if (isMountedRef.current) {
        setError(apiError);
        onError?.(apiError);
      }
    } finally {
      if (isMountedRef.current) {
        setIsLoading(false);
      }
    }
  }, [queryFn, enabled, onError, onSuccess]);

  useEffect(() => {
    isMountedRef.current = true;
    
    // Initial fetch
    fetchData();

    // Set up refetch interval if specified
    if (refetchInterval && enabled) {
      intervalRef.current = setInterval(fetchData, refetchInterval);
    }

    return () => {
      isMountedRef.current = false;
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [fetchData, refetchInterval, enabled]);

  return {
    data,
    isLoading,
    error,
    refetch: fetchData
  };
}

// ==================== LIVE DATA HOOKS ====================

/**
 * Get server health status
 */
export function useServerHealth(refetchInterval = 5000) {
  return useQuery(
    () => apiClient.getHealth(),
    { refetchInterval }
  );
}

/**
 * Get server status
 */
export function useServerStatus(refetchInterval = 10000) {
  return useQuery(
    () => apiClient.getServerStatus(),
    { refetchInterval }
  );
}

/**
 * Get live player list
 */
export function usePlayers(refetchInterval = 5000) {
  return useQuery(
    () => apiClient.getPlayers(),
    { refetchInterval }
  );
}

/**
 * Get specific player data
 */
export function usePlayer(serverId: number | null) {
  return useQuery(
    () => serverId ? apiClient.getPlayer(serverId) : Promise.reject(new APIError('No server ID')),
    { enabled: serverId !== null }
  );
}

/**
 * Get ban list
 */
export function useBans(activeOnly = false, refetchInterval = 30000) {
  return useQuery(
    () => apiClient.getBans(activeOnly),
    { refetchInterval }
  );
}

/**
 * Get vehicle list
 */
export function useVehicles(refetchInterval = 10000) {
  return useQuery(
    () => apiClient.getVehicles(),
    { refetchInterval }
  );
}

/**
 * Get server metrics
 */
export function useMetrics(refetchInterval = 5000) {
  return useQuery(
    () => apiClient.getMetrics(),
    { refetchInterval }
  );
}

/**
 * Get resource list
 */
export function useResources(refetchInterval = 15000) {
  return useQuery(
    () => apiClient.getResources(),
    { refetchInterval }
  );
}

/**
 * Get logs
 */
export function useLogs(type?: string, limit = 100, refetchInterval = 10000) {
  return useQuery(
    () => apiClient.getLogs(type, limit),
    { refetchInterval }
  );
}

/**
 * Get reports
 */
export function useReports(refetchInterval = 30000) {
  return useQuery(
    () => apiClient.getReports(),
    { refetchInterval }
  );
}

// ==================== MUTATION HOOKS ====================

interface UseMutationOptions<T, V> {
  onSuccess?: (data: T) => void;
  onError?: (error: APIError) => void;
}

interface MutationState<T, V> {
  mutate: (variables: V) => Promise<T>;
  data: T | null;
  isLoading: boolean;
  error: APIError | null;
}

function useMutation<T, V>(
  mutationFn: (variables: V) => Promise<T>,
  options: UseMutationOptions<T, V> = {}
): MutationState<T, V> {
  const { onSuccess, onError } = options;
  
  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<APIError | null>(null);

  const mutate = useCallback(async (variables: V) => {
    try {
      setIsLoading(true);
      setError(null);
      
      const result = await mutationFn(variables);
      
      setData(result);
      onSuccess?.(result);
      
      return result;
    } catch (err) {
      const apiError = err instanceof APIError ? err : new APIError('Unknown error');
      setError(apiError);
      onError?.(apiError);
      throw apiError;
    } finally {
      setIsLoading(false);
    }
  }, [mutationFn, onSuccess, onError]);

  return { mutate, data, isLoading, error };
}

/**
 * Kick player mutation
 */
export function useKickPlayer(options?: UseMutationOptions<any, { serverId: number; reason: string }>) {
  return useMutation(
    ({ serverId, reason }) => apiClient.kickPlayer(serverId, reason),
    options
  );
}

/**
 * Create ban mutation
 */
export function useCreateBan(options?: UseMutationOptions<any, {
  identifier: string;
  reason: string;
  duration: number;
  adminName?: string;
  global?: boolean;
}>) {
  return useMutation(
    (data) => apiClient.createBan(data),
    options
  );
}

/**
 * Remove ban mutation
 */
export function useRemoveBan(options?: UseMutationOptions<any, string>) {
  return useMutation(
    (banId) => apiClient.removeBan(banId),
    options
  );
}

/**
 * Delete vehicle mutation
 */
export function useDeleteVehicle(options?: UseMutationOptions<any, number>) {
  return useMutation(
    (netId) => apiClient.deleteVehicle(netId),
    options
  );
}

/**
 * Restart server mutation
 */
export function useRestartServer(options?: UseMutationOptions<any, { delay?: number; reason?: string }>) {
  return useMutation(
    ({ delay, reason }) => apiClient.restartServer(delay, reason),
    options
  );
}

/**
 * Send announcement mutation
 */
export function useSendAnnouncement(options?: UseMutationOptions<any, { message: string; type?: string }>) {
  return useMutation(
    ({ message, type }) => apiClient.sendAnnouncement(message, type),
    options
  );
}

/**
 * Restart resource mutation
 */
export function useRestartResource(options?: UseMutationOptions<any, string>) {
  return useMutation(
    (name) => apiClient.restartResource(name),
    options
  );
}

/**
 * Grant staff access mutation (Host only)
 */
export function useGrantStaffAccess(options?: UseMutationOptions<any, { staffEmail: string; level?: string }>) {
  return useMutation(
    ({ staffEmail, level }) => apiClient.grantStaffAccess(staffEmail, level),
    options
  );
}

/**
 * Revoke staff access mutation (Host only)
 */
export function useRevokeStaffAccess(options?: UseMutationOptions<any, string>) {
  return useMutation(
    (email) => apiClient.revokeStaffAccess(email),
    options
  );
}
