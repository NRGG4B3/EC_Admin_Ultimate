import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Switch } from '../ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { ScrollArea } from '../ui/scroll-area';
import { Separator } from '../ui/separator';
import { fetchNui } from '../nui-bridge';
import { toastSuccess, toastError } from '../../lib/toast';
import {
  Server,
  Globe,
  Shield,
  Database,
  Users,
  Activity,
  AlertTriangle,
  CheckCircle,
  XCircle,
  BarChart3,
  Settings,
  RefreshCw,
  Power,
  Eye,
  Terminal,
  Zap,
  TrendingUp,
  TrendingDown,
  Clock,
  HardDrive,
  Cpu,
  Network,
  PlayCircle,
  StopCircle,
  PauseCircle,
  Send,
  MessageSquare,
  Radio,
  Trash2,
  Edit,
  ExternalLink,
  Code,
  Wifi,
  WifiOff,
  AlertCircle,
  Lock,
  Unlock,
  Download,
  Upload,
  FileText,
  Search
} from 'lucide-react';

interface APIStatus {
  name: string;
  port: number;
  status: 'online' | 'offline' | 'degraded';
  uptime: number;
  requests: number;
  avgResponseTime: number;
  errorRate: number;
  version?: string;
  lastRestart?: string;
}

interface ConnectedCity {
  id: string;
  name: string;
  ip: string;
  status: 'online' | 'offline';
  players: number;
  maxPlayers: number;
  version: string;
  lastSeen: string;
  framework: string;
  connectedAPIs: string[];
  uptime: number;
  performance: {
    tps: number;
    memoryUsage: number;
    cpuUsage: number;
  };
}

interface GlobalStats {
  totalCities: number;
  totalPlayers: number;
  totalBans: number;
  totalReports: number;
  apiUptime: number;
  totalRequests: number;
  avgResponseTime: number;
  dataProcessed: number;
  storageUsed: number;
  totalAlerts: number;
  activeAlerts: number;
}

export function HostControlPage() {
  const [apis, setApis] = useState<APIStatus[]>([]);
  const [cities, setCities] = useState<ConnectedCity[]>([]);
  const [globalStats, setGlobalStats] = useState<GlobalStats | null>(null);
  const [selectedAPI, setSelectedAPI] = useState<string | null>(null);
  const [selectedCity, setSelectedCity] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');

  // Load host data
  useEffect(() => {
    loadHostData();
    
    // Refresh every 30 seconds
    const interval = setInterval(loadHostData, 30000);
    
    return () => clearInterval(interval);
  }, []);

  const loadHostData = async () => {
    try {
      // Get APIs status
      const apisData = await fetchNui<APIStatus[]>('getAPIsStatus');
      if (apisData) setApis(apisData);

      // Get connected cities
      const citiesData = await fetchNui<ConnectedCity[]>('getConnectedCities');
      if (citiesData) setCities(citiesData);

      // Get global stats
      const statsData = await fetchNui<GlobalStats>('getGlobalStats');
      if (statsData) setGlobalStats(statsData);

      setLoading(false);
    } catch (error) {
      console.error('Failed to load host data:', error);
      setLoading(false);
    }
  };

  const controlAPI = async (apiName: string, action: string, params?: any) => {
    try {
      await fetchNui('controlAPI', { apiName, action, params });
      toastSuccess(`API action initiated: ${action}`);
      setTimeout(loadHostData, 2000); // Refresh after action
    } catch (error) {
      toastError('Failed to control API');
    }
  };

  const executeCityCommand = async (cityId: string, command: string, params?: any) => {
    try {
      await fetchNui('executeCityCommand', { cityId, command, params });
      toastSuccess('City command executed');
    } catch (error) {
      toastError('Failed to execute city command');
    }
  };

  const emergencyStopAPI = async (apiName: string, reason: string) => {
    if (!confirm(`Emergency stop ${apiName}?\nReason: ${reason}\n\nThis will immediately stop the API.`)) {
      return;
    }

    try {
      await fetchNui('emergencyStopAPI', { apiName, reason });
      toastSuccess('Emergency stop initiated');
      setTimeout(loadHostData, 2000);
    } catch (error) {
      toastError('Emergency stop failed');
    }
  };

  const restartAPI = async (apiName: string) => {
    try {
      await fetchNui('restartAPI', { apiName });
      toastSuccess(`Restarting ${apiName}...`);
      setTimeout(loadHostData, 5000);
    } catch (error) {
      toastError('Restart failed');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online': return 'text-green-500';
      case 'offline': return 'text-red-500';
      case 'degraded': return 'text-yellow-500';
      default: return 'text-gray-500';
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'online': return <Badge variant="default" className="bg-green-500">Online</Badge>;
      case 'offline': return <Badge variant="destructive">Offline</Badge>;
      case 'degraded': return <Badge variant="secondary" className="bg-yellow-500">Degraded</Badge>;
      default: return <Badge variant="outline">Unknown</Badge>;
    }
  };

  const filteredAPIs = apis.filter(api => {
    const matchesSearch = api.name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || api.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  const filteredCities = cities.filter(city => {
    const matchesSearch = city.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          city.id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || city.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-center">
          <RefreshCw className="size-8 animate-spin mx-auto mb-4 text-primary" />
          <p className="text-muted-foreground">Loading host control data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Host Control</h1>
          <p className="text-muted-foreground">NRG API Suite - Full Control Panel</p>
        </div>
        <Button onClick={loadHostData} variant="outline" className="gap-2">
          <RefreshCw className="size-4" />
          Refresh All
        </Button>
      </div>

      {/* Global Stats */}
      {globalStats && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 xl:grid-cols-6 gap-4">
          <Card key="stat-cities">
            <CardHeader className="pb-2">
              <CardDescription>Total Cities</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <Server className="size-5 text-primary" />
                <span className="text-2xl font-bold">{globalStats.totalCities}</span>
              </div>
            </CardContent>
          </Card>

          <Card key="stat-players">
            <CardHeader className="pb-2">
              <CardDescription>Total Players</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <Users className="size-5 text-blue-500" />
                <span className="text-2xl font-bold">{globalStats.totalPlayers}</span>
              </div>
            </CardContent>
          </Card>

          <Card key="stat-uptime">
            <CardHeader className="pb-2">
              <CardDescription>API Uptime</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <Activity className="size-5 text-green-500" />
                <span className="text-2xl font-bold">{globalStats.apiUptime}%</span>
              </div>
            </CardContent>
          </Card>

          <Card key="stat-requests">
            <CardHeader className="pb-2">
              <CardDescription">Total Requests</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <BarChart3 className="size-5 text-purple-500" />
                <span className="text-2xl font-bold">{(globalStats.totalRequests / 1000000).toFixed(1)}M</span>
              </div>
            </CardContent>
          </Card>

          <Card key="stat-response">
            <CardHeader className="pb-2">
              <CardDescription>Avg Response</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <Clock className="size-5 text-orange-500" />
                <span className="text-2xl font-bold">{globalStats.avgResponseTime}ms</span>
              </div>
            </CardContent>
          </Card>

          <Card key="stat-alerts">
            <CardHeader className="pb-2">
              <CardDescription>Active Alerts</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <AlertTriangle className={`size-5 ${globalStats.activeAlerts > 0 ? 'text-red-500' : 'text-gray-500'}`} />
                <span className="text-2xl font-bold">{globalStats.activeAlerts}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Main Tabs */}
      <Tabs defaultValue="apis" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="apis">APIs ({apis.length})</TabsTrigger>
          <TabsTrigger value="cities">Connected Cities ({cities.length})</TabsTrigger>
          <TabsTrigger value="control">Global Control</TabsTrigger>
        </TabsList>

        {/* APIs Tab */}
        <TabsContent value="apis" className="space-y-4">
          {/* Search & Filter */}
          <Card key="apis-filters">
            <CardContent className="p-4">
              <div className="flex gap-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
                  <Input
                    placeholder="Search APIs..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
                <Select value={filterStatus} onValueChange={setFilterStatus}>
                  <SelectTrigger className="w-[180px]">
                    <SelectValue placeholder="Filter by status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="online">Online</SelectItem>
                    <SelectItem value="offline">Offline</SelectItem>
                    <SelectItem value="degraded">Degraded</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* APIs Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {filteredAPIs.map((api) => (
              <Card key={api.name} className="relative">
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base">{api.name}</CardTitle>
                    {getStatusBadge(api.status)}
                  </div>
                  <CardDescription>Port: {api.port}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <p className="text-muted-foreground">Uptime</p>
                      <p className="font-medium">{api.uptime}h</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Requests</p>
                      <p className="font-medium">{(api.requests / 1000).toFixed(1)}k</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Response</p>
                      <p className="font-medium">{api.avgResponseTime}ms</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Error Rate</p>
                      <p className="font-medium">{(api.errorRate * 100).toFixed(2)}%</p>
                    </div>
                  </div>
                  
                  <Separator />
                  
                  <div className="flex gap-2">
                    <Button 
                      size="sm" 
                      variant="outline" 
                      className="flex-1 gap-1"
                      onClick={() => restartAPI(api.name)}
                    >
                      <RefreshCw className="size-3" />
                      Restart
                    </Button>
                    <Button 
                      size="sm" 
                      variant="outline" 
                      className="flex-1 gap-1"
                      onClick={() => setSelectedAPI(api.name)}
                    >
                      <Settings className="size-3" />
                      Config
                    </Button>
                  </div>
                  
                  <Button 
                    size="sm" 
                    variant="destructive" 
                    className="w-full gap-1"
                    onClick={() => {
                      const reason = prompt('Emergency stop reason:');
                      if (reason) emergencyStopAPI(api.name, reason);
                    }}
                  >
                    <AlertTriangle className="size-3" />
                    Emergency Stop
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Cities Tab */}
        <TabsContent value="cities" className="space-y-4">
          {/* Search & Filter */}
          <Card key="cities-filters">
            <CardContent className="p-4">
              <div className="flex gap-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
                  <Input
                    placeholder="Search cities..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
                <Select value={filterStatus} onValueChange={setFilterStatus}>
                  <SelectTrigger className="w-[180px]">
                    <SelectValue placeholder="Filter by status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="online">Online</SelectItem>
                    <SelectItem value="offline">Offline</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Cities Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
            {filteredCities.map((city) => (
              <Card key={city.id}>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base">{city.name}</CardTitle>
                    {getStatusBadge(city.status)}
                  </div>
                  <CardDescription>{city.ip}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <p className="text-muted-foreground">Players</p>
                      <p className="font-medium">{city.players}/{city.maxPlayers}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Framework</p>
                      <p className="font-medium">{city.framework}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">TPS</p>
                      <p className="font-medium">{city.performance.tps.toFixed(1)}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">CPU</p>
                      <p className="font-medium">{city.performance.cpuUsage.toFixed(1)}%</p>
                    </div>
                  </div>
                  
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Connected APIs ({city.connectedAPIs.length})</p>
                    <div className="flex flex-wrap gap-1">
                      {city.connectedAPIs.slice(0, 3).map(api => (
                        <Badge key={api} variant="outline" className="text-xs">{api}</Badge>
                      ))}
                      {city.connectedAPIs.length > 3 && (
                        <Badge variant="outline" className="text-xs">+{city.connectedAPIs.length - 3}</Badge>
                      )}
                    </div>
                  </div>
                  
                  <Separator />
                  
                  <div className="flex gap-2">
                    <Button 
                      size="sm" 
                      variant="outline" 
                      className="flex-1 gap-1"
                      onClick={() => setSelectedCity(city.id)}
                    >
                      <Eye className="size-3" />
                      View Details
                    </Button>
                    <Button 
                      size="sm" 
                      variant="outline" 
                      className="flex-1 gap-1"
                      onClick={() => {
                        const message = prompt('Broadcast message to city:');
                        if (message) executeCityCommand(city.id, 'broadcast', { message });
                      }}
                    >
                      <MessageSquare className="size-3" />
                      Message
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Global Control Tab */}
        <TabsContent value="control" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Global API Actions */}
            <Card key="global-api-actions">
              <CardHeader>
                <CardTitle>Global API Actions</CardTitle>
                <CardDescription>Control all APIs at once</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <Button variant="outline" className="w-full gap-2">
                  <RefreshCw className="size-4" />
                  Restart All APIs
                </Button>
                <Button variant="outline" className="w-full gap-2">
                  <Download className="size-4" />
                  Export All Logs
                </Button>
                <Button variant="outline" className="w-full gap-2">
                  <BarChart3 className="size-4" />
                  Generate Analytics Report
                </Button>
                <Button variant="destructive" className="w-full gap-2">
                  <AlertTriangle className="size-4" />
                  Emergency Shutdown All
                </Button>
              </CardContent>
            </Card>

            {/* Global City Actions */}
            <Card key="global-city-actions">
              <CardHeader>
                <CardTitle>Global City Actions</CardTitle>
                <CardDescription>Control all connected cities</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <Button variant="outline" className="w-full gap-2">
                  <Radio className="size-4" />
                  Broadcast to All Cities
                </Button>
                <Button variant="outline" className="w-full gap-2">
                  <Download className="size-4" />
                  Backup All City Data
                </Button>
                <Button variant="outline" className="w-full gap-2">
                  <Settings className="size-4" />
                  Sync Config to All
                </Button>
                <Button variant="outline" className="w-full gap-2">
                  <FileText className="size-4" />
                  Export Global Analytics
                </Button>
              </CardContent>
            </Card>

            {/* System Health */}
            <Card key="system-health">
              <CardHeader>
                <CardTitle>System Health</CardTitle>
                <CardDescription>Overall system status</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm">APIs Online</span>
                  <Badge variant="default" className="bg-green-500">
                    {apis.filter(a => a.status === 'online').length}/{apis.length}
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">Cities Online</span>
                  <Badge variant="default" className="bg-green-500">
                    {cities.filter(c => c.status === 'online').length}/{cities.length}
                  </Badge>
                </div>
                {globalStats && (
                  <>
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Data Processed (24h)</span>
                      <span className="font-medium">{globalStats.dataProcessed.toFixed(1)} GB</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Storage Used</span>
                      <span className="font-medium">{globalStats.storageUsed.toFixed(1)} GB</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Total Bans</span>
                      <span className="font-medium">{globalStats.totalBans}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Total Reports</span>
                      <span className="font-medium">{globalStats.totalReports}</span>
                    </div>
                  </>
                )}
              </CardContent>
            </Card>

            {/* Quick Actions */}
            <Card key="quick-actions">
              <CardHeader>
                <CardTitle>Quick Actions</CardTitle>
                <CardDescription>Common administrative tasks</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <Button variant="outline" className="w-full gap-2">
                  <Shield className="size-4" />
                  Apply Global Ban
                </Button>
                <Button variant="outline" className="w-full gap-2">
                  <Unlock className="size-4" />
                  Remove Global Ban
                </Button>
                <Button variant="outline" className="w-full gap-2">
                  <FileText className="size-4" />
                  View Audit Logs
                </Button>
                <Button variant="outline" className="w-full gap-2">
                  <Database className="size-4" />
                  Database Maintenance
                </Button>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
