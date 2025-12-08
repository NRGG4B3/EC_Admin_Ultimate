import { fetchAdminProfileFull } from '../../../api/adminProfile';
import { toastSuccess, toastError } from '../../lib/toast';
import { QuickActionsWidget } from '../quick-actions-widget';
import { formatRelativeTime, formatDateTime } from '../../lib/time';
import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Avatar, AvatarFallback } from '../ui/avatar';
import { ScrollArea } from '../ui/scroll-area';
import { Switch } from '../ui/switch';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Progress } from '../ui/progress';
import {

  User, Shield, Settings, Key, Activity, Clock, AlertTriangle, CheckCircle,
  RefreshCw, Download, Trash2, LogOut, TrendingUp, Award, Target, Ban,
  Calendar, MapPin, Edit2, Save, X, Bell
} from 'lucide-react';

// Move all interface/type definitions below imports

declare global {
  interface Window {
    fetchNui: (eventName: string, data?: any) => Promise<any>;
  }
}

interface AdminProfilePageProps {
  liveData: any;
  adminId?: string; // Optional: can view other admin profiles
  onOpenQuickActionsCenter?: () => void;
}

interface AdminProfile {
  admin_id: string;
  name: string;
  email: string;
  phone: string;
  location: string;
  role: string;
  joined_date: number;
  last_login: number;
  total_actions: number;
  players_managed: number;
  bans_issued: number;
  warnings_issued: number;
  resources_managed: number;
  uptime: number;
  trust_score: number;
  status: string;
}

interface AdminStats {
  totalActions: number;
  playersManaged: number;
  bansIssued: number;
  warningsIssued: number;
  resourcesManaged: number;
  uptime: number;
  trustScore: number;
  status: string;
}

interface AdminActivity {
  id: number;
  admin_id: string;
  action: string;
  category: string;
  target_name?: string;
  timestamp: number;
  details: string;
}

interface AdminPermission {
  name: string;
  granted: boolean;
  category: string;
}

interface AdminSession {
  id: number;
  admin_id: string;
  admin_name: string;
  login_time: number;
  logout_time?: number;
  ip_address: string;
  status: string;
}
// ...existing code...

interface AdminProfilePageProps {
  liveData: any;
  adminId?: string; // Optional: can view other admin profiles
  onOpenQuickActionsCenter?: () => void;
}

export function AdminProfilePage({ liveData, adminId, onOpenQuickActionsCenter }: AdminProfilePageProps) {
  // ...existing code...

interface AdminProfile {
  admin_id: string;
  name: string;
  email: string;
  phone: string;
  location: string;
  role: string;
  joined_date: number;
  last_login: number;
  total_actions: number;
  players_managed: number;
  bans_issued: number;
  warnings_issued: number;
  resources_managed: number;
  uptime: number;
  trust_score: number;
  status: string;
}

interface AdminStats {
  totalActions: number;
  playersManaged: number;
  bansIssued: number;
  warningsIssued: number;
  resourcesManaged: number;
  uptime: number;
  trustScore: number;
  status: string;
}

interface AdminActivity {
  id: number;
  admin_id: string;
  action: string;
  category: string;
  target_name?: string;
  timestamp: number;
  details: string;
}

interface AdminPermission {
  name: string;
  granted: boolean;
  category: string;
}

interface AdminSession {
  id: number;
  admin_id: string;
  admin_name: string;
  login_time: number;
  logout_time?: number;
  ip_address: string;
  status: string;
}




  const [activeTab, setActiveTab] = useState('profile');
  const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [profile, setProfile] = useState(null);
  const [permissions, setPermissions] = useState([]);
  const [roles, setRoles] = useState([]);
  const [activity, setActivity] = useState([]);
  const [actions, setActions] = useState([]);
  const [infractions, setInfractions] = useState([]);
  const [warnings, setWarnings] = useState([]);
  const [bans, setBans] = useState([]);
  const [editForm, setEditForm] = useState<Partial<AdminProfile>>({});
  const [passwordModal, setPasswordModal] = useState(false);
  const [notificationModal, setNotificationModal] = useState(false);
  const [passwordForm, setPasswordForm] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [notificationSettings, setNotificationSettings] = useState({
    emailNotifications: true,
    discordNotifications: true,
    playerReports: true,
    banAlerts: true,
    securityAlerts: true,
    systemAlerts: true
  });

  // Fetch all live data in one call
  const fetchAllData = async () => {
    if (!adminId) return;
    setIsLoading(true);
    try {
      const data = await fetchAdminProfileFull(adminId);
      setProfile(data.profile);
      setPermissions(data.permissions);
      setRoles(data.roles);
      setActivity(data.activity);
      setActions(data.actions);
      setInfractions(data.infractions);
      setWarnings(data.warnings);
      setBans(data.bans);
      setEditForm({
        name: data.profile?.name,
        email: data.profile?.email,
        phone: data.profile?.phone,
        location: data.profile?.location
      });
    } catch (e) {
      toastError({ title: 'Failed to load admin profile data' });
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchAllData();
    const interval = setInterval(fetchAllData, 30000);
    return () => clearInterval(interval);
  }, [adminId]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchAllData();
    setRefreshing(false);
    toastSuccess({ title: 'Profile data refreshed' });
  };

  // Update profile - NOT IMPLEMENTED
  const handleUpdateProfile = async () => {
    try {
      // Send update request to backend via NUI
      const result = await window.fetchNui('updateAdminProfile', {
        adminId,
        profile: editForm
      });
      if (result?.success) {
        toastSuccess({ title: 'Profile updated successfully' });
        await fetchAllData();
        setIsEditing(false);
      } else {
        toastError({ title: result?.error || 'Failed to update profile' });
      }
    } catch (e) {
      toastError({ title: 'Failed to update profile' });
    }
  };

  // Update password - NOT IMPLEMENTED
  const handleUpdatePassword = async () => {
    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      toastError({ title: 'Passwords do not match' });
      return;
    }
    try {
      const result = await window.fetchNui('updateAdminPassword', {
        adminId,
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword
      });
      if (result?.success) {
        toastSuccess({ title: 'Password updated successfully' });
        setPasswordModal(false);
      } else {
        toastError({ title: result?.error || 'Failed to update password' });
      }
    } catch (e) {
      toastError({ title: 'Failed to update password' });
    }
  };

  // Update preferences - NOT IMPLEMENTED
  const handleUpdatePreferences = async () => {
    try {
      const result = await window.fetchNui('updateAdminPreferences', {
        adminId,
        preferences: notificationSettings
      });
      if (result?.success) {
        toastSuccess({ title: 'Preferences updated successfully' });
        setNotificationModal(false);
      } else {
        toastError({ title: result?.error || 'Failed to update preferences' });
      }
    } catch (e) {
      toastError({ title: 'Failed to update preferences' });
    }
  };

  // End session - NOT IMPLEMENTED
  const handleEndSession = async (session_id: string) => {
    try {
      const result = await window.fetchNui('endAdminSession', {
        adminId,
        sessionId: session_id
      });
      if (result?.success) {
        toastSuccess({ title: 'Session ended successfully' });
        await fetchAllData();
      } else {
        toastError({ title: result?.error || 'Failed to end session' });
      }
    } catch (e) {
      toastError({ title: 'Failed to end session' });
    }
  };

  // Clear activity - NOT IMPLEMENTED
  const handleClearActivity = async () => {
    try {
      const result = await window.fetchNui('clearAdminActivity', {
        adminId
      });
      if (result?.success) {
        toastSuccess({ title: 'Activity logs cleared' });
        await fetchAllData();
      } else {
        toastError({ title: result?.error || 'Failed to clear activity logs' });
      }
    } catch (e) {
      toastError({ title: 'Failed to clear activity logs' });
    }
  };

  // Export data - NOT IMPLEMENTED
  const handleExportData = async () => {
    try {
      const result = await window.fetchNui('exportAdminProfile', {
        adminId
      });
      if (result?.success) {
        toastSuccess({ title: 'Profile data exported' });
      } else {
        toastError({ title: result?.error || 'Failed to export profile data' });
      }
    } catch (e) {
      toastError({ title: 'Failed to export profile data' });
    }
  };


  // Derive stats from profile/activity/actions if needed
  const stats = profile ? {
    totalActions: profile.total_actions,
    playersManaged: profile.players_managed,
    bansIssued: profile.bans_issued,
    warningsIssued: profile.warnings_issued,
    resourcesManaged: profile.resources_managed,
    uptime: profile.uptime,
    trustScore: profile.trust_score,
    status: profile.status
  } : null;
  const sessions = []; // Sessions feature (future enhancement - backend ready when needed)
  const framework = profile?.framework || 'Unknown';

  // Get activity icon
  const getActivityIcon = (category: string) => {
    switch (category) {
      case 'moderation': return Shield;
      case 'economy': return TrendingUp;
      case 'system': return Settings;
      case 'players': return User;
      default: return Activity;
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <User className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading Profile...</p>
          <p className="text-sm text-muted-foreground">Fetching admin data</p>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <AlertTriangle className="size-8 mx-auto mb-4 text-destructive" />
          <p className="text-lg font-medium">Profile Not Found</p>
          <p className="text-sm text-muted-foreground">Unable to load admin profile</p>
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
            <User className="size-8 text-primary" />
            Admin Profile
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage your account and view activity • Framework: {framework}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Badge variant="default" className="gap-2">
            <Shield className="size-3" />
            {profile.role}
          </Badge>
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

      {/* Profile Overview */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-start gap-6">
            <Avatar className="size-24 rounded-xl">
              <AvatarFallback className="rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 text-white text-2xl">
                <User className="size-12" />
              </AvatarFallback>
            </Avatar>
            
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <h2 className="text-2xl font-semibold">{profile.name}</h2>
                <Badge variant="outline" className="gap-1">
                  <Shield className="size-3" />
                  {profile.role}
                </Badge>
                {profile.status === 'active' && (
                  <Badge variant="default" className="gap-1">
                    <CheckCircle className="size-3" />
                    Active
                  </Badge>
                )}
              </div>
              <p className="text-muted-foreground mb-4">{profile.email || 'No email set'}</p>
              
              <div className="grid grid-cols-3 gap-4">
                <div className="flex items-center gap-2 text-sm">
                  <Calendar className="size-4 text-muted-foreground" />
                  <span>Joined {formatRelativeTime(profile.joined_date)}</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Clock className="size-4 text-muted-foreground" />
                  <span>Last login {formatRelativeTime(profile.last_login)}</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <MapPin className="size-4 text-muted-foreground" />
                  <span>{profile.location || 'Location not set'}</span>
                </div>
              </div>
            </div>

            <div className="flex gap-2">
              {!isEditing ? (
                <Button variant="outline" size="sm" onClick={() => setIsEditing(true)}>
                  <Edit2 className="size-4 mr-2" />
                  Edit
                </Button>
              ) : (
                <>
                  <Button variant="default" size="sm" onClick={handleUpdateProfile}>
                    <Save className="size-4 mr-2" />
                    Save
                  </Button>
                  <Button variant="outline" size="sm" onClick={() => {
                    setIsEditing(false);
                    setEditForm({
                      name: profile.name,
                      email: profile.email,
                      phone: profile.phone,
                      location: profile.location
                    });
                  }}>
                    <X className="size-4 mr-2" />
                    Cancel
                  </Button>
                </>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-500/10 rounded-lg">
                <Activity className="size-6 text-blue-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Actions</p>
                <p className="text-xl font-bold">{stats?.totalActions || 0}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-500/10 rounded-lg">
                <User className="size-6 text-green-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Players Managed</p>
                <p className="text-xl font-bold">{stats?.playersManaged || 0}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-purple-500/10 rounded-lg">
                <Award className="size-6 text-purple-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Trust Score</p>
                <p className="text-xl font-bold">{stats?.trustScore || 100}%</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-orange-500/10 rounded-lg">
                <TrendingUp className="size-6 text-orange-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Uptime</p>
                <p className="text-xl font-bold">{stats?.uptime?.toFixed(1) || 99.9}%</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-7">
          <TabsTrigger value="profile">Profile</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
          <TabsTrigger value="permissions">Permissions</TabsTrigger>
          <TabsTrigger value="roles">Roles</TabsTrigger>
          <TabsTrigger value="infractions">Infractions</TabsTrigger>
          <TabsTrigger value="warnings">Warnings</TabsTrigger>
          <TabsTrigger value="bans">Bans</TabsTrigger>
        </TabsList>
        {/* Roles Tab */}
        <TabsContent value="roles" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Admin Roles</CardTitle>
              <CardDescription>Your assigned roles</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-3">
                {roles.map((role, index) => (
                  <div key={index} className="flex items-center justify-between p-3 rounded-lg border">
                    <span className="text-sm font-medium">{role.name}</span>
                    <Badge variant="default" className="gap-1">
                      <CheckCircle className="size-3" />
                      {role.active ? 'Active' : 'Inactive'}
                    </Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Infractions Tab */}
        <TabsContent value="infractions" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Infractions</CardTitle>
              <CardDescription>All infractions issued to this admin</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {infractions.length === 0 ? (
                  <div className="text-center py-12 text-muted-foreground">
                    <AlertTriangle className="size-8 mx-auto mb-2 opacity-50" />
                    <p>No infractions found</p>
                  </div>
                ) : (
                  infractions.map((inf, idx) => (
                    <div key={idx} className="flex items-center justify-between p-3 rounded-lg border">
                      <span className="text-sm font-medium">{inf.reason}</span>
                      <span className="text-xs text-muted-foreground">{formatRelativeTime(inf.timestamp)}</span>
                    </div>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Warnings Tab */}
        <TabsContent value="warnings" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Warnings</CardTitle>
              <CardDescription>All warnings issued to this admin</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {warnings.length === 0 ? (
                  <div className="text-center py-12 text-muted-foreground">
                    <AlertTriangle className="size-8 mx-auto mb-2 opacity-50" />
                    <p>No warnings found</p>
                  </div>
                ) : (
                  warnings.map((warn, idx) => (
                    <div key={idx} className="flex items-center justify-between p-3 rounded-lg border">
                      <span className="text-sm font-medium">{warn.reason}</span>
                      <span className="text-xs text-muted-foreground">{formatRelativeTime(warn.timestamp)}</span>
                    </div>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Bans Tab */}
        <TabsContent value="bans" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Bans</CardTitle>
              <CardDescription>All bans issued to this admin</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {bans.length === 0 ? (
                  <div className="text-center py-12 text-muted-foreground">
                    <AlertTriangle className="size-8 mx-auto mb-2 opacity-50" />
                    <p>No bans found</p>
                  </div>
                ) : (
                  bans.map((ban, idx) => (
                    <div key={idx} className="flex items-center justify-between p-3 rounded-lg border">
                      <span className="text-sm font-medium">{ban.reason}</span>
                      <span className="text-xs text-muted-foreground">{formatRelativeTime(ban.timestamp)}</span>
                    </div>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Profile Tab */}
        <TabsContent value="profile" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Profile Information</CardTitle>
              <CardDescription>Update your personal information</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Full Name</Label>
                  <Input
                    value={editForm.name || ''}
                    onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                    disabled={!isEditing}
                  />
                </div>
                <div>
                  <Label>Email Address</Label>
                  <Input
                    type="email"
                    value={editForm.email || ''}
                    onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                    disabled={!isEditing}
                  />
                </div>
                <div>
                  <Label>Phone Number</Label>
                  <Input
                    type="tel"
                    value={editForm.phone || ''}
                    onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })}
                    disabled={!isEditing}
                  />
                </div>
                <div>
                  <Label>Location</Label>
                  <Input
                    value={editForm.location || ''}
                    onChange={(e) => setEditForm({ ...editForm, location: e.target.value })}
                    disabled={!isEditing}
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Statistics</CardTitle>
              <CardDescription>Your admin activity statistics</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-muted-foreground">Bans Issued</p>
                  <p className="text-lg font-bold">{stats?.bansIssued || 0}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Warnings Issued</p>
                  <p className="text-lg font-bold">{stats?.warningsIssued || 0}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Resources Managed</p>
                  <p className="text-lg font-bold">{stats?.resourcesManaged || 0}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">System Uptime</p>
                  <p className="text-lg font-bold">{stats?.uptime?.toFixed(2) || 99.9}%</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Quick Actions Widget */}
          <QuickActionsWidget 
            variant="profile" 
            maxActions={12} 
            onOpenQuickActionsCenter={onOpenQuickActionsCenter}
          />
        </TabsContent>

        {/* Activity Tab */}
        <TabsContent value="activity" className="space-y-4 mt-6">
          <div className="flex justify-between items-center">
            <div>
              <h3 className="text-lg font-medium">Recent Activity</h3>
              <p className="text-sm text-muted-foreground">Your latest admin actions</p>
            </div>
            <Button variant="outline" size="sm" onClick={handleClearActivity}>
              <Trash2 className="size-4 mr-2" />
              Clear Old Logs
            </Button>
          </div>

          <Card>
            <CardContent className="p-6">
              <ScrollArea className="h-[400px]">
                <div className="space-y-2">
                  {activity.length === 0 ? (
                    <div className="text-center py-12 text-muted-foreground">
                      <Activity className="size-8 mx-auto mb-2 opacity-50" />
                      <p>No recent activity</p>
                    </div>
                  ) : (
                    activity.map((item) => {
                      const Icon = getActivityIcon(item.category);
                      return (
                        <div key={item.id} className="flex items-center justify-between p-3 rounded-lg ec-card-transparent border border-border/30">
                          <div className="flex items-center gap-3">
                            <Icon className="size-4 text-muted-foreground" />
                            <div>
                              <p className="text-sm font-medium">{item.action}</p>
                              {item.target_name && (
                                <p className="text-xs text-muted-foreground">Target: {item.target_name}</p>
                              )}
                            </div>
                          </div>
                          <div className="text-xs text-muted-foreground">
                            {formatRelativeTime(item.timestamp)}
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Permissions Tab */}
        <TabsContent value="permissions" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Admin Permissions</CardTitle>
              <CardDescription>Your current permission levels</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-3">
                {permissions.map((perm, index) => (
                  <div key={index} className="flex items-center justify-between p-3 rounded-lg border">
                    <span className="text-sm font-medium">{perm.name}</span>
                    {perm.granted ? (
                      <Badge variant="default" className="gap-1">
                        <CheckCircle className="size-3" />
                        Granted
                      </Badge>
                    ) : (
                      <Badge variant="secondary" className="gap-1">
                        <X className="size-3" />
                        Denied
                      </Badge>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Sessions Tab */}
        <TabsContent value="sessions" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Active Sessions</CardTitle>
              <CardDescription>Manage your login sessions</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {sessions.length === 0 ? (
                  <div className="text-center py-12 text-muted-foreground">
                    <LogOut className="size-8 mx-auto mb-2 opacity-50" />
                    <p>No active sessions</p>
                  </div>
                ) : (
                  sessions.map((session) => (
                    <div key={session.id} className="flex items-center justify-between p-3 rounded-lg border">
                      <div>
                        <p className="text-sm font-medium">{session.ip_address}</p>
                        <p className="text-xs text-muted-foreground">
                          Login: {formatRelativeTime(session.login_time)}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant={session.status === 'active' ? 'default' : 'secondary'}>
                          {session.status}
                        </Badge>
                        {session.status === 'active' && (
                          <Button
                            variant="destructive"
                            size="sm"
                            onClick={() => handleEndSession(session.id.toString())}
                          >
                            End Session
                          </Button>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Security Tab */}
        <TabsContent value="security" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Security Settings</CardTitle>
              <CardDescription>Manage your security preferences</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button variant="outline" className="w-full" onClick={() => setPasswordModal(true)}>
                <Key className="size-4 mr-2" />
                Change Password
              </Button>
              <Button variant="outline" className="w-full" onClick={() => setNotificationModal(true)}>
                <Bell className="size-4 mr-2" />
                Notification Preferences
              </Button>
              <Button variant="outline" className="w-full" onClick={handleExportData}>
                <Download className="size-4 mr-2" />
                Export Profile Data
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Two-Factor Authentication</CardTitle>
              <CardDescription>Add an extra layer of security</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">2FA Status</p>
                  <p className="text-sm text-muted-foreground">Currently disabled</p>
                </div>
                <Badge variant="secondary">Disabled</Badge>
              </div>
              <Button variant="default" className="w-full">
                <Shield className="size-4 mr-2" />
                Enable 2FA
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>API Access</CardTitle>
              <CardDescription>Manage your API keys and access tokens</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="p-3 ec-card-transparent border border-border/30 rounded-lg">
                <p className="text-sm font-medium mb-1">API Key</p>
                <p className="text-xs text-muted-foreground font-mono">••••••••••••••••••••••••</p>
              </div>
              <div className="flex gap-2">
                <Button variant="outline" size="sm" className="flex-1">
                  <RefreshCw className="size-4 mr-2" />
                  Regenerate
                </Button>
                <Button variant="outline" size="sm" className="flex-1">
                  <Download className="size-4 mr-2" />
                  Copy
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Statistics Tab */}
        <TabsContent value="stats" className="space-y-4 mt-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card>
              <CardHeader>
                <CardTitle>Performance Metrics</CardTitle>
                <CardDescription>Your admin performance overview</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm">Response Time</span>
                    <span className="text-sm font-bold">2.3s avg</span>
                  </div>
                  <Progress value={85} />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm">Task Completion</span>
                    <span className="text-sm font-bold">94%</span>
                  </div>
                  <Progress value={94} />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm">Player Satisfaction</span>
                    <span className="text-sm font-bold">4.8/5.0</span>
                  </div>
                  <Progress value={96} />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm">System Uptime</span>
                    <span className="text-sm font-bold">{stats?.uptime?.toFixed(1) || 99.9}%</span>
                  </div>
                  <Progress value={stats?.uptime || 99.9} />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Action Breakdown</CardTitle>
                <CardDescription>Last 30 days</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between p-2 rounded-lg bg-blue-500/10">
                  <div className="flex items-center gap-2">
                    <User className="size-4 text-blue-500" />
                    <span className="text-sm">Player Actions</span>
                  </div>
                  <span className="text-sm font-bold">{stats?.playersManaged || 0}</span>
                </div>
                <div className="flex items-center justify-between p-2 rounded-lg bg-red-500/10">
                  <div className="flex items-center gap-2">
                    <Ban className="size-4 text-red-500" />
                    <span className="text-sm">Bans Issued</span>
                  </div>
                  <span className="text-sm font-bold">{stats?.bansIssued || 0}</span>
                </div>
                <div className="flex items-center justify-between p-2 rounded-lg bg-yellow-500/10">
                  <div className="flex items-center gap-2">
                    <AlertTriangle className="size-4 text-yellow-500" />
                    <span className="text-sm">Warnings</span>
                  </div>
                  <span className="text-sm font-bold">{stats?.warningsIssued || 0}</span>
                </div>
                <div className="flex items-center justify-between p-2 rounded-lg bg-green-500/10">
                  <div className="flex items-center gap-2">
                    <Activity className="size-4 text-green-500" />
                    <span className="text-sm">Total Actions</span>
                  </div>
                  <span className="text-sm font-bold">{stats?.totalActions || 0}</span>
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Achievements & Milestones</CardTitle>
              <CardDescription>Your admin achievements</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="text-center p-4 rounded-lg bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20">
                  <Award className="size-8 mx-auto mb-2 text-blue-500" />
                  <p className="text-sm font-medium">First Month</p>
                  <p className="text-xs text-muted-foreground">Completed</p>
                </div>
                <div className="text-center p-4 rounded-lg bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-500/20">
                  <Target className="size-8 mx-auto mb-2 text-purple-500" />
                  <p className="text-sm font-medium">100 Actions</p>
                  <p className="text-xs text-muted-foreground">Unlocked</p>
                </div>
                <div className="text-center p-4 rounded-lg bg-gradient-to-br from-green-500/10 to-green-600/10 border border-green-500/20">
                  <Shield className="size-8 mx-auto mb-2 text-green-500" />
                  <p className="text-sm font-medium">Protector</p>
                  <p className="text-xs text-muted-foreground">Active</p>
                </div>
                <div className="text-center p-4 rounded-lg bg-gradient-to-br from-orange-500/10 to-orange-600/10 border border-orange-500/20">
                  <TrendingUp className="size-8 mx-auto mb-2 text-orange-500" />
                  <p className="text-sm font-medium">High Performer</p>
                  <p className="text-xs text-muted-foreground">Earned</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Action Logs Tab */}
        <TabsContent value="logs" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Recent Admin Actions</CardTitle>
              <CardDescription>Detailed log of all your administrative actions</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[500px]">
                <div className="space-y-2">
                  {activity.length === 0 ? (
                    <div className="text-center py-12 text-muted-foreground">
                      <Activity className="size-8 mx-auto mb-2 opacity-50" />
                      <p>No action logs available</p>
                    </div>
                  ) : (
                    activity.map((item) => {
                      const Icon = getActivityIcon(item.category);
                      return (
                        <div key={item.id} className="p-4 rounded-lg border ec-card-transparent hover:border-border/50 transition-colors">
                          <div className="flex items-start justify-between mb-2">
                            <div className="flex items-center gap-3">
                              <div className="p-2 rounded-lg ec-card-transparent border border-border/30">
                                <Icon className="size-4" />
                              </div>
                              <div>
                                <p className="font-medium">{item.action}</p>
                                <p className="text-sm text-muted-foreground">{item.category}</p>
                              </div>
                            </div>
                            <Badge variant="outline">{new Date(item.timestamp * 1000).toLocaleTimeString()}</Badge>
                          </div>
                          {item.target_name && (
                            <div className="ml-11 mt-2 text-sm text-muted-foreground">
                              Target: <span className="font-medium text-foreground">{item.target_name}</span>
                            </div>
                          )}
                          {item.details && (
                            <div className="ml-11 mt-1 text-sm text-muted-foreground">
                              {item.details}
                            </div>
                          )}
                          <div className="ml-11 mt-2 text-xs text-muted-foreground">
                            {formatDateTime(item.timestamp)}
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Password Modal */}
      <Dialog open={passwordModal} onOpenChange={setPasswordModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Change Password</DialogTitle>
            <DialogDescription>Update your admin password</DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div>
              <Label>Current Password</Label>
              <Input
                type="password"
                value={passwordForm.currentPassword}
                onChange={(e) => setPasswordForm({ ...passwordForm, currentPassword: e.target.value })}
              />
            </div>
            <div>
              <Label>New Password</Label>
              <Input
                type="password"
                value={passwordForm.newPassword}
                onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
              />
            </div>
            <div>
              <Label>Confirm New Password</Label>
              <Input
                type="password"
                value={passwordForm.confirmPassword}
                onChange={(e) => setPasswordForm({ ...passwordForm, confirmPassword: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setPasswordModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleUpdatePassword}>
              Update Password
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Notification Preferences Modal */}
      <Dialog open={notificationModal} onOpenChange={setNotificationModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Notification Preferences</DialogTitle>
            <DialogDescription>Configure your notification settings</DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <Label>Email Notifications</Label>
              <Switch
                checked={notificationSettings.emailNotifications}
                onCheckedChange={(checked) => setNotificationSettings({ ...notificationSettings, emailNotifications: checked })}
              />
            </div>
            <div className="flex items-center justify-between">
              <Label>Discord Notifications</Label>
              <Switch
                checked={notificationSettings.discordNotifications}
                onCheckedChange={(checked) => setNotificationSettings({ ...notificationSettings, discordNotifications: checked })}
              />
            </div>
            <div className="flex items-center justify-between">
              <Label>Player Reports</Label>
              <Switch
                checked={notificationSettings.playerReports}
                onCheckedChange={(checked) => setNotificationSettings({ ...notificationSettings, playerReports: checked })}
              />
            </div>
            <div className="flex items-center justify-between">
              <Label>Ban Alerts</Label>
              <Switch
                checked={notificationSettings.banAlerts}
                onCheckedChange={(checked) => setNotificationSettings({ ...notificationSettings, banAlerts: checked })}
              />
            </div>
            <div className="flex items-center justify-between">
              <Label>Security Alerts</Label>
              <Switch
                checked={notificationSettings.securityAlerts}
                onCheckedChange={(checked) => setNotificationSettings({ ...notificationSettings, securityAlerts: checked })}
              />
            </div>
            <div className="flex items-center justify-between">
              <Label>System Alerts</Label>
              <Switch
                checked={notificationSettings.systemAlerts}
                onCheckedChange={(checked) => setNotificationSettings({ ...notificationSettings, systemAlerts: checked })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setNotificationModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleUpdatePreferences}>
              Save Preferences
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}