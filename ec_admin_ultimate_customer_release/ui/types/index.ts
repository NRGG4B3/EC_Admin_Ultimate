// EC Admin Ultimate - TypeScript Type Definitions
// Centralized type definitions for the entire application

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
  alerts: Alert[];
  aiAnalytics?: AIAnalytics;
  economy?: Economy;
  performance?: Performance;
}

export interface Alert {
  id: string;
  type: string;
  message: string;
  time: number;
  severity?: string;
}

export interface AIAnalytics {
  totalDetections: number;
  criticalThreats: number;
  highRiskAlerts: number;
  mediumRiskAlerts: number;
  lowRiskAlerts: number;
  aiConfidence: number;
  modelsActive: number;
  threatPredictionAccuracy: number;
}

export interface Economy {
  totalTransactions: number;
  cashFlow: number;
  bankFlow: number;
  averageWealth: number;
  economyHealth: number;
  suspiciousTransactions: number;
}

export interface Performance {
  frameRate: number;
  scriptTime: number;
  entityCount: number;
  vehicleCount: number;
  playerLoad: number;
}

export interface PageProps {
  liveData: LiveData;
}

export interface Player {
  id: number;
  name: string;
  identifier: string;
  ping: number;
  job?: string;
  gang?: string;
  money?: {
    cash: number;
    bank: number;
  };
  position?: {
    x: number;
    y: number;
    z: number;
  };
  health?: number;
  armor?: number;
}

export interface Vehicle {
  id: number;
  model: string;
  plate: string;
  owner?: string;
  position?: {
    x: number;
    y: number;
    z: number;
  };
}

export interface Ban {
  id: number;
  playerId: string;
  playerName: string;
  reason: string;
  bannedBy: string;
  bannedAt: number;
  expiresAt?: number;
  isPermanent: boolean;
}

export interface Warning {
  id: number;
  playerId: string;
  playerName: string;
  reason: string;
  warnedBy: string;
  warnedAt: number;
}

export interface Resource {
  name: string;
  status: 'started' | 'stopped' | 'error';
  description?: string;
  version?: string;
}

export interface AdminLog {
  id: number;
  adminId: string;
  adminName: string;
  action: string;
  target?: string;
  details: string;
  timestamp: number;
}

export interface Backup {
  id: string;
  name: string;
  size: number;
  createdAt: number;
  type: 'auto' | 'manual';
}

export interface WhitelistEntry {
  id: number;
  identifier: string;
  name: string;
  addedBy: string;
  addedAt: number;
  priority?: number;
}

export interface EconomyStats {
  totalCash: number;
  totalBank: number;
  totalTransactions: number;
  averageWealth: number;
  topRichest: Array<{
    name: string;
    total: number;
  }>;
}

export interface PerformanceMetrics {
  cpu: number;
  memory: number;
  fps: number;
  scriptTime: number;
  players: number;
  entities: number;
}

export interface AIDetection {
  id: number;
  playerId: string;
  playerName: string;
  type: string;
  confidence: number;
  detectedAt: number;
  resolved: boolean;
}

export interface AnticheatLog {
  id: number;
  playerId: string;
  playerName: string;
  violation: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  detectedAt: number;
  action: string;
}

export type PageType = 
  | 'dashboard'
  | 'players' 
  | 'player-profile'
  | 'vehicles'
  | 'monitor'
  | 'ai-analytics'
  | 'ai-detection'
  | 'anticheat'
  | 'admin-abuse'
  | 'admin-profile'
  | 'jobs-gangs'
  | 'inventory'
  | 'global-tools'
  | 'settings'
  | 'economy'
  | 'bans-warnings'
  | 'live-map'
  | 'backups'
  | 'security'
  | 'performance'
  | 'communications'
  | 'events'
  | 'whitelist'
  | 'resources'
  | 'housing'
  | 'dev-tools';
