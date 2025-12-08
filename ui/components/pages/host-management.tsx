import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { ScrollArea } from '../ui/scroll-area';
import { Separator } from '../ui/separator';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Switch } from '../ui/switch';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { fetchNui } from '../nui-bridge';
import { toastSuccess, toastError } from '../../lib/toast';
import {
  Shield,
  Ban,
  AlertTriangle,
  FileText,
  Webhook,
  Users,
  Activity,
  CheckCircle,
  XCircle,
  Clock,
  Search,
  Filter,
  Download,
  Upload,
  Eye,
  Trash2,
  Edit,
  Plus,
  RefreshCw,
  Send,
  MessageSquare,
  Bell,
  AlertCircle,
  CheckCheck,
  X,
  MoreHorizontal,
  Settings,
  BarChart3,
  TrendingUp,
  Database,
  Globe,
  UserCheck,
  UserX,
  History,
  FileCheck,
  Flag,
  Target,
  Zap,
  Server,
  Info,
  Save,
  PlayCircle,
  StopCircle,
  PauseCircle
} from 'lucide-react';

interface GlobalBan {
  id: number;
  identifier: string;
  player_name: string;
  reason: string;
  banned_by: string;
  banned_at: number;
  expires_at?: number;
  is_permanent: boolean;
  active: boolean;
  applied_cities: string;
}

interface BanAppeal {
  id: number;
  ban_id: number;
  appeal_reason: string;
  evidence?: string;
  contact_info?: string;
  submitted_at: number;
  status: 'pending' | 'approved' | 'denied';
  reviewed_by?: string;
  reviewed_at?: number;
  review_notes?: string;
  identifier?: string;
  player_name?: string;
  ban_reason?: string;
}

interface GlobalWarning {
  id: number;
  identifier: string;
  player_name: string;
  reason: string;
  issued_by: string;
  issued_at: number;
  severity: 'low' | 'medium' | 'high' | 'critical';
  active: boolean;
  applied_cities?: string;
  notes?: string;
}

interface Webhook {
  id: number;
  webhook_name: string;
  webhook_url: string;
  event_type: string;
  enabled: boolean;
  config?: string;
  created_by: string;
  created_at: number;
  color?: string;
  username?: string;
  avatar_url?: string;
  mention_roles?: string;
}

interface WebhookLog {
  id: number;
  webhook_id: number;
  event_type: string;
  status: string;
  response?: string;
  timestamp: number;
  webhook_name?: string;
}

interface ActionLog {
  id: number;
  action_type: string;
  admin_id: string;
  admin_name: string;
  city_id?: string;
  city_name?: string;
  target_identifier?: string;
  target_name?: string;
  details: string;
  timestamp: number;
}

interface StaffActivity {
  id: number;
  staff_identifier: string;
  staff_name: string;
  city_id?: string;
  city_name?: string;
  action: string;
  details?: string;
  timestamp: number;
}

interface DashboardStats {
  totalBans: number;
  totalBansPermanent: number;
  pendingAppeals: number;
  totalAppeals: number;
  totalWarnings: number;
  totalWebhooks: number;
  webhookExecutions24h: number;
  actionsToday: number;
  totalCities: number;
  onlineCities: number;
  recentActions?: ActionLog[];
  activeAlerts?: any[];
}

interface APIStatus {
  name: string;
  key: string;
  port: number;
  status: 'online' | 'offline' | 'degraded' | 'starting' | 'stopping';
  uptime: number;
  uptimeFormatted?: string;
  requests: number;
  requestsToday: number;
  avgResponseTime: number;
  errorRate: number;
  version: string;
  lastRestart?: number;
  lastRestartFormatted?: string;
  healthStatus: 'healthy' | 'degraded' | 'unhealthy';
  memoryUsage?: number;
  cpuUsage?: number;
  activeConnections?: number;
  errorCount?: number;
  warningCount?: number;
  autoRestart?: boolean;
  enabled?: boolean;
}

interface APILog {
  id: number;
  api_name: string;
  log_level: 'info' | 'warn' | 'error' | 'debug';
  message: string;
  details?: string;
  timestamp: number;
  source?: string;
}

interface APIMetric {
  api_name: string;
  metric_name: string;
  value: number;
  timestamp: number;
}

export function HostDashboard() {
  const [dashboardStats, setDashboardStats] = useState<DashboardStats | null>(null);
  const [globalBans, setGlobalBans] = useState<GlobalBan[]>([]);
  const [banAppeals, setBanAppeals] = useState<BanAppeal[]>([]);
  const [globalWarnings, setGlobalWarnings] = useState<GlobalWarning[]>([]);
  const [webhooks, setWebhooks] = useState<Webhook[]>([]);
  const [webhookLogs, setWebhookLogs] = useState<WebhookLog[]>([]);
  const [actionLogs, setActionLogs] = useState<ActionLog[]>([]);
  const [staffActivity, setStaffActivity] = useState<StaffActivity[]>([]);
  const [apiStatuses, setApiStatuses] = useState<APIStatus[]>([]);
  const [apiLogs, setApiLogs] = useState<APILog[]>([]);
  const [apiMetrics, setApiMetrics] = useState<APIMetric[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [activeTab, setActiveTab] = useState('overview');
  const [selectedAPI, setSelectedAPI] = useState<APIStatus | null>(null);
  const [showAPILogsDialog, setShowAPILogsDialog] = useState(false);
  
  // Dialogs
  const [showBanDialog, setShowBanDialog] = useState(false);
  const [showAppealDialog, setShowAppealDialog] = useState(false);
  const [showWarningDialog, setShowWarningDialog] = useState(false);
  const [showWebhookDialog, setShowWebhookDialog] = useState(false);
  const [selectedAppeal, setSelectedAppeal] = useState<BanAppeal | null>(null);
  const [selectedBan, setSelectedBan] = useState<GlobalBan | null>(null);
  const [selectedWarning, setSelectedWarning] = useState<GlobalWarning | null>(null);
  const [selectedWebhook, setSelectedWebhook] = useState<Webhook | null>(null);
  
  // Form states
  const [warningForm, setWarningForm] = useState({
    identifier: '',
    playerName: '',
    reason: '',
    severity: 'medium'
  });

  const [webhookForm, setWebhookForm] = useState({
    webhookName: '',
    webhookUrl: '',
    eventType: 'global_ban',
    color: '#ff0000',
    username: 'NRG Host System',
    avatarUrl: '',
    mentionRoles: ''
  });

  useEffect(() => {
    loadAllData();
    
    // Refresh every minute
    const interval = setInterval(loadAllData, 60000);
    
    return () => clearInterval(interval);
  }, []);

  const loadAllData = async () => {
    try {
      const [stats, bans, appeals, warnings, hooks, hookLogs, actLogs, staffAct, apis, logs, metrics] = await Promise.all([
        fetchNui<DashboardStats>('getHostSystemStats', {}, {
          totalBans: 0,
          totalBansPermanent: 0,
          pendingAppeals: 0,
          totalAppeals: 0,
          totalWarnings: 0,
          totalWebhooks: 0,
          webhookExecutions24h: 0,
          actionsToday: 0,
          totalCities: 0,
          onlineCities: 0,
          recentActions: [],
          activeAlerts: []
        }),
        fetchNui<GlobalBan[]>('getGlobalBans', {}, []),
        fetchNui<BanAppeal[]>('getBanAppeals', {}, []),
        fetchNui<GlobalWarning[]>('getGlobalWarnings', {}, []),
        fetchNui<Webhook[]>('getHostWebhooks', {}, []),
        fetchNui<WebhookLog[]>('getWebhookLogs', { filters: {} }, []),
        fetchNui<ActionLog[]>('getHostActionLogs', { filters: {} }, []),
        fetchNui<StaffActivity[]>('getNRGStaffActivity', { filters: {} }, []),
        fetchNui<APIStatus[]>('getHostAPIStatuses', {}, []),
        fetchNui<APILog[]>('getHostAPILogs', { limit: 100 }, []),
        fetchNui<APIMetric[]>('getHostAPIMetrics', {}, [])
      ]);

      if (stats) setDashboardStats(stats);
      if (Array.isArray(bans)) setGlobalBans(bans);
      if (Array.isArray(appeals)) setBanAppeals(appeals);
      if (Array.isArray(warnings)) setGlobalWarnings(warnings);
      if (Array.isArray(hooks)) setWebhooks(hooks);
      if (Array.isArray(hookLogs)) setWebhookLogs(hookLogs);
      if (Array.isArray(actLogs)) setActionLogs(actLogs);
      if (Array.isArray(staffAct)) setStaffActivity(staffAct);
      if (Array.isArray(apis)) setApiStatuses(apis);
      if (Array.isArray(logs)) setApiLogs(logs);
      if (Array.isArray(metrics)) setApiMetrics(metrics);

      setLoading(false);
    } catch (error) {
      console.error('Failed to load host data:', error);
      setLoading(false);
    }
  };

  const handleApplyGlobalBan = async (banData: any) => {
    try {
      await fetchNui('applyGlobalBan', banData);
      toastSuccess('Global ban applied to all cities');
      setShowBanDialog(false);
      loadAllData();
    } catch (error) {
      toastError('Failed to apply global ban');
    }
  };

  const handleRemoveGlobalBan = async (banId: number, reason: string) => {
    if (!confirm('Remove this global ban from ALL cities?\n\nThis action cannot be undone.')) {
      return;
    }

    try {
      await fetchNui('removeGlobalBan', { banId, reason });
      toastSuccess('Global ban removed from all cities');
      loadAllData();
    } catch (error) {
      toastError('Failed to remove global ban');
    }
  };

  const handleProcessAppeal = async (appealId: number, action: 'approve' | 'deny', reviewNotes: string) => {
    try {
      await fetchNui('processBanAppeal', { appealId, action, reviewNotes });
      toastSuccess(`Ban appeal ${action}d`);
      setShowAppealDialog(false);
      setSelectedAppeal(null);
      loadAllData();
    } catch (error) {
      toastError('Failed to process appeal');
    }
  };

  const handleIssueWarning = async () => {
    try {
      await fetchNui('issueGlobalWarning', warningForm);
      toastSuccess('Global warning issued to all cities');
      setShowWarningDialog(false);
      setWarningForm({ identifier: '', playerName: '', reason: '', severity: 'medium' });
      loadAllData();
    } catch (error) {
      toastError('Failed to issue global warning');
    }
  };

  const handleRemoveWarning = async (warningId: number) => {
    if (!confirm('Remove this global warning from ALL cities?')) {
      return;
    }

    try {
      await fetchNui('removeGlobalWarning', { warningId, reason: 'Manually removed' });
      toastSuccess('Global warning removed');
      loadAllData();
    } catch (error) {
      toastError('Failed to remove warning');
    }
  };

  const handleTestWebhook = async (webhookId: number) => {
    try {
      await fetchNui('testHostWebhook', { webhookId });
      toastSuccess('Webhook test sent - check your Discord');
    } catch (error) {
      toastError('Failed to test webhook');
    }
  };

  const handleToggleWebhook = async (webhookId: number, enabled: boolean) => {
    try {
      await fetchNui('toggleHostWebhook', { webhookId, enabled: !enabled });
      toastSuccess(`Webhook ${enabled ? 'disabled' : 'enabled'}`);
      loadAllData();
    } catch (error) {
      toastError('Failed to toggle webhook');
    }
  };

  const handleSaveWebhook = async () => {
    if (!webhookForm.webhookName) {
      toastError('Please fill in webhook name');
      return;
    }

    // Allow saving without URL (can add later)
    const webhookUrl = webhookForm.webhookUrl || 'https://discord.com/api/webhooks/PENDING';

    try {
      if (selectedWebhook) {
        await fetchNui('updateHostWebhook', { 
          webhookId: selectedWebhook.id,
          ...webhookForm,
          webhookUrl 
        });
        toastSuccess('Webhook updated successfully');
      } else {
        await fetchNui('createHostWebhook', { 
          ...webhookForm,
          webhookUrl 
        });
        toastSuccess('Webhook created successfully - Add URL when ready');
      }
      setShowWebhookDialog(false);
      setSelectedWebhook(null);
      setWebhookForm({
        webhookName: '',
        webhookUrl: '',
        eventType: 'global_ban',
        color: '#ff0000',
        username: 'NRG Host System',
        avatarUrl: '',
        mentionRoles: ''
      });
      loadAllData();
    } catch (error) {
      toastError('Failed to save webhook');
    }
  };

  const handleDeleteWebhook = async (webhookId: number) => {
    if (!confirm('Are you sure you want to delete this webhook?')) {
      return;
    }

    try {
      await fetchNui('deleteHostWebhook', { webhookId });
      toastSuccess('Webhook deleted successfully');
      loadAllData();
    } catch (error) {
      toastError('Failed to delete webhook');
    }
  };

  // API Management Functions
  const handleStartAPI = async (apiKey: string, apiName: string) => {
    try {
      await fetchNui('startHostAPI', { apiKey });
      toastSuccess(`Starting ${apiName}...`);
      setTimeout(loadAllData, 2000);
    } catch (error) {
      toastError(`Failed to start ${apiName}`);
    }
  };

  const handleStopAPI = async (apiKey: string, apiName: string) => {
    if (!confirm(`Stop ${apiName}?\n\nThis will disconnect all cities using this API.`)) {
      return;
    }

    try {
      await fetchNui('stopHostAPI', { apiKey });
      toastSuccess(`Stopping ${apiName}...`);
      setTimeout(loadAllData, 2000);
    } catch (error) {
      toastError(`Failed to stop ${apiName}`);
    }
  };

  const handleRestartAPI = async (apiKey: string, apiName: string) => {
    try {
      await fetchNui('restartHostAPI', { apiKey });
      toastSuccess(`Restarting ${apiName}...`);
      setTimeout(loadAllData, 3000);
    } catch (error) {
      toastError(`Failed to restart ${apiName}`);
    }
  };

  const handleToggleAPIAutoRestart = async (apiKey: string, apiName: string, enabled: boolean) => {
    try {
      await fetchNui('toggleAPIAutoRestart', { apiKey, enabled: !enabled });
      toastSuccess(`Auto-restart ${!enabled ? 'enabled' : 'disabled'} for ${apiName}`);
      loadAllData();
    } catch (error) {
      toastError('Failed to toggle auto-restart');
    }
  };

  const handleStartAllAPIs = async () => {
    if (!confirm('Start all APIs?\n\nThis will start all stopped APIs.')) {
      return;
    }

    try {
      await fetchNui('startAllHostAPIs', {});
      toastSuccess('Starting all APIs...');
      setTimeout(loadAllData, 5000);
    } catch (error) {
      toastError('Failed to start all APIs');
    }
  };

  const handleStopAllAPIs = async () => {
    if (!confirm('Stop all APIs?\n\nThis will disconnect ALL cities from ALL services.\n\nAre you absolutely sure?')) {
      return;
    }

    const confirmation = prompt('Type "STOP ALL" to confirm:');
    if (confirmation !== 'STOP ALL') {
      toastError('Cancelled');
      return;
    }

    try {
      await fetchNui('stopAllHostAPIs', {});
      toastSuccess('Stopping all APIs...');
      setTimeout(loadAllData, 3000);
    } catch (error) {
      toastError('Failed to stop all APIs');
    }
  };

  const handleRestartAllAPIs = async () => {
    if (!confirm('Restart all APIs?\n\nThis will briefly disconnect all cities from all services.')) {
      return;
    }

    try {
      await fetchNui('restartAllHostAPIs', {});
      toastSuccess('Restarting all APIs...');
      setTimeout(loadAllData, 10000);
    } catch (error) {
      toastError('Failed to restart all APIs');
    }
  };

  const handleViewAPILogs = async (api: APIStatus) => {
    try {
      const logs = await fetchNui<APILog[]>('getHostAPILogs', { apiKey: api.key, limit: 500 }, []);
      if (Array.isArray(logs)) {
        setApiLogs(logs);
      }
      setSelectedAPI(api);
      setShowAPILogsDialog(true);
    } catch (error) {
      toastError('Failed to load API logs');
    }
  };

  const handleClearAPILogs = async (apiKey: string) => {
    if (!confirm('Clear all logs for this API?')) {
      return;
    }

    try {
      await fetchNui('clearHostAPILogs', { apiKey });
      toastSuccess('API logs cleared');
      if (selectedAPI?.key === apiKey) {
        setApiLogs([]);
      }
    } catch (error) {
      toastError('Failed to clear logs');
    }
  };

  const handleEditWebhook = (webhook: Webhook) => {
    setSelectedWebhook(webhook);
    setWebhookForm({
      webhookName: webhook.webhook_name,
      webhookUrl: webhook.webhook_url,
      eventType: webhook.event_type,
      color: webhook.color || '#ff0000',
      username: webhook.username || 'NRG Host System',
      avatarUrl: webhook.avatar_url || '',
      mentionRoles: webhook.mention_roles || ''
    });
    setShowWebhookDialog(true);
  };

  const formatDate = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleString();
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'low': return 'text-blue-500';
      case 'medium': return 'text-yellow-500';
      case 'high': return 'text-orange-500';
      case 'critical': return 'text-red-500';
      default: return 'text-gray-500';
    }
  };

  const getActionTypeIcon = (actionType: string) => {
    switch (actionType) {
      case 'global_ban': return Ban;
      case 'global_unban': return UserCheck;
      case 'global_warning': return AlertTriangle;
      case 'appeal_processed': return FileCheck;
      case 'webhook_updated': return Webhook;
      case 'staff_added': return UserCheck;
      case 'staff_removed': return UserX;
      default: return Activity;
    }
  };

  // Safety checks
  const safeBans = Array.isArray(globalBans) ? globalBans : [];
  const safeAppeals = Array.isArray(banAppeals) ? banAppeals : [];
  const safeWarnings = Array.isArray(globalWarnings) ? globalWarnings : [];
  const safeWebhookLogs = Array.isArray(webhookLogs) ? webhookLogs : [];
  const safeActionLogs = Array.isArray(actionLogs) ? actionLogs : [];
  const safeStaffActivity = Array.isArray(staffActivity) ? staffActivity : [];

  const filteredBans = safeBans.filter(ban => {
    const matchesSearch = ban.player_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          ban.identifier?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || 
                          (filterStatus === 'active' && ban.active) ||
                          (filterStatus === 'inactive' && !ban.active);
    return matchesSearch && matchesStatus;
  });

  const filteredAppeals = safeAppeals.filter(appeal => {
    const matchesSearch = !searchTerm || 
                          appeal.player_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          appeal.identifier?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || appeal.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  const filteredWarnings = safeWarnings.filter(warning => {
    const matchesSearch = warning.player_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          warning.identifier?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || 
                          (filterStatus === 'active' && warning.active) ||
                          (filterStatus === 'inactive' && !warning.active);
    return matchesSearch && matchesStatus;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-center">
          <RefreshCw className="size-8 animate-spin mx-auto mb-4 text-primary" />
          <p className="text-muted-foreground">Loading host management...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">👑 Host Dashboard</h1>
          <p className="text-muted-foreground">NRG Global Control Panel - Complete API & Server Management</p>
        </div>
        <div className="flex gap-2">
          <Button onClick={loadAllData} variant="outline" className="gap-2">
            <RefreshCw className="size-4" />
            Refresh All
          </Button>
          <Button variant="destructive" className="gap-2">
            <Download className="size-4" />
            Export Data
          </Button>
        </div>
      </div>

      {/* Dashboard Stats */}
      {dashboardStats && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Active Global Bans</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <Ban className="size-5 text-red-500" />
                <span className="text-2xl font-bold">{dashboardStats.totalBans}</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                {dashboardStats.totalBansPermanent} permanent
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Pending Appeals</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <FileText className="size-5 text-yellow-500" />
                <span className="text-2xl font-bold">{dashboardStats.pendingAppeals}</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                {dashboardStats.totalAppeals} total appeals
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Active Warnings</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <AlertTriangle className="size-5 text-orange-500" />
                <span className="text-2xl font-bold">{dashboardStats.totalWarnings}</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Cross-city warnings
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Webhooks Active</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <Webhook className="size-5 text-blue-500" />
                <span className="text-2xl font-bold">{dashboardStats.totalWebhooks}</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                {dashboardStats.webhookExecutions24h} executions today
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardDescription>Actions Today</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2">
                <Activity className="size-5 text-green-500" />
                <span className="text-2xl font-bold">{dashboardStats.actionsToday}</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                {dashboardStats.onlineCities}/{dashboardStats.totalCities} cities online
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Active Alerts */}
      {dashboardStats?.activeAlerts && dashboardStats.activeAlerts.length > 0 && (
        <Card className="border-orange-500 bg-orange-500/5">
          <CardHeader>
            <div className="flex items-center gap-2">
              <AlertCircle className="size-5 text-orange-500" />
              <CardTitle>Active Alerts</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {dashboardStats.activeAlerts.map((alert: any) => (
                <div key={alert.id} className="flex items-center justify-between p-3 bg-background rounded-md">
                  <div className="flex-1">
                    <p className="font-semibold">{alert.message}</p>
                    <p className="text-sm text-muted-foreground">{alert.source} - {formatDate(alert.timestamp)}</p>
                  </div>
                  <Badge variant={alert.severity === 'high' ? 'destructive' : 'secondary'}>
                    {alert.severity}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Main Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-7">
          <TabsTrigger value="overview">
            <Database className="size-4 mr-2" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="apis">
            <Server className="size-4 mr-2" />
            API Management
          </TabsTrigger>
          <TabsTrigger value="bans">
            <Ban className="size-4 mr-2" />
            Bans ({safeBans.length})
          </TabsTrigger>
          <TabsTrigger value="appeals">
            <FileText className="size-4 mr-2" />
            Appeals ({dashboardStats?.pendingAppeals || 0})
          </TabsTrigger>
          <TabsTrigger value="warnings">
            <AlertTriangle className="size-4 mr-2" />
            Warnings ({safeWarnings.length})
          </TabsTrigger>
          <TabsTrigger value="webhooks">
            <Webhook className="size-4 mr-2" />
            Webhooks
          </TabsTrigger>
          <TabsTrigger value="logs">
            <Activity className="size-4 mr-2" />
            Logs & Activity
          </TabsTrigger>
        </TabsList>

        {/* API Management Tab */}
        <TabsContent value="apis" className="space-y-4">
          {/* API Control Actions */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Zap className="size-5" />
                API Control Center
              </CardTitle>
              <CardDescription>Manage all API services and infrastructure</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
                <Button 
                  onClick={handleStartAllAPIs} 
                  variant="outline" 
                  className="gap-2 bg-green-500/10 hover:bg-green-500/20 border-green-500/50"
                >
                  <PlayCircle className="size-4" />
                  Start All
                </Button>
                <Button 
                  onClick={handleRestartAllAPIs} 
                  variant="outline" 
                  className="gap-2 bg-blue-500/10 hover:bg-blue-500/20 border-blue-500/50"
                >
                  <RefreshCw className="size-4" />
                  Restart All
                </Button>
                <Button 
                  onClick={handleStopAllAPIs} 
                  variant="outline" 
                  className="gap-2 bg-red-500/10 hover:bg-red-500/20 border-red-500/50"
                >
                  <StopCircle className="size-4" />
                  Stop All
                </Button>
                <Button 
                  onClick={loadAllData} 
                  variant="outline" 
                  className="gap-2"
                >
                  <RefreshCw className="size-4" />
                  Refresh Status
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* API Status Overview */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="pb-2">
                <CardDescription>Total APIs</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-2">
                  <Server className="size-5 text-blue-500" />
                  <span className="text-2xl font-bold">{apiStatuses.length}</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardDescription>Online</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-2">
                  <CheckCircle className="size-5 text-green-500" />
                  <span className="text-2xl font-bold">
                    {apiStatuses.filter(api => api.status === 'online').length}
                  </span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardDescription>Degraded</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-2">
                  <AlertTriangle className="size-5 text-yellow-500" />
                  <span className="text-2xl font-bold">
                    {apiStatuses.filter(api => api.status === 'degraded').length}
                  </span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardDescription>Offline</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-2">
                  <XCircle className="size-5 text-red-500" />
                  <span className="text-2xl font-bold">
                    {apiStatuses.filter(api => api.status === 'offline').length}
                  </span>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* API Services List */}
          <div className="space-y-3">
            {apiStatuses.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center text-muted-foreground">
                  No API services found. Make sure the host infrastructure is running.
                </CardContent>
              </Card>
            ) : (
              apiStatuses.map(api => (
                <Card key={api.key} className={
                  api.status === 'online' ? 'border-green-500/30' :
                  api.status === 'degraded' ? 'border-yellow-500/30' :
                  api.status === 'offline' ? 'border-red-500/30' :
                  'border-blue-500/30'
                }>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between gap-4">
                      {/* API Info */}
                      <div className="flex-1 space-y-3">
                        <div className="flex items-center gap-3">
                          <Server className="size-5 text-primary" />
                          <div>
                            <h3 className="font-semibold">{api.name}</h3>
                            <p className="text-xs text-muted-foreground">Port: {api.port} | v{api.version}</p>
                          </div>
                          <Badge variant={
                            api.status === 'online' ? 'default' :
                            api.status === 'degraded' ? 'secondary' :
                            api.status === 'offline' ? 'destructive' :
                            'outline'
                          } className={
                            api.status === 'online' ? 'bg-green-500' :
                            api.status === 'degraded' ? 'bg-yellow-500' :
                            api.status === 'offline' ? 'bg-red-500' :
                            'bg-blue-500'
                          }>
                            {api.status.toUpperCase()}
                          </Badge>
                          {api.healthStatus && (
                            <Badge variant="outline" className={
                              api.healthStatus === 'healthy' ? 'border-green-500/50 text-green-500' :
                              api.healthStatus === 'degraded' ? 'border-yellow-500/50 text-yellow-500' :
                              'border-red-500/50 text-red-500'
                            }>
                              {api.healthStatus}
                            </Badge>
                          )}
                          {api.autoRestart && (
                            <Badge variant="outline" className="border-blue-500/50 text-blue-500">
                              Auto-Restart
                            </Badge>
                          )}
                        </div>

                        {/* API Metrics */}
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                          <div>
                            <p className="text-muted-foreground">Uptime</p>
                            <p className="font-medium">{api.uptimeFormatted || formatUptime(api.uptime)}</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Requests Today</p>
                            <p className="font-medium">{api.requestsToday?.toLocaleString() || api.requests.toLocaleString()}</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Avg Response</p>
                            <p className="font-medium">{api.avgResponseTime}ms</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Error Rate</p>
                            <p className={`font-medium ${api.errorRate > 5 ? 'text-red-500' : api.errorRate > 1 ? 'text-yellow-500' : 'text-green-500'}`}>
                              {api.errorRate.toFixed(2)}%
                            </p>
                          </div>
                          {api.memoryUsage !== undefined && (
                            <div>
                              <p className="text-muted-foreground">Memory</p>
                              <p className="font-medium">{api.memoryUsage}MB</p>
                            </div>
                          )}
                          {api.cpuUsage !== undefined && (
                            <div>
                              <p className="text-muted-foreground">CPU</p>
                              <p className="font-medium">{api.cpuUsage.toFixed(1)}%</p>
                            </div>
                          )}
                          {api.activeConnections !== undefined && (
                            <div>
                              <p className="text-muted-foreground">Connections</p>
                              <p className="font-medium">{api.activeConnections}</p>
                            </div>
                          )}
                          {api.lastRestart && (
                            <div>
                              <p className="text-muted-foreground">Last Restart</p>
                              <p className="font-medium text-xs">{api.lastRestartFormatted || formatDate(api.lastRestart)}</p>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* API Actions */}
                      <div className="flex flex-col gap-2 min-w-[140px]">
                        {api.status === 'offline' ? (
                          <Button 
                            size="sm" 
                            variant="default"
                            className="gap-2 bg-green-500 hover:bg-green-600"
                            onClick={() => handleStartAPI(api.key, api.name)}
                          >
                            <PlayCircle className="size-4" />
                            Start
                          </Button>
                        ) : (
                          <Button 
                            size="sm" 
                            variant="destructive"
                            className="gap-2"
                            onClick={() => handleStopAPI(api.key, api.name)}
                          >
                            <StopCircle className="size-4" />
                            Stop
                          </Button>
                        )}
                        
                        <Button 
                          size="sm" 
                          variant="outline"
                          className="gap-2"
                          onClick={() => handleRestartAPI(api.key, api.name)}
                          disabled={api.status === 'offline'}
                        >
                          <RefreshCw className="size-4" />
                          Restart
                        </Button>

                        <Button 
                          size="sm" 
                          variant="outline"
                          className="gap-2"
                          onClick={() => handleViewAPILogs(api)}
                        >
                          <FileText className="size-4" />
                          View Logs
                        </Button>

                        <div className="flex items-center gap-2 px-2 py-1">
                          <span className="text-xs">Auto-Restart</span>
                          <Switch 
                            checked={api.autoRestart || false}
                            onCheckedChange={() => handleToggleAPIAutoRestart(api.key, api.name, api.autoRestart || false)}
                          />
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Recent Actions */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <History className="size-5" />
                  Recent Actions
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ScrollArea className="h-[300px]">
                  <div className="space-y-2">
                    {dashboardStats?.recentActions && dashboardStats.recentActions.length > 0 ? (
                      dashboardStats.recentActions.map((action: ActionLog) => {
                        const Icon = getActionTypeIcon(action.action_type);
                        return (
                          <div key={action.id} className="flex items-start gap-3 p-2 bg-muted/50 rounded">
                            <Icon className="size-4 mt-1 text-muted-foreground" />
                            <div className="flex-1">
                              <p className="text-sm font-medium">{action.action_type.replace(/_/g, ' ').toUpperCase()}</p>
                              <p className="text-xs text-muted-foreground">
                                By {action.admin_name} - {formatDate(action.timestamp)}
                              </p>
                              {action.target_name && (
                                <p className="text-xs text-muted-foreground">Target: {action.target_name}</p>
                              )}
                            </div>
                          </div>
                        );
                      })
                    ) : (
                      <p className="text-sm text-muted-foreground text-center py-4">No recent actions</p>
                    )}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>

            {/* Quick Stats */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <BarChart3 className="size-5" />
                  System Statistics
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm">Total Global Bans</span>
                    <Badge>{safeBans.length}</Badge>
                  </div>
                  <Separator />
                  <div className="flex items-center justify-between">
                    <span className="text-sm">Total Warnings</span>
                    <Badge variant="secondary">{safeWarnings.length}</Badge>
                  </div>
                  <Separator />
                  <div className="flex items-center justify-between">
                    <span className="text-sm">Webhook Executions (24h)</span>
                    <Badge variant="outline">{dashboardStats?.webhookExecutions24h || 0}</Badge>
                  </div>
                  <Separator />
                  <div className="flex items-center justify-between">
                    <span className="text-sm">Actions Today</span>
                    <Badge variant="default">{dashboardStats?.actionsToday || 0}</Badge>
                  </div>
                  <Separator />
                  <div className="flex items-center justify-between">
                    <span className="text-sm">Cities Online</span>
                    <Badge className="bg-green-500">{dashboardStats?.onlineCities || 0} / {dashboardStats?.totalCities || 0}</Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Global Bans Tab */}
        <TabsContent value="bans" className="space-y-4">
          <Card>
            <CardContent className="p-4">
              <div className="flex gap-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
                  <Input
                    placeholder="Search bans by player name or identifier..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
                <Select value={filterStatus} onValueChange={setFilterStatus}>
                  <SelectTrigger className="w-[180px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Bans</SelectItem>
                    <SelectItem value="active">Active Only</SelectItem>
                    <SelectItem value="inactive">Inactive Only</SelectItem>
                  </SelectContent>
                </Select>
                <Button onClick={() => setShowBanDialog(true)} className="gap-2">
                  <Plus className="size-4" />
                  Apply Global Ban
                </Button>
              </div>
            </CardContent>
          </Card>

          <div className="space-y-2">
            {filteredBans.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center text-muted-foreground">
                  No global bans found
                </CardContent>
              </Card>
            ) : (
              filteredBans.map(ban => (
                <Card key={ban.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="font-semibold">{ban.player_name}</h3>
                          {ban.active ? (
                            <Badge variant="destructive">Active</Badge>
                          ) : (
                            <Badge variant="outline">Inactive</Badge>
                          )}
                          {ban.is_permanent && (
                            <Badge variant="secondary">Permanent</Badge>
                          )}
                        </div>
                        
                        <div className="grid grid-cols-2 gap-4 text-sm">
                          <div>
                            <p className="text-muted-foreground">Identifier</p>
                            <p className="font-mono">{ban.identifier}</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Banned By</p>
                            <p>{ban.banned_by}</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Ban Date</p>
                            <p>{formatDate(ban.banned_at)}</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Expires</p>
                            <p>{ban.expires_at ? formatDate(ban.expires_at) : 'Never'}</p>
                          </div>
                        </div>
                        
                        <div className="mt-3">
                          <p className="text-sm text-muted-foreground">Reason</p>
                          <p className="text-sm">{ban.reason}</p>
                        </div>
                      </div>
                      
                      <div className="flex flex-col gap-2 ml-4">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => setSelectedBan(ban)}
                        >
                          <Eye className="size-4" />
                        </Button>
                        {ban.active && (
                          <Button
                            size="sm"
                            variant="destructive"
                            onClick={() => {
                              const reason = prompt('Enter reason for removal:');
                              if (reason) handleRemoveGlobalBan(ban.id, reason);
                            }}
                          >
                            <X className="size-4" />
                          </Button>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Ban Appeals Tab */}
        <TabsContent value="appeals" className="space-y-4">
          <Card>
            <CardContent className="p-4">
              <div className="flex gap-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
                  <Input
                    placeholder="Search appeals..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
                <Select value={filterStatus} onValueChange={setFilterStatus}>
                  <SelectTrigger className="w-[180px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Appeals</SelectItem>
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="approved">Approved</SelectItem>
                    <SelectItem value="denied">Denied</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          <div className="space-y-2">
            {filteredAppeals.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center text-muted-foreground">
                  No ban appeals found
                </CardContent>
              </Card>
            ) : (
              filteredAppeals.map(appeal => (
                <Card key={appeal.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="font-semibold">{appeal.player_name || 'Unknown'}</h3>
                          {appeal.status === 'pending' && <Badge variant="secondary">Pending</Badge>}
                          {appeal.status === 'approved' && <Badge variant="default" className="bg-green-500">Approved</Badge>}
                          {appeal.status === 'denied' && <Badge variant="destructive">Denied</Badge>}
                        </div>
                        
                        <div className="grid grid-cols-2 gap-4 text-sm mb-3">
                          <div>
                            <p className="text-muted-foreground">Submitted</p>
                            <p>{formatDate(appeal.submitted_at)}</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Ban Reason</p>
                            <p>{appeal.ban_reason || 'N/A'}</p>
                          </div>
                        </div>
                        
                        <div>
                          <p className="text-sm text-muted-foreground">Appeal Reason</p>
                          <p className="text-sm">{appeal.appeal_reason}</p>
                        </div>
                        
                        {appeal.reviewed_by && (
                          <div className="mt-3 pt-3 border-t">
                            <p className="text-sm text-muted-foreground">Reviewed by {appeal.reviewed_by}</p>
                            {appeal.review_notes && <p className="text-sm">{appeal.review_notes}</p>}
                          </div>
                        )}
                      </div>
                      
                      {appeal.status === 'pending' && (
                        <div className="flex flex-col gap-2 ml-4">
                          <Button
                            size="sm"
                            variant="default"
                            className="bg-green-500 hover:bg-green-600 gap-2"
                            onClick={() => {
                              setSelectedAppeal(appeal);
                              setShowAppealDialog(true);
                            }}
                          >
                            <CheckCircle className="size-4" />
                            Review
                          </Button>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Warnings Tab */}
        <TabsContent value="warnings" className="space-y-4">
          <Card>
            <CardContent className="p-4">
              <div className="flex gap-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
                  <Input
                    placeholder="Search warnings..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
                <Select value={filterStatus} onValueChange={setFilterStatus}>
                  <SelectTrigger className="w-[180px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Warnings</SelectItem>
                    <SelectItem value="active">Active Only</SelectItem>
                    <SelectItem value="inactive">Inactive Only</SelectItem>
                  </SelectContent>
                </Select>
                <Button onClick={() => setShowWarningDialog(true)} className="gap-2">
                  <Plus className="size-4" />
                  Issue Global Warning
                </Button>
              </div>
            </CardContent>
          </Card>

          <div className="space-y-2">
            {filteredWarnings.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center">
                  <AlertTriangle className="size-12 mx-auto mb-4 text-orange-500" />
                  <h3 className="text-xl font-semibold mb-2">No Global Warnings</h3>
                  <p className="text-muted-foreground">
                    Issue warnings that apply across all connected cities
                  </p>
                </CardContent>
              </Card>
            ) : (
              filteredWarnings.map(warning => (
                <Card key={warning.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="font-semibold">{warning.player_name}</h3>
                          {warning.active ? (
                            <Badge variant="destructive">Active</Badge>
                          ) : (
                            <Badge variant="outline">Inactive</Badge>
                          )}
                          <Badge className={getSeverityColor(warning.severity)}>
                            {warning.severity.toUpperCase()}
                          </Badge>
                        </div>
                        
                        <div className="grid grid-cols-2 gap-4 text-sm">
                          <div>
                            <p className="text-muted-foreground">Identifier</p>
                            <p className="font-mono">{warning.identifier}</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Issued By</p>
                            <p>{warning.issued_by}</p>
                          </div>
                          <div>
                            <p className="text-muted-foreground">Issue Date</p>
                            <p>{formatDate(warning.issued_at)}</p>
                          </div>
                        </div>
                        
                        <div className="mt-3">
                          <p className="text-sm text-muted-foreground">Reason</p>
                          <p className="text-sm">{warning.reason}</p>
                        </div>
                        
                        {warning.notes && (
                          <div className="mt-2">
                            <p className="text-sm text-muted-foreground">Notes</p>
                            <p className="text-sm">{warning.notes}</p>
                          </div>
                        )}
                      </div>
                      
                      <div className="flex flex-col gap-2 ml-4">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => setSelectedWarning(warning)}
                        >
                          <Eye className="size-4" />
                        </Button>
                        {warning.active && (
                          <Button
                            size="sm"
                            variant="destructive"
                            onClick={() => handleRemoveWarning(warning.id)}
                          >
                            <X className="size-4" />
                          </Button>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Webhooks Tab */}
        <TabsContent value="webhooks" className="space-y-4">
          {/* Header Card */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <Webhook className="size-5" />
                    Host System Webhooks
                  </CardTitle>
                  <CardDescription>
                    Configure Discord webhooks for global NRG events across all connected cities
                  </CardDescription>
                </div>
                <Button onClick={() => {
                  setSelectedWebhook(null);
                  setWebhookForm({
                    webhookName: '',
                    webhookUrl: '',
                    eventType: 'global_ban',
                    color: '#ff0000',
                    username: 'NRG Host System',
                    avatarUrl: '',
                    mentionRoles: ''
                  });
                  setShowWebhookDialog(true);
                }} className="gap-2">
                  <Plus className="size-4" />
                  Add Webhook
                </Button>
              </div>
            </CardHeader>
          </Card>

          {/* Webhook Setup Status */}
          <Card className="border-blue-500/20 bg-blue-500/5">
            <CardContent className="p-4">
              <div className="flex items-start gap-3">
                <Info className="size-5 text-blue-500 mt-0.5" />
                <div className="flex-1">
                  <h3 className="font-semibold mb-1">Recommended Webhook Setup</h3>
                  <p className="text-sm text-muted-foreground mb-3">
                    Configure Discord webhooks for these critical event types. URLs can be added later - save with placeholder for now.
                  </p>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2 text-sm">
                    <div className="flex items-center gap-2">
                      <Badge variant={webhooks.some(w => w.event_type === 'global_ban') ? 'default' : 'outline'} className="text-xs">
                        {webhooks.some(w => w.event_type === 'global_ban') ? '✓' : '○'}
                      </Badge>
                      <span>Global Bans</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={webhooks.some(w => w.event_type === 'ban_appeal_submitted') ? 'default' : 'outline'} className="text-xs">
                        {webhooks.some(w => w.event_type === 'ban_appeal_submitted') ? '✓' : '○'}
                      </Badge>
                      <span>Ban Appeals</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={webhooks.some(w => w.event_type === 'security_alert') ? 'default' : 'outline'} className="text-xs">
                        {webhooks.some(w => w.event_type === 'security_alert') ? '✓' : '○'}
                      </Badge>
                      <span>Security Alerts</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={webhooks.some(w => w.event_type === 'api_offline') ? 'default' : 'outline'} className="text-xs">
                        {webhooks.some(w => w.event_type === 'api_offline') ? '✓' : '○'}
                      </Badge>
                      <span>API Status</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={webhooks.some(w => w.event_type === 'city_connected') ? 'default' : 'outline'} className="text-xs">
                        {webhooks.some(w => w.event_type === 'city_connected') ? '✓' : '○'}
                      </Badge>
                      <span>City Connections</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant={webhooks.some(w => w.event_type === 'emergency_stop') ? 'default' : 'outline'} className="text-xs">
                        {webhooks.some(w => w.event_type === 'emergency_stop') ? '✓' : '○'}
                      </Badge>
                      <span>Emergency Events</span>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Event Type Categories */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <Card className="border-red-500/20 bg-red-500/5">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-2">
                  <Ban className="size-5 text-red-500" />
                  <h3 className="font-semibold">Ban Events</h3>
                </div>
                <p className="text-sm text-muted-foreground">
                  {webhooks.filter(w => w.event_type.includes('ban')).length} webhooks
                </p>
              </CardContent>
            </Card>

            <Card className="border-yellow-500/20 bg-yellow-500/5">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="size-5 text-yellow-500" />
                  <h3 className="font-semibold">Warning Events</h3>
                </div>
                <p className="text-sm text-muted-foreground">
                  {webhooks.filter(w => w.event_type.includes('warning')).length} webhooks
                </p>
              </CardContent>
            </Card>

            <Card className="border-blue-500/20 bg-blue-500/5">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-2">
                  <UserCheck className="size-5 text-blue-500" />
                  <h3 className="font-semibold">Staff Events</h3>
                </div>
                <p className="text-sm text-muted-foreground">
                  {webhooks.filter(w => w.event_type.includes('staff') || w.event_type.includes('admin')).length} webhooks
                </p>
              </CardContent>
            </Card>

            <Card className="border-green-500/20 bg-green-500/5">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-2">
                  <Server className="size-5 text-green-500" />
                  <h3 className="font-semibold">API Events</h3>
                </div>
                <p className="text-sm text-muted-foreground">
                  {webhooks.filter(w => w.event_type.includes('api_')).length} webhooks
                </p>
              </CardContent>
            </Card>

            <Card className="border-purple-500/20 bg-purple-500/5">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-2">
                  <Globe className="size-5 text-purple-500" />
                  <h3 className="font-semibold">System Events</h3>
                </div>
                <p className="text-sm text-muted-foreground">
                  {webhooks.filter(w => w.event_type.includes('system') || w.event_type.includes('city') || w.event_type.includes('emergency')).length} webhooks
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Webhooks List */}
          {webhooks.length === 0 ? (
            <Card>
              <CardContent className="p-12 text-center">
                <Webhook className="size-16 mx-auto mb-4 text-muted-foreground opacity-50" />
                <h3 className="text-xl font-semibold mb-2">No Webhooks Configured</h3>
                <p className="text-muted-foreground mb-4">
                  Set up Discord webhooks to receive real-time notifications about important events
                </p>
                <Button onClick={() => setShowWebhookDialog(true)} className="gap-2">
                  <Plus className="size-4" />
                  Create Your First Webhook
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              {webhooks.map(webhook => (
                <Card key={webhook.id} className={webhook.enabled ? '' : 'opacity-60'}>
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div 
                          className="size-3 rounded-full" 
                          style={{ backgroundColor: webhook.color || '#ff0000' }}
                        />
                        <CardTitle className="text-base">{webhook.webhook_name}</CardTitle>
                      </div>
                      <Badge variant={webhook.enabled ? 'default' : 'secondary'}>
                        {webhook.enabled ? 'Active' : 'Disabled'}
                      </Badge>
                    </div>
                    <CardDescription className="flex items-center gap-2">
                      {webhook.event_type.replace(/_/g, ' ').toUpperCase()}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div>
                        <p className="text-xs text-muted-foreground mb-1">Webhook URL</p>
                        <p className="text-sm font-mono truncate bg-muted px-2 py-1 rounded">
                          {webhook.webhook_url}
                        </p>
                      </div>
                      
                      {webhook.username && (
                        <div>
                          <p className="text-xs text-muted-foreground mb-1">Bot Username</p>
                          <p className="text-sm">{webhook.username}</p>
                        </div>
                      )}

                      {webhook.mention_roles && (
                        <div>
                          <p className="text-xs text-muted-foreground mb-1">Mention Roles</p>
                          <div className="flex flex-wrap gap-1">
                            {webhook.mention_roles.split(',').map((role, idx) => (
                              <Badge key={idx} variant="outline" className="text-xs">
                                @{role.trim()}
                              </Badge>
                            ))}
                          </div>
                        </div>
                      )}

                      <div className="text-xs text-muted-foreground">
                        Created by {webhook.created_by} • {formatDate(webhook.created_at)}
                      </div>
                      
                      <Separator />

                      <div className="flex gap-2">
                        <Button 
                          size="sm" 
                          variant="outline" 
                          className="flex-1 gap-1"
                          onClick={() => handleTestWebhook(webhook.id)}
                        >
                          <Send className="size-3" />
                          Test
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          className="flex-1 gap-1"
                          onClick={() => handleToggleWebhook(webhook.id, webhook.enabled)}
                        >
                          {webhook.enabled ? <X className="size-3" /> : <CheckCircle className="size-3" />}
                          {webhook.enabled ? 'Disable' : 'Enable'}
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          className="gap-1"
                          onClick={() => handleEditWebhook(webhook)}
                        >
                          <Edit className="size-3" />
                        </Button>
                        <Button 
                          size="sm" 
                          variant="destructive" 
                          className="gap-1"
                          onClick={() => handleDeleteWebhook(webhook.id)}
                        >
                          <Trash2 className="size-3" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Recent Webhook Activity */}
          {safeWebhookLogs.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Activity className="size-5" />
                  Recent Webhook Activity
                </CardTitle>
                <CardDescription>Last 10 webhook executions</CardDescription>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Webhook</TableHead>
                      <TableHead>Event Type</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Time</TableHead>
                      <TableHead>Response</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {safeWebhookLogs.slice(0, 10).map(log => (
                      <TableRow key={log.id}>
                        <TableCell className="font-medium">{log.webhook_name || 'Unknown'}</TableCell>
                        <TableCell>
                          <Badge variant="outline">{log.event_type}</Badge>
                        </TableCell>
                        <TableCell>
                          <Badge variant={log.status === 'success' ? 'default' : 'destructive'}>
                            {log.status}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {formatDate(log.timestamp)}
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground truncate max-w-[200px]">
                          {log.response || 'N/A'}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {/* Logs & Activity Tab */}
        <TabsContent value="logs" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Activity className="size-5" />
                  Action Logs
                </CardTitle>
                <CardDescription>All host actions and events</CardDescription>
              </CardHeader>
              <CardContent>
                <ScrollArea className="h-[400px]">
                  <div className="space-y-2">
                    {safeActionLogs.length > 0 ? (
                      safeActionLogs.map(log => {
                        const Icon = getActionTypeIcon(log.action_type);
                        return (
                          <div key={log.id} className="p-3 bg-muted/50 rounded-md space-y-1">
                            <div className="flex items-start gap-2">
                              <Icon className="size-4 mt-0.5 text-muted-foreground" />
                              <div className="flex-1">
                                <p className="text-sm font-medium">{log.action_type.replace(/_/g, ' ')}</p>
                                <p className="text-xs text-muted-foreground">By {log.admin_name}</p>
                                <p className="text-xs text-muted-foreground">{formatDate(log.timestamp)}</p>
                                {log.target_name && (
                                  <p className="text-xs text-muted-foreground">Target: {log.target_name}</p>
                                )}
                              </div>
                            </div>
                          </div>
                        );
                      })
                    ) : (
                      <p className="text-sm text-muted-foreground text-center py-8">No action logs found</p>
                    )}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Webhook className="size-5" />
                  Webhook Logs
                </CardTitle>
                <CardDescription>Recent webhook executions</CardDescription>
              </CardHeader>
              <CardContent>
                <ScrollArea className="h-[400px]">
                  <div className="space-y-2">
                    {safeWebhookLogs.length > 0 ? (
                      safeWebhookLogs.map(log => (
                        <div key={log.id} className="p-3 bg-muted/50 rounded-md space-y-1">
                          <div className="flex items-center justify-between">
                            <p className="text-sm font-medium">{log.event_type}</p>
                            <Badge variant={log.status === 'success' ? 'default' : 'destructive'} className="text-xs">
                              {log.status}
                            </Badge>
                          </div>
                          <p className="text-xs text-muted-foreground">{formatDate(log.timestamp)}</p>
                          {log.response && (
                            <p className="text-xs text-muted-foreground truncate">{log.response}</p>
                          )}
                        </div>
                      ))
                    ) : (
                      <p className="text-sm text-muted-foreground text-center py-8">No webhook logs found</p>
                    )}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="size-5" />
                  Staff Activity
                </CardTitle>
                <CardDescription>NRG staff actions</CardDescription>
              </CardHeader>
              <CardContent>
                <ScrollArea className="h-[400px]">
                  <div className="space-y-2">
                    {safeStaffActivity.length > 0 ? (
                      safeStaffActivity.map(activity => (
                        <div key={activity.id} className="p-3 bg-muted/50 rounded-md space-y-1">
                          <p className="text-sm font-medium">{activity.staff_name}</p>
                          <p className="text-sm text-muted-foreground">{activity.action}</p>
                          {activity.city_name && (
                            <p className="text-xs text-muted-foreground">City: {activity.city_name}</p>
                          )}
                          <p className="text-xs text-muted-foreground">{formatDate(activity.timestamp)}</p>
                        </div>
                      ))
                    ) : (
                      <p className="text-sm text-muted-foreground text-center py-8">No staff activity found</p>
                    )}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>

      {/* Issue Warning Dialog */}
      <Dialog open={showWarningDialog} onOpenChange={setShowWarningDialog}>
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <DialogTitle>Issue Global Warning</DialogTitle>
            <DialogDescription>
              This warning will be applied to all connected cities
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <Label>Player Identifier</Label>
              <Input
                placeholder="license:xxxxx"
                value={warningForm.identifier}
                onChange={(e) => setWarningForm({ ...warningForm, identifier: e.target.value })}
              />
            </div>
            
            <div>
              <Label>Player Name</Label>
              <Input
                placeholder="Player Name"
                value={warningForm.playerName}
                onChange={(e) => setWarningForm({ ...warningForm, playerName: e.target.value })}
              />
            </div>
            
            <div>
              <Label>Severity</Label>
              <Select value={warningForm.severity} onValueChange={(v) => setWarningForm({ ...warningForm, severity: v })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="low">Low</SelectItem>
                  <SelectItem value="medium">Medium</SelectItem>
                  <SelectItem value="high">High</SelectItem>
                  <SelectItem value="critical">Critical</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <Label>Reason</Label>
              <Textarea
                placeholder="Warning reason..."
                value={warningForm.reason}
                onChange={(e) => setWarningForm({ ...warningForm, reason: e.target.value })}
                rows={4}
              />
            </div>
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowWarningDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleIssueWarning} className="bg-orange-500 hover:bg-orange-600">
              <AlertTriangle className="size-4 mr-2" />
              Issue Warning
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Appeal Review Dialog */}
      {selectedAppeal && showAppealDialog && (
        <Dialog open={showAppealDialog} onOpenChange={setShowAppealDialog}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Review Ban Appeal</DialogTitle>
              <DialogDescription>
                Review and process this ban appeal
              </DialogDescription>
            </DialogHeader>
            
            <div className="space-y-4">
              <div>
                <Label>Player</Label>
                <p>{selectedAppeal.player_name}</p>
              </div>
              
              <div>
                <Label>Original Ban Reason</Label>
                <p>{selectedAppeal.ban_reason}</p>
              </div>
              
              <div>
                <Label>Appeal Reason</Label>
                <p>{selectedAppeal.appeal_reason}</p>
              </div>
              
              {selectedAppeal.evidence && (
                <div>
                  <Label>Evidence</Label>
                  <p className="text-sm">{selectedAppeal.evidence}</p>
                </div>
              )}
              
              <div>
                <Label>Review Notes</Label>
                <Textarea placeholder="Enter your review notes..." id="review-notes" />
              </div>
            </div>
            
            <DialogFooter className="gap-2">
              <Button
                variant="outline"
                onClick={() => {
                  setShowAppealDialog(false);
                  setSelectedAppeal(null);
                }}
              >
                Cancel
              </Button>
              <Button
                variant="destructive"
                className="gap-2"
                onClick={() => {
                  const notes = (document.getElementById('review-notes') as HTMLTextAreaElement)?.value || '';
                  handleProcessAppeal(selectedAppeal.id, 'deny', notes);
                }}
              >
                <XCircle className="size-4" />
                Deny Appeal
              </Button>
              <Button
                className="bg-green-500 hover:bg-green-600 gap-2"
                onClick={() => {
                  const notes = (document.getElementById('review-notes') as HTMLTextAreaElement)?.value || '';
                  handleProcessAppeal(selectedAppeal.id, 'approve', notes);
                }}
              >
                <CheckCircle className="size-4" />
                Approve & Unban
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* API Logs Dialog */}
      {selectedAPI && (
        <Dialog open={showAPILogsDialog} onOpenChange={setShowAPILogsDialog}>
          <DialogContent className="max-w-6xl max-h-[80vh]">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <FileText className="size-5" />
                {selectedAPI.name} - API Logs
              </DialogTitle>
              <DialogDescription>
                Real-time logs for {selectedAPI.name} (Port {selectedAPI.port})
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4">
              {/* Log Controls */}
              <div className="flex items-center gap-2">
                <Button 
                  size="sm" 
                  variant="outline" 
                  onClick={() => handleViewAPILogs(selectedAPI)}
                  className="gap-2"
                >
                  <RefreshCw className="size-4" />
                  Refresh Logs
                </Button>
                <Button 
                  size="sm" 
                  variant="outline" 
                  onClick={() => handleClearAPILogs(selectedAPI.key)}
                  className="gap-2"
                >
                  <Trash2 className="size-4" />
                  Clear Logs
                </Button>
                <div className="flex-1" />
                <Badge variant="outline">{apiLogs.length} log entries</Badge>
              </div>

              {/* Logs Display */}
              <ScrollArea className="h-[500px] w-full rounded-md border p-4 bg-black/50">
                <div className="space-y-1 font-mono text-xs">
                  {apiLogs.length === 0 ? (
                    <p className="text-muted-foreground text-center py-8">No logs available</p>
                  ) : (
                    apiLogs.map((log, index) => (
                      <div 
                        key={log.id || index}
                        className={`p-2 rounded ${
                          log.log_level === 'error' ? 'bg-red-500/10 text-red-400' :
                          log.log_level === 'warn' ? 'bg-yellow-500/10 text-yellow-400' :
                          log.log_level === 'info' ? 'bg-blue-500/10 text-blue-400' :
                          'bg-gray-500/10 text-gray-400'
                        }`}
                      >
                        <div className="flex items-start gap-2">
                          <span className="text-muted-foreground min-w-[140px]">
                            {formatDate(log.timestamp)}
                          </span>
                          <Badge 
                            variant="outline" 
                            className={`min-w-[60px] text-center ${
                              log.log_level === 'error' ? 'border-red-500/50' :
                              log.log_level === 'warn' ? 'border-yellow-500/50' :
                              log.log_level === 'info' ? 'border-blue-500/50' :
                              'border-gray-500/50'
                            }`}
                          >
                            {log.log_level.toUpperCase()}
                          </Badge>
                          <span className="flex-1">{log.message}</span>
                        </div>
                        {log.details && (
                          <div className="ml-[200px] mt-1 text-muted-foreground">
                            {log.details}
                          </div>
                        )}
                        {log.source && (
                          <div className="ml-[200px] mt-1 text-xs text-muted-foreground">
                            Source: {log.source}
                          </div>
                        )}
                      </div>
                    ))
                  )}
                </div>
              </ScrollArea>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setShowAPILogsDialog(false)}>
                Close
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Webhook Dialog */}
      <Dialog open={showWebhookDialog} onOpenChange={(open) => {
        setShowWebhookDialog(open);
        if (!open) {
          setSelectedWebhook(null);
          setWebhookForm({
            webhookName: '',
            webhookUrl: '',
            eventType: 'global_ban',
            color: '#ff0000',
            username: 'NRG Host System',
            avatarUrl: '',
            mentionRoles: ''
          });
        }
      }}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{selectedWebhook ? 'Edit' : 'Add'} Webhook</DialogTitle>
            <DialogDescription>
              Configure a Discord webhook for NRG host system events
            </DialogDescription>
          </DialogHeader>
          
          <ScrollArea className="max-h-[600px] pr-4">
            <div className="space-y-4">
              <div>
                <Label>Webhook Name *</Label>
                <Input
                  placeholder="e.g. Global Bans Logger"
                  value={webhookForm.webhookName}
                  onChange={(e) => setWebhookForm({ ...webhookForm, webhookName: e.target.value })}
                />
              </div>
              
              <div>
                <Label>Webhook URL (Optional - Can Add Later)</Label>
                <Input
                  placeholder="https://discord.com/api/webhooks/... (leave empty if not ready)"
                  value={webhookForm.webhookUrl}
                  onChange={(e) => setWebhookForm({ ...webhookForm, webhookUrl: e.target.value })}
                />
                <p className="text-xs text-muted-foreground mt-1">
                  💡 Get this from Discord: Server Settings → Integrations → Webhooks → Create/Copy Webhook URL
                </p>
                <p className="text-xs text-yellow-500 mt-1">
                  ⏳ You can save this webhook now and add the URL later when ready
                </p>
              </div>

              <div>
                <Label>Event Type *</Label>
                <Select value={webhookForm.eventType} onValueChange={(v) => setWebhookForm({ ...webhookForm, eventType: v })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="max-h-[400px]">
                    {/* Ban Events */}
                    <SelectItem value="global_ban">🚫 Global Ban Applied</SelectItem>
                    <SelectItem value="global_unban">✅ Global Ban Removed</SelectItem>
                    <SelectItem value="ban_appeal_submitted">📝 Ban Appeal Submitted</SelectItem>
                    <SelectItem value="ban_appeal_processed">⚖️ Ban Appeal Processed</SelectItem>
                    
                    {/* Warning Events */}
                    <SelectItem value="global_warning">⚠️ Global Warning Issued</SelectItem>
                    <SelectItem value="warning_removed">✔️ Global Warning Removed</SelectItem>
                    
                    {/* Staff Events */}
                    <SelectItem value="staff_authenticated">🔐 NRG Staff Authentication</SelectItem>
                    <SelectItem value="staff_action">👮 NRG Staff Action</SelectItem>
                    <SelectItem value="admin_action">⚡ Admin Action</SelectItem>
                    
                    {/* City/Server Events */}
                    <SelectItem value="city_connected">🌐 City Connected</SelectItem>
                    <SelectItem value="city_disconnected">📡 City Disconnected</SelectItem>
                    <SelectItem value="player_threshold">👥 Player Threshold Reached</SelectItem>
                    
                    {/* API Events */}
                    <SelectItem value="api_online">✅ API Online</SelectItem>
                    <SelectItem value="api_offline">❌ API Offline</SelectItem>
                    <SelectItem value="api_error">🔴 API Error</SelectItem>
                    <SelectItem value="api_degraded">⚠️ API Degraded</SelectItem>
                    <SelectItem value="api_restarted">🔄 API Restarted</SelectItem>
                    
                    {/* System Events */}
                    <SelectItem value="system_alert">🚨 System Alert</SelectItem>
                    <SelectItem value="system_error">❗ System Error</SelectItem>
                    <SelectItem value="emergency_stop">🛑 Emergency Stop</SelectItem>
                    <SelectItem value="performance_alert">📊 Performance Alert</SelectItem>
                    <SelectItem value="security_alert">🔒 Security Alert</SelectItem>
                    
                    {/* Sync & Backup Events */}
                    <SelectItem value="config_sync">🔄 Config Sync Completed</SelectItem>
                    <SelectItem value="backup_completed">💾 Backup Completed</SelectItem>
                    <SelectItem value="restore_completed">📥 Restore Completed</SelectItem>
                    
                    {/* Special */}
                    <SelectItem value="all_events">🌟 All Events</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground mt-1">
                  ⏳ Webhook URLs can be added later - save with placeholder for now
                </p>
              </div>

              <Separator />

              <div className="space-y-4">
                <h4 className="font-semibold flex items-center gap-2">
                  <Settings className="size-4" />
                  Advanced Configuration
                </h4>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label>Embed Color</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={webhookForm.color}
                        onChange={(e) => setWebhookForm({ ...webhookForm, color: e.target.value })}
                        className="w-16"
                      />
                      <Input
                        value={webhookForm.color}
                        onChange={(e) => setWebhookForm({ ...webhookForm, color: e.target.value })}
                        placeholder="#ff0000"
                        className="flex-1"
                      />
                    </div>
                  </div>

                  <div>
                    <Label>Bot Username</Label>
                    <Input
                      placeholder="NRG Host System"
                      value={webhookForm.username}
                      onChange={(e) => setWebhookForm({ ...webhookForm, username: e.target.value })}
                    />
                  </div>
                </div>

                <div>
                  <Label>Bot Avatar URL (optional)</Label>
                  <Input
                    placeholder="https://..."
                    value={webhookForm.avatarUrl}
                    onChange={(e) => setWebhookForm({ ...webhookForm, avatarUrl: e.target.value })}
                  />
                </div>

                <div>
                  <Label>Mention Roles (optional)</Label>
                  <Input
                    placeholder="Admin, Moderator (comma separated)"
                    value={webhookForm.mentionRoles}
                    onChange={(e) => setWebhookForm({ ...webhookForm, mentionRoles: e.target.value })}
                  />
                  <p className="text-xs text-muted-foreground mt-1">
                    These role names will be mentioned in webhook messages
                  </p>
                </div>
              </div>

              <Separator />

              <div className="bg-muted p-4 rounded-lg space-y-2">
                <h4 className="font-semibold flex items-center gap-2">
                  <Info className="size-4" />
                  Preview
                </h4>
                <div className="space-y-1 text-sm">
                  <p><span className="text-muted-foreground">Name:</span> {webhookForm.webhookName || 'Not set'}</p>
                  <p><span className="text-muted-foreground">Event:</span> {webhookForm.eventType.replace(/_/g, ' ').toUpperCase()}</p>
                  <p><span className="text-muted-foreground">Color:</span> <span className="inline-block size-3 rounded-full align-middle" style={{ backgroundColor: webhookForm.color }} /> {webhookForm.color}</p>
                  <p><span className="text-muted-foreground">Bot Name:</span> {webhookForm.username || 'NRG Host System'}</p>
                </div>
              </div>
            </div>
          </ScrollArea>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowWebhookDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleSaveWebhook} className="gap-2">
              <Save className="size-4" />
              {selectedWebhook ? 'Update' : 'Create'} Webhook
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
