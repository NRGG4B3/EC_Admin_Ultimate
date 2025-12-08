import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { ScrollArea } from '../ui/scroll-area';
import { 
  Server, Play, Square, RotateCw, Search, RefreshCw, AlertTriangle,
  Database, Trash2, Settings, Activity, HardDrive, Cpu, Users,
  Clock, Zap, MessageSquare, LogOut, Bell, Terminal, BarChart3,
  Package, CheckCircle, XCircle, Pause
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';

interface SystemManagementPageProps {
  liveData: any;
}

interface Resource {
  name: string;
  state: string;
  description: string;
  version: string;
  author: string;
}

interface ServerInfo {
  hostname: string;
  maxPlayers: number;
  currentPlayers: number;
  gametype: string;
  mapname: string;
  version: string;
  build: string;
  scriptHookAllowed: boolean;
  oneSync: string;
  txAdminAvailable: boolean;
}

interface PerformanceStats {
  playerCount: number;
  resourceCount: number;
  uptime: number;
  tickTime: number;
  memoryUsage: number;
  averagePing: number;
}

interface SystemAction {
  id: number;
  admin_name: string;
  action_type: string;
  target: string | null;
  details: string | null;
  success: number;
  created_at: string;
}

interface ConsoleLog {
  id: number;
  log_type: 'info' | 'warning' | 'error' | 'debug';
  message: string;
  source: string | null;
  created_at: string;
}

interface SystemData {
  resources: Resource[];
  serverInfo: ServerInfo;
  performanceStats: PerformanceStats;
  recentActions: SystemAction[];
  scheduledRestarts: any[];
  consoleLogs: ConsoleLog[];
  stats: {
    totalResources: number;
    runningResources: number;
    stoppedResources: number;
    totalActions: number;
    scheduledRestarts: number;
    uptime: number;
    playerCount: number;
    memoryUsage: number;
  };
  framework: string;
}

export function SystemManagementPage({ liveData }: SystemManagementPageProps) {
  const [activeTab, setActiveTab] = useState('resources');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [data, setData] = useState<SystemData | null>(null);
  const [consoleLogs, setConsoleLogs] = useState<ConsoleLog[]>([]);
  const [performanceLive, setPerformanceLive] = useState<any>(null);

  // Modals
  const [announcementModal, setAnnouncementModal] = useState(false);
  const [kickAllModal, setKickAllModal] = useState(false);
  const [cleanupModal, setCleanupModal] = useState(false);
  const [resourceModal, setResourceModal] = useState<{ isOpen: boolean; resource?: Resource }>({ isOpen: false });

  const [formData, setFormData] = useState<any>({});

  // Fetch system data
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/system:getData', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        // Data will be received via NUI message
      }
    } catch (error) {
      if (import.meta.env?.DEV) {
        console.log('[System] Not in FiveM environment');
      }
    }
  }, []);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      if (action === 'systemData') {
        if (msgData.success) {
          setData(msgData.data);
          setConsoleLogs(msgData.data.consoleLogs || []);
        }
      } else if (action === 'systemResponse') {
        if (msgData.success) {
          toastSuccess({ title: msgData.message });
          fetchData();
        } else {
          toastError({ title: msgData.message });
        }
      } else if (action === 'performanceUpdate') {
        setPerformanceLive(msgData);
      } else if (action === 'consoleLog') {
        setConsoleLogs(prev => [msgData, ...prev].slice(0, 500));
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [fetchData]);

  // Initial load
  useEffect(() => {
    const loadData = async () => {
      await fetchData();
      setIsLoading(false);
    };

    loadData();

    // Auto-refresh every 10 seconds
    const interval = setInterval(() => {
      fetchData();
    }, 10000);

    return () => clearInterval(interval);
  }, [fetchData]);

  // Manual refresh
  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
    toastSuccess({ title: 'Data refreshed' });
  };

  // Start resource
  const handleStartResource = async (resourceName: string) => {
    try {
      await fetch('https://ec_admin_ultimate/system:startResource', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ resourceName })
      });
    } catch (error) {
      toastError({ title: 'Failed to start resource' });
    }
  };

  // Stop resource
  const handleStopResource = async (resourceName: string) => {
    try {
      await fetch('https://ec_admin_ultimate/system:stopResource', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ resourceName })
      });
    } catch (error) {
      toastError({ title: 'Failed to stop resource' });
    }
  };

  // Restart resource
  const handleRestartResource = async (resourceName: string) => {
    try {
      await fetch('https://ec_admin_ultimate/system:restartResource', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ resourceName })
      });
    } catch (error) {
      toastError({ title: 'Failed to restart resource' });
    }
  };

  // Server announcement
  const handleAnnouncement = async () => {
    if (!formData.message) {
      toastError({ title: 'Please enter a message' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/system:serverAnnouncement', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: formData.message,
          duration: formData.duration || 10000
        })
      });

      setAnnouncementModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to send announcement' });
    }
  };

  // Kick all players
  const handleKickAll = async () => {
    try {
      await fetch('https://ec_admin_ultimate/system:kickAllPlayers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          reason: formData.reason || 'Server maintenance'
        })
      });

      setKickAllModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to kick players' });
    }
  };

  // Clear cache
  const handleClearCache = async () => {
    try {
      await fetch('https://ec_admin_ultimate/system:clearCache', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });
    } catch (error) {
      toastError({ title: 'Failed to clear cache' });
    }
  };

  // Database cleanup
  const handleDatabaseCleanup = async () => {
    try {
      await fetch('https://ec_admin_ultimate/system:databaseCleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          days: formData.cleanupDays || 30
        })
      });

      setCleanupModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to cleanup database' });
    }
  };

  // Format uptime
  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) {
      return days + 'd ' + hours + 'h ' + minutes + 'm';
    } else if (hours > 0) {
      return hours + 'h ' + minutes + 'm';
    } else {
      return minutes + 'm';
    }
  };

  // Format date
  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleString();
  };

  // Get resource state color
  const getStateColor = (state: string) => {
    switch (state) {
      case 'started': return 'default';
      case 'starting': return 'default';
      case 'stopped': return 'secondary';
      case 'stopping': return 'secondary';
      default: return 'outline';
    }
  };

  // Get log type color
  const getLogTypeColor = (type: string) => {
    switch (type) {
      case 'error': return 'text-red-500';
      case 'warning': return 'text-yellow-500';
      case 'info': return 'text-blue-500';
      case 'debug': return 'text-gray-500';
      default: return 'text-muted-foreground';
    }
  };

  // Get data from state
  const resources = data?.resources || [];
  const serverInfo = data?.serverInfo || null;
  const performanceStats = performanceLive || data?.performanceStats || null;
  const recentActions = data?.recentActions || [];
  const stats = data?.stats || {
    totalResources: 0,
    runningResources: 0,
    stoppedResources: 0,
    totalActions: 0,
    scheduledRestarts: 0,
    uptime: 0,
    playerCount: 0,
    memoryUsage: 0
  };

  // Filter resources
  const filteredResources = resources.filter(r =>
    r.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.author.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Filter logs
  const filteredLogs = consoleLogs.filter(l =>
    l.message.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (l.source && l.source.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Server className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading System Management...</p>
          <p className="text-sm text-muted-foreground">Fetching server data</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl tracking-tight flex items-center gap-3">
            <Server className="size-8 text-primary" />
            System Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Server control, resource management, and monitoring
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button 
            variant="outline" 
            size="sm" 
            onClick={() => setAnnouncementModal(true)}
          >
            <Bell className="size-4 mr-2" />
            Announce
          </Button>
          <Button 
            variant="outline" 
            size="sm" 
            onClick={handleClearCache}
          >
            <Trash2 className="size-4 mr-2" />
            Clear Cache
          </Button>
          <Button 
            variant="outline" 
            size="sm" 
            onClick={handleRefresh}
            disabled={refreshing}
          >
            <RefreshCw className={`size-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-blue-500/10 rounded-lg mx-auto w-fit mb-2">
                <Package className="size-6 text-blue-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Resources</p>
              <p className="text-xl font-bold">{stats.totalResources}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-green-500/10 rounded-lg mx-auto w-fit mb-2">
                <CheckCircle className="size-6 text-green-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Running</p>
              <p className="text-xl font-bold">{stats.runningResources}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-gray-500/10 rounded-lg mx-auto w-fit mb-2">
                <XCircle className="size-6 text-gray-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Stopped</p>
              <p className="text-xl font-bold">{stats.stoppedResources}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-purple-500/10 rounded-lg mx-auto w-fit mb-2">
                <Users className="size-6 text-purple-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Players</p>
              <p className="text-xl font-bold">{stats.playerCount}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-yellow-500/10 rounded-lg mx-auto w-fit mb-2">
                <Clock className="size-6 text-yellow-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Uptime</p>
              <p className="text-xl font-bold">{formatUptime(stats.uptime)}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-orange-500/10 rounded-lg mx-auto w-fit mb-2">
                <HardDrive className="size-6 text-orange-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Memory</p>
              <p className="text-xl font-bold">{stats.memoryUsage.toFixed(0)} MB</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-cyan-500/10 rounded-lg mx-auto w-fit mb-2">
                <Activity className="size-6 text-cyan-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Tick Time</p>
              <p className="text-xl font-bold">{performanceStats?.tickTime || 0} ms</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-pink-500/10 rounded-lg mx-auto w-fit mb-2">
                <Zap className="size-6 text-pink-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Avg Ping</p>
              <p className="text-xl font-bold">{performanceStats?.averagePing?.toFixed(0) || 0} ms</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Server Info */}
      {serverInfo && (
        <Card>
          <CardHeader>
            <CardTitle>Server Information</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <Label>Hostname</Label>
                <p className="font-medium">{serverInfo.hostname}</p>
              </div>
              <div>
                <Label>Players</Label>
                <p className="font-medium">{serverInfo.currentPlayers} / {serverInfo.maxPlayers}</p>
              </div>
              <div>
                <Label>Game Build</Label>
                <p className="font-medium">{serverInfo.build}</p>
              </div>
              <div>
                <Label>OneSync</Label>
                <Badge>{serverInfo.oneSync}</Badge>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="resources" className="flex items-center gap-2">
            <Package className="size-4" />
            Resources ({filteredResources.length})
          </TabsTrigger>
          <TabsTrigger value="console" className="flex items-center gap-2">
            <Terminal className="size-4" />
            Console ({filteredLogs.length})
          </TabsTrigger>
          <TabsTrigger value="actions" className="flex items-center gap-2">
            <Activity className="size-4" />
            Actions ({recentActions.length})
          </TabsTrigger>
          <TabsTrigger value="database" className="flex items-center gap-2">
            <Database className="size-4" />
            Database
          </TabsTrigger>
        </TabsList>

        {/* Search */}
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            placeholder="Search..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-9"
          />
        </div>

        {/* Resources Tab */}
        <TabsContent value="resources" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Resource Management</CardTitle>
              <CardDescription>Control all server resources</CardDescription>
            </CardHeader>
            <CardContent>
              {filteredResources.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <Package className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No resources found</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-2">
                    {filteredResources.map((resource) => (
                      <Card key={resource.name}>
                        <CardContent className="p-4">
                          <div className="flex items-center justify-between">
                            <div className="space-y-1 flex-1">
                              <div className="flex items-center gap-2">
                                <p className="font-medium">{resource.name}</p>
                                <Badge variant={getStateColor(resource.state) as any}>
                                  {resource.state}
                                </Badge>
                                <Badge variant="outline">{resource.version}</Badge>
                              </div>
                              <p className="text-sm text-muted-foreground">{resource.description}</p>
                              <p className="text-xs text-muted-foreground">Author: {resource.author}</p>
                            </div>
                            <div className="flex items-center gap-2">
                              {(resource.state === 'stopped' || resource.state === 'missing') && (
                                <Button 
                                  variant="outline" 
                                  size="sm"
                                  onClick={() => handleStartResource(resource.name)}
                                >
                                  <Play className="size-4" />
                                </Button>
                              )}
                              {(resource.state === 'started' || resource.state === 'starting') && (
                                <Button 
                                  variant="outline" 
                                  size="sm"
                                  onClick={() => handleStopResource(resource.name)}
                                >
                                  <Square className="size-4" />
                                </Button>
                              )}
                              <Button 
                                variant="outline" 
                                size="sm"
                                onClick={() => handleRestartResource(resource.name)}
                              >
                                <RotateCw className="size-4" />
                              </Button>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                </ScrollArea>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Console Tab */}
        <TabsContent value="console" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Console Logs</CardTitle>
              <CardDescription>Real-time server console output</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px] bg-black/50 rounded-lg p-4 font-mono text-sm">
                {filteredLogs.length === 0 ? (
                  <p className="text-muted-foreground">No logs</p>
                ) : (
                  <div className="space-y-1">
                    {filteredLogs.map((log, index) => (
                      <div key={log.id || index} className={getLogTypeColor(log.log_type)}>
                        <span className="text-gray-500">[{formatDate(log.created_at)}]</span>
                        {log.source && <span className="text-gray-400"> [{log.source}]</span>}
                        <span className="ml-2">{log.message}</span>
                      </div>
                    ))}
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Actions Tab */}
        <TabsContent value="actions" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Recent Actions</CardTitle>
              <CardDescription>System action history</CardDescription>
            </CardHeader>
            <CardContent>
              {recentActions.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <Activity className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No actions found</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-3">
                    {recentActions.map((action) => (
                      <Card key={action.id}>
                        <CardContent className="p-4">
                          <div className="flex items-start justify-between">
                            <div className="space-y-1 flex-1">
                              <div className="flex items-center gap-2">
                                <Badge>{action.action_type}</Badge>
                                <p className="font-medium text-sm">{action.admin_name}</p>
                                {action.success === 1 ? (
                                  <CheckCircle className="size-4 text-green-500" />
                                ) : (
                                  <XCircle className="size-4 text-red-500" />
                                )}
                              </div>
                              {action.target && (
                                <p className="text-sm text-muted-foreground">Target: {action.target}</p>
                              )}
                              {action.details && (
                                <p className="text-sm text-muted-foreground">{action.details}</p>
                              )}
                              <p className="text-xs text-muted-foreground">{formatDate(action.created_at)}</p>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                </ScrollArea>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Database Tab */}
        <TabsContent value="database" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Database Management</CardTitle>
              <CardDescription>Database maintenance and cleanup</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div>
                  <p className="font-medium">Cleanup Old Records</p>
                  <p className="text-sm text-muted-foreground">Remove old logs and data</p>
                </div>
                <Button onClick={() => setCleanupModal(true)}>
                  <Trash2 className="size-4 mr-2" />
                  Cleanup
                </Button>
              </div>

              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div>
                  <p className="font-medium">Kick All Players</p>
                  <p className="text-sm text-muted-foreground">Remove all players from server</p>
                </div>
                <Button variant="destructive" onClick={() => setKickAllModal(true)}>
                  <LogOut className="size-4 mr-2" />
                  Kick All
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Announcement Modal */}
      <Dialog open={announcementModal} onOpenChange={setAnnouncementModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Server Announcement</DialogTitle>
            <DialogDescription>
              Send a message to all players
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="message">Message</Label>
              <Textarea
                id="message"
                placeholder="Enter announcement message"
                value={formData.message || ''}
                onChange={(e) => setFormData({ ...formData, message: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="duration">Duration (ms)</Label>
              <Input
                id="duration"
                type="number"
                placeholder="10000"
                value={formData.duration || ''}
                onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setAnnouncementModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleAnnouncement}>
              Send Announcement
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Kick All Modal */}
      <Dialog open={kickAllModal} onOpenChange={setKickAllModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Kick All Players</DialogTitle>
            <DialogDescription>
              This will kick all players from the server
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="reason">Reason</Label>
              <Textarea
                id="reason"
                placeholder="Server maintenance"
                value={formData.reason || ''}
                onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setKickAllModal(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleKickAll}>
              Kick All Players
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Cleanup Modal */}
      <Dialog open={cleanupModal} onOpenChange={setCleanupModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Database Cleanup</DialogTitle>
            <DialogDescription>
              Remove old records from the database
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="cleanupDays">Delete records older than (days)</Label>
              <Input
                id="cleanupDays"
                type="number"
                placeholder="30"
                value={formData.cleanupDays || ''}
                onChange={(e) => setFormData({ ...formData, cleanupDays: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setCleanupModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleDatabaseCleanup}>
              Cleanup Database
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
