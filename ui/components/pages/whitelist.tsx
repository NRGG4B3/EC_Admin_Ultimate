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
import { Switch } from '../ui/switch';
import { 
  Shield, Plus, Trash2, RefreshCw, Search, Edit, CheckCircle, 
  XCircle, Clock, User, Mail, Hash, Crown, Star, AlertCircle,
  FileText, UserCheck, UserX, Award, Settings
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';

interface WhitelistPageProps {
  liveData: any;
}

interface WhitelistEntry {
  id: number;
  identifier: string;
  name: string;
  steam_id: string | null;
  license: string | null;
  discord_id: string | null;
  ip_address: string | null;
  roles: string[];
  status: 'active' | 'inactive' | 'banned';
  added_by: string;
  added_at: string;
  priority: string;
  notes: string | null;
  expires_at: string | null;
}

interface Application {
  id: number;
  identifier: string;
  applicant_name: string;
  steam_id: string | null;
  license: string | null;
  discord_id: string | null;
  age: number | null;
  discord_tag: string | null;
  reason: string | null;
  experience: string | null;
  referral: string | null;
  status: 'pending' | 'approved' | 'denied';
  submitted_at: string;
  reviewed_by: string | null;
  reviewed_at: string | null;
  deny_reason: string | null;
}

interface Role {
  id: number;
  name: string;
  display_name: string;
  priority: number;
  color: string;
  permissions: string[];
  is_default: number;
  created_at: string;
}

interface WhitelistData {
  whitelist: WhitelistEntry[];
  applications: Application[];
  roles: Role[];
  stats: {
    totalWhitelisted: number;
    activeWhitelisted: number;
    inactiveWhitelisted: number;
    totalApplications: number;
    pendingApplications: number;
    approvedApplications: number;
    deniedApplications: number;
    totalRoles: number;
  };
  framework: string;
}

export function WhitelistPage({ liveData }: WhitelistPageProps) {
  const [activeTab, setActiveTab] = useState('whitelist');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [data, setData] = useState<WhitelistData | null>(null);

  // Modals
  const [addModal, setAddModal] = useState(false);
  const [editModal, setEditModal] = useState<{ isOpen: boolean; entry?: WhitelistEntry }>({ isOpen: false });
  const [deleteModal, setDeleteModal] = useState<{ isOpen: boolean; id?: number; name?: string }>({ isOpen: false });
  const [applicationModal, setApplicationModal] = useState<{ isOpen: boolean; application?: Application }>({ isOpen: false });
  const [roleModal, setRoleModal] = useState(false);
  const [editRoleModal, setEditRoleModal] = useState<{ isOpen: boolean; role?: Role }>({ isOpen: false });

  const [formData, setFormData] = useState<any>({});

  // Fetch whitelist data
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/whitelist:getData', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        // Data will be received via NUI message
      }
    } catch (error) {
      console.log('[Whitelist] Not in FiveM environment');
    }
  }, []);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      if (action === 'whitelistData') {
        if (msgData.success) {
          setData(msgData.data);
        }
      } else if (action === 'whitelistResponse') {
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

  // Add whitelist entry
  const handleAdd = async () => {
    if (!formData.identifier || !formData.name) {
      toastError({ title: 'Please fill all required fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/whitelist:add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          identifier: formData.identifier,
          name: formData.name,
          steamId: formData.steamId || null,
          license: formData.license || null,
          discordId: formData.discordId || null,
          ipAddress: formData.ipAddress || null,
          roles: formData.roles || ['whitelist'],
          status: formData.status || 'active',
          priority: formData.priority || 'normal',
          notes: formData.notes || null,
          expiresAt: formData.expiresAt || null
        })
      });

      setAddModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to add whitelist entry' });
    }
  };

  // Update whitelist entry
  const handleUpdate = async () => {
    if (!editModal.entry) return;

    try {
      await fetch('https://ec_admin_ultimate/whitelist:update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: editModal.entry.id,
          name: formData.name || editModal.entry.name,
          steamId: formData.steamId !== undefined ? formData.steamId : editModal.entry.steam_id,
          license: formData.license !== undefined ? formData.license : editModal.entry.license,
          discordId: formData.discordId !== undefined ? formData.discordId : editModal.entry.discord_id,
          roles: formData.roles || editModal.entry.roles,
          status: formData.status || editModal.entry.status,
          priority: formData.priority || editModal.entry.priority,
          notes: formData.notes !== undefined ? formData.notes : editModal.entry.notes,
          expiresAt: formData.expiresAt !== undefined ? formData.expiresAt : editModal.entry.expires_at
        })
      });

      setEditModal({ isOpen: false });
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to update whitelist entry' });
    }
  };

  // Remove whitelist entry
  const handleDelete = async () => {
    if (!deleteModal.id) return;

    try {
      await fetch('https://ec_admin_ultimate/whitelist:remove', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: deleteModal.id })
      });

      setDeleteModal({ isOpen: false });
    } catch (error) {
      toastError({ title: 'Failed to remove whitelist entry' });
    }
  };

  // Approve application
  const handleApprove = async () => {
    if (!applicationModal.application) return;

    try {
      await fetch('https://ec_admin_ultimate/whitelist:approveApplication', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: applicationModal.application.id,
          roles: formData.approveRoles || ['whitelist']
        })
      });

      setApplicationModal({ isOpen: false });
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to approve application' });
    }
  };

  // Deny application
  const handleDeny = async () => {
    if (!applicationModal.application) return;

    try {
      await fetch('https://ec_admin_ultimate/whitelist:denyApplication', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: applicationModal.application.id,
          reason: formData.denyReason || 'No reason provided'
        })
      });

      setApplicationModal({ isOpen: false });
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to deny application' });
    }
  };

  // Create role
  const handleCreateRole = async () => {
    if (!formData.roleName || !formData.roleDisplayName) {
      toastError({ title: 'Please fill all required fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/whitelist:createRole', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.roleName,
          displayName: formData.roleDisplayName,
          priority: formData.rolePriority || 50,
          color: formData.roleColor || '#3b82f6',
          permissions: formData.rolePermissions || []
        })
      });

      setRoleModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to create role' });
    }
  };

  // Format date
  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleString();
  };

  // Get status color
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'default';
      case 'inactive': return 'secondary';
      case 'banned': return 'destructive';
      case 'pending': return 'outline';
      case 'approved': return 'default';
      case 'denied': return 'destructive';
      default: return 'outline';
    }
  };

  // Get data from state
  const whitelist = data?.whitelist || [];
  const applications = data?.applications || [];
  const roles = data?.roles || [];
  const stats = data?.stats || {
    totalWhitelisted: 0,
    activeWhitelisted: 0,
    inactiveWhitelisted: 0,
    totalApplications: 0,
    pendingApplications: 0,
    approvedApplications: 0,
    deniedApplications: 0,
    totalRoles: 0
  };

  // Filter data
  const filteredWhitelist = whitelist.filter(w =>
    w.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    w.identifier.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (w.steam_id && w.steam_id.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (w.license && w.license.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const filteredApplications = applications.filter(a =>
    a.applicant_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    a.identifier.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (a.discord_tag && a.discord_tag.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Shield className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading Whitelist...</p>
          <p className="text-sm text-muted-foreground">Fetching whitelist data</p>
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
            Whitelist Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage whitelisted players, applications, and roles
          </p>
        </div>
        <div className="flex items-center gap-3">
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
                <Shield className="size-6 text-blue-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Total Whitelisted</p>
              <p className="text-xl font-bold">{stats.totalWhitelisted}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-green-500/10 rounded-lg mx-auto w-fit mb-2">
                <CheckCircle className="size-6 text-green-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Active</p>
              <p className="text-xl font-bold">{stats.activeWhitelisted}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-gray-500/10 rounded-lg mx-auto w-fit mb-2">
                <XCircle className="size-6 text-gray-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Inactive</p>
              <p className="text-xl font-bold">{stats.inactiveWhitelisted}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-purple-500/10 rounded-lg mx-auto w-fit mb-2">
                <FileText className="size-6 text-purple-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Applications</p>
              <p className="text-xl font-bold">{stats.totalApplications}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-yellow-500/10 rounded-lg mx-auto w-fit mb-2">
                <Clock className="size-6 text-yellow-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Pending</p>
              <p className="text-xl font-bold">{stats.pendingApplications}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-green-500/10 rounded-lg mx-auto w-fit mb-2">
                <UserCheck className="size-6 text-green-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Approved</p>
              <p className="text-xl font-bold">{stats.approvedApplications}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-red-500/10 rounded-lg mx-auto w-fit mb-2">
                <UserX className="size-6 text-red-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Denied</p>
              <p className="text-xl font-bold">{stats.deniedApplications}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="text-center">
              <div className="p-3 bg-indigo-500/10 rounded-lg mx-auto w-fit mb-2">
                <Crown className="size-6 text-indigo-500" />
              </div>
              <p className="text-sm text-muted-foreground mb-1">Roles</p>
              <p className="text-xl font-bold">{stats.totalRoles}</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="whitelist" className="flex items-center gap-2">
            <Shield className="size-4" />
            Whitelist ({filteredWhitelist.length})
          </TabsTrigger>
          <TabsTrigger value="applications" className="flex items-center gap-2">
            <FileText className="size-4" />
            Applications ({filteredApplications.length})
          </TabsTrigger>
          <TabsTrigger value="roles" className="flex items-center gap-2">
            <Crown className="size-4" />
            Roles ({roles.length})
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

        {/* Whitelist Tab */}
        <TabsContent value="whitelist" className="space-y-4 mt-6">
          <div className="flex justify-end mb-4">
            <Button onClick={() => setAddModal(true)}>
              <Plus className="size-4 mr-2" />
              Add Whitelist Entry
            </Button>
          </div>

          <ScrollArea className="h-[600px]">
            <div className="space-y-3">
              {filteredWhitelist.map((entry) => (
                <Card key={entry.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="space-y-2 flex-1">
                        <div className="flex items-center gap-2">
                          <h3 className="font-bold">{entry.name}</h3>
                          <Badge variant={getStatusColor(entry.status) as any}>
                            {entry.status}
                          </Badge>
                          {entry.roles && entry.roles.map((role: string) => (
                            <Badge key={role} variant="outline">
                              {role}
                            </Badge>
                          ))}
                        </div>
                        <div className="grid grid-cols-2 gap-2 text-sm">
                          <div className="flex items-center gap-1">
                            <Hash className="size-4" />
                            <span className="text-muted-foreground truncate">{entry.identifier}</span>
                          </div>
                          {entry.steam_id && (
                            <div className="flex items-center gap-1">
                              <User className="size-4" />
                              <span className="text-muted-foreground truncate">{entry.steam_id}</span>
                            </div>
                          )}
                        </div>
                        <div className="flex items-center gap-4 text-xs text-muted-foreground">
                          <span>Added by: {entry.added_by}</span>
                          <span>•</span>
                          <span>{formatDate(entry.added_at)}</span>
                        </div>
                        {entry.notes && (
                          <p className="text-sm text-muted-foreground">{entry.notes}</p>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => {
                            setEditModal({ isOpen: true, entry });
                            setFormData({});
                          }}
                        >
                          <Edit className="size-4" />
                        </Button>
                        <Button 
                          variant="ghost" 
                          size="sm"
                          onClick={() => setDeleteModal({ isOpen: true, id: entry.id, name: entry.name })}
                        >
                          <Trash2 className="size-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </ScrollArea>
        </TabsContent>

        {/* Applications Tab */}
        <TabsContent value="applications" className="space-y-4 mt-6">
          <ScrollArea className="h-[600px]">
            <div className="space-y-3">
              {filteredApplications.map((app) => (
                <Card key={app.id}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="space-y-2 flex-1">
                        <div className="flex items-center gap-2">
                          <h3 className="font-bold">{app.applicant_name}</h3>
                          <Badge variant={getStatusColor(app.status) as any}>
                            {app.status}
                          </Badge>
                        </div>
                        <div className="grid grid-cols-2 gap-2 text-sm">
                          {app.age && (
                            <div>
                              <span className="text-muted-foreground">Age: {app.age}</span>
                            </div>
                          )}
                          {app.discord_tag && (
                            <div>
                              <span className="text-muted-foreground">Discord: {app.discord_tag}</span>
                            </div>
                          )}
                        </div>
                        {app.reason && (
                          <div>
                            <p className="text-sm font-medium">Reason:</p>
                            <p className="text-sm text-muted-foreground">{app.reason}</p>
                          </div>
                        )}
                        {app.experience && (
                          <div>
                            <p className="text-sm font-medium">Experience:</p>
                            <p className="text-sm text-muted-foreground">{app.experience}</p>
                          </div>
                        )}
                        <div className="flex items-center gap-4 text-xs text-muted-foreground">
                          <span>Submitted: {formatDate(app.submitted_at)}</span>
                          {app.reviewed_by && (
                            <>
                              <span>•</span>
                              <span>Reviewed by: {app.reviewed_by}</span>
                            </>
                          )}
                        </div>
                        {app.deny_reason && (
                          <div className="flex items-start gap-2 p-2 bg-destructive/10 rounded">
                            <AlertCircle className="size-4 text-destructive mt-0.5" />
                            <span className="text-sm">{app.deny_reason}</span>
                          </div>
                        )}
                      </div>
                      {app.status === 'pending' && (
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => setApplicationModal({ isOpen: true, application: app })}
                        >
                          Review
                        </Button>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </ScrollArea>
        </TabsContent>

        {/* Roles Tab */}
        <TabsContent value="roles" className="space-y-4 mt-6">
          <div className="flex justify-end mb-4">
            <Button onClick={() => setRoleModal(true)}>
              <Plus className="size-4 mr-2" />
              Create Role
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {roles.map((role) => (
              <Card key={role.id}>
                <CardContent className="p-6">
                  <div className="space-y-3">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-2">
                        <div 
                          className="size-3 rounded-full" 
                          style={{ backgroundColor: role.color }}
                        />
                        <h3 className="font-bold">{role.display_name}</h3>
                      </div>
                      {role.is_default === 0 && (
                        <Button 
                          variant="ghost" 
                          size="sm"
                          onClick={() => setEditRoleModal({ isOpen: true, role })}
                        >
                          <Edit className="size-4" />
                        </Button>
                      )}
                    </div>
                    <div className="flex items-center justify-between">
                      <Badge>Priority: {role.priority}</Badge>
                      {role.is_default === 1 && (
                        <Badge variant="outline">Default</Badge>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>
      </Tabs>

      {/* Add Whitelist Modal */}
      <Dialog open={addModal} onOpenChange={setAddModal}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Add Whitelist Entry</DialogTitle>
            <DialogDescription>Add a new player to the whitelist</DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="identifier">Identifier *</Label>
                <Input
                  id="identifier"
                  placeholder="steam:110000... or license:..."
                  value={formData.identifier || ''}
                  onChange={(e) => setFormData({ ...formData, identifier: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="name">Name *</Label>
                <Input
                  id="name"
                  placeholder="Player name"
                  value={formData.name || ''}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="steamId">Steam ID</Label>
                <Input
                  id="steamId"
                  placeholder="steam:110000..."
                  value={formData.steamId || ''}
                  onChange={(e) => setFormData({ ...formData, steamId: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="license">License</Label>
                <Input
                  id="license"
                  placeholder="license:..."
                  value={formData.license || ''}
                  onChange={(e) => setFormData({ ...formData, license: e.target.value })}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="discordId">Discord ID</Label>
                <Input
                  id="discordId"
                  placeholder="discord:..."
                  value={formData.discordId || ''}
                  onChange={(e) => setFormData({ ...formData, discordId: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="priority">Priority</Label>
                <Select
                  value={formData.priority || 'normal'}
                  onValueChange={(value) => setFormData({ ...formData, priority: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="low">Low</SelectItem>
                    <SelectItem value="normal">Normal</SelectItem>
                    <SelectItem value="high">High</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="notes">Notes</Label>
              <Textarea
                id="notes"
                placeholder="Additional notes..."
                value={formData.notes || ''}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setAddModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleAdd}>
              Add to Whitelist
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Whitelist Modal */}
      <Dialog open={editModal.isOpen} onOpenChange={(open) => !open && setEditModal({ isOpen: false })}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Edit Whitelist Entry</DialogTitle>
            <DialogDescription>Update player whitelist information</DialogDescription>
          </DialogHeader>

          {editModal.entry && (
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="editName">Name</Label>
                <Input
                  id="editName"
                  placeholder="Player name"
                  defaultValue={editModal.entry.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="editStatus">Status</Label>
                <Select
                  defaultValue={editModal.entry.status}
                  onValueChange={(value) => setFormData({ ...formData, status: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="inactive">Inactive</SelectItem>
                    <SelectItem value="banned">Banned</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="editNotes">Notes</Label>
                <Textarea
                  id="editNotes"
                  placeholder="Additional notes..."
                  defaultValue={editModal.entry.notes || ''}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                />
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button onClick={handleUpdate}>
              Update
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Modal */}
      <Dialog open={deleteModal.isOpen} onOpenChange={(open) => !open && setDeleteModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Delete</DialogTitle>
            <DialogDescription>
              Are you sure you want to remove "{deleteModal.name}" from the whitelist?
            </DialogDescription>
          </DialogHeader>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete}>
              Remove
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Application Review Modal */}
      <Dialog open={applicationModal.isOpen} onOpenChange={(open) => !open && setApplicationModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Review Application</DialogTitle>
            <DialogDescription>
              Approve or deny whitelist application
            </DialogDescription>
          </DialogHeader>

          {applicationModal.application && (
            <div className="space-y-4 py-4">
              <div>
                <p className="font-bold">{applicationModal.application.applicant_name}</p>
                <p className="text-sm text-muted-foreground">{applicationModal.application.identifier}</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="denyReason">Deny Reason (optional)</Label>
                <Textarea
                  id="denyReason"
                  placeholder="Reason for denial..."
                  value={formData.denyReason || ''}
                  onChange={(e) => setFormData({ ...formData, denyReason: e.target.value })}
                />
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setApplicationModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDeny}>
              <UserX className="size-4 mr-2" />
              Deny
            </Button>
            <Button onClick={handleApprove}>
              <UserCheck className="size-4 mr-2" />
              Approve
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Create Role Modal */}
      <Dialog open={roleModal} onOpenChange={setRoleModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Role</DialogTitle>
            <DialogDescription>Create a new whitelist role</DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="roleName">Role Name (ID)</Label>
              <Input
                id="roleName"
                placeholder="vip_gold"
                value={formData.roleName || ''}
                onChange={(e) => setFormData({ ...formData, roleName: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="roleDisplayName">Display Name</Label>
              <Input
                id="roleDisplayName"
                placeholder="VIP Gold"
                value={formData.roleDisplayName || ''}
                onChange={(e) => setFormData({ ...formData, roleDisplayName: e.target.value })}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="rolePriority">Priority</Label>
                <Input
                  id="rolePriority"
                  type="number"
                  placeholder="50"
                  value={formData.rolePriority || ''}
                  onChange={(e) => setFormData({ ...formData, rolePriority: e.target.value })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="roleColor">Color</Label>
                <Input
                  id="roleColor"
                  type="color"
                  value={formData.roleColor || '#3b82f6'}
                  onChange={(e) => setFormData({ ...formData, roleColor: e.target.value })}
                />
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setRoleModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateRole}>
              Create Role
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
