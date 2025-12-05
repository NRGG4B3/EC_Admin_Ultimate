import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Textarea } from '../ui/textarea';
import { Switch } from '../ui/switch';
import { ScrollArea } from '../ui/scroll-area';
import { Separator } from '../ui/separator';
import { 
  Settings as SettingsIcon, Save, RefreshCw, Webhook, Shield, 
  Bell, Zap, Database, Palette, Activity, Lock, Globe,
  AlertTriangle, CheckCircle, RotateCcw, TestTube2, Eye,
  Server, Code, Sliders
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';

interface SettingsPageProps {
  liveData: any;
}

interface SettingsData {
  settings: {
    general: any;
    permissions: any;
    webhooks: any;
    notifications: any;
    limits: any;
    anticheat: any;
    aiDetection: any;
    economy: any;
    whitelist: any;
    logging: any;
    performance: any;
    ui: any;
  };
  webhooks: any;
  permissions: any;
  serverInfo: {
    hostname: string;
    maxPlayers: number;
    version: string;
    framework: string;
    resourceName: string;
    uptime: number;
  };
  recentChanges: any[];
  defaults: any;
}

export function SettingsPage({ liveData }: SettingsPageProps) {
  const [activeTab, setActiveTab] = useState('general');
  const [isLoading, setIsLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [data, setData] = useState<SettingsData | null>(null);
  const [formData, setFormData] = useState<any>({});
  const [hasChanges, setHasChanges] = useState(false);

  // Fetch settings data
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/settings:getData', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        // Data will be received via NUI message
      }
    } catch (error) {
      console.log('[Settings] Not in FiveM environment');
    }
  }, []);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      if (action === 'settingsData') {
        if (msgData.success) {
          setData(msgData.data);
          // Initialize form data with current settings
          setFormData(msgData.data.settings || {});
          setHasChanges(false);
        }
      } else if (action === 'settingsResponse') {
        if (msgData.success) {
          toastSuccess({ title: msgData.message });
          fetchData();
          setHasChanges(false);
        } else {
          toastError({ title: msgData.message });
        }
        setSaving(false);
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
  }, [fetchData]);

  // Track changes
  const updateFormData = (category: string, key: string, value: any) => {
    setFormData((prev: any) => ({
      ...prev,
      [category]: {
        ...(prev[category] || {}),
        [key]: value
      }
    }));
    setHasChanges(true);
  };

  // Save settings
  const handleSave = async (category: string) => {
    setSaving(true);

    try {
      await fetch('https://ec_admin_ultimate/settings:save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          category,
          values: formData[category]
        })
      });
    } catch (error) {
      toastError({ title: 'Failed to save settings' });
      setSaving(false);
    }
  };

  // Save webhooks
  const handleSaveWebhooks = async () => {
    setSaving(true);

    try {
      await fetch('https://ec_admin_ultimate/settings:saveWebhooks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          webhooks: formData.webhooks
        })
      });
    } catch (error) {
      toastError({ title: 'Failed to save webhooks' });
      setSaving(false);
    }
  };

  // Test webhook
  const handleTestWebhook = async (webhookUrl: string) => {
    if (!webhookUrl) {
      toastError({ title: 'Please enter a webhook URL first' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/settings:testWebhook', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ webhookUrl })
      });
    } catch (error) {
      toastError({ title: 'Failed to test webhook' });
    }
  };

  // Reset settings
  const handleReset = async (category: string) => {
    if (!confirm(`Are you sure you want to reset ${category} settings to defaults?`)) {
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/settings:reset', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ category })
      });
    } catch (error) {
      toastError({ title: 'Failed to reset settings' });
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

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <SettingsIcon className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading Settings...</p>
        </div>
      </div>
    );
  }

  const settings = formData || {};
  const serverInfo = data?.serverInfo;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl tracking-tight flex items-center gap-3">
            <SettingsIcon className="size-8 text-primary" />
            Settings
          </h1>
          <p className="text-muted-foreground mt-1">
            Configure admin panel settings and preferences
          </p>
        </div>
        <div className="flex items-center gap-3">
          {hasChanges && (
            <Badge variant="outline" className="text-yellow-500">
              <AlertTriangle className="size-3 mr-1" />
              Unsaved Changes
            </Badge>
          )}
          <Button 
            variant="outline" 
            size="sm" 
            onClick={() => fetchData()}
          >
            <RefreshCw className="size-4 mr-2" />
            Refresh
          </Button>
        </div>
      </div>

      {/* Server Info */}
      {serverInfo && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Server className="size-5" />
              Server Information
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <Label>Server Name</Label>
                <p className="font-medium">{serverInfo.hostname}</p>
              </div>
              <div>
                <Label>Max Players</Label>
                <p className="font-medium">{serverInfo.maxPlayers}</p>
              </div>
              <div>
                <Label>Framework</Label>
                <Badge>{serverInfo.framework}</Badge>
              </div>
              <div>
                <Label>Uptime</Label>
                <p className="font-medium">{formatUptime(serverInfo.uptime)}</p>
              </div>
              <div>
                <Label>Panel Version</Label>
                <p className="font-medium">{serverInfo.version}</p>
              </div>
              <div>
                <Label>Resource Name</Label>
                <p className="font-medium">{serverInfo.resourceName}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Settings Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="general">
            <Globe className="size-4 mr-2" />
            General
          </TabsTrigger>
          <TabsTrigger value="permissions">
            <Lock className="size-4 mr-2" />
            Permissions
          </TabsTrigger>
          <TabsTrigger value="webhooks">
            <Webhook className="size-4 mr-2" />
            Webhooks
          </TabsTrigger>
          <TabsTrigger value="notifications">
            <Bell className="size-4 mr-2" />
            Notifications
          </TabsTrigger>
          <TabsTrigger value="anticheat">
            <Shield className="size-4 mr-2" />
            Anticheat
          </TabsTrigger>
          <TabsTrigger value="advanced">
            <Sliders className="size-4 mr-2" />
            Advanced
          </TabsTrigger>
        </TabsList>

        {/* General Settings */}
        <TabsContent value="general" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>General Settings</CardTitle>
              <CardDescription>Basic server and panel configuration</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="serverName">Server Name</Label>
                <Input
                  id="serverName"
                  placeholder="My FiveM Server"
                  value={settings.general?.serverName || ''}
                  onChange={(e) => updateFormData('general', 'serverName', e.target.value)}
                />
                <p className="text-xs text-muted-foreground">Displayed in the top bar</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="serverLogo">Server Logo URL</Label>
                <Input
                  id="serverLogo"
                  placeholder="https://example.com/logo.png"
                  value={settings.general?.serverLogo || ''}
                  onChange={(e) => updateFormData('general', 'serverLogo', e.target.value)}
                />
                <p className="text-xs text-muted-foreground">URL to your server logo image (displayed in top bar, replaces default icon)</p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="language">Language</Label>
                  <Select
                    value={settings.general?.language || 'en'}
                    onValueChange={(value) => updateFormData('general', 'language', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="en">English</SelectItem>
                      <SelectItem value="es">Español</SelectItem>
                      <SelectItem value="fr">Français</SelectItem>
                      <SelectItem value="de">Deutsch</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="timezone">Timezone</Label>
                  <Select
                    value={settings.general?.timezone || 'UTC'}
                    onValueChange={(value) => updateFormData('general', 'timezone', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="UTC">UTC</SelectItem>
                      <SelectItem value="America/New_York">EST</SelectItem>
                      <SelectItem value="America/Chicago">CST</SelectItem>
                      <SelectItem value="America/Los_Angeles">PST</SelectItem>
                      <SelectItem value="Europe/London">GMT</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="theme">Theme</Label>
                  <Select
                    value={settings.general?.theme || 'dark'}
                    onValueChange={(value) => updateFormData('general', 'theme', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="dark">Dark</SelectItem>
                      <SelectItem value="light">Light</SelectItem>
                      <SelectItem value="system">System</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="accentColor">Accent Color</Label>
                  <Input
                    id="accentColor"
                    type="color"
                    value={settings.general?.accentColor || '#3b82f6'}
                    onChange={(e) => updateFormData('general', 'accentColor', e.target.value)}
                  />
                </div>
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Enable Sounds</Label>
                  <p className="text-sm text-muted-foreground">Play sounds for notifications and actions</p>
                </div>
                <Switch
                  checked={settings.general?.enableSounds !== false}
                  onCheckedChange={(checked) => updateFormData('general', 'enableSounds', checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Enable Animations</Label>
                  <p className="text-sm text-muted-foreground">Show UI animations and transitions</p>
                </div>
                <Switch
                  checked={settings.general?.enableAnimations !== false}
                  onCheckedChange={(checked) => updateFormData('general', 'enableAnimations', checked)}
                />
              </div>

              <Separator />

              <div className="flex justify-between">
                <Button 
                  variant="outline" 
                  onClick={() => handleReset('general')}
                >
                  <RotateCcw className="size-4 mr-2" />
                  Reset to Defaults
                </Button>
                <Button 
                  onClick={() => handleSave('general')}
                  disabled={saving}
                >
                  <Save className="size-4 mr-2" />
                  Save General Settings
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Permissions Settings */}
        <TabsContent value="permissions" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Permissions & Access Control</CardTitle>
              <CardDescription>Configure access permissions and security</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Require Admin for Panel</Label>
                  <p className="text-sm text-muted-foreground">Only admins can access the panel</p>
                </div>
                <Switch
                  checked={settings.permissions?.requireAdminForPanel !== false}
                  onCheckedChange={(checked) => updateFormData('permissions', 'requireAdminForPanel', checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Allow Player Reports</Label>
                  <p className="text-sm text-muted-foreground">Players can submit reports</p>
                </div>
                <Switch
                  checked={settings.permissions?.allowPlayerReports !== false}
                  onCheckedChange={(checked) => updateFormData('permissions', 'allowPlayerReports', checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Enable Anticheat</Label>
                  <p className="text-sm text-muted-foreground">Activate anticheat detection system</p>
                </div>
                <Switch
                  checked={settings.permissions?.enableAnticheat !== false}
                  onCheckedChange={(checked) => updateFormData('permissions', 'enableAnticheat', checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Enable AI Detection</Label>
                  <p className="text-sm text-muted-foreground">Activate AI-powered bot detection</p>
                </div>
                <Switch
                  checked={settings.permissions?.enableAIDetection === true}
                  onCheckedChange={(checked) => updateFormData('permissions', 'enableAIDetection', checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Enable Whitelist</Label>
                  <p className="text-sm text-muted-foreground">Require whitelist to join server</p>
                </div>
                <Switch
                  checked={settings.permissions?.enableWhitelist === true}
                  onCheckedChange={(checked) => updateFormData('permissions', 'enableWhitelist', checked)}
                />
              </div>

              <Separator />

              <div className="flex justify-between">
                <Button 
                  variant="outline" 
                  onClick={() => handleReset('permissions')}
                >
                  <RotateCcw className="size-4 mr-2" />
                  Reset to Defaults
                </Button>
                <Button 
                  onClick={() => handleSave('permissions')}
                  disabled={saving}
                >
                  <Save className="size-4 mr-2" />
                  Save Permissions
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Webhooks Settings */}
        <TabsContent value="webhooks" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Discord Webhooks</CardTitle>
              <CardDescription>Configure Discord webhook integrations</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between mb-4">
                <div className="space-y-0.5">
                  <Label>Enable Webhooks</Label>
                  <p className="text-sm text-muted-foreground">Send logs to Discord</p>
                </div>
                <Switch
                  checked={settings.webhooks?.enabled === true}
                  onCheckedChange={(checked) => updateFormData('webhooks', 'enabled', checked)}
                />
              </div>

              <Separator />

                {/* Ensure all webhook categories from config are present and mapped safely */}
                {(window?.Config?.Webhooks ? Object.keys(window.Config.Webhooks) : ['adminActions','bans','reports','economy','anticheat','aiDetection','whitelist','system']).map((type) => (
                  <div key={type} className="space-y-2">
                    <Label htmlFor={type}>
                      {type.charAt(0).toUpperCase() + type.slice(1).replace(/([A-Z])/g, ' $1')} Webhook
                    </Label>
                    <div className="flex gap-2">
                      <Input
                        id={type}
                        placeholder="https://discord.com/api/webhooks/..."
                        value={settings.webhooks?.[type + 'Webhook'] || settings.webhooks?.[type] || ''}
                        onChange={(e) => updateFormData('webhooks', type + 'Webhook', e.target.value)}
                        className="flex-1"
                      />
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleTestWebhook(settings.webhooks?.[type + 'Webhook'] || settings.webhooks?.[type] || '')}
                      >
                        <TestTube2 className="size-4" />
                      </Button>
                    </div>
                  </div>
                ))}

              <Separator />

              <div className="flex justify-between">
                <Button 
                  variant="outline" 
                  onClick={() => handleReset('webhooks')}
                >
                  <RotateCcw className="size-4 mr-2" />
                  Clear All Webhooks
                </Button>
                <Button 
                  onClick={handleSaveWebhooks}
                  disabled={saving}
                >
                  <Save className="size-4 mr-2" />
                  Save Webhooks
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Notifications Settings */}
        <TabsContent value="notifications" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Notification Settings</CardTitle>
              <CardDescription>Configure in-panel notifications</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Enable Notifications</Label>
                  <p className="text-sm text-muted-foreground">Show notifications in the panel</p>
                </div>
                <Switch
                  checked={settings.notifications?.enabled !== false}
                  onCheckedChange={(checked) => updateFormData('notifications', 'enabled', checked)}
                />
              </div>

              <Separator />

              {['playerJoin', 'playerLeave', 'adminActions', 'anticheat', 'aiDetection', 'reports', 'economy', 'vehicles', 'housing'].map((type) => (
                <div key={type} className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>{type.charAt(0).toUpperCase() + type.slice(1).replace(/([A-Z])/g, ' $1')}</Label>
                  </div>
                  <Switch
                    checked={settings.notifications?.[type] !== false}
                    onCheckedChange={(checked) => updateFormData('notifications', type, checked)}
                  />
                </div>
              ))}

              <Separator />

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Position</Label>
                  <Select
                    value={settings.notifications?.position || 'top-right'}
                    onValueChange={(value) => updateFormData('notifications', 'position', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="top-right">Top Right</SelectItem>
                      <SelectItem value="top-left">Top Left</SelectItem>
                      <SelectItem value="bottom-right">Bottom Right</SelectItem>
                      <SelectItem value="bottom-left">Bottom Left</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Duration (ms)</Label>
                  <Input
                    type="number"
                    value={settings.notifications?.duration || 5000}
                    onChange={(e) => updateFormData('notifications', 'duration', parseInt(e.target.value))}
                  />
                </div>
              </div>

              <Separator />

              <div className="flex justify-between">
                <Button 
                  variant="outline" 
                  onClick={() => handleReset('notifications')}
                >
                  <RotateCcw className="size-4 mr-2" />
                  Reset to Defaults
                </Button>
                <Button 
                  onClick={() => handleSave('notifications')}
                  disabled={saving}
                >
                  <Save className="size-4 mr-2" />
                  Save Notifications
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Anticheat Settings */}
        <TabsContent value="anticheat" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Anticheat Configuration</CardTitle>
              <CardDescription>Configure anticheat detection systems</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Enable Anticheat</Label>
                  <p className="text-sm text-muted-foreground">Activate anticheat system</p>
                </div>
                <Switch
                  checked={settings.anticheat?.enabled !== false}
                  onCheckedChange={(checked) => updateFormData('anticheat', 'enabled', checked)}
                />
              </div>

              <Separator />

              {['godModeDetection', 'speedHackDetection', 'teleportDetection', 'weaponDetection', 'noclipDetection', 'resourceInjection'].map((type) => (
                <div key={type} className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>{type.charAt(0).toUpperCase() + type.slice(1).replace(/([A-Z])/g, ' $1')}</Label>
                  </div>
                  <Switch
                    checked={settings.anticheat?.[type] !== false}
                    onCheckedChange={(checked) => updateFormData('anticheat', type, checked)}
                  />
                </div>
              ))}

              <Separator />

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Auto-Ban</Label>
                  <p className="text-sm text-muted-foreground">Automatically ban detected cheaters</p>
                </div>
                <Switch
                  checked={settings.anticheat?.autoban === true}
                  onCheckedChange={(checked) => updateFormData('anticheat', 'autoban', checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-0.5">
                  <Label>Auto-Kick</Label>
                  <p className="text-sm text-muted-foreground">Automatically kick detected cheaters</p>
                </div>
                <Switch
                  checked={settings.anticheat?.autokick !== false}
                  onCheckedChange={(checked) => updateFormData('anticheat', 'autokick', checked)}
                />
              </div>

              <div className="space-y-2">
                <Label>Detection Sensitivity</Label>
                <Select
                  value={settings.anticheat?.sensitivity || 'medium'}
                  onValueChange={(value) => updateFormData('anticheat', 'sensitivity', value)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="low">Low</SelectItem>
                    <SelectItem value="medium">Medium</SelectItem>
                    <SelectItem value="high">High</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <Separator />

              <div className="flex justify-between">
                <Button 
                  variant="outline" 
                  onClick={() => handleReset('anticheat')}
                >
                  <RotateCcw className="size-4 mr-2" />
                  Reset to Defaults
                </Button>
                <Button 
                  onClick={() => handleSave('anticheat')}
                  disabled={saving}
                >
                  <Save className="size-4 mr-2" />
                  Save Anticheat
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Advanced Settings */}
        <TabsContent value="advanced" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Advanced Settings</CardTitle>
              <CardDescription>Performance and system configuration</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <h3 className="font-medium">Performance</h3>
                
                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Enable Optimization</Label>
                    <p className="text-sm text-muted-foreground">Optimize resource usage</p>
                  </div>
                  <Switch
                    checked={settings.performance?.enableOptimization !== false}
                    onCheckedChange={(checked) => updateFormData('performance', 'enableOptimization', checked)}
                  />
                </div>

                <div className="flex items-center justify-between">
                  <div className="space-y-0.5">
                    <Label>Low Memory Mode</Label>
                    <p className="text-sm text-muted-foreground">Reduce memory usage</p>
                  </div>
                  <Switch
                    checked={settings.performance?.lowMemoryMode === true}
                    onCheckedChange={(checked) => updateFormData('performance', 'lowMemoryMode', checked)}
                  />
                </div>

                <div className="space-y-2">
                  <Label>Update Interval (ms)</Label>
                  <Input
                    type="number"
                    value={settings.performance?.updateInterval || 5000}
                    onChange={(e) => updateFormData('performance', 'updateInterval', parseInt(e.target.value))}
                  />
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <h3 className="font-medium">Logging</h3>
                
                <div className="space-y-2">
                  <Label>Log Retention (days)</Label>
                  <Input
                    type="number"
                    value={settings.logging?.retentionDays || 30}
                    onChange={(e) => updateFormData('logging', 'retentionDays', parseInt(e.target.value))}
                  />
                </div>

                <div className="space-y-2">
                  <Label>Log Level</Label>
                  <Select
                    value={settings.logging?.logLevel || 'info'}
                    onValueChange={(value) => updateFormData('logging', 'logLevel', value)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="debug">Debug</SelectItem>
                      <SelectItem value="info">Info</SelectItem>
                      <SelectItem value="warning">Warning</SelectItem>
                      <SelectItem value="error">Error</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <Separator />

              <div className="flex justify-end">
                <Button 
                  onClick={() => handleSave('performance')}
                  disabled={saving}
                >
                  <Save className="size-4 mr-2" />
                  Save Advanced Settings
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}