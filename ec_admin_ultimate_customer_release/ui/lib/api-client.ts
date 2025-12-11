/**
 * EC Admin Ultimate - API Client
 * Handles all API communication with Node.js Host API
 * NO MOCK DATA - All requests are real
 */

const HOST_API_URL = import.meta.env.VITE_HOST_API_URL || 'http://localhost:30121';
const API_KEY = import.meta.env.VITE_API_KEY || '';

export class APIError extends Error {
  constructor(
    message: string,
    public statusCode?: number,
    public code?: string
  ) {
    super(message);
    this.name = 'APIError';
  }
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  body?: any;
  headers?: Record<string, string>;
  timeout?: number;
}

/**
 * Make authenticated request to Host API
 */
async function request<T>(endpoint: string, options: RequestOptions = {}): Promise<T> {
  const {
    method = 'GET',
    body,
    headers = {},
    timeout = 30000
  } = options;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(`${HOST_API_URL}${endpoint}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': API_KEY,
        ...headers
      },
      body: body ? JSON.stringify(body) : undefined,
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const error = await response.json().catch(() => ({
        error: { message: response.statusText, code: 'UNKNOWN_ERROR' }
      }));

      throw new APIError(
        error.error?.message || 'Request failed',
        response.status,
        error.error?.code
      );
    }

    return await response.json();
  } catch (error) {
    clearTimeout(timeoutId);

    if (error instanceof APIError) {
      throw error;
    }

    if (error instanceof Error && error.name === 'AbortError') {
      throw new APIError('Request timeout', 408, 'TIMEOUT');
    }

    throw new APIError(
      error instanceof Error ? error.message : 'Unknown error',
      500,
      'NETWORK_ERROR'
    );
  }
}

// ==================== HEALTH & STATUS ====================

export async function getHealth(): Promise<{
  status: string;
  timestamp: number;
  version: string;
}> {
  return request('/health');
}

export async function getServerStatus(): Promise<{
  success: boolean;
  server: {
    online: boolean;
    uptime: number;
    version: string;
  };
  players: {
    online: number;
    max: number;
  };
}> {
  return request('/api/v1/status');
}

// ==================== PLAYERS ====================

export interface Player {
  serverId: number;
  name: string;
  identifier: string;
  ping?: number;
}

export async function getPlayers(): Promise<{
  success: boolean;
  count: number;
  players: Player[];
}> {
  return request('/api/v1/players');
}

export async function getPlayer(serverId: number): Promise<{
  success: boolean;
  player: Player;
}> {
  return request(`/api/v1/players/${serverId}`);
}

export async function kickPlayer(serverId: number, reason: string): Promise<{
  success: boolean;
  message: string;
}> {
  return request(`/api/v1/players/${serverId}/kick`, {
    method: 'POST',
    body: { reason }
  });
}

// ==================== BANS ====================

export interface Ban {
  id: string;
  identifier: string;
  reason: string;
  duration: number;
  adminName: string;
  global: boolean;
  timestamp: number;
  active: boolean;
}

export async function getBans(activeOnly = false): Promise<{
  success: boolean;
  count: number;
  bans: Ban[];
}> {
  const params = activeOnly ? '?active=true' : '';
  return request(`/api/v1/bans${params}`);
}

export async function createBan(data: {
  identifier: string;
  reason: string;
  duration: number;
  adminName?: string;
  global?: boolean;
}): Promise<{
  success: boolean;
  message: string;
  ban: Ban;
}> {
  return request('/api/v1/bans', {
    method: 'POST',
    body: data
  });
}

export async function removeBan(banId: string): Promise<{
  success: boolean;
  message: string;
}> {
  return request(`/api/v1/bans/${banId}`, {
    method: 'DELETE'
  });
}

// ==================== VEHICLES ====================

export interface Vehicle {
  netId: number;
  model: string;
  plate: string;
  owner?: string;
}

export async function getVehicles(): Promise<{
  success: boolean;
  count: number;
  vehicles: Vehicle[];
}> {
  return request('/api/v1/vehicles');
}

export async function deleteVehicle(netId: number): Promise<{
  success: boolean;
  message: string;
}> {
  return request(`/api/v1/vehicles/${netId}`, {
    method: 'DELETE'
  });
}

// ==================== SERVER CONTROL ====================

export async function restartServer(delay = 0, reason = 'Manual restart'): Promise<{
  success: boolean;
  message: string;
  delay: number;
  reason: string;
}> {
  return request('/api/v1/server/restart', {
    method: 'POST',
    body: { delay, reason }
  });
}

export async function sendAnnouncement(message: string, type = 'info'): Promise<{
  success: boolean;
  message: string;
}> {
  return request('/api/v1/server/announce', {
    method: 'POST',
    body: { message, type }
  });
}

export async function getMetrics(): Promise<{
  success: boolean;
  metrics: {
    cpu: number;
    memory: number;
    tps: number;
    players: number;
    uptime: number;
  };
}> {
  return request('/api/v1/server/metrics');
}

export async function getResources(): Promise<{
  success: boolean;
  count: number;
  resources: Array<{
    name: string;
    status: string;
    uptime: number;
  }>;
}> {
  return request('/api/v1/server/resources');
}

export async function restartResource(name: string): Promise<{
  success: boolean;
  message: string;
}> {
  return request(`/api/v1/server/resources/${name}/restart`, {
    method: 'POST'
  });
}

// ==================== MONITORING ====================

export async function getLogs(type?: string, limit = 100): Promise<{
  success: boolean;
  count: number;
  logs: Array<{
    timestamp: number;
    type: string;
    message: string;
    data?: any;
  }>;
}> {
  const params = new URLSearchParams();
  if (type) params.set('type', type);
  params.set('limit', limit.toString());
  
  return request(`/api/v1/monitoring/logs?${params}`);
}

export async function getReports(): Promise<{
  success: boolean;
  count: number;
  reports: Array<{
    id: string;
    playerId: number;
    reason: string;
    timestamp: number;
    status: string;
  }>;
}> {
  return request('/api/v1/monitoring/reports');
}

// ==================== NRG STAFF (HOST ONLY) ====================

export async function grantStaffAccess(staffEmail: string, level = 'admin'): Promise<{
  success: boolean;
  message: string;
  staff: {
    email: string;
    level: string;
  };
}> {
  return request('/api/v1/staff/access', {
    method: 'POST',
    body: { staffEmail, level }
  });
}

export async function revokeStaffAccess(email: string): Promise<{
  success: boolean;
  message: string;
}> {
  return request(`/api/v1/staff/access/${email}`, {
    method: 'DELETE'
  });
}

// ==================== API CLIENT SINGLETON ====================

export const apiClient = {
  // Health
  getHealth,
  getServerStatus,
  
  // Players
  getPlayers,
  getPlayer,
  kickPlayer,
  
  // Bans
  getBans,
  createBan,
  removeBan,
  
  // Vehicles
  getVehicles,
  deleteVehicle,
  
  // Server Control
  restartServer,
  sendAnnouncement,
  getMetrics,
  getResources,
  restartResource,
  
  // Monitoring
  getLogs,
  getReports,
  
  // Staff (Host only)
  grantStaffAccess,
  revokeStaffAccess
};
