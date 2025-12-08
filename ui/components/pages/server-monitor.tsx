import { useState, useEffect, useMemo, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { ScrollArea } from '../ui/scroll-area';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Progress } from '../ui/progress';
import { 
  Activity, Server, Cpu, HardDrive, Network, Database, Map, Layers,
  RefreshCw, Download, Search, TrendingUp, TrendingDown, AlertTriangle,
  CheckCircle, XCircle, Zap, BarChart3, Users, MapPin, Eye
} from 'lucide-react';
import { PlayerMarker } from '../player-marker';
import { toastSuccess, toastError } from '../../lib/toast';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, AreaChart, Area, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar } from 'recharts';

interface ServerMonitorPageProps {
  liveData: any;
}

interface Resource {
  id: string;
  name: string;
  status: 'running' | 'stopped' | 'error';
  cpu: number;
  memory: number;
  threads: number;
  uptime: number;
}

interface NetworkMetrics {
  playersOnline: number;
  peakToday: number;
  avgPing: number;
  bandwidth: {
    in: number;
    out: number;
  };
  connections: number;
}

interface DatabaseMetrics {
  queries: number;
  avgQueryTime: number;
  slowQueries: number;
  connections: number;
  size: number;
  sizeFormatted: string;
}

interface PlayerPosition {
  id: string;
  name: string;
  coords: { x: number; y: number; z: number };
  normalizedX?: number;
  normalizedY?: number;
  heading?: number;
  vehicle?: string;
  job?: string;
  health?: number;
  armor?: number;
  identifier?: string;
}

export function ServerMonitorPage({ liveData }: ServerMonitorPageProps) {
  const [activeTab, setActiveTab] = useState('overview');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshTrigger, setRefreshTrigger] = useState(0); // Trigger for manual refresh

  // Real-time data
  const [resources, setResources] = useState<Resource[]>([]);
  const [networkMetrics, setNetworkMetrics] = useState<NetworkMetrics>({
    playersOnline: 0,
    peakToday: 0,
    avgPing: 0,
    bandwidth: { in: 0, out: 0 },
    connections: 0
  });
  const [databaseMetrics, setDatabaseMetrics] = useState<DatabaseMetrics>({
    queries: 0,
    avgQueryTime: 0,
    slowQueries: 0,
    connections: 0,
    size: 0,
    sizeFormatted: '0 MB'
  });
  const [playerPositions, setPlayerPositions] = useState<PlayerPosition[]>([]);
  const [serverMetrics, setServerMetrics] = useState({
    cpu: 0,
    memory: 0,
    tps: 0,
    uptime: 0
  });
  const [metricsHistory, setMetricsHistory] = useState<any[]>([]);

  // Hash tracking
  const lastResourcesHashRef = useRef<string>('');
  const lastPositionsHashRef = useRef<string>('');

  // Fetch real data
  useEffect(() => {
    let isMounted = true;
    const controller = new AbortController();

    const fetchAllData = async () => {
      setIsLoading(true);

      const isInGame = !!(window as any).GetParentResourceName;
      
      try {
        // Fetch all data in parallel based on active tab
        const promises: Promise<any>[] = [];

        if (activeTab === 'overview') {
          promises.push(
            // Server Metrics
            (async () => {
              try {
                if (!isInGame) {
                  return {
                    type: 'serverMetrics',
                    data: {
                      players: 42,
                      tps: 58.4,
                      memory: 2847,
                      cpu: 34,
                      uptime: Date.now() - (7 * 24 * 60 * 60 * 1000)
                    },
                    history: Array.from({ length: 20 }, (_, i) => ({
                      time: new Date(Date.now() - (20 - i) * 60000).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
                      tps: 55 + Math.floor(Math.random() * 5),
                      memory: 2500 + Math.floor(Math.random() * 500),
                      cpu: 30 + Math.floor(Math.random() * 10)
                    }))
                  };
                }
                
                const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'ec_admin_ultimate'}/getServerMetrics`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({ includeHistory: true })
                });
                const result = await response.json();
                return { type: 'serverMetrics', ...result };
              } catch (err) {
                console.error('[ServerMonitor] Failed to fetch server metrics:', err);
                return { type: 'serverMetrics', success: false };
              }
            })(),
            
            // Network Metrics
            (async () => {
              try {
                if (!isInGame) {
                  return {
                    type: 'networkMetrics',
                    success: true,
                    metrics: {
                      playersOnline: 42,
                      peakToday: 58,
                      avgPing: 47,
                      bandwidth: { in: 12.4, out: 8.7 },
                      connections: 42
                    }
                  };
                }
                
                const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'ec_admin_ultimate'}/getNetworkMetrics`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({})
                });
                const result = await response.json();
                return { type: 'networkMetrics', ...result };
              } catch (err) {
                console.error('[ServerMonitor] Failed to fetch network metrics:', err);
                return { type: 'networkMetrics', success: false };
              }
            })()
          );
        } else if (activeTab === 'resources') {
          promises.push(
            (async () => {
              try {
                if (!isInGame) {
                  // Mock data for browser/Figma preview
                  return {
                    type: 'resources',
                    success: true,
                    resources: Array.from({ length: 45 }, (_, i) => ({
                      id: `resource_${i}`,
                      name: ['ec_admin_ultimate', 'qb-core', 'qb-inventory', 'qb-vehicleshop', 'qb-banking', 
                             'qb-garages', 'qb-apartments', 'qb-policejob', 'qb-ambulancejob', 'qb-radialmenu',
                             'oxmysql', 'ox_lib', 'ox_inventory', 'ox_target', 'interact-sound',
                             'screenshot-basic', 'mythic_notify', 'pma-voice', 'saltychat', 'tokovoip',
                             'bob74_ipl', 'weathersync', 'dpemotes', 'scully_emotemenu', 'rpemotes',
                             'progressbar', 'memorygame', 'lockpick', 'safecracker', 'hacking',
                             'vehiclekeys', 'fuel', 'carwash', 'tunerchip', 'racing',
                             'phone', 'houses', 'multicharacter', 'spawn-selector', 'loadingscreen',
                             'scoreboard', 'chat', 'nui_doorlock', 'ql-menu', 'advancedparking'][i] || `resource_${i}`,
                      status: i < 40 ? 'running' : (i < 43 ? 'stopped' : 'error') as 'running' | 'stopped' | 'error',
                      cpu: Math.random() * 5,
                      memory: 10 + Math.random() * 100,
                      threads: Math.floor(Math.random() * 5) + 1,
                      uptime: 3600 * 24 * 7 + Math.random() * 10000
                    }))
                  };
                }
                
                const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'ec_admin_ultimate'}/getResources`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({})
                });
                const result = await response.json();
                return { type: 'resources', ...result };
              } catch (err) {
                console.error('[ServerMonitor] Failed to fetch resources:', err);
                return { type: 'resources', success: false };
              }
            })()
          );
        } else if (activeTab === 'database') {
          promises.push(
            (async () => {
              try {
                if (!isInGame) {
                  // Mock data for browser/Figma preview
                  return {
                    type: 'databaseMetrics',
                    success: true,
                    metrics: {
                      queries: 127,
                      avgQueryTime: 12,
                      slowQueries: 3,
                      connections: 24,
                      size: 1847,
                      sizeFormatted: '1.8 GB'
                    }
                  };
                }
                
                const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'ec_admin_ultimate'}/getDatabaseMetrics`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({})
                });
                const result = await response.json();
                return { type: 'databaseMetrics', ...result };
              } catch (err) {
                console.error('[ServerMonitor] Failed to fetch database metrics:', err);
                return { type: 'databaseMetrics', success: false };
              }
            })()
          );
        } else if (activeTab === 'live-map') {
          promises.push(
            (async () => {
              try {
                if (!isInGame) {
                  // Mock data for browser/Figma preview with normalized coordinates
                  return {
                    type: 'playerPositions',
                    success: true,
                    positions: Array.from({ length: 12 }, (_, i) => {
                      // Generate realistic GTA coordinates
                      const x = -2000 + Math.random() * 4000;
                      const y = -2000 + Math.random() * 4000;
                      const minX = -4000, maxX = 4000;
                      const minY = -4000, maxY = 4000;
                      const normalizedX = Math.max(0, Math.min(1, (x - minX) / (maxX - minX)));
                      const normalizedY = Math.max(0, Math.min(1, (y - minY) / (maxY - minY)));
                      
                      return {
                        id: `player_${i}`,
                        name: ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Williams', 'Tom Brown',
                               'Emily Davis', 'Chris Wilson', 'Lisa Anderson', 'David Martinez', 'Anna Garcia',
                               'James Rodriguez', 'Maria Lopez'][i] || `Player ${i}`,
                        coords: { x, y, z: 20 + Math.random() * 10 },
                        normalizedX,
                        normalizedY,
                        heading: Math.random() * 360,
                        vehicle: i % 3 === 0 ? ['Police Cruiser', 'Ambulance', 'Fire Truck', 'Taxi', 'Bus'][i % 5] : undefined,
                        job: ['Police', 'EMS', 'Mechanic', 'Taxi', 'Civilian'][i % 5],
                        health: 80 + Math.random() * 20,
                        armor: i % 2 === 0 ? Math.random() * 100 : 0,
                        identifier: `license:mock_${i}`
                      };
                    })
                  };
                }
                
                const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'ec_admin_ultimate'}/getPlayerPositions`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({})
                });
                const result = await response.json();
                return { type: 'playerPositions', ...result };
              } catch (err) {
                console.error('[ServerMonitor] Failed to fetch player positions:', err);
                return { type: 'playerPositions', success: false };
              }
            })()
          );
        }

        // Wait for all promises to complete
  const results = await Promise.all(promises);
        
        if (!isMounted) return;

        // Process results
        results.forEach(result => {
          if (result.type === 'serverMetrics' && result.success !== false) {
            if (result.current || result.data) {
              setServerMetrics(result.current || result.data);
            }
            if (result.history) {
              setMetricsHistory(result.history);
            }
          } else if (result.type === 'networkMetrics' && result.success && result.metrics) {
            setNetworkMetrics(result.metrics);
          } else if (result.type === 'resources' && result.success && result.resources) {
            const resourcesHash = JSON.stringify(result.resources.map((r: any) => r.name));
            if (resourcesHash !== lastResourcesHashRef.current) {
              lastResourcesHashRef.current = resourcesHash;
              setResources(result.resources);
            }
          } else if (result.type === 'databaseMetrics' && result.success && result.metrics) {
            setDatabaseMetrics(result.metrics);
          } else if (result.type === 'playerPositions' && result.success && result.positions) {
            const positionsHash = JSON.stringify(result.positions.map((p: any) => p.id));
            if (positionsHash !== lastPositionsHashRef.current) {
              lastPositionsHashRef.current = positionsHash;
              setPlayerPositions(result.positions);
            }
          }
        });

      } catch (err) {
        console.error('[ServerMonitor] Failed to fetch data:', err);
      } finally {
        if (isMounted) setIsLoading(false);
      }
    };

    // Initial fetch
    fetchAllData();

    // Auto-refresh only for currently active tab, with sensible cadence
    // Live map refreshes every 1.5 seconds for real-time tracking
    const intervalMs = activeTab === 'overview' ? 5000 : activeTab === 'live-map' ? 1500 : 10000;
    const interval = setInterval(() => {
      if (!isMounted) return;
      fetchAllData();
    }, intervalMs);

    // Pause updates when tab becomes hidden to reduce unnecessary work
    const handleVisibility = () => {
      if (document.hidden) {
        clearInterval(interval);
      }
    };
    document.addEventListener('visibilitychange', handleVisibility);

    return () => {
      isMounted = false;
      controller.abort();
      clearInterval(interval);
      document.removeEventListener('visibilitychange', handleVisibility);
    };
  }, [activeTab, refreshTrigger]);

  // Statistics
  const stats = useMemo(() => {
    const runningResources = resources.filter(r => r.status === 'running').length;
    const errorResources = resources.filter(r => r.status === 'error').length;
    const totalCpu = resources.reduce((sum, r) => sum + r.cpu, 0);
    const totalMemory = resources.reduce((sum, r) => sum + r.memory, 0);

    return {
      runningResources,
      errorResources,
      totalResources: resources.length,
      totalCpu: totalCpu.toFixed(1),
      totalMemory: totalMemory.toFixed(0)
    };
  }, [resources]);

  // Filtered resources
  const filteredResources = useMemo(() => {
    if (!searchTerm) return resources;

    return resources.filter(r =>
      r.name.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [resources, searchTerm]);

  // Manual refresh handler
  const handleRefresh = () => {
    setRefreshTrigger(prev => prev + 1); // Increment refresh trigger to re-run useEffect
    toastSuccess({
      title: 'Refreshing Data',
      description: 'Server monitor data is being updated...'
    });
  };

  const handleRestartResource = async (resourceName: string) => {
    try {
      await fetch('https://ec_admin_ultimate/restartResource', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ resource: resourceName })
      });

      toastSuccess({
        title: 'Resource Restarted',
        description: resourceName + ' has been restarted'
      });
    } catch (error) {
      toastError({
        title: 'Restart Failed',
        description: 'Failed to restart resource'
      });
    }
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return days + 'd ' + hours + 'h ' + minutes + 'm';
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Server className="size-12 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg">Loading Server Monitor...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl tracking-tight">
            <span className="bg-gradient-to-r from-green-600 to-teal-600 dark:from-green-400 dark:to-teal-400 bg-clip-text text-transparent">
              Server Monitor
            </span>
          </h1>
          <p className="text-muted-foreground mt-1">
            Real-time server metrics, resources, and live map
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={handleRefresh}>
            <RefreshCw className="size-4 mr-2" />
            Refresh
          </Button>
          <Button variant="outline" size="sm">
            <Download className="size-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-500/10 rounded-lg">
                <Activity className="size-5 text-green-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Server TPS</p>
                <p className="text-2xl">{serverMetrics.tps}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-500/10 rounded-lg">
                <Users className="size-5 text-blue-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Online</p>
                <p className="text-2xl">{networkMetrics.playersOnline}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-500/10 rounded-lg">
                <Cpu className="size-5 text-purple-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">CPU</p>
                <p className="text-2xl">{serverMetrics.cpu}%</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-500/10 rounded-lg">
                <HardDrive className="size-5 text-cyan-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Memory</p>
                <p className="text-2xl">{serverMetrics.memory}%</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-500/10 rounded-lg">
                <Layers className="size-5 text-orange-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Resources</p>
                <p className="text-2xl">{stats.runningResources}/{stats.totalResources}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-yellow-500/10 rounded-lg">
                <Database className="size-5 text-yellow-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">DB Size</p>
                <p className="text-2xl">{databaseMetrics.sizeFormatted}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="overview">
            <BarChart3 className="size-4 mr-2" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="resources">
            <Layers className="size-4 mr-2" />
            Resources
          </TabsTrigger>
          <TabsTrigger value="network">
            <Network className="size-4 mr-2" />
            Network
          </TabsTrigger>
          <TabsTrigger value="database">
            <Database className="size-4 mr-2" />
            Database
          </TabsTrigger>
          <TabsTrigger value="live-map">
            <Map className="size-4 mr-2" />
            Live Map
          </TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card>
              <CardHeader>
                <CardTitle>Server Performance</CardTitle>
                <CardDescription>Real-time metrics over time</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={metricsHistory}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                      <XAxis dataKey="time" stroke="#64748b" fontSize={12} />
                      <YAxis stroke="#64748b" fontSize={12} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'hsl(var(--card))',
                          border: '1px solid hsl(var(--border))',
                          borderRadius: '8px'
                        }}
                      />
                      <Legend />
                      <Line type="monotone" dataKey="cpu" stroke="#8b5cf6" strokeWidth={2} name="CPU %" />
                      <Line type="monotone" dataKey="memory" stroke="#3b82f6" strokeWidth={2} name="Memory %" />
                      <Line type="monotone" dataKey="tps" stroke="#10b981" strokeWidth={2} name="TPS" />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Resource Usage</CardTitle>
                <CardDescription>Top resource consumers</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {resources
                    .sort((a, b) => b.cpu - a.cpu)
                    .slice(0, 5)
                    .map((resource, index) => (
                      <div key={resource.name}>
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center gap-2">
                            <div className="size-8 rounded-full bg-primary/10 flex items-center justify-center">
                              <span className="text-sm font-medium">{index + 1}</span>
                            </div>
                            <span className="font-medium">{resource.name}</span>
                          </div>
                          <span className="text-sm text-muted-foreground">{resource.cpu.toFixed(2)}%</span>
                        </div>
                        <Progress value={resource.cpu} />
                      </div>
                    ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Server Information</CardTitle>
                <CardDescription>Current server status</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Uptime</span>
                  <span className="text-sm font-medium">{formatUptime(serverMetrics.uptime)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Players Online</span>
                  <span className="text-sm font-medium">{networkMetrics.playersOnline} / {networkMetrics.peakToday}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Average Ping</span>
                  <span className="text-sm font-medium">{networkMetrics.avgPing}ms</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Active Resources</span>
                  <span className="text-sm font-medium">{stats.runningResources}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Database Queries</span>
                  <span className="text-sm font-medium">{databaseMetrics.queries}/s</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Network Traffic</CardTitle>
                <CardDescription>Bandwidth usage</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm text-muted-foreground">Incoming</span>
                    <span className="text-sm font-medium">{networkMetrics.bandwidth.in.toFixed(2)} MB/s</span>
                  </div>
                  <Progress value={(networkMetrics.bandwidth.in / 10) * 100} />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm text-muted-foreground">Outgoing</span>
                    <span className="text-sm font-medium">{networkMetrics.bandwidth.out.toFixed(2)} MB/s</span>
                  </div>
                  <Progress value={(networkMetrics.bandwidth.out / 10) * 100} />
                </div>
                <div className="flex items-center justify-between pt-2">
                  <span className="text-sm text-muted-foreground">Active Connections</span>
                  <span className="text-sm font-medium">{networkMetrics.connections}</span>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Resources Tab */}
        <TabsContent value="resources" className="space-y-4">
          <Card>
            <CardContent className="p-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
                <Input
                  placeholder="Search resources..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Resources</CardTitle>
              <CardDescription>{filteredResources.length} resources loaded</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Resource</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>CPU</TableHead>
                      <TableHead>Memory</TableHead>
                      <TableHead>Threads</TableHead>
                      <TableHead>Uptime</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredResources.map((resource) => (
                      <TableRow key={resource.name}>
                        <TableCell>
                          <span className="font-medium">{resource.name}</span>
                        </TableCell>
                        <TableCell>
                          <Badge variant={
                            resource.status === 'running' ? 'default' :
                            resource.status === 'error' ? 'destructive' : 'secondary'
                          }>
                            {resource.status === 'running' && <CheckCircle className="size-3 mr-1" />}
                            {resource.status === 'error' && <XCircle className="size-3 mr-1" />}
                            {resource.status}
                          </Badge>
                        </TableCell>
                        <TableCell>{resource.cpu.toFixed(2)}%</TableCell>
                        <TableCell>{resource.memory.toFixed(0)} MB</TableCell>
                        <TableCell>{resource.threads}</TableCell>
                        <TableCell>{formatUptime(resource.uptime)}</TableCell>
                        <TableCell>
                          <div className="flex items-center justify-end gap-2">
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleRestartResource(resource.name)}
                            >
                              <RefreshCw className="size-3 mr-1" />
                              Restart
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                {filteredResources.length === 0 && (
                  <div className="text-center py-12 text-muted-foreground">
                    <Layers className="size-12 mx-auto mb-4 opacity-50" />
                    <p className="text-lg">No resources found</p>
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Network Tab */}
        <TabsContent value="network" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card>
              <CardHeader>
                <CardTitle>Network Statistics</CardTitle>
                <CardDescription>Current network metrics</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Players Online</span>
                  <span className="text-sm font-medium">{networkMetrics.playersOnline}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Peak Today</span>
                  <span className="text-sm font-medium">{networkMetrics.peakToday}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Average Ping</span>
                  <span className="text-sm font-medium">{networkMetrics.avgPing}ms</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Active Connections</span>
                  <span className="text-sm font-medium">{networkMetrics.connections}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Bandwidth In</span>
                  <span className="text-sm font-medium">{networkMetrics.bandwidth.in.toFixed(2)} MB/s</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Bandwidth Out</span>
                  <span className="text-sm font-medium">{networkMetrics.bandwidth.out.toFixed(2)} MB/s</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Connection Quality</CardTitle>
                <CardDescription>Player connection distribution</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm">Excellent (&lt;50ms)</span>
                      <Badge variant="default">45%</Badge>
                    </div>
                    <Progress value={45} />
                  </div>
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm">Good (50-100ms)</span>
                      <Badge variant="secondary">30%</Badge>
                    </div>
                    <Progress value={30} />
                  </div>
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm">Fair (100-150ms)</span>
                      <Badge variant="secondary">20%</Badge>
                    </div>
                    <Progress value={20} />
                  </div>
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm">Poor (&gt;150ms)</span>
                      <Badge variant="destructive">5%</Badge>
                    </div>
                    <Progress value={5} />
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Database Tab */}
        <TabsContent value="database" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <Card>
              <CardHeader>
                <CardTitle>Database Metrics</CardTitle>
                <CardDescription>Current database performance</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Queries/Second</span>
                  <span className="text-sm font-medium">{databaseMetrics.queries}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Avg Query Time</span>
                  <span className="text-sm font-medium">{databaseMetrics.avgQueryTime}ms</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Slow Queries</span>
                  <span className="text-sm font-medium">{databaseMetrics.slowQueries}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Connections</span>
                  <span className="text-sm font-medium">{databaseMetrics.connections}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Database Size</span>
                  <span className="text-sm font-medium">{databaseMetrics.sizeFormatted}</span>
                </div>
              </CardContent>
            </Card>

            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle>Query Performance</CardTitle>
                <CardDescription>Database health indicators</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm">Query Efficiency</span>
                    <span className="text-sm font-medium">94%</span>
                  </div>
                  <Progress value={94} />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm">Connection Pool Usage</span>
                    <span className="text-sm font-medium">67%</span>
                  </div>
                  <Progress value={67} />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm">Cache Hit Rate</span>
                    <span className="text-sm font-medium">89%</span>
                  </div>
                  <Progress value={89} />
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Live Map Tab */}
        <TabsContent value="live-map" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <MapPin className="size-5 text-primary animate-pulse" />
                    Live Player Positions
                  </CardTitle>
                  <CardDescription>
                    {playerPositions.length} {playerPositions.length === 1 ? 'player' : 'players'} tracked in real-time
                  </CardDescription>
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setRefreshTrigger(prev => prev + 1)}
                >
                  <RefreshCw className="size-4 mr-2" />
                  Refresh
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="relative rounded-lg overflow-hidden border-2 border-border bg-background" style={{ minHeight: '600px' }}>
                {/* Map Background Image */}
                <img
                  src="/images/map/gta_map.png"
                  alt="GTA V Map"
                  className="absolute inset-0 w-full h-full object-cover opacity-90"
                  style={{ imageRendering: 'high-quality' }}
                  onError={(e) => {
                    // Fallback if image doesn't load
                    (e.target as HTMLImageElement).style.display = 'none';
                    const parent = (e.target as HTMLImageElement).parentElement;
                    if (parent) {
                      parent.style.backgroundColor = 'hsl(var(--muted))';
                    }
                  }}
                />
                
                {/* Map Overlay (for better marker visibility) */}
                <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-background/20 pointer-events-none" />
                
                {/* Player Markers */}
                {playerPositions.length > 0 ? (
                  <div className="absolute inset-0">
                    {playerPositions.map((player) => {
                      // Use normalized coordinates if available, otherwise calculate from raw coords
                      let normalizedX = player.normalizedX;
                      let normalizedY = player.normalizedY;
                      
                      if (normalizedX === undefined || normalizedY === undefined) {
                        // Fallback: normalize from raw coordinates
                        const minX = -4000, maxX = 4000;
                        const minY = -4000, maxY = 4000;
                        normalizedX = Math.max(0, Math.min(1, (player.coords.x - minX) / (maxX - minX)));
                        normalizedY = Math.max(0, Math.min(1, (player.coords.y - minY) / (maxY - minY)));
                      }
                      
                      return (
                        <PlayerMarker
                          key={player.id}
                          player={{
                            ...player,
                            normalizedX,
                            normalizedY
                          }}
                          onClick={(playerId) => {
                            // Handle player click - could open player profile
                            console.log('Clicked player:', playerId);
                          }}
                        />
                      );
                    })}
                  </div>
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center text-muted-foreground">
                    <div className="text-center bg-background/80 backdrop-blur-sm rounded-lg p-8">
                      <Map className="size-16 mx-auto mb-4 opacity-50" />
                      <p className="text-lg font-medium">No Players Online</p>
                      <p className="text-sm mt-2">Player markers will appear here when players join</p>
                    </div>
                  </div>
                )}
                
                {/* Map Legend */}
                <div className="absolute bottom-4 left-4 bg-card/95 backdrop-blur-sm border rounded-lg p-3 shadow-lg">
                  <div className="text-xs font-medium mb-2">Legend</div>
                  <div className="space-y-1 text-xs">
                    <div className="flex items-center gap-2">
                      <MapPin className="size-4 text-blue-500" fill="currentColor" />
                      <span>Player Marker</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="size-3 rounded-full bg-orange-500" />
                      <span>In Vehicle</span>
                    </div>
                    <div className="text-muted-foreground mt-2">
                      Colors indicate job/role
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}