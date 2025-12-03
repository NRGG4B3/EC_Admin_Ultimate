// FiveM TypeScript declarations
declare global {
  interface Window {
    invokeNative?: (hash: string, ...args: any[]) => any;
    GetParentResourceName?: () => string;
  }

  // FiveM NUI functions
  const GetParentResourceName: () => string;
  const SendNUIMessage: (data: any) => void;
  const RegisterNUICallback: (type: string, callback: (data: any, cb: (response: any) => void) => void) => void;

  // Extend fetch for NUI requests
  interface RequestInit {
    resource?: string;
  }
}

export {};

// FiveM specific types
export interface FiveMPlayer {
  id: number;
  name: string;
  identifier: string;
  ping: number;
  coords: { x: number; y: number; z: number };
  health: number;
  armor: number;
  job?: string;
  gang?: string;
  isAdmin: boolean;
  isDead: boolean;
  isInVehicle: boolean;
  vehicle?: string;
}

export interface FiveMVehicle {
  id: number;
  plate: string;
  model: string;
  owner?: string;
  coords: { x: number; y: number; z: number };
  health: number;
  fuel: number;
  locked: boolean;
  spawned: Date;
}

export interface ServerMetrics {
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
}

export interface AdminAction {
  action: string;
  playerId?: number;
  playerIds?: number[];
  reason?: string;
  duration?: number;
  coords?: { x: number; y: number; z: number };
  data?: any;
}

export interface NotificationData {
  id: string;
  type: 'info' | 'warning' | 'error' | 'success' | 'player' | 'vehicle' | 'system';
  title: string;
  message: string;
  timestamp: number;
  severity: 'low' | 'medium' | 'high' | 'critical';
  source?: string;
  actions?: Array<{
    label: string;
    action: string;
  }>;
}