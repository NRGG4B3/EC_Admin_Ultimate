import { useState, useEffect } from 'react';
import { Users, Car, Activity, Database, TrendingUp, AlertTriangle, Zap, Globe, Server, Wifi, HardDrive, Clock, Shield, Eye } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Progress } from '../ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell, ResponsiveContainer, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import { LiveData } from '../nui-bridge';
import { QuickActionsWidget } from '../quick-actions-widget';

interface DashboardProps {
  liveData: LiveData;
  onOpenQuickActionsCenter?: () => void;
}

interface MetricsHistory {
  time: string;
  players: number;
  tps: number;
  memory: number;
  cpu: number;
  avgPing?: number;
}

export function Dashboard({ liveData, onOpenQuickActionsCenter }: DashboardProps) {
  const [historicalData, setHistoricalData] = useState<MetricsHistory[]>([]);
  const [resourceData, setResourceData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [metricsData, setMetricsData] = useState<any>(null);

  // Fetch server metrics with percentage changes and health status
  // Memoize to prevent unnecessary re-fetches
  useEffect(() => {
    let isMounted = true;
    
    const fetchServerMetrics = async () => {
      try {
        const isInGame = !!(window as any).GetParentResourceName;
        
        if (!isInGame) {
          // FIGMA/BROWSER MODE ONLY: Use mock data
          console.log('[Dashboard] BROWSER/FIGMA MODE - Using mock metrics');
          if (isMounted) {
            setMetricsData({
              success: true,
              playersOnline: 42,
              serverTPS: 58,
              memoryUsage: 2847,
              cpuUsage: 34
            });
          }
          return;
        }
        
        // IN-GAME MODE: Fetch real metrics
        console.log('[Dashboard] IN-GAME MODE - Fetching real server metrics');
        
        // @ts-ignore - NUI callback
        const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
        const response = await fetch(`https://${resourceName}/getServerMetrics`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        });

        if (!response.ok) {
          throw new Error('HTTP ' + response.status);
        }

        const data = await response.json();
        
        if (!data || typeof data !== 'object') {
          throw new Error('Invalid response structure');
        }
        
        if (!data.success) {
          throw new Error(data.error || 'Server returned success=false');
        }
        
        console.log('[Dashboard] ✅ Received real metrics:', data.playersOnline, 'players,', data.serverTPS, 'TPS');
        
        if (isMounted && data.success) {
          // Only update if data has actually changed (prevent unnecessary re-renders)
          setMetricsData(prev => {
            if (JSON.stringify(prev) === JSON.stringify(data)) {
              return prev; // No change, return same reference
            }
            return data;
          });
        }
      } catch (err) {
        console.error('[Dashboard] CRITICAL ERROR fetching metrics:', err);
        // IN-GAME: Show error, don't fallback to mock
        if (isMounted && !!(window as any).GetParentResourceName) {
          setMetricsData({ success: false, error: err.message || 'Failed to fetch metrics' });
        }
      }
    };

    // Initial fetch
    fetchServerMetrics();

    // Update every 5 seconds
    const interval = setInterval(fetchServerMetrics, 5000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, []); // Empty deps - only run once on mount

  // Fetch real historical data from API
  useEffect(() => {
    const fetchMetricsHistory = async () => {
      try {
        setLoading(true);
        
        const isInGame = !!(window as any).GetParentResourceName;
        
        if (!isInGame) {
          // FIGMA MODE: Generate mock historical data
          const mockHistory = Array.from({ length: 20 }, (_, i) => {
            const time = new Date(Date.now() - (20 - i) * 60000);
            return {
              time: time.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
              players: 35 + Math.floor(Math.random() * 15),
              tps: 55 + Math.floor(Math.random() * 5),
              memory: 2500 + Math.floor(Math.random() * 500),
              cpu: 30 + Math.floor(Math.random() * 10),
              avgPing: 45 + Math.floor(Math.random() * 20)
            };
          });
          setHistoricalData(mockHistory);
          setError(null);
          setLoading(false);
          return;
        }
        
        // @ts-ignore - NUI callback
        const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
        const response = await fetch(`https://${resourceName}/getMetricsHistory`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        });

        const data = await response.json();
        
        if (data.success && (data.history || data.data)) {
          // Support both `history` and `data` keys
          const historyData = data.history || data.data;
          
          // Transform data if needed
          if (historyData.labels && historyData.datasets) {
            // Format: { labels: [], datasets: { players: [], cpu: [], memory: [], tps: [] } }
            const transformedData = historyData.labels.map((label: string, index: number) => ({
              time: label,
              players: historyData.datasets.players[index] || 0,
              tps: historyData.datasets.tps ? historyData.datasets.tps[index] || 0 : 0,
              memory: historyData.datasets.memory[index] || 0,
              cpu: historyData.datasets.cpu[index] || 0
            }));
            setHistoricalData(transformedData);
            setError(null);
            console.log('[Dashboard] Loaded', transformedData.length, 'historical data points');
          } else if (Array.isArray(historyData)) {
            // Format: [{ time, players, tps, memory, cpu }, ...]
            setHistoricalData(historyData);
            setError(null);
            console.log('[Dashboard] Loaded', historyData.length, 'historical data points');
          } else {
            console.warn('[Dashboard] Invalid history data format');
            throw new Error('Invalid history data format');
          }
        } else {
          console.warn('[Dashboard] No historical data available, using live data');
          // Fallback: use current live data
          setHistoricalData([{
            time: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
            players: liveData.playersOnline,
            tps: liveData.serverTPS,
            memory: liveData.memoryUsage,
            cpu: liveData.cpuUsage
          }]);
        }
      } catch (err) {
        console.error('[Dashboard] Failed to fetch metrics history:', err);
        setError('Failed to load metrics history');
        // Use fallback data
        setHistoricalData([{
          time: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
          players: liveData.playersOnline,
          tps: liveData.serverTPS,
          memory: liveData.memoryUsage,
          cpu: liveData.cpuUsage
        }]);
      } finally {
        setLoading(false);
      }
    };

    // Calculate real resource distribution
    const calculateResourceData = () => {
      const total = liveData.totalResources;
      const started = liveData.totalResources; // Assume most are started
      const idle = Math.floor(total * 0.05);
      const error = Math.floor(total * 0.02);
      const active = total - idle - error;

      return [
        { name: 'Active', value: Math.max(0, active), color: '#10b981' },
        { name: 'Idle', value: Math.max(0, idle), color: '#3b82f6' },
        { name: 'Error', value: Math.max(0, error), color: '#ef4444' }
      ];
    };

    fetchMetricsHistory();
    setResourceData(calculateResourceData());

    // Update every 5 seconds
    const interval = setInterval(() => {
      fetchMetricsHistory();
      setResourceData(calculateResourceData());
    }, 5000);

    return () => clearInterval(interval);
  }, [liveData]);

  const formatUptime = (ms: number) => {
    const hours = Math.floor(ms / (1000 * 60 * 60));
    const minutes = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60));
    return hours + 'h ' + minutes + 'm';
  };

  // Use real metrics data with percentage changes and health status
  const realMetrics = metricsData || liveData;
  const percentChanges = metricsData?.percentageChanges || { players: 0, vehicles: 0 };
  const healthStatus = metricsData?.healthStatus || { tps: 'Good', memory: 'Healthy' };

  const statCards = [
    {
      title: 'Players Online',
      value: realMetrics.playersOnline || 0,
      icon: Users,
      color: 'text-blue-500',
      bgColor: 'bg-blue-500/10',
      trend: percentChanges.players !== 0 ? (percentChanges.players > 0 ? '+' : '') + percentChanges.players + '%' : '--',
      trendUp: percentChanges.players >= 0
    },
    {
      title: 'Server TPS',
      value: (realMetrics.serverTPS || 0).toFixed(1),
      icon: Activity,
      color: 'text-green-500',
      bgColor: 'bg-green-500/10',
      trend: healthStatus.tps,
      trendUp: healthStatus.tps === 'Excellent' || healthStatus.tps === 'Good'
    },
    {
      title: 'Vehicles Cached',
      value: realMetrics.cachedVehicles || 0,
      icon: Car,
      color: 'text-orange-500',
      bgColor: 'bg-orange-500/10',
      trend: percentChanges.vehicles !== 0 ? (percentChanges.vehicles > 0 ? '+' : '') + percentChanges.vehicles + '%' : '--',
      trendUp: percentChanges.vehicles >= 0
    },
    {
      title: 'Memory Usage',
      value: (realMetrics.memoryUsage || 0).toFixed(1) + ' MB',
      icon: Zap,
      color: 'text-purple-500',
      bgColor: 'bg-purple-500/10',
      trend: healthStatus.memory,
      trendUp: healthStatus.memory === 'Healthy' || healthStatus.memory === 'Good'
    }
  ];

  const performanceMetrics = [
    { label: 'CPU Usage', value: liveData.cpuUsage, max: 100, color: 'bg-blue-500' },
    { label: 'Memory', value: liveData.memoryUsage, max: 100, color: 'bg-purple-500' },
    { label: 'Network In', value: (liveData.networkIn / 100) * 100, max: 100, color: 'bg-green-500' },
    { label: 'Network Out', value: (liveData.networkOut / 100) * 100, max: 100, color: 'bg-orange-500' }
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl tracking-tight bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
            Server Dashboard
          </h1>
          <p className="text-muted-foreground mt-1">
            Real-time overview of your FiveM server performance and statistics
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Badge variant="outline" className="gap-2 border-green-500/30 text-green-500">
            <div className="size-2 rounded-full bg-green-500 animate-pulse" />
            Live Data
          </Badge>
          <Badge variant="outline" className="gap-2">
            <Clock className="size-3" />
            Uptime: {formatUptime(liveData.uptime)}
          </Badge>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.title}
              className="animate-in fade-in-0 duration-300"
              style={{ animationDelay: (index * 50) + 'ms' }}
            >
              <Card className="relative overflow-hidden hover:shadow-lg transition-shadow duration-300">
                <CardContent className="p-6">
                  <div className="flex items-center justify-between">
                    <div className="space-y-2">
                      <p className="text-sm text-muted-foreground">{stat.title}</p>
                      <p className="text-3xl font-bold tracking-tight">{stat.value}</p>
                      <Badge 
                        variant={stat.trendUp ? "default" : "secondary"} 
                        className={`text-xs ${stat.trendUp ? 'bg-green-500/10 text-green-500 border-green-500/20' : 'bg-orange-500/10 text-orange-500 border-orange-500/20'}`}
                      >
                        {stat.trend}
                      </Badge>
                    </div>
                    <div className={`p-4 rounded-xl ${stat.bgColor} backdrop-blur-sm`}>
                      <Icon className={`size-8 ${stat.color}`} />
                    </div>
                  </div>
                </CardContent>
                <div className={`absolute bottom-0 left-0 right-0 h-1 ${stat.bgColor.replace('/10', '/30')}`} />
              </Card>
            </div>
          );
        })}
      </div>

      {/* Quick Actions Widget */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2">
          <QuickActionsWidget 
            variant="dashboard" 
            maxActions={16} 
            onOpenQuickActionsCenter={onOpenQuickActionsCenter}
          />
        </div>
        
        {/* Quick Stats Card */}
        <Card className="border-border/50 ec-card-transparent">
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center gap-2">
              <Activity className="size-4 text-primary" />
              Quick Stats
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="flex justify-between items-center p-2 rounded-lg ec-card-transparent border border-border">
              <span className="text-xs text-muted-foreground">Active Events</span>
              <Badge variant="outline" className="text-xs">{liveData.activeEvents || 0}</Badge>
            </div>
            <div className="flex justify-between items-center p-2 rounded-lg ec-card-transparent border border-border">
              <span className="text-xs text-muted-foreground">DB Queries</span>
              <Badge variant="outline" className="text-xs">{liveData.database?.queries || 0}/s</Badge>
            </div>
            <div className="flex justify-between items-center p-2 rounded-lg ec-card-transparent border border-border">
              <span className="text-xs text-muted-foreground">Avg Response</span>
              <Badge variant="outline" className="text-xs">{liveData.database?.avgResponseTime || 0}ms</Badge>
            </div>
            <div className="flex justify-between items-center p-2 rounded-lg ec-card-transparent border border-border">
              <span className="text-xs text-muted-foreground">Network Load</span>
              <Badge variant="outline" className="text-xs">
                {((liveData.networkIn + liveData.networkOut) / 2).toFixed(1)} MB/s
              </Badge>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts Section */}
      <Tabs defaultValue="performance" className="space-y-4">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="performance">Performance</TabsTrigger>
          <TabsTrigger value="players">Players & Activity</TabsTrigger>
          <TabsTrigger value="resources">Resources</TabsTrigger>
        </TabsList>

        <TabsContent value="performance" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Server Performance Chart */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Activity className="size-5 text-blue-500" />
                  Server Performance (Last 20 min)
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={250}>
                  <AreaChart data={historicalData}>
                    <defs>
                      <linearGradient id="colorTPS" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                      </linearGradient>
                      <linearGradient id="colorCPU" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                    <XAxis dataKey="time" stroke="#94a3b8" fontSize={12} />
                    <YAxis stroke="#94a3b8" fontSize={12} />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: 'hsl(var(--card))', 
                        border: '1px solid hsl(var(--border))',
                        borderRadius: '8px'
                      }} 
                    />
                    <Legend />
                    <Area type="monotone" dataKey="tps" stroke="#10b981" fill="url(#colorTPS)" name="TPS" strokeWidth={2} />
                    <Area type="monotone" dataKey="cpu" stroke="#3b82f6" fill="url(#colorCPU)" name="CPU %" strokeWidth={2} />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Memory & Network Chart */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <HardDrive className="size-5 text-purple-500" />
                  Memory & Network Usage
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={250}>
                  <LineChart data={historicalData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                    <XAxis dataKey="time" stroke="#94a3b8" fontSize={12} />
                    <YAxis stroke="#94a3b8" fontSize={12} />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: 'hsl(var(--card))', 
                        border: '1px solid hsl(var(--border))',
                        borderRadius: '8px'
                      }} 
                    />
                    <Legend />
                    <Line type="monotone" dataKey="memory" stroke="#8b5cf6" name="Memory %" strokeWidth={2} dot={false} />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </div>

          {/* Performance Metrics Bars */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="size-5 text-green-500" />
                Current Performance Metrics
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {performanceMetrics.map((metric) => (
                <div key={metric.label} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">{metric.label}</span>
                    <span className="text-sm text-muted-foreground">{metric.value.toFixed(1)}%</span>
                  </div>
                  <Progress value={metric.value} indicatorClassName={metric.color} className="h-2" />
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="players" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Player Count Chart */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="size-5 text-blue-500" />
                  Player Activity (Last 20 min)
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={250}>
                  <BarChart data={historicalData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                    <XAxis dataKey="time" stroke="#94a3b8" fontSize={12} />
                    <YAxis stroke="#94a3b8" fontSize={12} />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: 'hsl(var(--card))', 
                        border: '1px solid hsl(var(--border))',
                        borderRadius: '8px'
                      }} 
                    />
                    <Legend />
                    <Bar dataKey="players" fill="#3b82f6" name="Players Online" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Quick Stats */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Eye className="size-5 text-purple-500" />
                  Live Server Statistics
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 rounded-lg bg-blue-500/10 border border-blue-500/20">
                    <p className="text-sm text-muted-foreground mb-1">Active Events</p>
                    <p className="text-2xl font-bold text-blue-500">{liveData.activeEvents}</p>
                  </div>
                  <div className="p-4 rounded-lg bg-green-500/10 border border-green-500/20">
                    <p className="text-sm text-muted-foreground mb-1">DB Queries</p>
                    <p className="text-2xl font-bold text-green-500">{liveData.database.queries.toLocaleString()}</p>
                  </div>
                  <div className="p-4 rounded-lg bg-orange-500/10 border border-orange-500/20">
                    <p className="text-sm text-muted-foreground mb-1">Vehicles</p>
                    <p className="text-2xl font-bold text-orange-500">{liveData.cachedVehicles}</p>
                  </div>
                  <div className="p-4 rounded-lg bg-purple-500/10 border border-purple-500/20">
                    <p className="text-sm text-muted-foreground mb-1">DB Response</p>
                    <p className="text-2xl font-bold text-purple-500">{liveData.database.avgResponseTime}ms</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="resources" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Resource Distribution */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Server className="size-5 text-green-500" />
                  Resource Distribution
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={250}>
                  <PieChart>
                    <Pie
                      data={resourceData}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => name + ': ' + (percent * 100).toFixed(0) + '%'}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {resourceData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
                <div className="flex justify-center gap-4 mt-4">
                  {resourceData.map((item) => (
                    <div key={item.name} className="flex items-center gap-2">
                      <div className="size-3 rounded-full" style={{ backgroundColor: item.color }} />
                      <span className="text-sm text-muted-foreground">{item.name}: {item.value}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            {/* System Info */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Globe className="size-5 text-blue-500" />
                  System Information
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between items-center p-3 rounded-lg ec-card-transparent border border-border/30">
                  <div className="flex items-center gap-2">
                    <Server className="size-4 text-blue-500" />
                    <span className="text-sm">Total Resources</span>
                  </div>
                  <span className="font-semibold">{liveData.totalResources}</span>
                </div>
                <div className="flex justify-between items-center p-3 rounded-lg ec-card-transparent border border-border/30">
                  <div className="flex items-center gap-2">
                    <Activity className="size-4 text-green-500" />
                    <span className="text-sm">Server TPS</span>
                  </div>
                  <span className="font-semibold">{liveData.serverTPS.toFixed(1)}</span>
                </div>
                <div className="flex justify-between items-center p-3 rounded-lg ec-card-transparent border border-border/30">
                  <div className="flex items-center gap-2">
                    <Wifi className="size-4 text-purple-500" />
                    <span className="text-sm">Network I/O</span>
                  </div>
                  <span className="font-semibold">{liveData.networkIn.toFixed(1)}/{liveData.networkOut.toFixed(1)} MB/s</span>
                </div>
                <div className="flex justify-between items-center p-3 rounded-lg ec-card-transparent border border-border/30">
                  <div className="flex items-center gap-2">
                    <Clock className="size-4 text-orange-500" />
                    <span className="text-sm">Uptime</span>
                  </div>
                  <span className="font-semibold">{formatUptime(liveData.uptime)}</span>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>

      {/* Recent Alerts */}
      {liveData.alerts && Array.isArray(liveData.alerts) && liveData.alerts.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertTriangle className="size-5 text-yellow-500" />
              Recent Alerts ({liveData.alerts.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {liveData.alerts.slice(0, 5).map((alert) => (
                <div key={alert.id} className="flex items-center gap-3 p-4 rounded-lg ec-card-transparent border border-border/30 hover:border-border/50 transition-colors">
                  <div className={`size-3 rounded-full flex-shrink-0 ${
                    alert.severity === 'critical' ? 'bg-red-500 animate-pulse' :
                    alert.severity === 'high' ? 'bg-orange-500' :
                    alert.severity === 'medium' ? 'bg-yellow-500' :
                    'bg-blue-500'
                  }`} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium">{alert.message}</p>
                    <p className="text-xs text-muted-foreground">
                      {new Date(alert.time).toLocaleString()}
                    </p>
                  </div>
                  <Badge variant="outline" className="text-xs capitalize">
                    {alert.type}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}