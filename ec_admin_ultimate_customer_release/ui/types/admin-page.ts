// Shared interface for admin page components
export interface AdminPageProps {
  liveData: {
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
    alerts: Array<{ id: string; type: string; message: string; time: number; }>;
  };
}