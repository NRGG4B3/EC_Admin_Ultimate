import { useState, useEffect, useMemo, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { ScrollArea } from '../ui/scroll-area';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Separator } from '../ui/separator';
import { 
  Shield, AlertTriangle, Eye, Ban, RefreshCw, Download, Search,
  Activity, TrendingUp, Users, Zap, Brain, Target, FileWarning,
  Clock, MapPin, Settings, CheckCircle, XCircle, Pause, Play,
  BarChart3, PieChart as PieChartIcon, Calendar, Filter, Award,
  Cpu, Layers, Lock, Unlock, AlertCircle, Info
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell, AreaChart, Area, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar } from 'recharts';

interface AnticheatPageProps {
  liveData: any;
  userPermissions?: {
    level: string;
    canViewAI: boolean;
    canManageDetections: boolean;
    canBanPlayers: boolean;
  };
}

interface Detection {
  id: string;
  player: string;
  playerName: string;
  type: string;
  category: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  confidence: number;
  timestamp: number;
  date: string;
  location: string;
  coords: { x: number; y: number; z: number };
  evidence: string[];
  action: 'none' | 'warn' | 'kick' | 'ban';
  aiAnalyzed: boolean;
  pattern?: string;
}

interface ViolationHistory {
  id: string;
  player: string;
  playerName: string;
  type: string;
  action: string;
  timestamp: number;
  date: string;
  bannedBy?: string;
}

interface AIPattern {
  id: string;
  name: string;
  type: string;
  confidence: number;
  occurrences: number;
  lastSeen: string;
  risk: 'low' | 'medium' | 'high';
}

export function AnticheatPage({ liveData, userPermissions }: AnticheatPageProps) {
  const [activeTab, setActiveTab] = useState('overview');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [filterSeverity, setFilterSeverity] = useState('all');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshTrigger, setRefreshTrigger] = useState(0); // Trigger for manual refresh

  // Real-time data
  const [liveDetections, setLiveDetections] = useState<Detection[]>([]);
  const [violationHistory, setViolationHistory] = useState<ViolationHistory[]>([]);
  const [aiPatterns, setAIPatterns] = useState<AIPattern[]>([]);
  const [anticheatConfig, setAnticheatConfig] = useState({
    enabled: true,
    autoActions: true,
    aiAnalysis: true,
    sensitivity: 'medium',
    logLevel: 'info'
  });

  // Hash tracking
  const lastDetectionsHashRef = useRef<string>('');
  const lastHistoryHashRef = useRef<string>('');

  // Fetch real data
  useEffect(() => {
    let isMounted = true;

    const fetchAllData = async () => {
      setIsLoading(true);

  // Use strict NUI bridge only
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const fetchNui = (window as any)?.fetchNui as (event: string, data?: any) => Promise<any>;
      
      try {
        // Fetch all data in parallel based on active tab
        const promises: Promise<any>[] = [];

        if (activeTab === 'live' || activeTab === 'overview') {
          // Detections
          promises.push(
            (async () => {
              try {
                if (!fetchNui) throw new Error('NUI bridge unavailable');
                const data = await fetchNui('getAnticheatAlerts', {});
                return { type: 'detections', ...data };
              } catch (err) {
                console.error('[Anticheat] Failed to fetch detections:', err);
                return { type: 'detections', success: false };
              }
            })()
          );
        }

        if (activeTab === 'history' || activeTab === 'overview') {
          // History
          promises.push(
            (async () => {
              try {
                if (!fetchNui) throw new Error('NUI bridge unavailable');
                const data = await fetchNui('getAnticheatAlerts', { history: true });
                return { type: 'history', ...data };
              } catch (err) {
                console.error('[Anticheat] Failed to fetch history:', err);
                return { type: 'history', success: false };
              }
            })()
          );
        }

        if (activeTab === 'ai-analytics' || activeTab === 'overview') {
          // AI Patterns
          promises.push(
            (async () => {
              try {
                if (!fetchNui) throw new Error('NUI bridge unavailable');
                const data = await fetchNui('getAnticheatAlerts', { patterns: true });
                return { type: 'patterns', ...data };
              } catch (err) {
                console.error('[Anticheat] Failed to fetch AI patterns:', err);
                return { type: 'patterns', success: false };
              }
            })()
          );
        }

        // Wait for all promises to complete
        const results = await Promise.all(promises);
        
        if (!isMounted) return;

        // Process results
        results.forEach(result => {
          if (result.type === 'detections' && result.success && result.detections) {
            const detectionsHash = JSON.stringify(result.detections.map((d: any) => d.id));
            if (detectionsHash !== lastDetectionsHashRef.current) {
              lastDetectionsHashRef.current = detectionsHash;
              setLiveDetections(result.detections);
            }
          } else if (result.type === 'history' && result.success && result.history) {
            const historyHash = JSON.stringify(result.history.map((h: any) => h.id));
            if (historyHash !== lastHistoryHashRef.current) {
              lastHistoryHashRef.current = historyHash;
              setViolationHistory(result.history);
            }
          } else if (result.type === 'patterns' && result.success && result.patterns) {
            setAIPatterns(result.patterns);
          }
        });

      } catch (err) {
        console.error('[Anticheat] Failed to fetch data:', err);
      } finally {
        if (isMounted) setIsLoading(false);
      }
    };

    // Initial fetch
    fetchAllData();

    // Refresh every 3 seconds for live detections
    const interval = setInterval(() => {
      if (!isMounted) return;
      if (activeTab === 'live') {
        fetchAllData();
      }
    }, 3000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [activeTab, refreshTrigger]);

  // Statistics
  const stats = useMemo(() => {
    const today = new Date();
    const todayDetections = liveDetections.filter(d => {
      const detectionDate = new Date(d.timestamp);
      return detectionDate.toDateString() === today.toDateString();
    }).length;

    const criticalDetections = liveDetections.filter(d => d.severity === 'critical').length;
    const bannedToday = violationHistory.filter(v => {
      const violationDate = new Date(v.timestamp);
      return v.action === 'ban' && violationDate.toDateString() === today.toDateString();
    }).length;
    const aiAnalyzed = liveDetections.filter(d => d.aiAnalyzed).length;

    return {
      detectionsToday: todayDetections,
      critical: criticalDetections,
      bannedToday,
      aiAnalyzed,
      total: liveDetections.length
    };
  }, [liveDetections, violationHistory]);

  // Chart data
  const detectionTrendsData = useMemo(() => {
    const last7Days = [];
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      
      const detectionsOnDay = liveDetections.filter(d => {
        const detectionDate = new Date(d.timestamp);
        return detectionDate.toDateString() === date.toDateString();
      }).length;
      
      last7Days.push({
        date: dateStr,
        detections: detectionsOnDay
      });
    }
    
    return last7Days;
  }, [liveDetections]);

  const detectionsByTypeData = useMemo(() => {
    const types: Record<string, number> = {};
    liveDetections.forEach(d => {
      types[d.type] = (types[d.type] || 0) + 1;
    });
    
    return Object.entries(types).map(([name, value]) => ({ 
      id: `detection-type-${name}`,
      name, 
      value 
    }));
  }, [liveDetections]);

  const detectionsBySeverityData = useMemo(() => {
    return [
      { id: 'low', name: 'Low', value: liveDetections.filter(d => d.severity === 'low').length },
      { id: 'medium', name: 'Medium', value: liveDetections.filter(d => d.severity === 'medium').length },
      { id: 'high', name: 'High', value: liveDetections.filter(d => d.severity === 'high').length },
      { id: 'critical', name: 'Critical', value: liveDetections.filter(d => d.severity === 'critical').length }
    ];
  }, [liveDetections]);

  const aiConfidenceData = useMemo(() => {
    const aiDetections = liveDetections.filter(d => d.aiAnalyzed);
    if (aiDetections.length === 0) return [];

    return [
      {
        metric: 'Accuracy',
        value: Math.round((aiDetections.filter(d => d.confidence > 80).length / aiDetections.length) * 100)
      },
      {
        metric: 'Detection Rate',
        value: Math.round((aiDetections.length / liveDetections.length) * 100)
      },
      {
        metric: 'False Positives',
        value: Math.round((aiDetections.filter(d => d.confidence < 50).length / aiDetections.length) * 100)
      },
      {
        metric: 'Pattern Match',
        value: Math.round((aiDetections.filter(d => d.pattern).length / aiDetections.length) * 100)
      }
    ];
  }, [liveDetections]);

  // Filtered detections
  const filteredDetections = useMemo(() => {
    let filtered = liveDetections;

    if (searchTerm) {
      filtered = filtered.filter(d =>
        d.playerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.type.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (filterType !== 'all') {
      filtered = filtered.filter(d => d.type === filterType);
    }

    if (filterSeverity !== 'all') {
      filtered = filtered.filter(d => d.severity === filterSeverity);
    }

    return filtered;
  }, [liveDetections, searchTerm, filterType, filterSeverity]);

  const handleDetectionAction = async (detectionId: string, action: 'warn' | 'kick' | 'ban' | 'dismiss') => {
    try {
      await fetch('https://ec_admin_ultimate/handleDetection', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ detectionId, action })
      });

      toastSuccess({
        title: 'Action Completed',
        description: 'Detection handled successfully'
      });
    } catch (error) {
      toastError({
        title: 'Action Failed',
        description: 'Failed to handle detection'
      });
    }
  };

  const handleConfigUpdate = async (key: string, value: any) => {
    setAnticheatConfig(prev => ({ ...prev, [key]: value }));

    try {
      await fetch('https://ec_admin_ultimate/updateAnticheatConfig', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ [key]: value })
      });

      toastSuccess({
        title: 'Config Updated',
        description: 'Anticheat configuration saved'
      });
    } catch (error) {
      toastError({
        title: 'Update Failed',
        description: 'Failed to update configuration'
      });
    }
  };

  const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Shield className="size-12 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg">Loading Anticheat System...</p>
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
            <span className="bg-gradient-to-r from-red-600 to-purple-600 dark:from-red-400 dark:to-purple-400 bg-clip-text text-transparent">
              Anticheat & AI Detection
            </span>
          </h1>
          <p className="text-muted-foreground mt-1">
            AI-powered cheat detection and violation management
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => setRefreshTrigger(prev => prev + 1)}>
            <RefreshCw className="size-4 mr-2" />
            Refresh
          </Button>
          <Button variant="outline" size="sm">
            <Download className="size-4 mr-2" />
            Export
          </Button>
          <Button variant="outline" size="sm">
            <Settings className="size-4 mr-2" />
            Settings
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card key="stat-detections">
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-500/10 rounded-lg">
                <AlertTriangle className="size-5 text-red-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Detections Today</p>
                <p className="text-2xl">{stats.detectionsToday}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card key="stat-critical">
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-500/10 rounded-lg">
                <AlertCircle className="size-5 text-purple-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Critical</p>
                <p className="text-2xl">{stats.critical}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card key="stat-banned">
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-500/10 rounded-lg">
                <Ban className="size-5 text-orange-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Banned Today</p>
                <p className="text-2xl">{stats.bannedToday}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card key="stat-ai">
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-500/10 rounded-lg">
                <Brain className="size-5 text-blue-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">AI Analyzed</p>
                <p className="text-2xl">{stats.aiAnalyzed}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card key="stat-status">
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className={anticheatConfig.enabled ? 'p-2 rounded-lg bg-green-500/10' : 'p-2 rounded-lg bg-gray-500/10'}>
                <Shield className={anticheatConfig.enabled ? 'size-5 text-green-500' : 'size-5 text-gray-500'} />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Status</p>
                <p className="text-2xl">{anticheatConfig.enabled ? 'Active' : 'Disabled'}</p>
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
          <TabsTrigger value="live">
            <Activity className="size-4 mr-2" />
            Live Detections
          </TabsTrigger>
          <TabsTrigger value="ai-analytics">
            <Brain className="size-4 mr-2" />
            AI Analytics
          </TabsTrigger>
          <TabsTrigger value="history">
            <Clock className="size-4 mr-2" />
            History
          </TabsTrigger>
          <TabsTrigger value="config">
            <Settings className="size-4 mr-2" />
            Configuration
          </TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Detection Trends */}
            <Card key="chart-trends">
              <CardHeader>
                <CardTitle>Detection Trends (7 Days)</CardTitle>
                <CardDescription>Daily violation activity</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={detectionTrendsData}>
                      <defs>
                        <linearGradient id="colorDetections" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3}/>
                          <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                      <XAxis dataKey="date" stroke="#64748b" fontSize={12} />
                      <YAxis stroke="#64748b" fontSize={12} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'hsl(var(--card))',
                          border: '1px solid hsl(var(--border))',
                          borderRadius: '8px'
                        }}
                      />
                      <Area 
                        type="monotone" 
                        dataKey="detections" 
                        stroke="#ef4444" 
                        fillOpacity={1} 
                        fill="url(#colorDetections)" 
                        strokeWidth={2}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            {/* Detections by Type */}
            <Card key="chart-types">
              <CardHeader>
                <CardTitle>Detections by Type</CardTitle>
                <CardDescription>Distribution of violation types</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={detectionsByTypeData}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percent }) => name + ' ' + (percent * 100).toFixed(0) + '%'}
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="value"
                      >
                        {detectionsByTypeData.map((entry, index) => (
                          <Cell key={entry.id} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'hsl(var(--card))',
                          border: '1px solid hsl(var(--border))',
                          borderRadius: '8px'
                        }}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            {/* Severity Distribution */}
            <Card key="chart-severity">
              <CardHeader>
                <CardTitle>Severity Distribution</CardTitle>
                <CardDescription>Violations by severity level</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={detectionsBySeverityData}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                      <XAxis dataKey="name" stroke="#64748b" fontSize={12} />
                      <YAxis stroke="#64748b" fontSize={12} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'hsl(var(--card))',
                          border: '1px solid hsl(var(--border))',
                          borderRadius: '8px'
                        }}
                      />
                      <Bar dataKey="value" fill="#ef4444" radius={[8, 8, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            {/* AI Performance */}
            <Card key="chart-ai-performance">
              <CardHeader>
                <CardTitle>AI Performance Metrics</CardTitle>
                <CardDescription>Machine learning effectiveness</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <RadarChart data={aiConfidenceData}>
                      <PolarGrid stroke="#334155" />
                      <PolarAngleAxis dataKey="metric" stroke="#64748b" fontSize={12} />
                      <PolarRadiusAxis stroke="#64748b" fontSize={12} />
                      <Radar name="AI Performance" dataKey="value" stroke="#8b5cf6" fill="#8b5cf6" fillOpacity={0.6} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'hsl(var(--card))',
                          border: '1px solid hsl(var(--border))',
                          borderRadius: '8px'
                        }}
                      />
                    </RadarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Live Detections Tab */}
        <TabsContent value="live" className="space-y-4">
          {/* Search & Filters */}
          <Card key="live-filters">
            <CardContent className="p-4">
              <div className="flex flex-col lg:flex-row gap-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
                  <Input
                    placeholder="Search detections..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
                
                <Select value={filterType} onValueChange={setFilterType}>
                  <SelectTrigger className="w-full lg:w-[180px]">
                    <SelectValue placeholder="Filter by type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Types</SelectItem>
                    <SelectItem value="aimbot">Aimbot</SelectItem>
                    <SelectItem value="esp">ESP</SelectItem>
                    <SelectItem value="speedhack">Speed Hack</SelectItem>
                    <SelectItem value="noclip">No Clip</SelectItem>
                    <SelectItem value="godmode">God Mode</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={filterSeverity} onValueChange={setFilterSeverity}>
                  <SelectTrigger className="w-full lg:w-[180px]">
                    <SelectValue placeholder="Filter by severity" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Severities</SelectItem>
                    <SelectItem value="low">Low</SelectItem>
                    <SelectItem value="medium">Medium</SelectItem>
                    <SelectItem value="high">High</SelectItem>
                    <SelectItem value="critical">Critical</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Live Detections Feed */}
          <Card key="live-detections">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Activity className="size-5 text-red-500 animate-pulse" />
                Live Detection Feed
              </CardTitle>
              <CardDescription>
                Real-time anticheat violations • {filteredDetections.length} active
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px]">
                <div className="space-y-3">
                  {filteredDetections.map((detection) => (
                    <div
                      key={detection.id}
                      className="p-4 rounded-lg border bg-card hover:bg-accent/50 transition-colors"
                    >
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex items-start gap-3 flex-1">
                          <div className={
                            detection.severity === 'critical' ? 'p-2 rounded bg-red-500/10' :
                            detection.severity === 'high' ? 'p-2 rounded bg-orange-500/10' :
                            detection.severity === 'medium' ? 'p-2 rounded bg-yellow-500/10' :
                            'p-2 rounded bg-blue-500/10'
                          }>
                            <AlertTriangle className={
                              detection.severity === 'critical' ? 'size-5 text-red-500' :
                              detection.severity === 'high' ? 'size-5 text-orange-500' :
                              detection.severity === 'medium' ? 'size-5 text-yellow-500' :
                              'size-5 text-blue-500'
                            } />
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-2">
                              <span className="font-medium">{detection.playerName}</span>
                              <Badge 
                                variant={
                                  detection.severity === 'critical' ? 'destructive' :
                                  detection.severity === 'high' ? 'default' : 'secondary'
                                }
                              >
                                {detection.type}
                              </Badge>
                              <Badge variant="outline">
                                {detection.severity}
                              </Badge>
                              {detection.aiAnalyzed && (
                                <Badge variant="secondary">
                                  <Brain className="size-3 mr-1" />
                                  AI {detection.confidence}%
                                </Badge>
                              )}
                            </div>
                            <div className="flex items-center gap-4 text-xs text-muted-foreground">
                              <div className="flex items-center gap-1">
                                <Clock className="size-3" />
                                {detection.date}
                              </div>
                              <div className="flex items-center gap-1">
                                <MapPin className="size-3" />
                                {detection.location}
                              </div>
                              {detection.pattern && (
                                <div className="flex items-center gap-1">
                                  <Target className="size-3" />
                                  Pattern: {detection.pattern}
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleDetectionAction(detection.id, 'warn')}
                          >
                            Warn
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleDetectionAction(detection.id, 'kick')}
                          >
                            Kick
                          </Button>
                          <Button
                            size="sm"
                            variant="destructive"
                            onClick={() => handleDetectionAction(detection.id, 'ban')}
                          >
                            Ban
                          </Button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
                {filteredDetections.length === 0 && (
                  <div className="text-center py-12 text-muted-foreground">
                    <CheckCircle className="size-12 mx-auto mb-4 opacity-50 text-green-500" />
                    <p className="text-lg">No Active Detections</p>
                    <p className="text-sm">All clear! System is monitoring...</p>
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* AI Analytics Tab */}
        <TabsContent value="ai-analytics" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card key="ai-patterns">
              <CardHeader>
                <CardTitle>Detected Patterns</CardTitle>
                <CardDescription>AI-identified cheating patterns</CardDescription>
              </CardHeader>
              <CardContent>
                <ScrollArea className="h-[400px]">
                  <div className="space-y-3">
                    {aiPatterns.map((pattern) => (
                      <div key={pattern.id} className="p-3 rounded-lg border bg-card">
                        <div className="flex items-center justify-between mb-2">
                          <span className="font-medium">{pattern.name}</span>
                          <Badge variant={
                            pattern.risk === 'high' ? 'destructive' :
                            pattern.risk === 'medium' ? 'default' : 'secondary'
                          }>
                            {pattern.risk} risk
                          </Badge>
                        </div>
                        <div className="flex items-center justify-between text-xs text-muted-foreground">
                          <span>Confidence: {pattern.confidence}%</span>
                          <span>Occurrences: {pattern.occurrences}</span>
                          <span>Last seen: {pattern.lastSeen}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>

            <Card key="ai-performance">
              <CardHeader>
                <CardTitle>AI Model Performance</CardTitle>
                <CardDescription>Machine learning metrics</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-6">
                  {[
                    { label: 'Detection Accuracy', value: 94, color: 'bg-green-500' },
                    { label: 'False Positive Rate', value: 3, color: 'bg-yellow-500' },
                    { label: 'Pattern Recognition', value: 89, color: 'bg-blue-500' },
                    { label: 'Prediction Confidence', value: 91, color: 'bg-purple-500' }
                  ].map((metric) => (
                    <div key={metric.label}>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm">{metric.label}</span>
                        <span className="text-sm font-medium">{metric.value}%</span>
                      </div>
                      <div className="h-2 bg-muted rounded-full overflow-hidden">
                        <div className={metric.color + ' h-full'} style={{ width: metric.value + '%' }} />
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* History Tab */}
        <TabsContent value="history" className="space-y-4">
          <Card key="violation-history">
            <CardHeader>
              <CardTitle>Violation History</CardTitle>
              <CardDescription>{violationHistory.length} violations recorded</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Player</TableHead>
                      <TableHead>Violation Type</TableHead>
                      <TableHead>Action Taken</TableHead>
                      <TableHead>Handled By</TableHead>
                      <TableHead>Timestamp</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {violationHistory.map((violation) => (
                      <TableRow key={violation.id}>
                        <TableCell>
                          <span className="font-medium">{violation.playerName}</span>
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline">{violation.type}</Badge>
                        </TableCell>
                        <TableCell>
                          <Badge variant={violation.action === 'ban' ? 'destructive' : 'default'}>
                            {violation.action}
                          </Badge>
                        </TableCell>
                        <TableCell>{violation.bannedBy || 'Auto'}</TableCell>
                        <TableCell>{violation.date}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                {violationHistory.length === 0 && (
                  <div className="text-center py-12 text-muted-foreground">
                    <Clock className="size-12 mx-auto mb-4 opacity-50" />
                    <p className="text-lg">No violation history</p>
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Configuration Tab */}
        <TabsContent value="config" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card key="config-general">
              <CardHeader>
                <CardTitle>General Settings</CardTitle>
                <CardDescription>Configure anticheat behavior</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="flex items-center justify-between">
                  <div>
                    <Label>Enable Anticheat</Label>
                    <p className="text-xs text-muted-foreground">Master switch for all detections</p>
                  </div>
                  <Switch
                    checked={anticheatConfig.enabled}
                    onCheckedChange={(checked) => handleConfigUpdate('enabled', checked)}
                  />
                </div>
                <Separator />
                <div className="flex items-center justify-between">
                  <div>
                    <Label>Auto Actions</Label>
                    <p className="text-xs text-muted-foreground">Automatically handle detections</p>
                  </div>
                  <Switch
                    checked={anticheatConfig.autoActions}
                    onCheckedChange={(checked) => handleConfigUpdate('autoActions', checked)}
                  />
                </div>
                <Separator />
                <div className="flex items-center justify-between">
                  <div>
                    <Label>AI Analysis</Label>
                    <p className="text-xs text-muted-foreground">Enable machine learning detection</p>
                  </div>
                  <Switch
                    checked={anticheatConfig.aiAnalysis}
                    onCheckedChange={(checked) => handleConfigUpdate('aiAnalysis', checked)}
                  />
                </div>
                <Separator />
                <div className="space-y-2">
                  <Label>Detection Sensitivity</Label>
                  <Select
                    value={anticheatConfig.sensitivity}
                    onValueChange={(value) => handleConfigUpdate('sensitivity', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="low">Low (Fewer false positives)</SelectItem>
                      <SelectItem value="medium">Medium (Balanced)</SelectItem>
                      <SelectItem value="high">High (Maximum detection)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>

            <Card key="config-modules">
              <CardHeader>
                <CardTitle>Detection Modules</CardTitle>
                <CardDescription>Enable/disable specific checks</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Target className="size-4 text-muted-foreground" />
                    <Label>Aimbot Detection</Label>
                  </div>
                  <Switch defaultChecked />
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Eye className="size-4 text-muted-foreground" />
                    <Label>ESP Detection</Label>
                  </div>
                  <Switch defaultChecked />
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Zap className="size-4 text-muted-foreground" />
                    <Label>Speed Hack Detection</Label>
                  </div>
                  <Switch defaultChecked />
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Layers className="size-4 text-muted-foreground" />
                    <Label>No Clip Detection</Label>
                  </div>
                  <Switch defaultChecked />
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Shield className="size-4 text-muted-foreground" />
                    <Label>God Mode Detection</Label>
                  </div>
                  <Switch defaultChecked />
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}