export interface AntiCheatLog {
  id: number;
  playerId: string;
  playerName: string;
  action: string;
  details: string;
  timestamp: string;
  detectionType?: string;
  severity?: string;
}

export interface AntiCheatDetection {
  id: number;
  playerId: string;
  detectionType: string;
  value: string;
  timestamp: string;
}

export interface AntiCheatChartData {
  labels: string[];
  data: number[];
  detectionTypes: string[];
}

export type RecentAntiCheatFlag = AntiCheatLog;
