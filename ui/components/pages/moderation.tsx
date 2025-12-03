import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Textarea } from '../ui/textarea';
import { ScrollArea } from '../ui/scroll-area';
import { 
  Shield, Users, Search, Plus, Trash2, Edit, RefreshCw, 
  AlertTriangle, Ban, Volume2, VolumeX, Clock, CheckCircle,
  X, FileText, Flag, Activity, TrendingUp, UserX, Eye,
  MessageSquare, Archive
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';

interface ModerationPageProps {
  liveData: any;
}

interface Warning {
  id: number;
  player_id: string;
  player_name: string;
  admin_id: string;
  admin_name: string;
  reason: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  points: number;
  active: number;
  created_at: string;
  expires_at: string | null;
}

interface Kick {
  id: number;
  player_id: string;
  player_name: string;
  admin_id: string;
  admin_name: string;
  reason: string;
  created_at: string;
}

interface Mute {
  id: number;
  player_id: string;
  player_name: string;
  admin_id: string;
  admin_name: string;
  reason: string;
  duration: number;
  active: number;
  created_at: string;
  expires_at: string | null;
}

interface Report {
  id: number;
  reporter_id: string;
  reporter_name: string;
  reported_id: string;
  reported_name: string;
  reason: string;
  category: string;
  status: 'pending' | 'investigating' | 'resolved' | 'dismissed';
  assigned_to: string | null;
  assigned_name: string | null;
  resolution: string | null;
  created_at: string;
  updated_at: string;
}

interface ActionLog {
  id: number;
  admin_id: string;
  admin_name: string;
  action_type: string;
  target_id: string | null;
  target_name: string | null;
  reason: string | null;
  details: string | null;
  created_at: string;
}

interface ModerationData {
  warnings: Warning[];
  kicks: Kick[];
  mutes: Mute[];
  reports: Report[];
  actionLogs: ActionLog[];
  stats: {
    totalWarnings: number;
    totalKicks: number;
    activeMutes: number;
    pendingReports: number;
    totalActions: number;
    warningsToday: number;
    kicksToday: number;
    reportsToday: number;
  };
  framework: string;
}

export function ModerationPage({ liveData }: ModerationPageProps) {
  const [activeTab, setActiveTab] = useState('warnings');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [data, setData] = useState<ModerationData | null>(null);

  // Modals
  const [warnModal, setWarnModal] = useState(false);
  const [kickModal, setKickModal] = useState(false);
  const [muteModal, setMuteModal] = useState(false);
  const [reportModal, setReportModal] = useState<{ isOpen: boolean; report?: Report }>({ isOpen: false });
  const [removeWarningModal, setRemoveWarningModal] = useState<{ isOpen: boolean; warning?: Warning }>({ isOpen: false });
  const [unmuteModal, setUnmuteModal] = useState<{ isOpen: boolean; mute?: Mute }>({ isOpen: false });

  const [formData, setFormData] = useState<any>({});

  // Fetch moderation data
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/moderation:getData', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        // Data will be received via NUI message
      }
    } catch (error) {
      console.log('[Moderation] Not in FiveM environment');
    }
  }, []);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      if (action === 'moderationData') {
        if (msgData.success) {
          setData(msgData.data);
        }
      } else if (action === 'moderationResponse') {
        if (msgData.success) {
          toastSuccess({ title: msgData.message });
          fetchData();
        } else {
          toastError({ title: msgData.message });
        }
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

    // Auto-refresh every 15 seconds
    const interval = setInterval(() => {
      fetchData();
    }, 15000);

    return () => clearInterval(interval);
  }, [fetchData]);

  // Manual refresh
  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
    toastSuccess({ title: 'Data refreshed' });
  };

  // Issue warning
  const handleIssueWarning = async () => {
    if (!formData.targetId || !formData.reason) {
      toastError({ title: 'Please fill all required fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/moderation:issueWarning', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          targetId: formData.targetId,
          reason: formData.reason,
          severity: formData.severity || 'medium',
          points: formData.points || 1,
          duration: formData.duration || 0
        })
      });

      setWarnModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to issue warning' });
    }
  };

  // Kick player
  const handleKickPlayer = async () => {
    if (!formData.targetId || !formData.reason) {
      toastError({ title: 'Please fill all required fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/moderation:kickPlayer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          targetId: formData.targetId,
          reason: formData.reason
        })
      });

      setKickModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to kick player' });
    }
  };

  // Mute player
  const handleMutePlayer = async () => {
    if (!formData.targetId || !formData.reason) {
      toastError({ title: 'Please fill all required fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/moderation:mutePlayer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          targetId: formData.targetId,
          reason: formData.reason,
          duration: formData.duration || 60
        })
      });

      setMuteModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to mute player' });
    }
  };

  // Remove warning
  const handleRemoveWarning = async () => {
    if (!removeWarningModal.warning) return;

    try {
      await fetch('https://ec_admin_ultimate/moderation:removeWarning', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          warningId: removeWarningModal.warning.id
        })
      });

      setRemoveWarningModal({ isOpen: false });
    } catch (error) {
      toastError({ title: 'Failed to remove warning' });
    }
  };

  // Unmute player
  const handleUnmute = async () => {
    if (!unmuteModal.mute) return;

    try {
      await fetch('https://ec_admin_ultimate/moderation:unmutePlayer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          muteId: unmuteModal.mute.id
        })
      });

      setUnmuteModal({ isOpen: false });
    } catch (error) {
      toastError({ title: 'Failed to unmute player' });
    }
  };

  // Update report status
  const handleUpdateReport = async (status: string) => {
    if (!reportModal.report) return;

    try {
      await fetch('https://ec_admin_ultimate/moderation:updateReportStatus', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          reportId: reportModal.report.id,
          status: status,
          resolution: formData.resolution || null
        })
      });

      setReportModal({ isOpen: false });
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to update report' });
    }
  };

  // Format date
  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleString();
  };

  // Get severity color
  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'low': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      case 'medium': return 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20';
      case 'high': return 'bg-orange-500/10 text-orange-500 border-orange-500/20';
      case 'critical': return 'bg-red-500/10 text-red-500 border-red-500/20';
      default: return 'bg-gray-500/10 text-gray-500 border-gray-500/20';
    }
  };

  // Get status color
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'destructive';
      case 'investigating': return 'default';
      case 'resolved': return 'secondary';
      case 'dismissed': return 'outline';
      default: return 'secondary';
    }
  };

  // Get data from state
  const warnings = data?.warnings || [];
  const kicks = data?.kicks || [];
  const mutes = data?.mutes || [];
  const reports = data?.reports || [];
  const actionLogs = data?.actionLogs || [];
  const stats = data?.stats || {
    totalWarnings: 0,
    totalKicks: 0,
    activeMutes: 0,
    pendingReports: 0,
    totalActions: 0,
    warningsToday: 0,
    kicksToday: 0,
    reportsToday: 0
  };

  // Filter data
  const filteredWarnings = warnings.filter(w =>
    w.player_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    w.admin_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    w.reason.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredKicks = kicks.filter(k =>
    k.player_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    k.admin_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    k.reason.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredMutes = mutes.filter(m =>
    m.player_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    m.admin_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    m.reason.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredReports = reports.filter(r =>
    r.reporter_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.reported_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.reason.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredLogs = actionLogs.filter(l =>
    l.admin_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (l.target_name && l.target_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
    l.action_type.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Shield className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading Moderation System...</p>
          <p className="text-sm text-muted-foreground">Fetching moderation data</p>
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
            <Shield className="size-8 text-primary" />
            Moderation Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage warnings, kicks, bans, mutes, and reports
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button 
            variant="outline" 
            size="sm" 
            onClick={() => setWarnModal(true)}
          >
            <AlertTriangle className="size-4 mr-2" />
            Warn
          </Button>
          <Button 
            variant="outline" 
            size="sm" 
            onClick={() => setKickModal(true)}
          >
            <UserX className="size-4 mr-2" />
            Kick
          </Button>
          <Button 
            variant="outline" 
            size="sm" 
            onClick={() => setMuteModal(true)}
          >
            <VolumeX className="size-4 mr-2" />
            Mute
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
              <div className="p-3 bg-yellow-500/10 rounded-lg mx-auto w-fit mb-2">
                <AlertTriangle className="size-6 text-yellow-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Warnings</p>
              <p className="text-xl font-bold">{stats.totalWarnings}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-orange-500/10 rounded-lg mx-auto w-fit mb-2">
                <UserX className="size-6 text-orange-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Kicks</p>
              <p className="text-xl font-bold">{stats.totalKicks}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-purple-500/10 rounded-lg mx-auto w-fit mb-2">
                <VolumeX className="size-6 text-purple-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Active Mutes</p>
              <p className="text-xl font-bold">{stats.activeMutes}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-red-500/10 rounded-lg mx-auto w-fit mb-2">
                <Flag className="size-6 text-red-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Pending Reports</p>
              <p className="text-xl font-bold">{stats.pendingReports}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-blue-500/10 rounded-lg mx-auto w-fit mb-2">
                <TrendingUp className="size-6 text-blue-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Warnings Today</p>
              <p className="text-xl font-bold">{stats.warningsToday}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-green-500/10 rounded-lg mx-auto w-fit mb-2">
                <TrendingUp className="size-6 text-green-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Kicks Today</p>
              <p className="text-xl font-bold">{stats.kicksToday}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-pink-500/10 rounded-lg mx-auto w-fit mb-2">
                <Flag className="size-6 text-pink-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Reports Today</p>
              <p className="text-xl font-bold">{stats.reportsToday}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-cyan-500/10 rounded-lg mx-auto w-fit mb-2">
                <Activity className="size-6 text-cyan-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Actions</p>
              <p className="text-xl font-bold">{stats.totalActions}</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="warnings" className="flex items-center gap-2">
            <AlertTriangle className="size-4" />
            Warnings ({filteredWarnings.length})
          </TabsTrigger>
          <TabsTrigger value="kicks" className="flex items-center gap-2">
            <UserX className="size-4" />
            Kicks ({filteredKicks.length})
          </TabsTrigger>
          <TabsTrigger value="mutes" className="flex items-center gap-2">
            <VolumeX className="size-4" />
            Mutes ({filteredMutes.length})
          </TabsTrigger>
          <TabsTrigger value="reports" className="flex items-center gap-2">
            <Flag className="size-4" />
            Reports ({filteredReports.length})
          </TabsTrigger>
          <TabsTrigger value="logs" className="flex items-center gap-2">
            <FileText className="size-4" />
            Logs ({filteredLogs.length})
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

        {/* Warnings Tab */}
        <TabsContent value="warnings" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Active Warnings</CardTitle>
              <CardDescription>All active player warnings</CardDescription>
            </CardHeader>
            <CardContent>
              {filteredWarnings.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <AlertTriangle className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No warnings found</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-3">
                    {filteredWarnings.map((warning) => (
                      <Card key={warning.id}>
                        <CardContent className="p-4">
                          <div className="flex items-start justify-between">
                            <div className="space-y-2 flex-1">
                              <div className="flex items-center gap-2">
                                <p className="font-medium">{warning.player_name}</p>
                                <Badge className={getSeverityColor(warning.severity)}>
                                  {warning.severity}
                                </Badge>
                                <Badge variant="outline">{warning.points} points</Badge>
                              </div>
                              <p className="text-sm text-muted-foreground">{warning.reason}</p>
                              <div className="flex items-center gap-4 text-xs text-muted-foreground">
                                <span>By: {warning.admin_name}</span>
                                <span>•</span>
                                <span>{formatDate(warning.created_at)}</span>
                                {warning.expires_at && (
                                  <>
                                    <span>•</span>
                                    <span>Expires: {formatDate(warning.expires_at)}</span>
                                  </>
                                )}
                              </div>
                            </div>
                            <Button 
                              variant="ghost" 
                              size="sm"
                              onClick={() => setRemoveWarningModal({ isOpen: true, warning })}
                            >
                              <Trash2 className="size-4" />
                            </Button>
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

        {/* Kicks Tab */}
        <TabsContent value="kicks" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Kick History</CardTitle>
              <CardDescription>All player kicks</CardDescription>
            </CardHeader>
            <CardContent>
              {filteredKicks.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <UserX className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No kicks found</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-3">
                    {filteredKicks.map((kick) => (
                      <Card key={kick.id}>
                        <CardContent className="p-4">
                          <div className="space-y-2">
                            <p className="font-medium">{kick.player_name}</p>
                            <p className="text-sm text-muted-foreground">{kick.reason}</p>
                            <div className="flex items-center gap-4 text-xs text-muted-foreground">
                              <span>By: {kick.admin_name}</span>
                              <span>•</span>
                              <span>{formatDate(kick.created_at)}</span>
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

        {/* Mutes Tab */}
        <TabsContent value="mutes" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Active Mutes</CardTitle>
              <CardDescription>All active player mutes</CardDescription>
            </CardHeader>
            <CardContent>
              {filteredMutes.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <VolumeX className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No mutes found</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-3">
                    {filteredMutes.map((mute) => (
                      <Card key={mute.id}>
                        <CardContent className="p-4">
                          <div className="flex items-start justify-between">
                            <div className="space-y-2 flex-1">
                              <div className="flex items-center gap-2">
                                <p className="font-medium">{mute.player_name}</p>
                                <Badge variant="outline">{mute.duration} min</Badge>
                              </div>
                              <p className="text-sm text-muted-foreground">{mute.reason}</p>
                              <div className="flex items-center gap-4 text-xs text-muted-foreground">
                                <span>By: {mute.admin_name}</span>
                                <span>•</span>
                                <span>{formatDate(mute.created_at)}</span>
                                {mute.expires_at && (
                                  <>
                                    <span>•</span>
                                    <span>Expires: {formatDate(mute.expires_at)}</span>
                                  </>
                                )}
                              </div>
                            </div>
                            <Button 
                              variant="ghost" 
                              size="sm"
                              onClick={() => setUnmuteModal({ isOpen: true, mute })}
                            >
                              <Volume2 className="size-4" />
                            </Button>
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

        {/* Reports Tab */}
        <TabsContent value="reports" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Player Reports</CardTitle>
              <CardDescription>Manage player reports</CardDescription>
            </CardHeader>
            <CardContent>
              {filteredReports.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <Flag className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No reports found</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-3">
                    {filteredReports.map((report) => (
                      <Card key={report.id} className="cursor-pointer hover:shadow-lg transition-shadow"
                        onClick={() => setReportModal({ isOpen: true, report })}>
                        <CardContent className="p-4">
                          <div className="flex items-start justify-between">
                            <div className="space-y-2 flex-1">
                              <div className="flex items-center gap-2">
                                <p className="font-medium">{report.reported_name}</p>
                                <Badge variant={getStatusColor(report.status) as any}>
                                  {report.status}
                                </Badge>
                                <Badge variant="outline">{report.category}</Badge>
                              </div>
                              <p className="text-sm text-muted-foreground">{report.reason}</p>
                              <div className="flex items-center gap-4 text-xs text-muted-foreground">
                                <span>Reporter: {report.reporter_name}</span>
                                <span>•</span>
                                <span>{formatDate(report.created_at)}</span>
                                {report.assigned_name && (
                                  <>
                                    <span>•</span>
                                    <span>Assigned: {report.assigned_name}</span>
                                  </>
                                )}
                              </div>
                            </div>
                            <Eye className="size-4 text-muted-foreground" />
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

        {/* Logs Tab */}
        <TabsContent value="logs" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Action Logs</CardTitle>
              <CardDescription>All moderation actions</CardDescription>
            </CardHeader>
            <CardContent>
              {filteredLogs.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <FileText className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No logs found</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-3">
                    {filteredLogs.map((log) => (
                      <Card key={log.id}>
                        <CardContent className="p-4">
                          <div className="space-y-2">
                            <div className="flex items-center gap-2">
                              <Badge>{log.action_type}</Badge>
                              <p className="font-medium text-sm">{log.admin_name}</p>
                            </div>
                            {log.target_name && (
                              <p className="text-sm text-muted-foreground">Target: {log.target_name}</p>
                            )}
                            {log.reason && (
                              <p className="text-sm text-muted-foreground">Reason: {log.reason}</p>
                            )}
                            <p className="text-xs text-muted-foreground">{formatDate(log.created_at)}</p>
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
      </Tabs>

      {/* Warn Modal */}
      <Dialog open={warnModal} onOpenChange={setWarnModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Issue Warning</DialogTitle>
            <DialogDescription>
              Issue a warning to a player
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="targetId">Player ID</Label>
              <Input
                id="targetId"
                type="number"
                placeholder="Enter player server ID"
                value={formData.targetId || ''}
                onChange={(e) => setFormData({ ...formData, targetId: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="severity">Severity</Label>
              <Select
                value={formData.severity || 'medium'}
                onValueChange={(value) => setFormData({ ...formData, severity: value })}
              >
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

            <div className="space-y-2">
              <Label htmlFor="points">Warning Points</Label>
              <Input
                id="points"
                type="number"
                min="1"
                placeholder="1"
                value={formData.points || ''}
                onChange={(e) => setFormData({ ...formData, points: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="duration">Duration (days, 0 = permanent)</Label>
              <Input
                id="duration"
                type="number"
                min="0"
                placeholder="0"
                value={formData.duration || ''}
                onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="reason">Reason</Label>
              <Textarea
                id="reason"
                placeholder="Enter warning reason"
                value={formData.reason || ''}
                onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setWarnModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleIssueWarning}>
              Issue Warning
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Kick Modal */}
      <Dialog open={kickModal} onOpenChange={setKickModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Kick Player</DialogTitle>
            <DialogDescription>
              Kick a player from the server
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="kickTargetId">Player ID</Label>
              <Input
                id="kickTargetId"
                type="number"
                placeholder="Enter player server ID"
                value={formData.targetId || ''}
                onChange={(e) => setFormData({ ...formData, targetId: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="kickReason">Reason</Label>
              <Textarea
                id="kickReason"
                placeholder="Enter kick reason"
                value={formData.reason || ''}
                onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setKickModal(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleKickPlayer}>
              Kick Player
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Mute Modal */}
      <Dialog open={muteModal} onOpenChange={setMuteModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Mute Player</DialogTitle>
            <DialogDescription>
              Mute a player from chat
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="muteTargetId">Player ID</Label>
              <Input
                id="muteTargetId"
                type="number"
                placeholder="Enter player server ID"
                value={formData.targetId || ''}
                onChange={(e) => setFormData({ ...formData, targetId: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="muteDuration">Duration (minutes)</Label>
              <Input
                id="muteDuration"
                type="number"
                min="1"
                placeholder="60"
                value={formData.duration || ''}
                onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="muteReason">Reason</Label>
              <Textarea
                id="muteReason"
                placeholder="Enter mute reason"
                value={formData.reason || ''}
                onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setMuteModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleMutePlayer}>
              Mute Player
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Report Details Modal */}
      <Dialog open={reportModal.isOpen} onOpenChange={(open) => !open && setReportModal({ isOpen: false })}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Report Details</DialogTitle>
            <DialogDescription>
              View and manage report
            </DialogDescription>
          </DialogHeader>

          {reportModal.report && (
            <div className="space-y-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Reporter</Label>
                  <p className="font-medium">{reportModal.report.reporter_name}</p>
                </div>
                <div>
                  <Label>Reported Player</Label>
                  <p className="font-medium">{reportModal.report.reported_name}</p>
                </div>
                <div>
                  <Label>Category</Label>
                  <Badge variant="outline">{reportModal.report.category}</Badge>
                </div>
                <div>
                  <Label>Status</Label>
                  <Badge variant={getStatusColor(reportModal.report.status) as any}>
                    {reportModal.report.status}
                  </Badge>
                </div>
                <div className="col-span-2">
                  <Label>Reason</Label>
                  <p className="font-medium">{reportModal.report.reason}</p>
                </div>
                <div>
                  <Label>Created</Label>
                  <p className="text-sm">{formatDate(reportModal.report.created_at)}</p>
                </div>
                {reportModal.report.assigned_name && (
                  <div>
                    <Label>Assigned To</Label>
                    <p className="text-sm">{reportModal.report.assigned_name}</p>
                  </div>
                )}
              </div>

              {reportModal.report.status !== 'resolved' && reportModal.report.status !== 'dismissed' && (
                <div className="space-y-2">
                  <Label htmlFor="resolution">Resolution Notes</Label>
                  <Textarea
                    id="resolution"
                    placeholder="Enter resolution notes..."
                    value={formData.resolution || ''}
                    onChange={(e) => setFormData({ ...formData, resolution: e.target.value })}
                  />
                </div>
              )}
            </div>
          )}

          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setReportModal({ isOpen: false })}>
              Close
            </Button>
            {reportModal.report?.status === 'pending' && (
              <Button onClick={() => handleUpdateReport('investigating')}>
                Investigate
              </Button>
            )}
            {reportModal.report?.status !== 'resolved' && (
              <Button variant="secondary" onClick={() => handleUpdateReport('resolved')}>
                Resolve
              </Button>
            )}
            {reportModal.report?.status !== 'dismissed' && (
              <Button variant="destructive" onClick={() => handleUpdateReport('dismissed')}>
                Dismiss
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Remove Warning Modal */}
      <Dialog open={removeWarningModal.isOpen} onOpenChange={(open) => !open && setRemoveWarningModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Remove Warning</DialogTitle>
            <DialogDescription>
              Are you sure you want to remove this warning?
            </DialogDescription>
          </DialogHeader>

          {removeWarningModal.warning && (
            <div className="py-4">
              <div className="flex items-center gap-3 p-4 bg-destructive/10 border border-destructive/20 rounded-lg">
                <AlertTriangle className="size-5 text-destructive" />
                <div>
                  <p className="font-medium">{removeWarningModal.warning.player_name}</p>
                  <p className="text-sm text-muted-foreground">{removeWarningModal.warning.reason}</p>
                </div>
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setRemoveWarningModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleRemoveWarning}>
              Remove
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Unmute Modal */}
      <Dialog open={unmuteModal.isOpen} onOpenChange={(open) => !open && setUnmuteModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Unmute Player</DialogTitle>
            <DialogDescription>
              Remove this mute?
            </DialogDescription>
          </DialogHeader>

          {unmuteModal.mute && (
            <div className="py-4">
              <p className="font-medium">{unmuteModal.mute.player_name}</p>
              <p className="text-sm text-muted-foreground">{unmuteModal.mute.reason}</p>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setUnmuteModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button onClick={handleUnmute}>
              Unmute
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
