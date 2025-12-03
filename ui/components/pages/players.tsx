import { useState, useMemo, useEffect, useRef } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Checkbox } from '../ui/checkbox';
import { ScrollArea } from '../ui/scroll-area';
import { Separator } from '../ui/separator';
import { 
  Users, Search, Filter, Download, RefreshCw, MoreVertical,
  UserX, Ban, Eye, MapPin, AlertTriangle, DollarSign,
  Heart, Shield, Zap, Clock, Activity, UserCheck, UserMinus,
  Wifi, WifiOff, ChevronDown, BarChart3, PieChart, Target,
  UserPlus, Pause, TrendingUp, ArrowUpDown, CheckSquare,
  Globe, Play, User, MoreHorizontal, Calendar, Settings
} from 'lucide-react';
import { AdminActionModal } from '../admin-action-modals';
import { toastSuccess, toastError } from '../../lib/toast';
import { LineChart, Line, BarChart, Bar, PieChart as RechartsPie, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { getPlayers, subscribeToData, dataManager } from '../../lib/data-manager';

interface PlayersPageProps {
  liveData: any;
  onNavigateToProfile?: (playerId: number) => void;
}

interface Player {
  id: number;
  name: string;
  steamid: string;
  ping?: number;
  playtime: string;
  playtimeMinutes?: number;
  status?: 'playing' | 'afk' | 'offline';
  admin: boolean;
  location?: string;
  lastSeen?: string;
  money?: number;
  job?: string;
  gang?: string;
  level?: number;
  warnings?: number;
  online?: boolean;
  joinDate?: string;
}

interface BannedPlayer {
  id: number;
  name: string;
  steamid: string;
  reason: string;
  bannedBy: string;
  banDate: string;
  duration: string;
  expiresAt?: string;
}

export function PlayersPage({ liveData, onNavigateToProfile }: PlayersPageProps) {
  const [activeTab, setActiveTab] = useState('online');
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc');
  const [filterRole, setFilterRole] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [selectedPlayers, setSelectedPlayers] = useState<Set<number>>(new Set());
  const [showBulkActions, setShowBulkActions] = useState(false);
  const [refreshTrigger, setRefreshTrigger] = useState(0); // Trigger for manual refresh
  const [actionModal, setActionModal] = useState<{ isOpen: boolean; player: any; action: any }>(({
    isOpen: false,
    player: null,
    action: null
  }));
  
  // Real-time player data from FiveM
  const [realTimePlayers, setRealTimePlayers] = useState<Player[]>([]);
  const [offlinePlayers, setOfflinePlayers] = useState<Player[]>([]);
  const [bannedPlayers, setBannedPlayers] = useState<BannedPlayer[]>([]);
  const [fetchError, setFetchError] = useState<string | null>(null);
  
  // NEW: Real player history data from server
  const [playerHistory, setPlayerHistory] = useState<any[]>([]);
  const [peakToday, setPeakToday] = useState(0);
  const [newToday, setNewToday] = useState(0);
  
  // Use refs to track previous data and prevent unnecessary updates
  const lastPlayersHashRef = useRef<string>('');
  const lastHistoryHashRef = useRef<string>('');

  // Fetch real player data from API
  useEffect(() => {
    let isMounted = true;
    
    const fetchPlayers = async () => {
      // Don't show loading spinner for refreshes
      if (realTimePlayers.length === 0) {
        setIsLoading(true);
      }
      setFetchError(null);

      try {
        // Check if we're in Figma/browser environment (no FiveM NUI)
        const isInGame = !!(window as any).GetParentResourceName;
        
        let data: any;
        
        if (isInGame) {
          // IN-GAME MODE: Fetch real data from server
          console.log('[Players] IN-GAME MODE - Fetching real player data from server');
          
          // @ts-ignore - NUI callback
          const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'ec_admin_ultimate'}/getPlayers`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ includeOffline: activeTab !== 'online' })
          });
          
          if (!response.ok) {
            throw new Error('Server returned ' + response.status + ': ' + response.statusText);
          }
          
          data = await response.json();
          
          // CRITICAL: Validate response structure
          if (!data || typeof data !== 'object') {
            throw new Error('Invalid response: not an object');
          }
          
          if (!data.success) {
            throw new Error(data.error || 'Server returned success=false');
          }
          
          if (!Array.isArray(data.players)) {
            throw new Error('Invalid players data: expected array, got ' + typeof data.players);
          }
          
          console.log('[Players] ✅ Received ' + data.players.length + ' players from server');
          
        } else {
          // FIGMA/BROWSER MODE ONLY: Use mock data
          console.log('[Players] BROWSER/FIGMA MODE - Using mock data (NOT IN-GAME)');
          data = {
            success: true,
            players: [
              { source: 1, name: 'John Doe', identifier: 'steam:110000103fa6f42', ping: 42, playtime: 450, status: 'playing', admin: true, location: 'Legion Square', online: true, money: 25000, job: { name: 'Police' }, level: 45, warnings: 0 },
              { source: 2, name: 'Jane Smith', identifier: 'steam:110000103fa6f43', ping: 38, playtime: 320, status: 'playing', admin: false, location: 'Sandy Shores', online: true, money: 15000, job: { name: 'Mechanic' }, level: 32, warnings: 1 },
              { source: 3, name: 'Mike Johnson', identifier: 'steam:110000103fa6f44', ping: 55, playtime: 890, status: 'afk', admin: false, location: 'Paleto Bay', online: true, money: 42000, job: { name: 'Civilian' }, level: 67, warnings: 0 },
              { source: 4, name: 'Sarah Williams', identifier: 'steam:110000103fa6f45', ping: 28, playtime: 1200, status: 'playing', admin: true, location: 'Downtown', online: true, money: 85000, job: { name: 'EMS' }, level: 89, warnings: 0 },
              { source: 5, name: 'Chris Brown', identifier: 'steam:110000103fa6f46', ping: 95, playtime: 180, status: 'playing', admin: false, location: 'LSIA', online: true, money: 8000, job: { name: 'Taxi Driver' }, level: 18, warnings: 2 }
            ],
            history: Array.from({ length: 24 }, (_, i) => ({
              hour: i,
              time: i < 12 ? (i || 12) + ' AM' : (i - 12 || 12) + ' PM',
              players: Math.floor(Math.random() * 30) + 10,
              peak: Math.floor(Math.random() * 40) + 20
            })),
            peakToday: 45
          };
        }

        if (!isMounted) return; // Component unmounted, abort

        if (data.success && data.players) {
          // Create hash of raw player data BEFORE transformation
          const rawDataHash = JSON.stringify(data.players.map((p: any) => p.id || p.source));
          
          // Only update if player list actually changed
          if (rawDataHash !== lastPlayersHashRef.current) {
            lastPlayersHashRef.current = rawDataHash;
            
            // Transform API data to match UI interface
            const transformedPlayers = data.players.map((p: any) => ({
              id: p.source || p.id,
              name: p.name,
              steamid: p.identifier || p.steamid,
              ping: p.ping,
              playtime: formatPlaytime(p.playtime || 0),
              playtimeMinutes: p.playtime || 0,
              status: p.status || (p.online ? 'playing' : 'offline'),
              admin: p.admin || p.isAdmin || false,
              location: p.location || p.zone,
              lastSeen: p.lastSeen,
              money: p.money || p.cash,
              job: p.job?.name || p.job,
              gang: p.gang?.name || p.gang,
              level: p.level,
              warnings: p.warnings || 0,
              online: p.online !== false,
              joinDate: p.joinDate || p.createdAt
            }));

            if (activeTab === 'online') {
              setRealTimePlayers(transformedPlayers.filter((p: Player) => p.online));
            } else if (activeTab === 'offline') {
              setOfflinePlayers(transformedPlayers.filter((p: Player) => !p.online));
            }
          }
          
          // Store real player history and peak data from server (only if changed)
          if (data.history && data.history.length > 0) {
            const historyHash = JSON.stringify(data.history);
            if (historyHash !== lastHistoryHashRef.current) {
              lastHistoryHashRef.current = historyHash;
              setPlayerHistory(data.history);
            }
          }
          if (data.peakToday !== undefined && data.peakToday !== peakToday) {
            setPeakToday(data.peakToday);
          }
          if (data.newToday !== undefined && data.newToday !== newToday) {
            setNewToday(data.newToday);
          }
        } else {
          console.warn('[Players] No player data available');
          setFetchError(data.error || 'Failed to fetch players');
        }
      } catch (err) {
        console.error('[Players] Failed to fetch player data:', err);
        setFetchError('Failed to load player data. Check server connection.');
      } finally {
        if (isMounted) {
          setIsLoading(false);
        }
      }
    };

    const fetchBannedPlayers = async () => {
      if (!isMounted) return;
      
      try {
        // Check if we're in Figma/browser environment (no FiveM NUI)
        const isInGame = !!(window as any).GetParentResourceName;
        
        let data: any;
        
        if (isInGame) {
          // @ts-ignore
          const response = await fetch(`https://${(window as any).GetParentResourceName?.() || 'ec_admin_ultimate'}/getBans`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
          });
          data = await response.json();
        } else {
          // FIGMA/BROWSER MODE: Use mock ban data
          data = {
            success: true,
            bans: [
              { id: 1, playerName: 'Hacker123', identifier: 'steam:110000103fa6f99', reason: 'Cheating', bannedBy: 'Admin Mike', createdAt: '2025-01-10', permanent: true },
              { id: 2, playerName: 'Toxic Player', identifier: 'steam:110000103fa6f88', reason: 'Harassment', bannedBy: 'Admin Sarah', createdAt: '2025-01-09', duration: '7 days', expiresAt: '2025-01-16' }
            ]
          };
        }

        if (!isMounted) return;

        if (data.success && data.bans) {
          const transformedBans = data.bans.map((b: any) => ({
            id: b.id,
            name: b.playerName || b.name,
            steamid: b.identifier || b.steamid,
            reason: b.reason,
            bannedBy: b.bannedBy || b.admin,
            banDate: b.createdAt || b.banDate,
            duration: b.permanent ? 'Permanent' : b.duration,
            expiresAt: b.expiresAt
          }));

          setBannedPlayers(transformedBans);
        }
      } catch (err) {
        console.error('[Players] Failed to fetch banned players:', err);
      }
    };

    // Initial fetch
    if (activeTab === 'banned') {
      fetchBannedPlayers();
    } else {
      fetchPlayers();
    }

    // Refresh every 30 seconds (REDUCED from 5 seconds to prevent constant reloading)
    // Only for online players tab
    const interval = setInterval(() => {
      if (isMounted && activeTab === 'online') {
        fetchPlayers();
      }
    }, 30000); // Changed from 5000 to 30000 (30 seconds)

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [activeTab, refreshTrigger]); // Only re-run when tab changes or refresh trigger is incremented

  function formatPlaytime(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return hours + 'h ' + mins + 'm';
  }

  // Statistics calculations - NOW USES REAL DATA
  const stats = useMemo(() => {
    const onlineCount = realTimePlayers.length;
    const offlineCount = offlinePlayers.length;
  const adminsOnline = realTimePlayers.filter(p => p.admin).length;
    const afkCount = realTimePlayers.filter(p => p.status === 'afk').length;
    const avgPing = onlineCount > 0
      ? Math.round(realTimePlayers.reduce((sum, p) => sum + (p.ping || 0), 0) / onlineCount)
      : 0;

    return {
      totalPlayers: onlineCount + offlineCount,
      onlineCount,
      adminsOnline,
      afkCount,
      avgPing,
      newToday: newToday || 0, // Use real data from server
      peakToday: peakToday || onlineCount // Use REAL peak from server
    };
  }, [realTimePlayers, offlinePlayers, peakToday, newToday]);

  // Chart data - NOW USES REAL HISTORY FROM SERVER
  const playerActivityData = useMemo(() => {
    // If we have real history, use it. Otherwise show empty chart
    if (playerHistory && playerHistory.length > 0) {
      return playerHistory;
    }
    
    // Empty/initial state - show flat line at 0
    const hours = [];
    const now = new Date();
    for (let i = 23; i >= 0; i--) {
      const hour = new Date(now.getTime() - i * 60 * 60 * 1000);
      hours.push({
        hour: hour.getHours() < 12 ? (hour.getHours() || 12) + ' AM' : (hour.getHours() - 12 || 12) + ' PM',
        time: hour.getHours(),
        players: 0,
        peak: 0
      });
    }
    return hours;
  }, [playerHistory]);

  const playtimeDistributionData = useMemo(() => {
    return [
      { range: '0-10h', count: 12, percentage: 15 },
      { range: '10-50h', count: 24, percentage: 30 },
      { range: '50-100h', count: 18, percentage: 23 },
      { range: '100-500h', count: 16, percentage: 20 },
      { range: '500h+', count: 10, percentage: 12 }
    ];
  }, []);

  const jobDistributionData = useMemo(() => {
    const jobCounts: Record<string, number> = {};
    realTimePlayers.forEach(p => {
      if (p.job) {
        jobCounts[p.job] = (jobCounts[p.job] || 0) + 1;
      }
    });
    
    return Object.entries(jobCounts).map(([name, value]) => ({ name, value }));
  }, [realTimePlayers]);

  const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#06b6d4'];

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 500);

    return () => clearTimeout(timer);
  }, []);

  // Filtering and sorting
  const filteredAndSortedPlayers = useMemo(() => {
    let players = activeTab === 'online' ? realTimePlayers : offlinePlayers;
    
    // Filter by search
    if (searchTerm) {
      players = players.filter(player =>
        player.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        player.steamid.toLowerCase().includes(searchTerm.toLowerCase()) ||
        player.job?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    
    // Filter by role
    if (filterRole !== 'all') {
      players = players.filter(p => filterRole === 'admin' ? p.admin : !p.admin);
    }
    
    // Filter by status
    if (filterStatus !== 'all' && activeTab === 'online') {
      players = players.filter(p => p.status === filterStatus);
    }
    
    // Sort
    const sorted = [...players].sort((a, b) => {
      let aVal: any = a[sortBy as keyof Player];
      let bVal: any = b[sortBy as keyof Player];
      
      if (sortBy === 'playtime') {
        aVal = a.playtimeMinutes || 0;
        bVal = b.playtimeMinutes || 0;
      }
      
      if (typeof aVal === 'string') {
        return sortOrder === 'asc' ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
      }
      
      return sortOrder === 'asc' ? (aVal || 0) - (bVal || 0) : (bVal || 0) - (aVal || 0);
    });
    
    return sorted;
  }, [realTimePlayers, offlinePlayers, activeTab, searchTerm, filterRole, filterStatus, sortBy, sortOrder]);

  const filteredBannedPlayers = useMemo(() => {
    if (!searchTerm) return bannedPlayers;
    return bannedPlayers.filter(player =>
      player.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      player.steamid.toLowerCase().includes(searchTerm.toLowerCase()) ||
      player.reason.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [bannedPlayers, searchTerm]);

  // Player action handlers with FiveM backend integration
  const handlePlayerAction = async (player: Player, action: string) => {
    try {
      switch (action) {
        case 'spectate':
          await fetch('https://ec_admin_ultimate/spectatePlayer', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerId: player.id })
          });
          toastSuccess({
            title: 'Spectating Player',
            description: `Now spectating ${player.name}`
          });
          break;
          
        case 'kick':
          setActionModal({ isOpen: true, player, action: 'kick' });
          break;
          
        case 'ban':
          setActionModal({ isOpen: true, player, action: 'ban' });
          break;
          
        case 'warn':
          setActionModal({ isOpen: true, player, action: 'warn' });
          break;
          
        case 'freeze':
          await fetch('https://ec_admin_ultimate/freezePlayer', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerId: player.id, freeze: true })
          });
          toastSuccess({
            title: 'Player Frozen',
            description: player.name + ' has been frozen'
          });
          break;
          
        case 'teleport':
          setActionModal({ isOpen: true, player, action: 'teleport' });
          break;
          
        case 'revive':
          await fetch('https://ec_admin_ultimate/revivePlayer', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerId: player.id })
          });
          toastSuccess({
            title: 'Player Revived',
            description: player.name + ' has been revived'
          });
          break;
          
        case 'heal':
          await fetch('https://ec_admin_ultimate/healPlayer', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerId: player.id })
          });
          toastSuccess({
            title: 'Player Healed',
            description: player.name + ' has been healed'
          });
          break;
          
        case 'more':
          setActionModal({ isOpen: true, player, action: 'actions' });
          break;
          
        default:
          setActionModal({ isOpen: true, player, action });
          break;
      }
    } catch (error) {
      console.error('Player action failed:', error);
      toastError({
        title: 'Action Failed',
        description: 'Failed to perform action. Check console.'
      });
    }
  };

  const handleActionConfirm = (data: any) => {
    console.log('Admin Action:', data);
    toastSuccess({
      title: 'Action Completed',
      description: data.action + ' for player ID ' + data.playerId
    });
    setActionModal({ isOpen: false, player: null, action: null });
  };

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedPlayers(new Set(filteredAndSortedPlayers.map(p => p.id)));
    } else {
      setSelectedPlayers(new Set());
    }
  };

  const handleSelectPlayer = (playerId: number, checked: boolean) => {
    const newSelected = new Set(selectedPlayers);
    if (checked) {
      newSelected.add(playerId);
    } else {
      newSelected.delete(playerId);
    }
    setSelectedPlayers(newSelected);
  };

  // Bulk action handler with FiveM integration
  const handleBulkAction = async (action: string) => {
    const playerIds = Array.from(selectedPlayers);
    
    try {
      switch (action) {
        case 'Kick':
          await fetch('https://ec_admin_ultimate/kickPlayers', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerIds, reason: 'Bulk action' })
          });
          toastSuccess({
            title: 'Players Kicked',
            description: `Kicked ${playerIds.length} players`
          });
          break;
          
        case 'Ban':
          setActionModal({ isOpen: true, player: { id: playerIds }, action: 'bulkBan' });
          break;
          
        case 'Message':
          setActionModal({ isOpen: true, player: { id: playerIds }, action: 'bulkMessage' });
          break;
          
        case 'Teleport':
          await fetch('https://ec_admin_ultimate/teleportPlayers', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ playerIds, coords: { x: 0, y: 0, z: 0 } })
          });
          toastSuccess({
            title: 'Players Teleported',
            description: `Teleported ${playerIds.length} players`
          });
          break;
      }
      
      setSelectedPlayers(new Set());
      setShowBulkActions(false);
    } catch (error) {
      console.error('Bulk action failed:', error);
      toastError({
        title: 'Bulk Action Failed',
        description: 'Failed to perform bulk action. Check console.'
      });
    }
  };

  const handleSort = (field: string) => {
    if (sortBy === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(field);
      setSortOrder('asc');
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Users className="size-12 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg">Loading Players...</p>
          <p className="text-sm text-muted-foreground">Fetching player data from server</p>
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
            <span className="bg-gradient-to-r from-green-600 to-blue-600 dark:from-green-400 dark:to-blue-400 bg-clip-text text-transparent">
              Player Management
            </span>
          </h1>
          <p className="text-muted-foreground mt-1">
            Monitor and manage {stats.totalPlayers} registered players
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => setRefreshTrigger(refreshTrigger + 1)}>
            <RefreshCw className="size-4 mr-2" />
            Refresh
          </Button>
          <Button variant="outline" size="sm">
            <Download className="size-4 mr-2" />
            Export
          </Button>
          <Button>
            <UserPlus className="size-4 mr-2" />
            Add Player
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 xl:grid-cols-6 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-500/10 rounded-lg">
                <Wifi className="size-5 text-green-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Online</p>
                <p className="text-2xl">{stats.onlineCount}</p>
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
                <p className="text-sm text-muted-foreground">Total</p>
                <p className="text-2xl">{stats.totalPlayers}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-500/10 rounded-lg">
                <Shield className="size-5 text-purple-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Admins</p>
                <p className="text-2xl">{stats.adminsOnline}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-yellow-500/10 rounded-lg">
                <Pause className="size-5 text-yellow-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">AFK</p>
                <p className="text-2xl">{stats.afkCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-500/10 rounded-lg">
                <Activity className="size-5 text-orange-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Avg Ping</p>
                <p className="text-2xl">{stats.avgPing}ms</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-500/10 rounded-lg">
                <TrendingUp className="size-5 text-cyan-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Peak Today</p>
                <p className="text-2xl">{stats.peakToday}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="size-5" />
              Player Activity (24h)
            </CardTitle>
            <CardDescription>Hourly player count over the last 24 hours</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[200px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={playerActivityData}>
                  <defs>
                    <linearGradient id="colorPlayers" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
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
                  <Area 
                    type="monotone" 
                    dataKey="players" 
                    stroke="#3b82f6" 
                    fillOpacity={1} 
                    fill="url(#colorPlayers)" 
                    strokeWidth={2}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <PieChart className="size-5" />
              Job Distribution
            </CardTitle>
            <CardDescription>Active players by job role</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[200px]">
              <ResponsiveContainer width="100%" height="100%">
                <RechartsPie>
                  <Pie
                    data={jobDistributionData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) => name + ' ' + (percent * 100).toFixed(0) + '%'}
                    outerRadius={60}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {jobDistributionData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'hsl(var(--card))',
                      border: '1px solid hsl(var(--border))',
                      borderRadius: '8px'
                    }}
                  />
                </RechartsPie>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters & Search */}
      <Card>
        <CardContent className="p-4">
          <div className="flex flex-col lg:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                placeholder="Search by name, Steam ID, or job..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            
            <Select value={filterRole} onValueChange={setFilterRole}>
              <SelectTrigger className="w-full lg:w-[180px]">
                <SelectValue placeholder="Filter by role" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Roles</SelectItem>
                <SelectItem value="admin">Admins Only</SelectItem>
                <SelectItem value="player">Players Only</SelectItem>
              </SelectContent>
            </Select>

            {activeTab === 'online' && (
              <Select value={filterStatus} onValueChange={setFilterStatus}>
                <SelectTrigger className="w-full lg:w-[180px]">
                  <SelectValue placeholder="Filter by status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="playing">Playing</SelectItem>
                  <SelectItem value="afk">AFK</SelectItem>
                </SelectContent>
              </Select>
            )}

            <Select value={sortBy} onValueChange={setSortBy}>
              <SelectTrigger className="w-full lg:w-[180px]">
                <SelectValue placeholder="Sort by" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="name">Name</SelectItem>
                <SelectItem value="playtime">Playtime</SelectItem>
                <SelectItem value="level">Level</SelectItem>
                <SelectItem value="money">Money</SelectItem>
                {activeTab === 'online' && <SelectItem value="ping">Ping</SelectItem>}
              </SelectContent>
            </Select>

            <Button
              variant="outline"
              size="icon"
              onClick={() => setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')}
              title={sortOrder === 'asc' ? 'Ascending' : 'Descending'}
            >
              <ArrowUpDown className="size-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Bulk Actions Bar */}
      {selectedPlayers.size > 0 && (
        <Card className="border-primary">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <CheckSquare className="size-5 text-primary" />
                <span className="font-medium">{selectedPlayers.size} players selected</span>
              </div>
              <div className="flex items-center gap-2">
                <Button variant="outline" size="sm" onClick={() => handleBulkAction('Kick')}>
                  <UserX className="size-4 mr-1" />
                  Kick All
                </Button>
                <Button variant="outline" size="sm" onClick={() => handleBulkAction('Message')}>
                  <Globe className="size-4 mr-1" />
                  Message All
                </Button>
                <Button variant="outline" size="sm" onClick={() => handleBulkAction('Teleport')}>
                  <MapPin className="size-4 mr-1" />
                  Teleport All
                </Button>
                <Button variant="destructive" size="sm" onClick={() => handleBulkAction('Ban')}>
                  <Ban className="size-4 mr-1" />
                  Ban All
                </Button>
                <Button variant="ghost" size="sm" onClick={() => setSelectedPlayers(new Set())}>
                  Clear
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="online">
            <Wifi className="size-4 mr-2" />
            Online ({filteredAndSortedPlayers.length > 0 && activeTab === 'online' ? filteredAndSortedPlayers.length : realTimePlayers.length})
          </TabsTrigger>
          <TabsTrigger value="offline">
            <WifiOff className="size-4 mr-2" />
            Offline ({filteredAndSortedPlayers.length > 0 && activeTab === 'offline' ? filteredAndSortedPlayers.length : offlinePlayers.length})
          </TabsTrigger>
          <TabsTrigger value="banned">
            <Ban className="size-4 mr-2" />
            Banned ({filteredBannedPlayers.length})
          </TabsTrigger>
        </TabsList>

        {/* Online Players Tab */}
        <TabsContent value="online" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="size-5" />
                Online Players
              </CardTitle>
              <CardDescription>
                {filteredAndSortedPlayers.length} of {realTimePlayers.length} players shown
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-12">
                        <Checkbox
                          checked={selectedPlayers.size === filteredAndSortedPlayers.length && filteredAndSortedPlayers.length > 0}
                          onCheckedChange={handleSelectAll}
                        />
                      </TableHead>
                      <TableHead className="cursor-pointer" onClick={() => handleSort('name')}>
                        Player {sortBy === 'name' && (sortOrder === 'asc' ? '↑' : '↓')}
                      </TableHead>
                      <TableHead>Steam ID</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Job</TableHead>
                      <TableHead>Location</TableHead>
                      <TableHead className="cursor-pointer" onClick={() => handleSort('ping')}>
                        Ping {sortBy === 'ping' && (sortOrder === 'asc' ? '↑' : '↓')}
                      </TableHead>
                      <TableHead className="cursor-pointer" onClick={() => handleSort('playtime')}>
                        Playtime {sortBy === 'playtime' && (sortOrder === 'asc' ? '↑' : '↓')}
                      </TableHead>
                      <TableHead>Role</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredAndSortedPlayers.map((player) => (
                      <TableRow key={player.id} className={selectedPlayers.has(player.id) ? 'bg-primary/5' : ''}>
                        <TableCell>
                          <Checkbox
                            checked={selectedPlayers.has(player.id)}
                            onCheckedChange={(checked) => handleSelectPlayer(player.id, checked as boolean)}
                          />
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <div className={`size-2 rounded-full ${player.status === 'playing' ? 'bg-green-500' : 'bg-yellow-500'}`}></div>
                            <span className="font-medium">{player.name}</span>
                            {player.level && (
                              <Badge variant="outline" className="ml-1">
                                Lv.{player.level}
                              </Badge>
                            )}
                          </div>
                        </TableCell>
                        <TableCell>
                          <code className="text-xs bg-muted px-2 py-1 rounded">
                            {player.steamid.substring(0, 20)}...
                          </code>
                        </TableCell>
                        <TableCell>
                          <Badge variant={player.status === 'playing' ? 'default' : 'secondary'}>
                            {player.status === 'playing' ? (
                              <><Play className="size-3 mr-1" /> Playing</>
                            ) : (
                              <><Pause className="size-3 mr-1" /> AFK</>
                            )}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <span className="text-sm">{player.job}</span>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-1">
                            <MapPin className="size-3 text-muted-foreground" />
                            <span className="text-sm">{player.location}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <span className={(player.ping || 0) > 100 ? 'text-red-500' : (player.ping || 0) > 50 ? 'text-yellow-500' : 'text-green-500'}>
                            {player.ping}ms
                          </span>
                        </TableCell>
                        <TableCell>{player.playtime}</TableCell>
                        <TableCell>
                          {player.admin ? (
                            <Badge variant="destructive">
                              <Shield className="size-3 mr-1" />
                              Admin
                            </Badge>
                          ) : (
                            <Badge variant="outline">Player</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center justify-end gap-1">
                            {onNavigateToProfile && (
                              <Button 
                                size="sm" 
                                variant="default" 
                                title="View Profile" 
                                onClick={() => onNavigateToProfile(player.id)}
                              >
                                <User className="size-3" />
                              </Button>
                            )}
                            <Button 
                              size="sm" 
                              variant="outline" 
                              title="Spectate" 
                              onClick={() => handlePlayerAction(player, 'spectate')}
                            >
                              <Eye className="size-3" />
                            </Button>
                            <Button 
                              size="sm" 
                              variant="outline" 
                              title="Actions" 
                              onClick={() => handlePlayerAction(player, 'more')}
                            >
                              <MoreHorizontal className="size-3" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                {filteredAndSortedPlayers.length === 0 && (
                  <div className="text-center py-12 text-muted-foreground">
                    <Search className="size-12 mx-auto mb-4 opacity-50" />
                    <p className="text-lg">No players found</p>
                    <p className="text-sm">Try adjusting your search or filters</p>
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Offline Players Tab */}
        <TabsContent value="offline" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="size-5" />
                Offline Players
              </CardTitle>
              <CardDescription>
                {filteredAndSortedPlayers.length} of {offlinePlayers.length} players shown
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Player</TableHead>
                      <TableHead>Steam ID</TableHead>
                      <TableHead>Last Seen</TableHead>
                      <TableHead className="cursor-pointer" onClick={() => handleSort('playtime')}>
                        Total Playtime {sortBy === 'playtime' && (sortOrder === 'asc' ? '↑' : '↓')}
                      </TableHead>
                      <TableHead>Join Date</TableHead>
                      <TableHead>Role</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredAndSortedPlayers.map((player) => (
                      <TableRow key={player.id}>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <div className="size-2 bg-gray-400 rounded-full"></div>
                            <span className="font-medium">{player.name}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <code className="text-xs bg-muted px-2 py-1 rounded">
                            {player.steamid.substring(0, 20)}...
                          </code>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-1">
                            <Clock className="size-3 text-muted-foreground" />
                            {player.lastSeen}
                          </div>
                        </TableCell>
                        <TableCell>{player.playtime}</TableCell>
                        <TableCell>
                          <div className="flex items-center gap-1">
                            <Calendar className="size-3 text-muted-foreground" />
                            {player.joinDate}
                          </div>
                        </TableCell>
                        <TableCell>
                          {player.admin ? (
                            <Badge variant="destructive">
                              <Shield className="size-3 mr-1" />
                              Admin
                            </Badge>
                          ) : (
                            <Badge variant="outline">Player</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center justify-end gap-1">
                            <Button size="sm" variant="outline" title="View Profile">
                              <Eye className="size-3" />
                            </Button>
                            <Button size="sm" variant="outline" title="Manage">
                              <Settings className="size-3" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                {filteredAndSortedPlayers.length === 0 && (
                  <div className="text-center py-12 text-muted-foreground">
                    <Search className="size-12 mx-auto mb-4 opacity-50" />
                    <p className="text-lg">No offline players found</p>
                    <p className="text-sm">Try adjusting your search or filters</p>
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Banned Players Tab */}
        <TabsContent value="banned" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Ban className="size-5" />
                Banned Players
              </CardTitle>
              <CardDescription>
                {filteredBannedPlayers.length} banned players
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Player</TableHead>
                    <TableHead>Steam ID</TableHead>
                    <TableHead>Reason</TableHead>
                    <TableHead>Banned By</TableHead>
                    <TableHead>Ban Date</TableHead>
                    <TableHead>Duration</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredBannedPlayers.map((player) => (
                    <TableRow key={player.id}>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <div className="size-2 bg-red-500 rounded-full"></div>
                          <span className="font-medium">{player.name}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <code className="text-xs bg-muted px-2 py-1 rounded">
                          {player.steamid.substring(0, 20)}...
                        </code>
                      </TableCell>
                      <TableCell>
                        <Badge variant="destructive">
                          <AlertTriangle className="size-3 mr-1" />
                          {player.reason}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-1">
                          <Shield className="size-3 text-muted-foreground" />
                          {player.bannedBy}
                        </div>
                      </TableCell>
                      <TableCell>{player.banDate}</TableCell>
                      <TableCell>
                        <Badge variant={player.duration === 'Permanent' ? 'destructive' : 'secondary'}>
                          {player.duration}
                        </Badge>
                        {player.expiresAt && (
                          <p className="text-xs text-muted-foreground mt-1">
                            Expires: {player.expiresAt}
                          </p>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center justify-end gap-1">
                          <Button size="sm" variant="outline" title="View Details">
                            <Eye className="size-3" />
                          </Button>
                          <Button size="sm" variant="outline">
                            Unban
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              {filteredBannedPlayers.length === 0 && (
                <div className="text-center py-12 text-muted-foreground">
                  <UserCheck className="size-12 mx-auto mb-4 opacity-50" />
                  <p className="text-lg">No banned players found</p>
                  <p className="text-sm">All clear!</p>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Action Modal */}
      <AdminActionModal
        isOpen={actionModal.isOpen}
        onClose={() => setActionModal({ isOpen: false, player: null, action: null })}
        player={actionModal.player}
        action={actionModal.action}
        onConfirm={handleActionConfirm}
      />
    </div>
  );
}