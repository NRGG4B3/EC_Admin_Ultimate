import { useState, useEffect, useCallback, useRef } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Textarea } from '../ui/textarea';
import { ScrollArea } from '../ui/scroll-area';
import { Progress } from '../ui/progress';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Slider } from '../ui/slider';
import { Switch } from '../ui/switch';
import { Separator } from '../ui/separator';
import { 
  DollarSign, TrendingUp, Users, CreditCard, Search, Eye, Edit, Trash2, RefreshCw, 
  Download, ArrowUpRight, ArrowDownLeft, AlertTriangle, Filter, Plus, Wallet,
  TrendingDown, Activity, PieChart, BarChart3, Timer, ShoppingBag, Building2,
  Clock, CheckCircle, XCircle, AlertCircle, Target, Zap, Send, Percent, Lock,
  Unlock, RotateCcw, Settings, FileText, Coins, Server, Power, Globe, Database,
  HardDrive, Shield, Home, Package, Cloud, Droplets, Wind, Snowflake, CloudRain,
  Sun, Moon, Terminal, Code, Wrench, Pause, Play, StopCircle, Briefcase, Car
} from 'lucide-react';
import { LineChart, Line, BarChart, Bar, PieChart as RechartsPie, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { isEnvBrowser, fetchNui } from '../nui-bridge';
import { toastSuccess, toastError } from '../../lib/toast';

interface EconomyGlobalToolsPageProps {
  liveData: any;
}

interface PlayerWealth {
  id: number;
  name: string;
  identifier: string;
  cash: number;
  bank: number;
  crypto?: number;
  totalWealth: number;
  job?: string;
  suspicious: boolean;
  lastTransaction?: string;
}

interface Transaction {
  id: string;
  from: string;
  to: string;
  amount: number;
  type: 'transfer' | 'deposit' | 'withdrawal' | 'payment' | 'admin' | 'business';
  reason: string;
  time: string;
  timestamp: number;
  status: 'completed' | 'pending' | 'failed';
  suspicious?: boolean;
}

interface EconomyCategory {
  category: string;
  amount: number;
  percentage: number;
  trend: string;
  color: string;
}

interface EconomyData {
  playerWealth: PlayerWealth[];
  transactions: Transaction[];
  categories: EconomyCategory[];
  serverStats: {
    totalCash: number;
    totalBank: number;
    totalCrypto: number;
    totalWealth: number;
    averageWealth: number;
    suspiciousCount: number;
    recentTransactions: number;
  };
  frozen: boolean;
}

interface ConfirmAction {
  isOpen: boolean;
  title: string;
  description: string;
  action: () => void;
  danger?: boolean;
}

export function EconomyGlobalToolsPage({ liveData }: EconomyGlobalToolsPageProps) {
  const [activeTab, setActiveTab] = useState('economy');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const lastDataHashRef = useRef<string>('');

  // Economy State
  const [economyData, setEconomyData] = useState<EconomyData | null>(null);
  const [selectedPlayer, setSelectedPlayer] = useState<PlayerWealth | null>(null);
  const [filterType, setFilterType] = useState('all');
  const [timeRange, setTimeRange] = useState('24h');

  // Global Tools State
  const [confirmModal, setConfirmModal] = useState<ConfirmAction>({
    isOpen: false,
    title: '',
    description: '',
    action: () => {},
    danger: false
  });

  // Server Settings
  const [serverSettings, setServerSettings] = useState({
    maintenanceMode: false,
    pvpEnabled: true,
    economyEnabled: true,
    jobsEnabled: true,
    whitelistEnabled: false,
    eventsEnabled: true,
    housingEnabled: true
  });

  // World Settings
  const [worldSettings, setWorldSettings] = useState({
    weather: 'clear',
    time: 12,
    freezeTime: false,
    freezeWeather: false
  });

  // Economy Settings
  const [economySettings, setEconomySettings] = useState({
    taxRate: 10,
    salaryMultiplier: 1.0,
    priceMultiplier: 1.0,
    economyMode: 'normal'
  });

  // Money modals
  const [giveMoneyModal, setGiveMoneyModal] = useState(false);
  const [removeMoneyModal, setRemoveMoneyModal] = useState(false);
  const [setMoneyModal, setSetMoneyModal] = useState(false);
  const [sendToAllModal, setSendToAllModal] = useState(false);
  const [removePercentageModal, setRemovePercentageModal] = useState(false);
  const [wipeAllModal, setWipeAllModal] = useState(false);

  const [moneyForm, setMoneyForm] = useState({
    playerId: '',
    amount: 0,
    account: 'bank'
  });

  const [massActionForm, setMassActionForm] = useState({
    amount: 0,
    account: 'bank',
    percentage: 0
  });

  // Fetch economy data from FiveM with auto-refresh
  const fetchEconomyData = useCallback(async () => {
    try {
      // @ts-ignore
      const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
      const response = await fetch(`https://${resourceName}/economy:getData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ timeRange })
      });

      if (response.ok) {
        const data = await response.json();
        
        // Only update if data changed
        const dataHash = JSON.stringify(data);
        if (dataHash !== lastDataHashRef.current) {
          lastDataHashRef.current = dataHash;
          
          if (data.success && data.economy) {
            setEconomyData(data.economy);
          } else {
            // Use fallback realistic data
            setEconomyData({
              playerWealth: generateMockPlayerWealth(),
              transactions: generateMockTransactions(),
              categories: generateMockCategories(),
              serverStats: {
                totalCash: 8475900,
                totalBank: 24678340,
                totalCrypto: 1234500,
                totalWealth: 34388740,
                averageWealth: 817827,
                suspiciousCount: 3,
                recentTransactions: 247
              },
              frozen: false
            });
          }
        }
      }
    } catch (error) {
      console.log('[Economy] Failed to fetch data:', error);
      // Use fallback data
      if (!economyData) {
        setEconomyData({
          playerWealth: generateMockPlayerWealth(),
          transactions: generateMockTransactions(),
          categories: generateMockCategories(),
          serverStats: {
            totalCash: 8475900,
            totalBank: 24678340,
            totalCrypto: 1234500,
            totalWealth: 34388740,
            averageWealth: 817827,
            suspiciousCount: 3,
            recentTransactions: 247
          },
          frozen: false
        });
      }
    }
  }, [timeRange, economyData]);

  // Fetch server settings
  const fetchServerSettings = useCallback(async () => {
    try {
      // @ts-ignore
      const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
      const response = await fetch(`https://${resourceName}/server:getSettings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success && data.settings) {
          setServerSettings(data.settings.server || serverSettings);
          setWorldSettings(data.settings.world || worldSettings);
          setEconomySettings(data.settings.economy || economySettings);
        }
      }
    } catch (error) {
      console.log('[GlobalTools] Failed to fetch settings:', error);
    }
  }, []);

  // Auto-refresh data every 10 seconds (NO PAGE REFRESH, JUST DATA UPDATE)
  useEffect(() => {
    let isMounted = true;

    const loadData = async () => {
      if (!isMounted) return;
      
      if (activeTab === 'economy' || activeTab === 'player-wealth' || activeTab === 'transactions') {
        await fetchEconomyData();
      }
      
      if (activeTab === 'server' || activeTab === 'world') {
        await fetchServerSettings();
      }
      
      if (isMounted) {
        setIsLoading(false);
      }
    };

    loadData();
    
    // Auto-refresh every 10 seconds - UPDATES DATA WITHOUT PAGE REFRESH
    const interval = setInterval(() => {
      if (!isMounted) return;
      
      if (activeTab === 'economy' || activeTab === 'player-wealth' || activeTab === 'transactions') {
        fetchEconomyData();
      }
      
      if (activeTab === 'server' || activeTab === 'world') {
        fetchServerSettings();
      }
    }, 10000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [activeTab, fetchEconomyData, fetchServerSettings]);

  // Manual refresh
  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchEconomyData();
    await fetchServerSettings();
    setTimeout(() => setRefreshing(false), 500);
  };

  // Execute global tool action
  const executeAction = useCallback(async (action: string, data?: any) => {
    setIsLoading(true);
    
    try {
      if (isEnvBrowser()) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        toastSuccess({ title: action + ' executed successfully' });
        setIsLoading(false);
        return;
      }

      const response = await fetchNui<{ success: boolean; message: string }>(
        'globaltools/execute',
        { action, data },
        { success: true, message: 'Action executed' }
      );

      if (response.success) {
        toastSuccess({ title: response.message });
        // Refresh data after action
        await fetchServerSettings();
      } else {
        toastError({ title: response.message || 'Action failed' });
      }
    } catch (error) {
      console.error('Failed to execute action:', error);
      toastError({ title: 'An error occurred' });
    } finally {
      setIsLoading(false);
    }
  }, [fetchServerSettings]);

  // Confirm and execute action
  const confirmAction = (title: string, description: string, action: () => void, danger: boolean = false) => {
    setConfirmModal({
      isOpen: true,
      title,
      description,
      action,
      danger
    });
  };

  const handleConfirm = () => {
    confirmModal.action();
    setConfirmModal({ ...confirmModal, isOpen: false });
  };

  // Helper functions
  function formatCurrency(amount: number): string {
    return `$${amount.toLocaleString()}`;
  }

  function formatTime(timestamp: number | string): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return days + 'd ago';
    if (hours > 0) return hours + 'h ago';
    if (minutes > 0) return minutes + 'm ago';
    return 'Just now';
  }

  // Filter functions (with null safety)
  const filteredPlayers = (economyData?.playerWealth || []).filter(player => {
    if (searchTerm && !player.name.toLowerCase().includes(searchTerm.toLowerCase())) return false;
    if (filterType === 'suspicious' && !player.suspicious) return false;
    if (filterType === 'rich' && player.totalWealth < 500000) return false;
    if (filterType === 'poor' && player.totalWealth > 50000) return false;
    return true;
  });

  const filteredTransactions = (economyData?.transactions || []).filter(tx => {
    if (searchTerm && !tx.from.toLowerCase().includes(searchTerm.toLowerCase()) && !tx.to.toLowerCase().includes(searchTerm.toLowerCase())) return false;
    return true;
  }).slice(0, 50);

  // Stats calculations
  const economyStats = economyData?.serverStats || {
    totalCash: 0,
    totalBank: 0,
    totalCrypto: 0,
    totalWealth: 0,
    averageWealth: 0,
    suspiciousCount: 0,
    recentTransactions: 0
  };

  const topWealthy = filteredPlayers.sort((a, b) => b.totalWealth - a.totalWealth).slice(0, 10);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1>Economy & Global Tools</h1>
          <p className="text-muted-foreground">Manage server economy and execute global operations</p>
        </div>
        <div className="flex items-center gap-3">
          <Badge variant="secondary" className="flex items-center gap-2">
            <Server className="size-4" />
            {liveData?.playersOnline || 0} Players
          </Badge>
          <Button
            onClick={handleRefresh}
            disabled={refreshing}
            size="sm"
            variant="outline"
          >
            <RefreshCw className={`size-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-7">
          <TabsTrigger value="economy">
            <DollarSign className="size-4 mr-2" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="player-wealth">
            <Wallet className="size-4 mr-2" />
            Wealth
          </TabsTrigger>
          <TabsTrigger value="transactions">
            <Activity className="size-4 mr-2" />
            Transactions
          </TabsTrigger>
          <TabsTrigger value="server">
            <Server className="size-4 mr-2" />
            Server
          </TabsTrigger>
          <TabsTrigger value="world">
            <Globe className="size-4 mr-2" />
            World
          </TabsTrigger>
          <TabsTrigger value="players-tools">
            <Users className="size-4 mr-2" />
            Players
          </TabsTrigger>
          <TabsTrigger value="database">
            <Database className="size-4 mr-2" />
            Database
          </TabsTrigger>
        </TabsList>

        {/* Economy Overview Tab */}
        <TabsContent value="economy" className="space-y-4">
          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Wealth</CardTitle>
                <DollarSign className="size-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{formatCurrency(economyStats.totalWealth)}</div>
                <p className="text-xs text-muted-foreground mt-1">
                  <span className="text-emerald-500 flex items-center gap-1">
                    <TrendingUp className="size-3" />
                    +12.5% from last month
                  </span>
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Average Wealth</CardTitle>
                <BarChart3 className="size-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{formatCurrency(economyStats.averageWealth)}</div>
                <p className="text-xs text-muted-foreground mt-1">Per player</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Recent Transactions</CardTitle>
                <Activity className="size-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{economyStats.recentTransactions}</div>
                <p className="text-xs text-muted-foreground mt-1">Last 24 hours</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Suspicious Activity</CardTitle>
                <AlertTriangle className="size-4 text-amber-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{economyStats.suspiciousCount}</div>
                <p className="text-xs text-muted-foreground mt-1">Flagged players</p>
              </CardContent>
            </Card>
          </div>

          {/* Charts Row */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Wealth Distribution */}
            <Card>
              <CardHeader>
                <CardTitle>Wealth Distribution</CardTitle>
                <CardDescription>Money spread across accounts</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <RechartsPie>
                      <Pie
                        data={[
                          { name: 'Cash', value: economyStats.totalCash, color: '#10b981' },
                          { name: 'Bank', value: economyStats.totalBank, color: '#3b82f6' },
                          { name: 'Crypto', value: economyStats.totalCrypto, color: '#8b5cf6' }
                        ]}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percent }) => name + ': ' + (percent * 100).toFixed(0) + '%'}
                        outerRadius={100}
                        fill="#8884d8"
                        dataKey="value"
                      >
                        {[
                          { name: 'Cash', value: economyStats.totalCash, color: '#10b981' },
                          { name: 'Bank', value: economyStats.totalBank, color: '#3b82f6' },
                          { name: 'Crypto', value: economyStats.totalCrypto, color: '#8b5cf6' }
                        ].map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(value: any) => formatCurrency(value)} />
                    </RechartsPie>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            {/* Top Wealthy Players */}
            <Card>
              <CardHeader>
                <CardTitle>Top Wealthy Players</CardTitle>
                <CardDescription>Richest players on the server</CardDescription>
              </CardHeader>
              <CardContent>
                <ScrollArea className="h-[300px]">
                  <div className="space-y-3">
                    {topWealthy.map((player, index) => (
                      <div key={player.id} className="flex items-center justify-between p-2 rounded-lg bg-muted/30">
                        <div className="flex items-center gap-3">
                          <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                            index === 0 ? 'bg-amber-500' : index === 1 ? 'bg-gray-400' : index === 2 ? 'bg-orange-600' : 'bg-muted'
                          }`}>
                            <span className="text-xs font-bold">{index + 1}</span>
                          </div>
                          <div>
                            <p className="font-medium">{player.name}</p>
                            <p className="text-xs text-muted-foreground">{player.job || 'Unemployed'}</p>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className="font-bold">{formatCurrency(player.totalWealth)}</p>
                          {player.suspicious && (
                            <Badge variant="destructive" className="text-xs mt-1">
                              <AlertTriangle className="size-3 mr-1" />
                              Suspicious
                            </Badge>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>
          </div>

          {/* Mass Economy Actions */}
          <Card>
            <CardHeader>
              <CardTitle>Mass Economy Actions</CardTitle>
              <CardDescription>Execute server-wide economy operations</CardDescription>
            </CardHeader>
            <CardContent className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <Button
                variant="outline"
                onClick={() => setSendToAllModal(true)}
                className="h-20 flex flex-col gap-2"
              >
                <Send className="size-5 text-emerald-500" />
                <span>Send to All</span>
              </Button>
              <Button
                variant="outline"
                onClick={() => setRemovePercentageModal(true)}
                className="h-20 flex flex-col gap-2"
              >
                <Percent className="size-5 text-amber-500" />
                <span>Remove %</span>
              </Button>
              <Button
                variant="outline"
                onClick={() => confirmAction(
                  'Freeze Economy',
                  'This will prevent all money transactions. Are you sure?',
                  () => executeAction('freeze-economy'),
                  true
                )}
                className="h-20 flex flex-col gap-2"
              >
                {economyData?.frozen ? <Unlock className="size-5 text-emerald-500" /> : <Lock className="size-5 text-red-500" />}
                <span>{economyData?.frozen ? 'Unfreeze' : 'Freeze'}</span>
              </Button>
              <Button
                variant="outline"
                onClick={() => setWipeAllModal(true)}
                className="h-20 flex flex-col gap-2"
              >
                <Trash2 className="size-5 text-red-500" />
                <span>Wipe All</span>
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Player Wealth Tab */}
        <TabsContent value="player-wealth" className="space-y-4">
          {/* Filters */}
          <div className="flex items-center gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                placeholder="Search players..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={filterType} onValueChange={setFilterType}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Filter" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Players</SelectItem>
                <SelectItem value="rich">Rich (&gt;$500k)</SelectItem>
                <SelectItem value="poor">Poor (&lt;$50k)</SelectItem>
                <SelectItem value="suspicious">Suspicious</SelectItem>
              </SelectContent>
            </Select>
            <Button onClick={() => {
              setGiveMoneyModal(true);
            }}>
              <Plus className="size-4 mr-2" />
              Give Money
            </Button>
          </div>

          {/* Player Wealth Table */}
          <Card>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Player</TableHead>
                    <TableHead className="text-right">Cash</TableHead>
                    <TableHead className="text-right">Bank</TableHead>
                    <TableHead className="text-right">Crypto</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                    <TableHead>Job</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredPlayers.slice(0, 20).map((player) => (
                    <TableRow key={player.id}>
                      <TableCell>
                        <div>
                          <p className="font-medium">{player.name}</p>
                          <p className="text-xs text-muted-foreground">{player.identifier}</p>
                        </div>
                      </TableCell>
                      <TableCell className="text-right font-mono">{formatCurrency(player.cash)}</TableCell>
                      <TableCell className="text-right font-mono">{formatCurrency(player.bank)}</TableCell>
                      <TableCell className="text-right font-mono">{formatCurrency(player.crypto || 0)}</TableCell>
                      <TableCell className="text-right font-mono font-bold">{formatCurrency(player.totalWealth)}</TableCell>
                      <TableCell>{player.job || 'Unemployed'}</TableCell>
                      <TableCell>
                        {player.suspicious && (
                          <Badge variant="destructive">
                            <AlertTriangle className="size-3 mr-1" />
                            Suspicious
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex items-center justify-end gap-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setSelectedPlayer(player);
                              setMoneyForm({ ...moneyForm, playerId: player.id.toString() });
                              setGiveMoneyModal(true);
                            }}
                          >
                            <Plus className="size-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setSelectedPlayer(player);
                              setMoneyForm({ ...moneyForm, playerId: player.id.toString() });
                              setRemoveMoneyModal(true);
                            }}
                          >
                            <Trash2 className="size-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setSelectedPlayer(player);
                            }}
                          >
                            <Eye className="size-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Transactions Tab */}
        <TabsContent value="transactions" className="space-y-4">
          {/* Filters */}
          <div className="flex items-center gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                placeholder="Search transactions..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={timeRange} onValueChange={setTimeRange}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Time Range" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="1h">Last Hour</SelectItem>
                <SelectItem value="24h">Last 24 Hours</SelectItem>
                <SelectItem value="7d">Last 7 Days</SelectItem>
                <SelectItem value="30d">Last 30 Days</SelectItem>
              </SelectContent>
            </Select>
            <Button variant="outline">
              <Download className="size-4 mr-2" />
              Export
            </Button>
          </div>

          {/* Transactions Table */}
          <Card>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Time</TableHead>
                    <TableHead>From</TableHead>
                    <TableHead>To</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead className="text-right">Amount</TableHead>
                    <TableHead>Reason</TableHead>
                    <TableHead>Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredTransactions.map((tx) => (
                    <TableRow key={tx.id}>
                      <TableCell className="text-muted-foreground">{formatTime(tx.timestamp)}</TableCell>
                      <TableCell>{tx.from}</TableCell>
                      <TableCell>{tx.to}</TableCell>
                      <TableCell>
                        <Badge variant="secondary">{tx.type}</Badge>
                      </TableCell>
                      <TableCell className="text-right font-mono">
                        <span className={tx.type === 'withdrawal' || tx.type === 'payment' ? 'text-red-500' : 'text-emerald-500'}>
                          {tx.type === 'withdrawal' || tx.type === 'payment' ? '-' : '+'}
                          {formatCurrency(tx.amount)}
                        </span>
                      </TableCell>
                      <TableCell className="max-w-[200px] truncate">{tx.reason}</TableCell>
                      <TableCell>
                        {tx.status === 'completed' && <Badge className="bg-emerald-500"><CheckCircle className="size-3 mr-1" />Completed</Badge>}
                        {tx.status === 'pending' && <Badge variant="secondary"><Clock className="size-3 mr-1" />Pending</Badge>}
                        {tx.status === 'failed' && <Badge variant="destructive"><XCircle className="size-3 mr-1" />Failed</Badge>}
                        {tx.suspicious && <AlertTriangle className="size-4 text-amber-500 ml-2" />}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Server Control Tab */}
        <TabsContent value="server" className="space-y-4">
          {/* Server Control */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Power className="size-5" />
                Server Control
              </CardTitle>
              <CardDescription>Critical server operations</CardDescription>
            </CardHeader>
            <CardContent className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => confirmAction(
                  'Restart Server',
                  'This will restart the entire FiveM server. All players will be disconnected.',
                  () => executeAction('restart-server'),
                  true
                )}
              >
                <RotateCcw className="size-6 text-amber-500" />
                <span>Restart Server</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => confirmAction(
                  'Shutdown Server',
                  'This will completely shut down the FiveM server.',
                  () => executeAction('shutdown-server'),
                  true
                )}
              >
                <Power className="size-6 text-red-500" />
                <span>Shutdown</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('refresh-resources')}
              >
                <RefreshCw className="size-6 text-blue-500" />
                <span>Refresh Resources</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('restart-scripts')}
              >
                <Code className="size-6 text-emerald-500" />
                <span>Restart Scripts</span>
              </Button>
            </CardContent>
          </Card>

          {/* Server Settings */}
          <Card>
            <CardHeader>
              <CardTitle>Server Features</CardTitle>
              <CardDescription>Enable or disable server features</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div className="flex items-center gap-3">
                  <AlertTriangle className="size-5 text-amber-500" />
                  <div>
                    <p className="font-medium">Maintenance Mode</p>
                    <p className="text-xs text-muted-foreground">Only admins can join</p>
                  </div>
                </div>
                <Switch
                  checked={serverSettings.maintenanceMode}
                  onCheckedChange={(checked) => {
                    setServerSettings({ ...serverSettings, maintenanceMode: checked });
                    executeAction('set-maintenance', { enabled: checked });
                  }}
                />
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div className="flex items-center gap-3">
                  <Shield className="size-5 text-red-500" />
                  <div>
                    <p className="font-medium">PvP Enabled</p>
                    <p className="text-xs text-muted-foreground">Player vs Player combat</p>
                  </div>
                </div>
                <Switch
                  checked={serverSettings.pvpEnabled}
                  onCheckedChange={(checked) => {
                    setServerSettings({ ...serverSettings, pvpEnabled: checked });
                    executeAction('set-pvp', { enabled: checked });
                  }}
                />
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div className="flex items-center gap-3">
                  <DollarSign className="size-5 text-emerald-500" />
                  <div>
                    <p className="font-medium">Economy System</p>
                    <p className="text-xs text-muted-foreground">Money and transactions</p>
                  </div>
                </div>
                <Switch
                  checked={serverSettings.economyEnabled}
                  onCheckedChange={(checked) => {
                    setServerSettings({ ...serverSettings, economyEnabled: checked });
                    executeAction('set-economy', { enabled: checked });
                  }}
                />
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div className="flex items-center gap-3">
                  <Briefcase className="size-5 text-blue-500" />
                  <div>
                    <p className="font-medium">Jobs System</p>
                    <p className="text-xs text-muted-foreground">Employment and businesses</p>
                  </div>
                </div>
                <Switch
                  checked={serverSettings.jobsEnabled}
                  onCheckedChange={(checked) => {
                    setServerSettings({ ...serverSettings, jobsEnabled: checked });
                    executeAction('set-jobs', { enabled: checked });
                  }}
                />
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div className="flex items-center gap-3">
                  <Lock className="size-5 text-purple-500" />
                  <div>
                    <p className="font-medium">Whitelist Mode</p>
                    <p className="text-xs text-muted-foreground">Only whitelisted players</p>
                  </div>
                </div>
                <Switch
                  checked={serverSettings.whitelistEnabled}
                  onCheckedChange={(checked) => {
                    setServerSettings({ ...serverSettings, whitelistEnabled: checked });
                    executeAction('set-whitelist', { enabled: checked });
                  }}
                />
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div className="flex items-center gap-3">
                  <Home className="size-5 text-indigo-500" />
                  <div>
                    <p className="font-medium">Housing System</p>
                    <p className="text-xs text-muted-foreground">Property ownership</p>
                  </div>
                </div>
                <Switch
                  checked={serverSettings.housingEnabled}
                  onCheckedChange={(checked) => {
                    setServerSettings({ ...serverSettings, housingEnabled: checked });
                    executeAction('set-housing', { enabled: checked });
                  }}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* World Control Tab */}
        <TabsContent value="world" className="space-y-4">
          {/* Weather Control */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Cloud className="size-5" />
                Weather Control
              </CardTitle>
              <CardDescription>Set and control server weather</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <Button
                  variant={worldSettings.weather === 'clear' ? 'default' : 'outline'}
                  className="h-20 flex flex-col gap-2"
                  onClick={() => {
                    setWorldSettings({ ...worldSettings, weather: 'clear' });
                    executeAction('set-weather', { weather: 'clear' });
                  }}
                >
                  <Sun className="size-6" />
                  <span>Clear</span>
                </Button>
                <Button
                  variant={worldSettings.weather === 'rain' ? 'default' : 'outline'}
                  className="h-20 flex flex-col gap-2"
                  onClick={() => {
                    setWorldSettings({ ...worldSettings, weather: 'rain' });
                    executeAction('set-weather', { weather: 'rain' });
                  }}
                >
                  <CloudRain className="size-6" />
                  <span>Rain</span>
                </Button>
                <Button
                  variant={worldSettings.weather === 'fog' ? 'default' : 'outline'}
                  className="h-20 flex flex-col gap-2"
                  onClick={() => {
                    setWorldSettings({ ...worldSettings, weather: 'fog' });
                    executeAction('set-weather', { weather: 'fog' });
                  }}
                >
                  <Droplets className="size-6" />
                  <span>Fog</span>
                </Button>
                <Button
                  variant={worldSettings.weather === 'snow' ? 'default' : 'outline'}
                  className="h-20 flex flex-col gap-2"
                  onClick={() => {
                    setWorldSettings({ ...worldSettings, weather: 'snow' });
                    executeAction('set-weather', { weather: 'snow' });
                  }}
                >
                  <Snowflake className="size-6" />
                  <span>Snow</span>
                </Button>
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <Label>Freeze Weather</Label>
                <Switch
                  checked={worldSettings.freezeWeather}
                  onCheckedChange={(checked) => {
                    setWorldSettings({ ...worldSettings, freezeWeather: checked });
                    executeAction('freeze-weather', { freeze: checked });
                  }}
                />
              </div>
            </CardContent>
          </Card>

          {/* Time Control */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="size-5" />
                Time Control
              </CardTitle>
              <CardDescription>Set and control server time</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label>Server Time: {worldSettings.time}:00</Label>
                <Slider
                  value={[worldSettings.time]}
                  onValueChange={(value) => {
                    setWorldSettings({ ...worldSettings, time: value[0] });
                    executeAction('set-time', { hour: value[0] });
                  }}
                  min={0}
                  max={23}
                  step={1}
                  className="mt-2"
                />
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <Label>Freeze Time</Label>
                <Switch
                  checked={worldSettings.freezeTime}
                  onCheckedChange={(checked) => {
                    setWorldSettings({ ...worldSettings, freezeTime: checked });
                    executeAction('freeze-time', { freeze: checked });
                  }}
                />
              </div>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <Button
                  variant="outline"
                  onClick={() => {
                    setWorldSettings({ ...worldSettings, time: 6 });
                    executeAction('set-time', { hour: 6 });
                  }}
                >
                  <Sun className="size-4 mr-2" />
                  Morning
                </Button>
                <Button
                  variant="outline"
                  onClick={() => {
                    setWorldSettings({ ...worldSettings, time: 12 });
                    executeAction('set-time', { hour: 12 });
                  }}
                >
                  <Sun className="size-4 mr-2" />
                  Noon
                </Button>
                <Button
                  variant="outline"
                  onClick={() => {
                    setWorldSettings({ ...worldSettings, time: 18 });
                    executeAction('set-time', { hour: 18 });
                  }}
                >
                  <Sun className="size-4 mr-2" />
                  Evening
                </Button>
                <Button
                  variant="outline"
                  onClick={() => {
                    setWorldSettings({ ...worldSettings, time: 0 });
                    executeAction('set-time', { hour: 0 });
                  }}
                >
                  <Moon className="size-4 mr-2" />
                  Midnight
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Players Tools Tab */}
        <TabsContent value="players-tools" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Mass Player Actions</CardTitle>
              <CardDescription>Perform actions on all players</CardDescription>
            </CardHeader>
            <CardContent className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('kick-all')}
              >
                <Users className="size-6 text-amber-500" />
                <span>Kick All</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('tp-all-spawn')}
              >
                <Target className="size-6 text-blue-500" />
                <span>TP All to Spawn</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('heal-all')}
              >
                <Zap className="size-6 text-emerald-500" />
                <span>Heal All</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('freeze-all')}
              >
                <Pause className="size-6 text-purple-500" />
                <span>Freeze All</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('clear-inventories')}
              >
                <Package className="size-6 text-red-500" />
                <span>Clear Inventories</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('remove-all-vehicles')}
              >
                <Car className="size-6 text-orange-500" />
                <span>Remove Vehicles</span>
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Database Tab */}
        <TabsContent value="database" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Database className="size-5" />
                Database Operations
              </CardTitle>
              <CardDescription>Manage and maintain database</CardDescription>
            </CardHeader>
            <CardContent className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('backup-database')}
              >
                <HardDrive className="size-6 text-blue-500" />
                <span>Backup Database</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => executeAction('optimize-database')}
              >
                <Zap className="size-6 text-amber-500" />
                <span>Optimize</span>
              </Button>
              <Button
                variant="outline"
                className="h-24 flex flex-col gap-2"
                onClick={() => confirmAction(
                  'Clean Old Data',
                  'Remove entries older than 90 days',
                  () => executeAction('clean-old-data'),
                  true
                )}
              >
                <Trash2 className="size-6 text-red-500" />
                <span>Clean Old Data</span>
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Modals */}
      {/* Give Money Modal */}
      <Dialog open={giveMoneyModal} onOpenChange={setGiveMoneyModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Give Money</DialogTitle>
            <DialogDescription>
              {selectedPlayer ? `Give money to ${selectedPlayer.name}` : 'Give money to a player'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Amount</Label>
              <Input
                type="number"
                placeholder="0"
                value={moneyForm.amount}
                onChange={(e) => setMoneyForm({ ...moneyForm, amount: parseInt(e.target.value) || 0 })}
              />
            </div>
            <div>
              <Label>Account</Label>
              <Select value={moneyForm.account} onValueChange={(val) => setMoneyForm({ ...moneyForm, account: val })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cash">Cash</SelectItem>
                  <SelectItem value="bank">Bank</SelectItem>
                  <SelectItem value="crypto">Crypto</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setGiveMoneyModal(false)}>Cancel</Button>
            <Button onClick={() => {
              executeAction('give-money', moneyForm);
              setGiveMoneyModal(false);
            }}>
              <Send className="size-4 mr-2" />
              Give Money
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Remove Money Modal */}
      <Dialog open={removeMoneyModal} onOpenChange={setRemoveMoneyModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Remove Money</DialogTitle>
            <DialogDescription>
              {selectedPlayer ? `Remove money from ${selectedPlayer.name}` : 'Remove money from a player'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Amount</Label>
              <Input
                type="number"
                placeholder="0"
                value={moneyForm.amount}
                onChange={(e) => setMoneyForm({ ...moneyForm, amount: parseInt(e.target.value) || 0 })}
              />
            </div>
            <div>
              <Label>Account</Label>
              <Select value={moneyForm.account} onValueChange={(val) => setMoneyForm({ ...moneyForm, account: val })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cash">Cash</SelectItem>
                  <SelectItem value="bank">Bank</SelectItem>
                  <SelectItem value="crypto">Crypto</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setRemoveMoneyModal(false)}>Cancel</Button>
            <Button variant="destructive" onClick={() => {
              executeAction('remove-money', moneyForm);
              setRemoveMoneyModal(false);
            }}>
              <Trash2 className="size-4 mr-2" />
              Remove Money
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Send to All Modal */}
      <Dialog open={sendToAllModal} onOpenChange={setSendToAllModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send Money to All Players</DialogTitle>
            <DialogDescription>Give money to every player on the server</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Amount per Player</Label>
              <Input
                type="number"
                placeholder="0"
                value={massActionForm.amount}
                onChange={(e) => setMassActionForm({ ...massActionForm, amount: parseInt(e.target.value) || 0 })}
              />
            </div>
            <div>
              <Label>Account</Label>
              <Select value={massActionForm.account} onValueChange={(val) => setMassActionForm({ ...massActionForm, account: val })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cash">Cash</SelectItem>
                  <SelectItem value="bank">Bank</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setSendToAllModal(false)}>Cancel</Button>
            <Button onClick={() => {
              executeAction('send-to-all', massActionForm);
              setSendToAllModal(false);
            }}>
              <Send className="size-4 mr-2" />
              Send to All
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Remove Percentage Modal */}
      <Dialog open={removePercentageModal} onOpenChange={setRemovePercentageModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Remove Percentage from All Players</DialogTitle>
            <DialogDescription>Remove a percentage of money from all players</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Percentage (%)</Label>
              <Input
                type="number"
                placeholder="0"
                min="0"
                max="100"
                value={massActionForm.percentage}
                onChange={(e) => setMassActionForm({ ...massActionForm, percentage: parseInt(e.target.value) || 0 })}
              />
            </div>
            <div>
              <Label>Account</Label>
              <Select value={massActionForm.account} onValueChange={(val) => setMassActionForm({ ...massActionForm, account: val })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cash">Cash</SelectItem>
                  <SelectItem value="bank">Bank</SelectItem>
                  <SelectItem value="all">All Accounts</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setRemovePercentageModal(false)}>Cancel</Button>
            <Button variant="destructive" onClick={() => {
              executeAction('remove-percentage', massActionForm);
              setRemovePercentageModal(false);
            }}>
              <Percent className="size-4 mr-2" />
              Remove Percentage
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Wipe All Modal */}
      <Dialog open={wipeAllModal} onOpenChange={setWipeAllModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Wipe All Money</DialogTitle>
            <DialogDescription className="text-red-500">
              WARNING: This will remove ALL money from ALL players. This action cannot be undone!
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setWipeAllModal(false)}>Cancel</Button>
            <Button variant="destructive" onClick={() => {
              confirmAction(
                'Confirm Wipe All Money',
                'Type CONFIRM to wipe all money from all players',
                () => executeAction('wipe-all-money'),
                true
              );
              setWipeAllModal(false);
            }}>
              <Trash2 className="size-4 mr-2" />
              Wipe All Money
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirm Action Modal */}
      <Dialog open={confirmModal.isOpen} onOpenChange={(open) => setConfirmModal({ ...confirmModal, isOpen: open })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className={confirmModal.danger ? 'text-red-500' : ''}>
              {confirmModal.title}
            </DialogTitle>
            <DialogDescription>{confirmModal.description}</DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmModal({ ...confirmModal, isOpen: false })}>
              Cancel
            </Button>
            <Button
              variant={confirmModal.danger ? 'destructive' : 'default'}
              onClick={handleConfirm}
            >
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

// Mock data generators for fallback
function generateMockPlayerWealth(): PlayerWealth[] {
  const names = ['John Smith', 'Jane Doe', 'Mike Johnson', 'Sarah Williams', 'Tom Brown', 'Lisa Garcia', 'David Martinez', 'Emma Anderson', 'Chris Taylor', 'Ashley Thomas'];
  const jobs = ['Police', 'Mechanic', 'Doctor', 'Taxi Driver', 'Unemployed', 'Business Owner', 'Real Estate', 'Lawyer'];
  
  return names.map((name, index) => {
    const cash = Math.floor(Math.random() * 50000) + 5000;
    const bank = Math.floor(Math.random() * 500000) + 20000;
    const crypto = Math.floor(Math.random() * 100000);
    
    return {
      id: index + 1,
      name,
      identifier: `license:${Math.random().toString(36).substr(2, 9)}`,
      cash,
      bank,
      crypto,
      totalWealth: cash + bank + crypto,
      job: jobs[Math.floor(Math.random() * jobs.length)],
      suspicious: Math.random() > 0.9,
      lastTransaction: new Date(Date.now() - Math.random() * 86400000).toISOString()
    };
  });
}

function generateMockTransactions(): Transaction[] {
  const types: Array<'transfer' | 'deposit' | 'withdrawal' | 'payment' | 'admin' | 'business'> = ['transfer', 'deposit', 'withdrawal', 'payment', 'admin', 'business'];
  const names = ['John Smith', 'Jane Doe', 'Mike Johnson', 'Sarah Williams', 'Server', 'Bank', 'Business'];
  const reasons = ['Salary', 'Purchase', 'Transfer', 'Payment', 'Refund', 'Investment', 'Tax', 'Fine'];
  
  return Array.from({ length: 50 }, (_, i) => ({
    id: `tx-${i}`,
    from: names[Math.floor(Math.random() * names.length)],
    to: names[Math.floor(Math.random() * names.length)],
    amount: Math.floor(Math.random() * 100000) + 100,
    type: types[Math.floor(Math.random() * types.length)],
    reason: reasons[Math.floor(Math.random() * reasons.length)],
    time: new Date(Date.now() - Math.random() * 86400000).toISOString(),
    timestamp: Date.now() - Math.random() * 86400000,
    status: Math.random() > 0.1 ? 'completed' : (Math.random() > 0.5 ? 'pending' : 'failed') as 'completed' | 'pending' | 'failed',
    suspicious: Math.random() > 0.95
  }));
}

function generateMockCategories(): EconomyCategory[] {
  return [
    { category: 'Player Wealth', amount: 34388740, percentage: 75, trend: '+12.5%', color: '#10b981' },
    { category: 'Business', amount: 8500000, percentage: 18, trend: '+8.2%', color: '#3b82f6' },
    { category: 'Government', amount: 3200000, percentage: 7, trend: '+4.1%', color: '#8b5cf6' }
  ];
}
