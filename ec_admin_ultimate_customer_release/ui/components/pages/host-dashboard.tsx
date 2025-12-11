import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Switch } from '../ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { ScrollArea } from '../ui/scroll-area';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { fetchNui, isEnvBrowser } from '../nui-bridge';
import { toastSuccess, toastError } from '../../lib/toast';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
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
  Lock,
  Zap,
  TrendingUp,
  TrendingDown,
  Clock,
  HardDrive,
  Cpu,
  Network,
  Package,
  Bell,
  FileText,
  Download,
  Upload,
  PlayCircle,
  StopCircle,
  Send,
  MessageSquare,
  Code,
  Ban,
  Webhook,
  Plus,
  Search,
  Filter,
  AlertCircle,
  X,
  UserCheck,
  UserX,
  History,
  Save,
  MoreHorizontal,
  Info,
  Flag,
  Building2,
  Edit,
  Trash2,
  Sparkles,
  Flame,
  Crown,
  Rocket,
  Wifi,
  WifiOff,
  Circle,
  ArrowUp,
  ArrowDown,
  Radio,
  MonitorCheck,
  ShieldCheck,
  Boxes,
  Layers,
  GitBranch,
  Gauge,
  ServerCog,
  CloudCog,
  Workflow,
  Container,
  Bug,
  Siren,
  HeartPulse,
  Unplug,
  Link,
  DollarSign,
  CalendarDays,
  Target,
  Percent
} from 'lucide-react';

// Host Infrastructure Interfaces
interface APIStatus {
  name: string;
  key: string;
  port: number;
  status: 'online' | 'offline' | 'degraded' | 'starting' | 'stopping';
  uptime: number;
  requests: number;
  requestsToday: number;
  avgResponseTime: number;
  errorRate: number;
  version: string;
  lastRestart?: number;
  healthStatus: 'healthy' | 'degraded' | 'unhealthy';
  memoryUsage?: number;
  cpuUsage?: number;
  activeConnections?: number;
  errorCount?: number;
  warningCount?: number;
  autoRestart?: boolean;
}

interface ConnectedCity {
  id: string;
  city_name: string;
  city_ip: string;
  server_id: string;
  cfx_license: string;
  framework: 'qbcore' | 'esx' | 'other';
  version: string;
  status: 'online' | 'offline';
  players_online: number;
  max_players: number;
  connected_at: number;
  last_seen: number;
  connected_apis: string[];
  total_requests: number;
  customer_label: 'ec_admin' | 'customer';
  discord_role_id?: string;
}

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
  cities_count: number;
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
  executions_24h: number;
  last_execution?: number;
  success_rate: number;
}

interface SystemLog {
  id: number;
  log_type: 'info' | 'warn' | 'error' | 'critical';
  source: string;
  message: string;
  details?: string;
  timestamp: number;
  resolved: boolean;
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

interface HostStats {
  // Infrastructure
  total_apis: number;
  online_apis: number;
  degraded_apis: number;
  offline_apis: number;
  system_health: number;
  
  // Connected Cities
  total_cities: number;
  online_cities: number;
  ec_admin_cities: number;
  customer_cities: number;
  total_players_online: number;
  
  // Requests & Performance
  total_requests_today: number;
  total_requests_all_time: number;
  avg_response_time: number;
  total_errors_today: number;
  avg_uptime: number;
  
  // Security & Moderation
  total_bans: number;
  bans_today: number;
  pending_appeals: number;
  total_warnings: number;
  warnings_today: number;
  
  // System Resources
  total_memory_usage: number;
  total_cpu_usage: number;
  database_size: number;
  
  // Webhooks
  total_webhooks: number;
  active_webhooks: number;
  webhook_executions_today: number;
  
  // Alerts
  critical_alerts: number;
  warnings_system: number;
  
  recent_alerts?: SystemLog[];
}

interface PerformanceMetric {
  timestamp: string;
  requests: number;
  response_time: number;
  error_rate: number;
  cpu: number;
  memory: number;
}

interface SalesProjection {
  month: string;
  projected_revenue: number;
  projected_customers: number;
  projected_mrr: number;
  confidence: number;
}

interface WebhookTemplate {
  name: string;
  event_type: string;
  description: string;
  category: 'security' | 'moderation' | 'system' | 'business' | 'monitoring';
  color: string;
  icon: string;
  default_enabled: boolean;
  priority: 'low' | 'medium' | 'high' | 'critical';
}

// Webhook Templates - Pre-configured for easy setup
const WEBHOOK_TEMPLATES: WebhookTemplate[] = [
  // Security Events
  { name: 'Global Ban Applied', event_type: 'global_ban', description: 'Player banned across all cities', category: 'security', color: '#ef4444', icon: '🚫', default_enabled: true, priority: 'critical' },
  { name: 'Global Ban Removed', event_type: 'global_unban', description: 'Ban removed from all cities', category: 'security', color: '#22c55e', icon: '✅', default_enabled: true, priority: 'high' },
  { name: 'Security Alert', event_type: 'security_alert', description: 'Critical security issue detected', category: 'security', color: '#dc2626', icon: '🚨', default_enabled: true, priority: 'critical' },
  { name: 'Suspicious Activity', event_type: 'suspicious_activity', description: 'Unusual player behavior detected', category: 'security', color: '#f59e0b', icon: '⚠️', default_enabled: true, priority: 'high' },
  { name: 'Mass Report', event_type: 'mass_report', description: 'Player reported by multiple cities', category: 'security', color: '#f97316', icon: '📢', default_enabled: true, priority: 'high' },
  
  // Moderation Events
  { name: 'Ban Appeal Submitted', event_type: 'ban_appeal_submitted', description: 'Player submitted ban appeal', category: 'moderation', color: '#3b82f6', icon: '📝', default_enabled: true, priority: 'medium' },
  { name: 'Ban Appeal Approved', event_type: 'ban_appeal_approved', description: 'Ban appeal was approved', category: 'moderation', color: '#10b981', icon: '✓', default_enabled: true, priority: 'medium' },
  { name: 'Ban Appeal Denied', event_type: 'ban_appeal_denied', description: 'Ban appeal was denied', category: 'moderation', color: '#ef4444', icon: '✗', default_enabled: true, priority: 'medium' },
  { name: 'Global Warning Issued', event_type: 'global_warning', description: 'Warning issued to all cities', category: 'moderation', color: '#eab308', icon: '⚡', default_enabled: true, priority: 'high' },
  { name: 'Warning Removed', event_type: 'warning_removed', description: 'Warning cleared from player', category: 'moderation', color: '#22c55e', icon: '🔓', default_enabled: false, priority: 'low' },
  { name: 'Player Kicked', event_type: 'player_kicked', description: 'Player kicked from city', category: 'moderation', color: '#f59e0b', icon: '👢', default_enabled: false, priority: 'low' },
  { name: 'Chat Violation', event_type: 'chat_violation', description: 'Inappropriate chat detected', category: 'moderation', color: '#f97316', icon: '💬', default_enabled: true, priority: 'medium' },
  
  // System Events
  { name: 'API Online', event_type: 'api_online', description: 'API service started', category: 'system', color: '#22c55e', icon: '🟢', default_enabled: false, priority: 'low' },
  { name: 'API Offline', event_type: 'api_offline', description: 'API service stopped', category: 'system', color: '#ef4444', icon: '🔴', default_enabled: true, priority: 'critical' },
  { name: 'API Degraded', event_type: 'api_degraded', description: 'API performance issues', category: 'system', color: '#f59e0b', icon: '🟡', default_enabled: true, priority: 'high' },
  { name: 'API Error', event_type: 'api_error', description: 'API encountered error', category: 'system', color: '#dc2626', icon: '❌', default_enabled: true, priority: 'high' },
  { name: 'System Alert', event_type: 'system_alert', description: 'General system notification', category: 'system', color: '#3b82f6', icon: '🔔', default_enabled: true, priority: 'medium' },
  { name: 'Database Issue', event_type: 'database_issue', description: 'Database connectivity problem', category: 'system', color: '#dc2626', icon: '💾', default_enabled: true, priority: 'critical' },
  { name: 'High CPU Usage', event_type: 'high_cpu', description: 'CPU usage exceeds threshold', category: 'system', color: '#f59e0b', icon: '📊', default_enabled: true, priority: 'high' },
  { name: 'High Memory Usage', event_type: 'high_memory', description: 'Memory usage exceeds threshold', category: 'system', color: '#f59e0b', icon: '🧠', default_enabled: true, priority: 'high' },
  { name: 'Disk Space Low', event_type: 'disk_space_low', description: 'Server disk space critical', category: 'system', color: '#f97316', icon: '💽', default_enabled: true, priority: 'high' },
  
  // Business Events
  { name: 'New Purchase', event_type: 'new_purchase', description: 'Customer made a purchase', category: 'business', color: '#10b981', icon: '💰', default_enabled: true, priority: 'medium' },
  { name: 'Subscription Started', event_type: 'subscription_started', description: 'New subscription created', category: 'business', color: '#22c55e', icon: '🎉', default_enabled: true, priority: 'medium' },
  { name: 'Subscription Cancelled', event_type: 'subscription_cancelled', description: 'Customer cancelled subscription', category: 'business', color: '#ef4444', icon: '😞', default_enabled: true, priority: 'high' },
  { name: 'Payment Failed', event_type: 'payment_failed', description: 'Payment processing failed', category: 'business', color: '#dc2626', icon: '💳', default_enabled: true, priority: 'high' },
  { name: 'Refund Issued', event_type: 'refund_issued', description: 'Refund processed', category: 'business', color: '#f59e0b', icon: '↩️', default_enabled: true, priority: 'medium' },
  { name: 'Trial Started', event_type: 'trial_started', description: 'Customer started trial', category: 'business', color: '#3b82f6', icon: '🆓', default_enabled: false, priority: 'low' },
  { name: 'Trial Expired', event_type: 'trial_expired', description: 'Trial period ended', category: 'business', color: '#f59e0b', icon: '⏰', default_enabled: true, priority: 'medium' },
  
  // Monitoring Events
  { name: 'City Connected', event_type: 'city_connected', description: 'City joined network', category: 'monitoring', color: '#22c55e', icon: '🌐', default_enabled: false, priority: 'low' },
  { name: 'City Disconnected', event_type: 'city_disconnected', description: 'City left network', category: 'monitoring', color: '#ef4444', icon: '🔌', default_enabled: true, priority: 'medium' },
  { name: 'High Request Volume', event_type: 'high_requests', description: 'Request spike detected', category: 'monitoring', color: '#f59e0b', icon: '📈', default_enabled: true, priority: 'medium' },
  { name: 'API Rate Limit Hit', event_type: 'rate_limit_hit', description: 'Rate limit exceeded', category: 'monitoring', color: '#f97316', icon: '🚦', default_enabled: true, priority: 'medium' },
  { name: 'Error Rate High', event_type: 'high_error_rate', description: 'Error rate exceeds threshold', category: 'monitoring', color: '#dc2626', icon: '⚠️', default_enabled: true, priority: 'high' },
  { name: 'Response Time Slow', event_type: 'slow_response', description: 'API response time degraded', category: 'monitoring', color: '#f59e0b', icon: '🐌', default_enabled: true, priority: 'medium' },
  { name: 'Server Restart', event_type: 'server_restart', description: 'City server restarted', category: 'monitoring', color: '#3b82f6', icon: '🔄', default_enabled: false, priority: 'low' },
  { name: 'Update Available', event_type: 'update_available', description: 'New version available', category: 'monitoring', color: '#8b5cf6', icon: '📦', default_enabled: false, priority: 'low' },
  
  // Catch-all
  { name: 'All Events', event_type: 'all_events', description: 'Receive all event notifications', category: 'monitoring', color: '#6b7280', icon: '🔔', default_enabled: false, priority: 'low' }
];

export function HostDashboard() {
  // State
  const [stats, setStats] = useState<HostStats | null>(null);
  const [apiStatuses, setApiStatuses] = useState<APIStatus[]>([]);
  const [connectedCities, setConnectedCities] = useState<ConnectedCity[]>([]);
  const [globalBans, setGlobalBans] = useState<GlobalBan[]>([]);
  const [banAppeals, setBanAppeals] = useState<BanAppeal[]>([]);
  const [globalWarnings, setGlobalWarnings] = useState<GlobalWarning[]>([]);
  const [webhooks, setWebhooks] = useState<Webhook[]>([]);
  const [systemLogs, setSystemLogs] = useState<SystemLog[]>([]);
  const [actionLogs, setActionLogs] = useState<ActionLog[]>([]);
  const [performanceMetrics, setPerformanceMetrics] = useState<PerformanceMetric[]>([]);
  const [salesProjections, setSalesProjections] = useState<SalesProjection[]>([]);
  
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [webhookCategory, setWebhookCategory] = useState<string>('all');
  
  // Selected Items
  const [selectedAPI, setSelectedAPI] = useState<APIStatus | null>(null);
  const [selectedCity, setSelectedCity] = useState<ConnectedCity | null>(null);
  const [selectedAppeal, setSelectedAppeal] = useState<BanAppeal | null>(null);
  const [selectedWebhook, setSelectedWebhook] = useState<Webhook | null>(null);
  const [selectedLog, setSelectedLog] = useState<SystemLog | null>(null);
  
  // Dialogs
  const [showBanDialog, setShowBanDialog] = useState(false);
  const [showAppealDialog, setShowAppealDialog] = useState(false);
  const [showWarningDialog, setShowWarningDialog] = useState(false);
  const [showWebhookDialog, setShowWebhookDialog] = useState(false);
  const [showLogDialog, setShowLogDialog] = useState(false);
  const [showAPIDetailsDialog, setShowAPIDetailsDialog] = useState(false);
  const [showCityDetailsDialog, setShowCityDetailsDialog] = useState(false);

  // Forms
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
  });

  useEffect(() => {
    loadAllData();
    const interval = setInterval(loadAllData, 15000); // Refresh every 15s
    return () => clearInterval(interval);
  }, []);

  const loadAllData = async () => {
    try {
      const [
        hostStats,
        apis,
        cities,
        bans,
        appeals,
        warnings,
        hooks,
        sysLogs,
        actLogs,
        perfMetrics,
        salesProj
      ] = await Promise.all([
        fetchNui<HostStats>('getHostSystemStats', {}, {
          total_apis: 20,
          online_apis: 0,
          degraded_apis: 0,
          offline_apis: 20,
          system_health: 0,
          total_cities: 0,
          online_cities: 0,
          ec_admin_cities: 0,
          customer_cities: 0,
          total_players_online: 0,
          total_requests_today: 0,
          total_requests_all_time: 0,
          avg_response_time: 0,
          total_errors_today: 0,
          avg_uptime: 0,
          total_bans: 0,
          bans_today: 0,
          pending_appeals: 0,
          total_warnings: 0,
          warnings_today: 0,
          total_memory_usage: 0,
          total_cpu_usage: 0,
          database_size: 0,
          total_webhooks: 0,
          active_webhooks: 0,
          webhook_executions_today: 0,
          critical_alerts: 0,
          warnings_system: 0
        }),
        fetchNui<APIStatus[]>('getHostAPIStatuses', {}, []),
        fetchNui<ConnectedCity[]>('getConnectedCities', {}, []),
        fetchNui<GlobalBan[]>('getGlobalBans', {}, []),
        fetchNui<BanAppeal[]>('getBanAppeals', {}, []),
        fetchNui<GlobalWarning[]>('getGlobalWarnings', {}, []),
        fetchNui<Webhook[]>('getHostWebhooks', {}, []),
        fetchNui<SystemLog[]>('getSystemLogs', {}, []),
        fetchNui<ActionLog[]>('getHostActionLogs', {}, []),
        fetchNui<PerformanceMetric[]>('getPerformanceMetrics', {}, []),
        fetchNui<SalesProjection[]>('getSalesProjections', {}, [])
      ]);

      if (hostStats) setStats(hostStats);
      if (Array.isArray(apis)) setApiStatuses(apis);
      if (Array.isArray(cities)) setConnectedCities(cities);
      if (Array.isArray(bans)) setGlobalBans(bans);
      if (Array.isArray(appeals)) setBanAppeals(appeals);
      if (Array.isArray(warnings)) setGlobalWarnings(warnings);
      if (Array.isArray(hooks)) setWebhooks(hooks);
      if (Array.isArray(sysLogs)) setSystemLogs(sysLogs);
      if (Array.isArray(actLogs)) setActionLogs(actLogs);
      if (Array.isArray(perfMetrics)) setPerformanceMetrics(perfMetrics);
      if (Array.isArray(salesProj)) setSalesProjections(salesProj);

      setLoading(false);
    } catch (error) {
      console.error('Failed to load host dashboard:', error);
      setLoading(false);
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
    if (!confirm(`Stop ${apiName}?\n\nThis will disconnect all cities using this API.`)) return;
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

  const handleStartAllAPIs = async () => {
    if (!confirm('Start ALL offline APIs?\n\nThis may take a few minutes.')) return;
    try {
      await fetchNui('startAllHostAPIs', {});
      toastSuccess('Starting all APIs...');
      setTimeout(loadAllData, 5000);
    } catch (error) {
      toastError('Failed to start all APIs');
    }
  };

  const handleStopAllAPIs = async () => {
    if (!confirm('⚠️ STOP ALL APIS?\n\nThis will disconnect ALL cities and customers!\n\nAre you absolutely sure?')) return;
    try {
      await fetchNui('stopAllHostAPIs', {});
      toastSuccess('Stopping all APIs...');
      setTimeout(loadAllData, 5000);
    } catch (error) {
      toastError('Failed to stop all APIs');
    }
  };

  // Global Ban Functions
  const handleRemoveGlobalBan = async (banId: number) => {
    if (!confirm('Remove this global ban from ALL cities?\n\nThis action cannot be undone.')) return;
    try {
      await fetchNui('removeGlobalBan', { banId, reason: 'Manually removed via Host Dashboard' });
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
    if (!confirm('Remove this global warning from ALL cities?')) return;
    try {
      await fetchNui('removeGlobalWarning', { warningId, reason: 'Manually removed' });
      toastSuccess('Global warning removed');
      loadAllData();
    } catch (error) {
      toastError('Failed to remove warning');
    }
  };

  // Webhook Functions
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
    if (!webhookForm.webhookName || !webhookForm.webhookUrl) {
      toastError('Please fill in all required fields');
      return;
    }

    try {
      if (selectedWebhook) {
        await fetchNui('updateHostWebhook', { webhookId: selectedWebhook.id, ...webhookForm });
        toastSuccess('Webhook updated');
      } else {
        await fetchNui('createHostWebhook', webhookForm);
        toastSuccess('Webhook created');
      }
      setShowWebhookDialog(false);
      setSelectedWebhook(null);
      setWebhookForm({ webhookName: '', webhookUrl: '', eventType: 'global_ban' });
      loadAllData();
    } catch (error) {
      toastError('Failed to save webhook');
    }
  };

  const handleDeleteWebhook = async (webhookId: number) => {
    if (!confirm('Delete this webhook?')) return;
    try {
      await fetchNui('deleteHostWebhook', { webhookId });
      toastSuccess('Webhook deleted');
      loadAllData();
    } catch (error) {
      toastError('Failed to delete webhook');
    }
  };

  // System Functions
  const handleResolveAlert = async (logId: number) => {
    try {
      await fetchNui('resolveSystemAlert', { logId });
      toastSuccess('Alert marked as resolved');
      loadAllData();
    } catch (error) {
      toastError('Failed to resolve alert');
    }
  };

  const handleDisconnectCity = async (cityId: string) => {
    if (!confirm('Disconnect this city?\n\nThey will need to reconnect manually.')) return;
    try {
      await fetchNui('disconnectCity', { cityId });
      toastSuccess('City disconnected');
      loadAllData();
    } catch (error) {
      toastError('Failed to disconnect city');
    }
  };

  // Utility Functions
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

  const formatNumber = (num: number) => {
    if (num >= 1000000) return `${(num / 1000000).toFixed(1)}M`;
    if (num >= 1000) return `${(num / 1000).toFixed(1)}K`;
    return num.toString();
  };

  const formatBytes = (bytes: number) => {
    if (bytes >= 1073741824) return `${(bytes / 1073741824).toFixed(2)} GB`;
    if (bytes >= 1048576) return `${(bytes / 1048576).toFixed(2)} MB`;
    if (bytes >= 1024) return `${(bytes / 1024).toFixed(2)} KB`;
    return `${bytes} B`;
  };

  const getHealthColor = (health: number) => {
    if (health >= 90) return 'text-green-500';
    if (health >= 70) return 'text-yellow-500';
    return 'text-red-500';
  };

  const getHealthBg = (health: number) => {
    if (health >= 90) return 'bg-green-500';
    if (health >= 70) return 'bg-yellow-500';
    return 'bg-red-500';
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

  const getLogTypeColor = (type: string) => {
    switch (type) {
      case 'info': return 'bg-blue-500';
      case 'warn': return 'bg-yellow-500';
      case 'error': return 'bg-orange-500';
      case 'critical': return 'bg-red-500';
      default: return 'bg-gray-500';
    }
  };

  const safeAPIs = Array.isArray(apiStatuses) ? apiStatuses : [];
  const onlineAPIs = safeAPIs.filter(api => api.status === 'online').length;
  const degradedAPIs = safeAPIs.filter(api => api.status === 'degraded').length;
  const offlineAPIs = safeAPIs.filter(api => api.status === 'offline').length;

  const ecAdminCities = connectedCities.filter(c => c.customer_label === 'ec_admin');
  const customerCities = connectedCities.filter(c => c.customer_label === 'customer');

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-center">
          <RefreshCw className="size-8 animate-spin mx-auto mb-4 text-primary" />
          <p className="text-muted-foreground">Loading Host Control Center...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* Hero Header - NRG Sales & Revenue Control Center */}
      <div className="relative overflow-hidden rounded-xl bg-gradient-to-br from-red-600 via-orange-600 to-yellow-600 p-8">
        <div className="absolute inset-0 bg-black/20"></div>
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGRlZnM+PHBhdHRlcm4gaWQ9ImdyaWQiIHdpZHRoPSI0MCIgaGVpZ2h0PSI0MCIgcGF0dGVyblVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+PHBhdGggZD0iTSAwIDEwIEwgNDAgMTAgTSAxMCAwIEwgMTAgNDAgTSAwIDIwIEwgNDAgMjAgTSAyMCAwIEwgMjAgNDAgTSAwIDMwIEwgNDAgMzAgTSAzMCAwIEwgMzAgNDAiIGZpbGw9Im5vbmUiIHN0cm9rZT0id2hpdGUiIHN0cm9rZS1vcGFjaXR5PSIwLjEiIHN0cm9rZS13aWR0aD0iMSIvPjwvcGF0dGVybj48L2RlZnM+PHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsbD0idXJsKCNncmlkKSIvPjwvc3ZnPg==')] opacity-20"></div>
        
        <div className="relative z-10 flex items-start justify-between">
          <div className="space-y-2">
            <div className="flex items-center gap-3">
              <DollarSign className="size-12 text-white animate-pulse" />
              <div>
                <h1 className="text-4xl text-white">NRG Sales & Revenue Dashboard</h1>
                <p className="text-white/90 text-lg mt-1">Internal Analytics • Revenue Tracking • Growth Forecasting</p>
              </div>
              <Badge className="bg-green-500 text-white border-0 animate-pulse">
                <TrendingUp className="size-3 mr-1" />
                LIVE
              </Badge>
            </div>
            
            <div className="flex gap-4 mt-4">
              <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/20">
                <p className="text-white/70 text-xs">Total Revenue (6mo)</p>
                <p className="text-2xl text-white">
                  ${salesProjections.length > 0 ? salesProjections.reduce((sum, p) => sum + p.projected_revenue, 0).toFixed(2) : '0.00'}
                </p>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/20">
                <p className="text-white/70 text-xs">Projected MRR</p>
                <p className="text-2xl text-white">
                  ${salesProjections.length > 0 ? (salesProjections[salesProjections.length - 1]?.projected_mrr || 0).toFixed(2) : '0.00'}
                </p>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/20">
                <p className="text-white/70 text-xs">New Customers</p>
                <p className="text-2xl text-white">
                  +{salesProjections.length > 0 ? (salesProjections[salesProjections.length - 1]?.projected_customers || 0) : 0}
                </p>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/20">
                <p className="text-white/70 text-xs">Forecast Confidence</p>
                <p className="text-2xl text-white">
                  {salesProjections.length > 0 ? (salesProjections.reduce((sum, p) => sum + p.confidence, 0) / salesProjections.length).toFixed(0) : 0}%
                </p>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2 border border-white/20">
                <p className="text-white/70 text-xs">Total Customers</p>
                <p className="text-2xl text-white">{stats?.total_cities || 0}</p>
              </div>
            </div>
          </div>
          
          <div className="flex gap-2">
            <Button onClick={loadAllData} variant="secondary" className="gap-2 bg-white/20 backdrop-blur-sm border-white/30 text-white hover:bg-white/30">
              <RefreshCw className="size-4" />
              Refresh
            </Button>
          </div>
        </div>
      </div>

      {/* Critical Alerts Bar */}
      {stats && stats.critical_alerts > 0 && (
        <Card className="border-red-500 bg-red-500/10">
          <CardContent className="py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Siren className="size-6 text-red-500 animate-pulse" />
                <div>
                  <p className="font-semibold text-red-500">Critical System Alerts</p>
                  <p className="text-sm text-muted-foreground">
                    {stats.critical_alerts} critical alert{stats.critical_alerts !== 1 ? 's' : ''} require immediate attention
                  </p>
                </div>
              </div>
              <Button variant="destructive" className="gap-2">
                <Eye className="size-4" />
                View Alerts
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Sales Projections Section */}
      {salesProjections.length > 0 && (
        <Card className="border-green-500/30">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="size-5 text-green-500" />
                  Sales Projections & Revenue Forecasting
                </CardTitle>
                <CardDescription>AI-powered revenue predictions based on historical data</CardDescription>
              </div>
              <Badge variant="outline" className="gap-1">
                <Target className="size-3" />
                Next 6 Months
              </Badge>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Projection Chart */}
              <div className="lg:col-span-2">
                <ResponsiveContainer width="100%" height={300}>
                  <AreaChart data={salesProjections}>
                    <defs>
                      <linearGradient id="colorProjectedRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                      </linearGradient>
                      <linearGradient id="colorProjectedMRR" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis dataKey="month" stroke="#64748b" fontSize={12} />
                    <YAxis stroke="#64748b" fontSize={12} />
                    <Tooltip 
                      contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                      labelStyle={{ color: '#e2e8f0' }}
                      formatter={(value: number) => `$${value.toFixed(2)}`}
                    />
                    <Legend />
                    <Area 
                      type="monotone" 
                      dataKey="projected_revenue" 
                      stroke="#10b981" 
                      fillOpacity={1} 
                      fill="url(#colorProjectedRevenue)" 
                      name="Projected Revenue" 
                    />
                    <Area 
                      type="monotone" 
                      dataKey="projected_mrr" 
                      stroke="#3b82f6" 
                      fillOpacity={1} 
                      fill="url(#colorProjectedMRR)" 
                      name="Projected MRR" 
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>

              {/* Projection Summary Cards */}
              <div className="space-y-4">
                <Card className="border-green-500/20 bg-gradient-to-br from-green-500/10 to-transparent">
                  <CardHeader className="pb-2">
                    <CardDescription className="text-xs">6-Month Revenue Projection</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl text-green-500">
                      ${salesProjections.reduce((sum, p) => sum + p.projected_revenue, 0).toFixed(2)}
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Avg confidence: {(salesProjections.reduce((sum, p) => sum + p.confidence, 0) / salesProjections.length).toFixed(0)}%
                    </p>
                  </CardContent>
                </Card>

                <Card className="border-blue-500/20 bg-gradient-to-br from-blue-500/10 to-transparent">
                  <CardHeader className="pb-2">
                    <CardDescription className="text-xs">Projected Customer Growth</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl text-blue-500">
                      +{salesProjections[salesProjections.length - 1]?.projected_customers || 0}
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      New customers in 6 months
                    </p>
                  </CardContent>
                </Card>

                <Card className="border-purple-500/20 bg-gradient-to-br from-purple-500/10 to-transparent">
                  <CardHeader className="pb-2">
                    <CardDescription className="text-xs">MRR Growth Target</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl text-purple-500">
                      ${(salesProjections[salesProjections.length - 1]?.projected_mrr || 0).toFixed(2)}
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Expected by {salesProjections[salesProjections.length - 1]?.month}
                    </p>
                  </CardContent>
                </Card>

                <Card className="border-amber-500/20 bg-gradient-to-br from-amber-500/10 to-transparent">
                  <CardHeader className="pb-2">
                    <CardDescription className="text-xs">Forecast Confidence</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl text-amber-500">
                      {(salesProjections.reduce((sum, p) => sum + p.confidence, 0) / salesProjections.length).toFixed(0)}%
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Based on historical trends
                    </p>
                    <div className="mt-2 h-2 bg-amber-500/20 rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-amber-500 rounded-full" 
                        style={{ width: `${(salesProjections.reduce((sum, p) => sum + p.confidence, 0) / salesProjections.length)}%` }}
                      ></div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>

            {/* Monthly Breakdown Table */}
            <div className="mt-6">
              <h4 className="text-sm font-medium mb-3 flex items-center gap-2">
                <CalendarDays className="size-4" />
                Monthly Breakdown
              </h4>
              <div className="rounded-lg border border-slate-800">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Month</TableHead>
                      <TableHead>Projected Revenue</TableHead>
                      <TableHead>Projected MRR</TableHead>
                      <TableHead>New Customers</TableHead>
                      <TableHead>Confidence</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {salesProjections.map((proj, idx) => (
                      <TableRow key={idx}>
                        <TableCell className="font-medium">{proj.month}</TableCell>
                        <TableCell className="text-green-500">${proj.projected_revenue.toFixed(2)}</TableCell>
                        <TableCell className="text-blue-500">${proj.projected_mrr.toFixed(2)}</TableCell>
                        <TableCell className="text-purple-500">+{proj.projected_customers}</TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <div className="flex-1 h-1.5 bg-slate-800 rounded-full overflow-hidden">
                              <div 
                                className="h-full bg-green-500 rounded-full" 
                                style={{ width: `${proj.confidence}%` }}
                              ></div>
                            </div>
                            <span className="text-xs text-muted-foreground w-10">{proj.confidence}%</span>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Infrastructure Stats Grid */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* API Services */}
          <Card className="border-blue-500/20 bg-gradient-to-br from-blue-500/10 to-transparent">
            <CardHeader className="pb-2">
              <CardDescription className="flex items-center gap-2">
                <Database className="size-4 text-blue-500" />
                API Services
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl text-blue-500">{stats.online_apis}/{stats.total_apis}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {offlineAPIs} offline • {degradedAPIs} degraded
              </p>
              <div className="flex gap-1 mt-2">
                <div className="flex-1 h-2 bg-green-500 rounded-l-full" style={{ width: `${(onlineAPIs/stats.total_apis)*100}%` }}></div>
                <div className="flex-1 h-2 bg-yellow-500" style={{ width: `${(degradedAPIs/stats.total_apis)*100}%` }}></div>
                <div className="flex-1 h-2 bg-red-500 rounded-r-full" style={{ width: `${(offlineAPIs/stats.total_apis)*100}%` }}></div>
              </div>
            </CardContent>
          </Card>

          {/* Connected Cities */}
          <Card className="border-green-500/20 bg-gradient-to-br from-green-500/10 to-transparent">
            <CardHeader className="pb-2">
              <CardDescription className="flex items-center gap-2">
                <Globe className="size-4 text-green-500" />
                Connected Cities
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl text-green-500">{stats.online_cities}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.ec_admin_cities} EC Admin • {stats.customer_cities} Customer
              </p>
              <p className="text-xs text-muted-foreground">
                {stats.total_players_online} players online
              </p>
            </CardContent>
          </Card>

          {/* Request Volume */}
          <Card className="border-purple-500/20 bg-gradient-to-br from-purple-500/10 to-transparent">
            <CardHeader className="pb-2">
              <CardDescription className="flex items-center gap-2">
                <Activity className="size-4 text-purple-500" />
                Request Volume
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl text-purple-500">{formatNumber(stats.total_requests_today)}</div>
              <p className="text-xs text-muted-foreground mt-1">
                Today • {formatNumber(stats.total_requests_all_time)} all-time
              </p>
              <p className="text-xs text-muted-foreground">
                Avg: {stats.avg_response_time}ms
              </p>
            </CardContent>
          </Card>

          {/* System Resources */}
          <Card className="border-orange-500/20 bg-gradient-to-br from-orange-500/10 to-transparent">
            <CardHeader className="pb-2">
              <CardDescription className="flex items-center gap-2">
                <Cpu className="size-4 text-orange-500" />
                System Resources
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl text-orange-500">{stats.total_cpu_usage.toFixed(0)}%</div>
              <p className="text-xs text-muted-foreground mt-1">
                CPU • {stats.total_memory_usage.toFixed(0)}% RAM
              </p>
              <p className="text-xs text-muted-foreground">
                DB: {formatBytes(stats.database_size)}
              </p>
            </CardContent>
          </Card>

          {/* Global Bans */}
          <Card className="border-red-500/20 bg-gradient-to-br from-red-500/10 to-transparent">
            <CardHeader className="pb-2">
              <CardDescription className="flex items-center gap-2">
                <Ban className="size-4 text-red-500" />
                Global Bans
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl text-red-500">{stats.total_bans}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.bans_today} today • {stats.pending_appeals} appeals
              </p>
            </CardContent>
          </Card>

          {/* Warnings */}
          <Card className="border-yellow-500/20 bg-gradient-to-br from-yellow-500/10 to-transparent">
            <CardHeader className="pb-2">
              <CardDescription className="flex items-center gap-2">
                <AlertTriangle className="size-4 text-yellow-500" />
                Global Warnings
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl text-yellow-500">{stats.total_warnings}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.warnings_today} issued today
              </p>
            </CardContent>
          </Card>

          {/* Webhooks */}
          <Card className="border-cyan-500/20 bg-gradient-to-br from-cyan-500/10 to-transparent">
            <CardHeader className="pb-2">
              <CardDescription className="flex items-center gap-2">
                <Webhook className="size-4 text-cyan-500" />
                Webhooks
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl text-cyan-500">{stats.active_webhooks}/{stats.total_webhooks}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.webhook_executions_today} executions today
              </p>
            </CardContent>
          </Card>

          {/* System Health */}
          <Card className="border-pink-500/20 bg-gradient-to-br from-pink-500/10 to-transparent">
            <CardHeader className="pb-2">
              <CardDescription className="flex items-center gap-2">
                <HeartPulse className="size-4 text-pink-500" />
                System Health
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className={`text-3xl ${getHealthColor(stats.system_health)}`}>
                {stats.system_health}%
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Avg uptime: {stats.avg_uptime.toFixed(1)}%
              </p>
              <div className="mt-2 h-2 bg-slate-800 rounded-full overflow-hidden">
                <div 
                  className={`h-full rounded-full ${getHealthBg(stats.system_health)}`}
                  style={{ width: `${stats.system_health}%` }}
                ></div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Quick Actions & Live Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Quick Actions */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Zap className="size-5 text-yellow-500" />
              Quick Actions
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <Button className="w-full justify-start gap-2" variant="outline" onClick={handleStartAllAPIs}>
              <PlayCircle className="size-4 text-green-500" />
              Start All APIs
            </Button>
            <Button className="w-full justify-start gap-2" variant="outline" onClick={handleStopAllAPIs}>
              <StopCircle className="size-4 text-red-500" />
              Stop All APIs
            </Button>
            <Button className="w-full justify-start gap-2" variant="outline" onClick={() => setShowBanDialog(true)}>
              <Ban className="size-4" />
              Apply Global Ban
            </Button>
            <Button className="w-full justify-start gap-2" variant="outline" onClick={() => setShowWarningDialog(true)}>
              <AlertTriangle className="size-4" />
              Issue Global Warning
            </Button>
            <Button className="w-full justify-start gap-2" variant="outline" onClick={() => setShowWebhookDialog(true)}>
              <Webhook className="size-4" />
              Create Webhook
            </Button>
            <Button className="w-full justify-start gap-2" variant="outline">
              <Download className="size-4" />
              Export System Logs
            </Button>
          </CardContent>
        </Card>

        {/* Live Activity Feed */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center gap-2">
                <Radio className="size-5 text-green-500 animate-pulse" />
                Live System Activity
              </CardTitle>
              <Badge variant="outline" className="gap-1">
                <Circle className="size-2 fill-green-500 text-green-500 animate-pulse" />
                Live
              </Badge>
            </div>
          </CardHeader>
          <CardContent>
            <ScrollArea className="h-64">
              <div className="space-y-2">
                {actionLogs.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground">
                    <Activity className="size-12 mx-auto mb-2 opacity-50" />
                    <p>No recent activity</p>
                  </div>
                ) : (
                  actionLogs.slice(0, 15).map((log) => (
                    <div key={log.id} className="flex items-start gap-3 p-3 rounded-lg bg-slate-900/50 border border-slate-800 hover:border-slate-700 transition-colors">
                      <div className={`size-2 rounded-full mt-2 ${
                        log.action_type.includes('ban') ? 'bg-red-500' :
                        log.action_type.includes('warning') ? 'bg-yellow-500' :
                        log.action_type.includes('api') ? 'bg-blue-500' :
                        log.action_type.includes('city') ? 'bg-green-500' :
                        'bg-purple-500'
                      }`}></div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm">
                          <span className="font-medium">{log.admin_name}</span>
                          {' '}
                          <span className="text-muted-foreground">{log.action_type.replace(/_/g, ' ')}</span>
                          {log.target_name && (
                            <>
                              {' → '}
                              <span className="font-medium">{log.target_name}</span>
                            </>
                          )}
                        </p>
                        <p className="text-xs text-muted-foreground mt-1">
                          {formatDate(log.timestamp)}
                          {log.city_name && ` • ${log.city_name}`}
                        </p>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </ScrollArea>
          </CardContent>
        </Card>
      </div>

      {/* Performance Charts */}
      {performanceMetrics.length > 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Request Volume Chart */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart3 className="size-5 text-blue-500" />
                Request Volume (24h)
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={250}>
                <AreaChart data={performanceMetrics}>
                  <defs>
                    <linearGradient id="colorRequests" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                  <XAxis dataKey="timestamp" stroke="#64748b" fontSize={12} />
                  <YAxis stroke="#64748b" fontSize={12} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                    labelStyle={{ color: '#e2e8f0' }}
                  />
                  <Area type="monotone" dataKey="requests" stroke="#3b82f6" fillOpacity={1} fill="url(#colorRequests)" name="Requests" />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* System Resources Chart */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Gauge className="size-5 text-orange-500" />
                System Resources (24h)
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={250}>
                <LineChart data={performanceMetrics}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                  <XAxis dataKey="timestamp" stroke="#64748b" fontSize={12} />
                  <YAxis stroke="#64748b" fontSize={12} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                    labelStyle={{ color: '#e2e8f0' }}
                  />
                  <Legend />
                  <Line type="monotone" dataKey="cpu" stroke="#f59e0b" name="CPU %" />
                  <Line type="monotone" dataKey="memory" stroke="#8b5cf6" name="Memory %" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Main Management Tabs */}
      <Tabs defaultValue="apis" className="w-full">
        <TabsList className="bg-slate-900 border border-slate-800">
          <TabsTrigger value="apis" className="gap-2">
            <Database className="size-4" />
            API Services
          </TabsTrigger>
          <TabsTrigger value="cities" className="gap-2">
            <Globe className="size-4" />
            Connected Cities
          </TabsTrigger>
          <TabsTrigger value="bans" className="gap-2">
            <Ban className="size-4" />
            Global Bans
          </TabsTrigger>
          <TabsTrigger value="appeals" className="gap-2">
            <FileText className="size-4" />
            Appeals {stats && stats.pending_appeals > 0 && (
              <Badge variant="destructive" className="ml-1">{stats.pending_appeals}</Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="warnings" className="gap-2">
            <AlertTriangle className="size-4" />
            Warnings
          </TabsTrigger>
          <TabsTrigger value="webhooks" className="gap-2">
            <Webhook className="size-4" />
            Webhooks
          </TabsTrigger>
          <TabsTrigger value="logs" className="gap-2">
            <Terminal className="size-4" />
            System Logs
          </TabsTrigger>
        </TabsList>

        {/* API Services Tab */}
        <TabsContent value="apis" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <ServerCog className="size-5" />
                    API Services Management
                  </CardTitle>
                  <CardDescription>Monitor and control all 20 API services</CardDescription>
                </div>
                <div className="flex gap-2">
                  <Button size="sm" variant="outline" className="gap-2" onClick={handleStartAllAPIs}>
                    <PlayCircle className="size-4 text-green-500" />
                    Start All
                  </Button>
                  <Button size="sm" variant="destructive" className="gap-2" onClick={handleStopAllAPIs}>
                    <StopCircle className="size-4" />
                    Stop All
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                {safeAPIs.map((api) => (
                  <Card 
                    key={api.key} 
                    className={`border-2 transition-all hover:shadow-lg ${
                      api.status === 'online' ? 'border-green-500/30 hover:shadow-green-500/20' :
                      api.status === 'degraded' ? 'border-yellow-500/30 hover:shadow-yellow-500/20' :
                      'border-red-500/30 hover:shadow-red-500/20'
                    }`}
                  >
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <CardTitle className="text-sm flex items-center gap-2">
                            {api.status === 'online' && <Wifi className="size-4 text-green-500" />}
                            {api.status === 'offline' && <WifiOff className="size-4 text-red-500" />}
                            {api.status === 'degraded' && <AlertTriangle className="size-4 text-yellow-500" />}
                            {api.name}
                          </CardTitle>
                          <CardDescription className="text-xs mt-1">
                            :{api.port} • v{api.version}
                          </CardDescription>
                        </div>
                        <Badge 
                          variant={
                            api.status === 'online' ? 'default' :
                            api.status === 'degraded' ? 'secondary' :
                            'destructive'
                          }
                          className="gap-1"
                        >
                          <Circle className={`size-2 ${api.status === 'online' ? 'fill-green-500 animate-pulse' : ''}`} />
                          {api.status}
                        </Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <div className="grid grid-cols-2 gap-2 text-xs">
                        <div>
                          <p className="text-muted-foreground">Uptime</p>
                          <p className="font-medium">{formatUptime(api.uptime)}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Requests</p>
                          <p className="font-medium">{formatNumber(api.requests)}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Response</p>
                          <p className={`font-medium ${api.avgResponseTime > 500 ? 'text-red-500' : 'text-green-500'}`}>
                            {api.avgResponseTime}ms
                          </p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Errors</p>
                          <p className={`font-medium ${api.errorRate > 5 ? 'text-red-500' : ''}`}>
                            {api.errorRate.toFixed(1)}%
                          </p>
                        </div>
                      </div>

                      {api.status === 'online' && (
                        <div className="space-y-1">
                          <div className="flex justify-between text-xs">
                            <span>Health: {api.healthStatus}</span>
                            <span>{api.activeConnections} active</span>
                          </div>
                          <div className="h-1 bg-slate-800 rounded-full overflow-hidden">
                            <div 
                              className={`h-full rounded-full ${
                                api.healthStatus === 'healthy' ? 'bg-green-500' :
                                api.healthStatus === 'degraded' ? 'bg-yellow-500' :
                                'bg-red-500'
                              }`}
                              style={{ width: api.healthStatus === 'healthy' ? '100%' : api.healthStatus === 'degraded' ? '60%' : '30%' }}
                            ></div>
                          </div>
                        </div>
                      )}
                      
                      <div className="flex gap-1">
                        {api.status === 'offline' ? (
                          <Button 
                            size="sm" 
                            variant="outline" 
                            className="flex-1 gap-1 text-green-500 border-green-500/50 hover:bg-green-500/10"
                            onClick={() => handleStartAPI(api.key, api.name)}
                          >
                            <PlayCircle className="size-3" />
                            Start
                          </Button>
                        ) : (
                          <>
                            <Button 
                              size="sm" 
                              variant="outline" 
                              className="flex-1 gap-1"
                              onClick={() => handleRestartAPI(api.key, api.name)}
                            >
                              <RefreshCw className="size-3" />
                            </Button>
                            <Button 
                              size="sm" 
                              variant="ghost" 
                              className="gap-1 text-red-500 hover:bg-red-500/10"
                              onClick={() => handleStopAPI(api.key, api.name)}
                            >
                              <StopCircle className="size-3" />
                            </Button>
                            <Button 
                              size="sm" 
                              variant="ghost"
                              onClick={() => {
                                setSelectedAPI(api);
                                setShowAPIDetailsDialog(true);
                              }}
                            >
                              <Eye className="size-3" />
                            </Button>
                          </>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Connected Cities Tab */}
        <TabsContent value="cities" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <Globe className="size-5" />
                    Connected Cities
                  </CardTitle>
                  <CardDescription>
                    {ecAdminCities.length} EC Admin • {customerCities.length} Customer
                  </CardDescription>
                </div>
                <div className="flex gap-2">
                  <Select value={filterStatus} onValueChange={setFilterStatus}>
                    <SelectTrigger className="w-32">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Cities</SelectItem>
                      <SelectItem value="ec_admin">EC Admin</SelectItem>
                      <SelectItem value="customer">Customer</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
                {connectedCities
                  .filter(city => filterStatus === 'all' || city.customer_label === filterStatus)
                  .map((city) => (
                  <Card key={city.id} className={`border-2 ${
                    city.status === 'online' ? 'border-green-500/30' : 'border-slate-800'
                  }`}>
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <CardTitle className="text-base flex items-center gap-2">
                            <Server className="size-4" />
                            {city.city_name}
                          </CardTitle>
                          <CardDescription className="text-xs mt-1">{city.city_ip}</CardDescription>
                        </div>
                        <div className="flex flex-col gap-1 items-end">
                          <Badge variant={city.status === 'online' ? 'default' : 'secondary'} className="gap-1">
                            <Circle className={`size-2 ${city.status === 'online' ? 'fill-green-500 animate-pulse' : ''}`} />
                            {city.status}
                          </Badge>
                          <Badge className={city.customer_label === 'ec_admin' ? 'bg-purple-600' : 'bg-blue-600'}>
                            {city.customer_label === 'ec_admin' ? 'EC Admin' : 'Customer'}
                          </Badge>
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <div className="grid grid-cols-3 gap-2 text-xs">
                        <div>
                          <p className="text-muted-foreground">Players</p>
                          <p className="font-medium text-green-500">{city.players_online}/{city.max_players}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Framework</p>
                          <p className="font-medium uppercase">{city.framework}</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground">Version</p>
                          <p className="font-medium">v{city.version}</p>
                        </div>
                      </div>

                      <div>
                        <p className="text-xs text-muted-foreground mb-1">Connected APIs ({city.connected_apis.length})</p>
                        <div className="flex flex-wrap gap-1">
                          {city.connected_apis.slice(0, 3).map((apiKey, idx) => (
                            <Badge key={idx} variant="outline" className="text-xs">
                              {apiKey.replace('_api', '')}
                            </Badge>
                          ))}
                          {city.connected_apis.length > 3 && (
                            <Badge variant="outline" className="text-xs">
                              +{city.connected_apis.length - 3} more
                            </Badge>
                          )}
                        </div>
                      </div>

                      <div className="flex gap-2 pt-2 border-t border-slate-800">
                        <Button 
                          size="sm" 
                          variant="outline" 
                          className="flex-1 gap-1"
                          onClick={() => {
                            setSelectedCity(city);
                            setShowCityDetailsDialog(true);
                          }}
                        >
                          <Eye className="size-3" />
                          Details
                        </Button>
                        <Button 
                          size="sm" 
                          variant="destructive" 
                          className="gap-1"
                          onClick={() => handleDisconnectCity(city.id)}
                        >
                          <Unplug className="size-3" />
                          Disconnect
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Global Bans Tab */}
        <TabsContent value="bans" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Global Ban Management</CardTitle>
                  <CardDescription>Cross-city ban enforcement</CardDescription>
                </div>
                <Button className="gap-2" onClick={() => setShowBanDialog(true)}>
                  <Plus className="size-4" />
                  Apply Global Ban
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Player</TableHead>
                    <TableHead>Identifier</TableHead>
                    <TableHead>Reason</TableHead>
                    <TableHead>Banned By</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Cities</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {globalBans.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center text-muted-foreground py-8">
                        No global bans on record
                      </TableCell>
                    </TableRow>
                  ) : (
                    globalBans.map((ban) => (
                      <TableRow key={ban.id}>
                        <TableCell className="font-medium">{ban.player_name}</TableCell>
                        <TableCell className="font-mono text-xs">{ban.identifier.substring(0, 20)}...</TableCell>
                        <TableCell className="max-w-xs truncate">{ban.reason}</TableCell>
                        <TableCell>{ban.banned_by}</TableCell>
                        <TableCell className="text-xs">{formatDate(ban.banned_at)}</TableCell>
                        <TableCell>
                          <Badge variant="outline">{ban.cities_count} cities</Badge>
                        </TableCell>
                        <TableCell>
                          <Badge variant={ban.active ? 'destructive' : 'secondary'}>
                            {ban.active ? 'Active' : 'Inactive'}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleRemoveGlobalBan(ban.id)}
                            disabled={!ban.active}
                          >
                            <Trash2 className="size-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Appeals Tab */}
        <TabsContent value="appeals" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Ban Appeal Management</CardTitle>
              <CardDescription>Review and process ban appeals</CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Player</TableHead>
                    <TableHead>Appeal Reason</TableHead>
                    <TableHead>Submitted</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {banAppeals.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center text-muted-foreground py-8">
                        No ban appeals to review
                      </TableCell>
                    </TableRow>
                  ) : (
                    banAppeals.map((appeal) => (
                      <TableRow key={appeal.id}>
                        <TableCell className="font-medium">{appeal.player_name}</TableCell>
                        <TableCell className="max-w-md truncate">{appeal.appeal_reason}</TableCell>
                        <TableCell className="text-xs">{formatDate(appeal.submitted_at)}</TableCell>
                        <TableCell>
                          <Badge 
                            variant={
                              appeal.status === 'pending' ? 'secondary' :
                              appeal.status === 'approved' ? 'default' : 'destructive'
                            }
                          >
                            {appeal.status}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => {
                              setSelectedAppeal(appeal);
                              setShowAppealDialog(true);
                            }}
                            disabled={appeal.status !== 'pending'}
                          >
                            <Eye className="size-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Warnings Tab */}
        <TabsContent value="warnings" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Global Warning System</CardTitle>
                  <CardDescription>Issue cross-city warnings</CardDescription>
                </div>
                <Button className="gap-2" onClick={() => setShowWarningDialog(true)}>
                  <Plus className="size-4" />
                  Issue Warning
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Player</TableHead>
                    <TableHead>Severity</TableHead>
                    <TableHead>Reason</TableHead>
                    <TableHead>Issued By</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {globalWarnings.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} className="text-center text-muted-foreground py-8">
                        No warnings issued
                      </TableCell>
                    </TableRow>
                  ) : (
                    globalWarnings.map((warning) => (
                      <TableRow key={warning.id}>
                        <TableCell className="font-medium">{warning.player_name}</TableCell>
                        <TableCell>
                          <Badge className={getSeverityColor(warning.severity)}>
                            {warning.severity}
                          </Badge>
                        </TableCell>
                        <TableCell className="max-w-xs truncate">{warning.reason}</TableCell>
                        <TableCell>{warning.issued_by}</TableCell>
                        <TableCell className="text-xs">{formatDate(warning.issued_at)}</TableCell>
                        <TableCell>
                          <Badge variant={warning.active ? 'default' : 'secondary'}>
                            {warning.active ? 'Active' : 'Inactive'}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleRemoveWarning(warning.id)}
                            disabled={!warning.active}
                          >
                            <Trash2 className="size-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Webhooks Tab */}
        <TabsContent value="webhooks" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <Webhook className="size-5" />
                    Discord Webhook Templates
                  </CardTitle>
                  <CardDescription>36 pre-configured events • Just add your webhook URL</CardDescription>
                </div>
                <Select value={webhookCategory} onValueChange={setWebhookCategory}>
                  <SelectTrigger className="w-40">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Categories</SelectItem>
                    <SelectItem value="security">🔒 Security</SelectItem>
                    <SelectItem value="moderation">⚖️ Moderation</SelectItem>
                    <SelectItem value="system">⚙️ System</SelectItem>
                    <SelectItem value="business">💰 Business</SelectItem>
                    <SelectItem value="monitoring">📊 Monitoring</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {WEBHOOK_TEMPLATES
                  .filter(template => webhookCategory === 'all' || template.category === webhookCategory)
                  .map((template) => {
                    // Check if webhook exists for this event type
                    const existingWebhook = webhooks.find(w => w.event_type === template.event_type);
                    
                    return (
                      <Card 
                        key={template.event_type} 
                        className={`border-2 transition-all hover:shadow-lg ${
                          existingWebhook?.enabled 
                            ? 'border-green-500/30 bg-green-500/5' 
                            : existingWebhook 
                            ? 'border-slate-700 bg-slate-900/50' 
                            : 'border-slate-800'
                        }`}
                      >
                        <CardHeader className="pb-3">
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <div className="flex items-center gap-2 mb-1">
                                <span className="text-xl">{template.icon}</span>
                                <CardTitle className="text-sm">{template.name}</CardTitle>
                              </div>
                              <CardDescription className="text-xs">{template.description}</CardDescription>
                            </div>
                            {existingWebhook && (
                              <Switch
                                checked={existingWebhook.enabled}
                                onCheckedChange={() => handleToggleWebhook(existingWebhook.id, existingWebhook.enabled)}
                              />
                            )}
                          </div>
                        </CardHeader>
                        <CardContent className="space-y-2">
                          <div className="flex items-center justify-between text-xs">
                            <Badge 
                              variant="outline" 
                              style={{ borderColor: template.color, color: template.color }}
                            >
                              {template.category}
                            </Badge>
                            <Badge 
                              variant={
                                template.priority === 'critical' ? 'destructive' :
                                template.priority === 'high' ? 'secondary' :
                                'outline'
                              }
                              className="text-xs"
                            >
                              {template.priority}
                            </Badge>
                          </div>
                          
                          {existingWebhook ? (
                            <>
                              <div className="flex items-center gap-1 text-xs text-muted-foreground">
                                <CheckCircle className="size-3 text-green-500" />
                                <span>{existingWebhook.executions_24h} executions today</span>
                              </div>
                              <div className="flex gap-1">
                                <Button 
                                  size="sm" 
                                  variant="outline" 
                                  className="flex-1 gap-1 h-7 text-xs"
                                  onClick={() => handleTestWebhook(existingWebhook.id)}
                                >
                                  <Send className="size-3" />
                                  Test
                                </Button>
                                <Button 
                                  size="sm" 
                                  variant="ghost" 
                                  className="gap-1 h-7 text-xs"
                                  onClick={() => {
                                    setSelectedWebhook(existingWebhook);
                                    setWebhookForm({
                                      webhookName: existingWebhook.webhook_name,
                                      webhookUrl: existingWebhook.webhook_url,
                                      eventType: existingWebhook.event_type
                                    });
                                    setShowWebhookDialog(true);
                                  }}
                                >
                                  <Edit className="size-3" />
                                </Button>
                                <Button 
                                  size="sm" 
                                  variant="ghost" 
                                  className="gap-1 h-7 text-xs text-red-500"
                                  onClick={() => handleDeleteWebhook(existingWebhook.id)}
                                >
                                  <Trash2 className="size-3" />
                                </Button>
                              </div>
                            </>
                          ) : (
                            <Button 
                              size="sm" 
                              variant="outline" 
                              className="w-full gap-1 h-7 text-xs"
                              onClick={() => {
                                setSelectedWebhook(null);
                                setWebhookForm({
                                  webhookName: template.name,
                                  webhookUrl: '',
                                  eventType: template.event_type
                                });
                                setShowWebhookDialog(true);
                              }}
                            >
                              <Plus className="size-3" />
                              Configure Webhook
                            </Button>
                          )}
                        </CardContent>
                      </Card>
                    );
                  })}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* System Logs Tab */}
        <TabsContent value="logs" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <Terminal className="size-5" />
                    System Logs
                  </CardTitle>
                  <CardDescription>Real-time system monitoring</CardDescription>
                </div>
                <div className="flex gap-2">
                  <Select defaultValue="all">
                    <SelectTrigger className="w-32">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Logs</SelectItem>
                      <SelectItem value="info">Info</SelectItem>
                      <SelectItem value="warn">Warnings</SelectItem>
                      <SelectItem value="error">Errors</SelectItem>
                      <SelectItem value="critical">Critical</SelectItem>
                    </SelectContent>
                  </Select>
                  <Button variant="outline" className="gap-2">
                    <Download className="size-4" />
                    Export
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-96">
                <div className="space-y-2">
                  {systemLogs.length === 0 ? (
                    <div className="text-center py-12 text-muted-foreground">
                      <FileText className="size-12 mx-auto mb-4 opacity-50" />
                      <p>No system logs</p>
                    </div>
                  ) : (
                    systemLogs.map((log) => (
                      <div 
                        key={log.id} 
                        className="flex items-start gap-3 p-3 rounded-lg bg-slate-900/50 border border-slate-800 hover:border-slate-700 transition-colors"
                      >
                        <div className={`size-2 rounded-full mt-2 ${getLogTypeColor(log.log_type)}`}></div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <p className="text-sm font-medium">{log.message}</p>
                              <p className="text-xs text-muted-foreground mt-1">
                                {log.source} • {formatDate(log.timestamp)}
                              </p>
                            </div>
                            {!log.resolved && log.log_type !== 'info' && (
                              <Button 
                                size="sm" 
                                variant="ghost"
                                onClick={() => handleResolveAlert(log.id)}
                              >
                                <CheckCircle className="size-4" />
                              </Button>
                            )}
                          </div>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Dialogs */}
      {showAppealDialog && selectedAppeal && (
        <Dialog open={showAppealDialog} onOpenChange={setShowAppealDialog}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Review Ban Appeal</DialogTitle>
              <DialogDescription>
                Appeal from {selectedAppeal.player_name}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label>Player</Label>
                <p className="text-sm mt-1">{selectedAppeal.player_name} ({selectedAppeal.identifier})</p>
              </div>
              <div>
                <Label>Original Ban Reason</Label>
                <p className="text-sm mt-1">{selectedAppeal.ban_reason}</p>
              </div>
              <div>
                <Label>Appeal Reason</Label>
                <p className="text-sm mt-1">{selectedAppeal.appeal_reason}</p>
              </div>
              {selectedAppeal.evidence && (
                <div>
                  <Label>Evidence</Label>
                  <p className="text-sm mt-1">{selectedAppeal.evidence}</p>
                </div>
              )}
              <div>
                <Label>Review Notes</Label>
                <Textarea placeholder="Add your review notes..." className="mt-1" id="appeal-notes" />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setShowAppealDialog(false)}>
                Cancel
              </Button>
              <Button 
                variant="destructive"
                onClick={() => {
                  const notes = (document.getElementById('appeal-notes') as HTMLTextAreaElement)?.value || '';
                  handleProcessAppeal(selectedAppeal.id, 'deny', notes);
                }}
              >
                Deny Appeal
              </Button>
              <Button 
                onClick={() => {
                  const notes = (document.getElementById('appeal-notes') as HTMLTextAreaElement)?.value || '';
                  handleProcessAppeal(selectedAppeal.id, 'approve', notes);
                }}
              >
                Approve Appeal
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {showWarningDialog && (
        <Dialog open={showWarningDialog} onOpenChange={setShowWarningDialog}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Issue Global Warning</DialogTitle>
              <DialogDescription>
                This warning will be synced to all connected cities
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label>Player Identifier</Label>
                <Input
                  value={warningForm.identifier}
                  onChange={(e) => setWarningForm({ ...warningForm, identifier: e.target.value })}
                  placeholder="license:abc123..."
                />
              </div>
              <div>
                <Label>Player Name</Label>
                <Input
                  value={warningForm.playerName}
                  onChange={(e) => setWarningForm({ ...warningForm, playerName: e.target.value })}
                  placeholder="Player Name"
                />
              </div>
              <div>
                <Label>Severity</Label>
                <Select value={warningForm.severity} onValueChange={(value) => setWarningForm({ ...warningForm, severity: value })}>
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
                  value={warningForm.reason}
                  onChange={(e) => setWarningForm({ ...warningForm, reason: e.target.value })}
                  placeholder="Warning reason..."
                />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setShowWarningDialog(false)}>
                Cancel
              </Button>
              <Button onClick={handleIssueWarning}>
                Issue Warning
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {showWebhookDialog && (
        <Dialog open={showWebhookDialog} onOpenChange={setShowWebhookDialog}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>{selectedWebhook ? 'Edit' : 'Create'} Webhook</DialogTitle>
              <DialogDescription>
                Configure Discord webhook notifications
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label>Webhook Name</Label>
                <Input
                  value={webhookForm.webhookName}
                  onChange={(e) => setWebhookForm({ ...webhookForm, webhookName: e.target.value })}
                  placeholder="e.g., Critical Bans Logger"
                />
              </div>
              <div>
                <Label>Discord Webhook URL</Label>
                <Input
                  value={webhookForm.webhookUrl}
                  onChange={(e) => setWebhookForm({ ...webhookForm, webhookUrl: e.target.value })}
                  placeholder="https://discord.com/api/webhooks/..."
                />
              </div>
              <div>
                <Label>Event Type</Label>
                <Select value={webhookForm.eventType} onValueChange={(value) => setWebhookForm({ ...webhookForm, eventType: value })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="global_ban">Global Ban Applied</SelectItem>
                    <SelectItem value="global_unban">Global Ban Removed</SelectItem>
                    <SelectItem value="ban_appeal_submitted">Ban Appeal Submitted</SelectItem>
                    <SelectItem value="ban_appeal_processed">Ban Appeal Processed</SelectItem>
                    <SelectItem value="global_warning">Global Warning Issued</SelectItem>
                    <SelectItem value="warning_removed">Warning Removed</SelectItem>
                    <SelectItem value="city_connected">City Connected</SelectItem>
                    <SelectItem value="city_disconnected">City Disconnected</SelectItem>
                    <SelectItem value="api_online">API Online</SelectItem>
                    <SelectItem value="api_offline">API Offline</SelectItem>
                    <SelectItem value="api_error">API Error</SelectItem>
                    <SelectItem value="system_alert">System Alert</SelectItem>
                    <SelectItem value="security_alert">Security Alert</SelectItem>
                    <SelectItem value="all_events">All Events</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setShowWebhookDialog(false)}>
                Cancel
              </Button>
              <Button onClick={handleSaveWebhook}>
                {selectedWebhook ? 'Update' : 'Create'} Webhook
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
}
