import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { Separator } from '../ui/separator';
import { 
  Shield, UserCheck, UserX, Clock, CheckCircle, XCircle, AlertCircle,
  Search, Plus, Trash2, Eye, Loader2, User, Mail, Calendar, FileText,
  Settings, Filter, Download, Upload, RotateCcw, Edit, Save, Copy,
  List, Grid, Hash, Link, MessageSquare, Phone, Globe, Send
} from 'lucide-react';
import { isEnvBrowser, fetchNui } from '../nui-bridge';
import { toastSuccess, toastError } from '../../lib/toast';

interface WhitelistPageProps {
  liveData: any;
}

interface WhitelistEntry {
  id: string;
  identifier: string;
  name: string;
  discord?: string;
  steam?: string;
  status: 'approved' | 'pending' | 'rejected';
  addedBy: string;
  addedAt: number;
  expiresAt?: number;
  reason?: string;
}

interface Application {
  id: string;
  name: string;
  discord?: string;
  steam?: string;
  age: number;
  reason: string;
  experience: string;
  submittedAt: number;
  status: 'pending' | 'approved' | 'rejected';
  customFields: Record<string, any>;
}

interface ApplicationField {
  id: string;
  name: string;
  label: string;
  type: 'text' | 'textarea' | 'number' | 'select' | 'checkbox';
  required: boolean;
  options?: string[];
  placeholder?: string;
  min?: number;
  max?: number;
  order: number;
}

interface ApplicationForm {
  id: string;
  name: string;
  description: string;
  fields: ApplicationField[];
  enabled: boolean;
  requireDiscord: boolean;
  requireSteam: boolean;
  minAge: number;
  autoApprove: boolean;
}

export function WhitelistPage({ liveData }: WhitelistPageProps) {
  const [activeTab, setActiveTab] = useState('whitelist');
  const [isLoading, setIsLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  
  const [whitelistEntries, setWhitelistEntries] = useState<WhitelistEntry[]>([]);
  const [applications, setApplications] = useState<Application[]>([]);
  const [applicationForm, setApplicationForm] = useState<ApplicationForm>({
    id: '1',
    name: 'Standard Application',
    description: 'Default whitelist application form',
    fields: [
      { id: '1', name: 'characterName', label: 'Character Name', type: 'text', required: true, order: 1, placeholder: 'Your character name...' },
      { id: '2', name: 'age', label: 'Age', type: 'number', required: true, order: 2, min: 13, max: 100, placeholder: 'Your age...' },
      { id: '3', name: 'reason', label: 'Why do you want to join?', type: 'textarea', required: true, order: 3, placeholder: 'Tell us why...' },
      { id: '4', name: 'experience', label: 'Previous RP Experience', type: 'textarea', required: true, order: 4, placeholder: 'Your experience...' },
      { id: '5', name: 'timezone', label: 'Timezone', type: 'select', required: true, order: 5, options: ['PST', 'EST', 'GMT', 'CET', 'AEST'] },
      { id: '6', name: 'playtime', label: 'Expected Playtime (hours/week)', type: 'number', required: false, order: 6, min: 0, max: 168 },
      { id: '7', name: 'referral', label: 'How did you find us?', type: 'select', required: false, order: 7, options: ['Discord', 'Friend', 'Reddit', 'FiveM Server List', 'YouTube', 'Other'] },
      { id: '8', name: 'agreedRules', label: 'I have read and agree to the server rules', type: 'checkbox', required: true, order: 8 }
    ],
    enabled: true,
    requireDiscord: true,
    requireSteam: false,
    minAge: 16,
    autoApprove: false
  });

  const [addModalOpen, setAddModalOpen] = useState(false);
  const [formEditorOpen, setFormEditorOpen] = useState(false);
  const [newField, setNewField] = useState<Partial<ApplicationField>>({
    name: '',
    label: '',
    type: 'text',
    required: false,
    order: applicationForm.fields.length + 1
  });

  const [newEntry, setNewEntry] = useState({
    identifier: '',
    name: '',
    discord: '',
    steam: '',
    reason: '',
    permanent: true,
    expiresIn: '30'
  });

  // Load data
  useEffect(() => {
    loadWhitelistData();
    const interval = setInterval(loadWhitelistData, 5000);
    return () => clearInterval(interval);
  }, []);

  const loadWhitelistData = async () => {
    if (isEnvBrowser()) {
      setWhitelistEntries([
        {
          id: '1',
          identifier: 'license:abc123',
          name: 'John Doe',
          discord: 'JohnDoe#1234',
          steam: 'steam:110000100000001',
          status: 'approved',
          addedBy: 'Admin',
          addedAt: Date.now() - 86400000
        }
      ]);

      setApplications([
        {
          id: '1',
          name: 'Mike Wilson',
          discord: 'MikeW#5678',
          age: 25,
          reason: 'Want to join and roleplay',
          experience: '2 years on other servers',
          submittedAt: Date.now() - 1800000,
          status: 'pending',
          customFields: {
            characterName: 'Mike Wilson',
            timezone: 'EST',
            playtime: 20,
            referral: 'Discord',
            agreedRules: true
          }
        }
      ]);
      return;
    }

    try {
      const response = await fetchNui<any>('whitelist/getData', {}, {});
      if (response) {
        setWhitelistEntries(response.whitelist || []);
        setApplications(response.applications || []);
        if (response.applicationForm) {
          setApplicationForm(response.applicationForm);
        }
      }
    } catch (error) {
      console.error('Failed to load whitelist data:', error);
    }
  };

  // Save application form
  const handleSaveApplicationForm = async () => {
    setIsLoading(true);

    try {
      if (isEnvBrowser()) {
        await new Promise(resolve => setTimeout(resolve, 500));
        toastSuccess({ title: 'Application form saved successfully' });
        setFormEditorOpen(false);
      } else {
        const response = await fetchNui<{ success: boolean; message: string }>(
          'whitelist/saveApplicationForm',
          applicationForm,
          { success: true, message: 'Form saved' }
        );

        if (response.success) {
          toastSuccess({ title: response.message });
          setFormEditorOpen(false);
        } else {
          toastError({ title: response.message });
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to save application form' });
    } finally {
      setIsLoading(false);
    }
  };

  // Add custom field
  const handleAddCustomField = () => {
    if (!newField.name || !newField.label) {
      toastError({ title: 'Please enter field name and label' });
      return;
    }

    const field: ApplicationField = {
      id: Date.now().toString(),
      name: newField.name!,
      label: newField.label!,
      type: newField.type || 'text',
      required: newField.required || false,
      options: newField.options || [],
      placeholder: newField.placeholder || '',
      min: newField.min,
      max: newField.max,
      order: applicationForm.fields.length + 1
    };

    setApplicationForm(prev => ({
      ...prev,
      fields: [...prev.fields, field]
    }));

    setNewField({
      name: '',
      label: '',
      type: 'text',
      required: false,
      order: applicationForm.fields.length + 2
    });

    toastSuccess({ title: 'Field added successfully' });
  };

  // Remove field
  const handleRemoveField = (fieldId: string) => {
    setApplicationForm(prev => ({
      ...prev,
      fields: prev.fields.filter(f => f.id !== fieldId)
    }));
    toastSuccess({ title: 'Field removed' });
  };

  // Approve application
  const handleApproveApplication = async (id: string) => {
    setIsLoading(true);

    try {
      if (isEnvBrowser()) {
        await new Promise(resolve => setTimeout(resolve, 500));
        toastSuccess({ title: 'Application approved' });
        loadWhitelistData();
      } else {
        const response = await fetchNui<{ success: boolean; message: string }>(
          'whitelist/approveApplication',
          { id },
          { success: true, message: 'Approved' }
        );

        if (response.success) {
          toastSuccess({ title: response.message });
          loadWhitelistData();
        } else {
          toastError({ title: response.message });
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to approve application' });
    } finally {
      setIsLoading(false);
    }
  };

  // Get public form link
  const getPublicFormLink = () => {
    const baseUrl = 'https://your-server.com/whitelist';
    return baseUrl + '?form=' + applicationForm.id;
  };

  // Copy form link
  const handleCopyFormLink = () => {
    navigator.clipboard.writeText(getPublicFormLink());
    toastSuccess({ title: 'Form link copied to clipboard' });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1>Advanced Whitelist Management</h1>
          <p className="text-muted-foreground">Customizable application system for Discord & in-game</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setFormEditorOpen(true)}>
            <Settings className="size-4 mr-2" />
            Form Builder
          </Button>
          <Button onClick={() => setAddModalOpen(true)}>
            <Plus className="size-4 mr-2" />
            Add Entry
          </Button>
        </div>
      </div>

      {/* Enhanced Stats */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Total Whitelisted</p>
                <p className="text-2xl">{whitelistEntries.filter(e => e.status === 'approved').length}</p>
              </div>
              <UserCheck className="size-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Pending</p>
                <p className="text-2xl">{applications.filter(a => a.status === 'pending').length}</p>
              </div>
              <Clock className="size-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">This Week</p>
                <p className="text-2xl">{applications.filter(a => a.submittedAt > Date.now() - 604800000).length}</p>
              </div>
              <FileText className="size-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Approval Rate</p>
                <p className="text-2xl">87%</p>
              </div>
              <CheckCircle className="size-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Avg. Time</p>
                <p className="text-2xl">2.4h</p>
              </div>
              <Clock className="size-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="whitelist">
            <Shield className="size-4 mr-2" />
            Whitelist ({whitelistEntries.length})
          </TabsTrigger>
          <TabsTrigger value="applications">
            <FileText className="size-4 mr-2" />
            Applications ({applications.filter(a => a.status === 'pending').length})
          </TabsTrigger>
          <TabsTrigger value="form">
            <List className="size-4 mr-2" />
            Application Form
          </TabsTrigger>
          <TabsTrigger value="settings">
            <Settings className="size-4 mr-2" />
            Settings
          </TabsTrigger>
        </TabsList>

        {/* Whitelist Tab */}
        <TabsContent value="whitelist" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Whitelist Entries</CardTitle>
                <Input placeholder="Search..." className="w-64" />
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Identifier</TableHead>
                    <TableHead>Discord</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Added By</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {whitelistEntries.map((entry) => (
                    <TableRow key={entry.id}>
                      <TableCell className="font-medium">{entry.name}</TableCell>
                      <TableCell className="font-mono text-sm">{entry.identifier}</TableCell>
                      <TableCell>{entry.discord || '-'}</TableCell>
                      <TableCell>
                        <Badge variant="default">
                          <CheckCircle className="size-3 mr-1" />
                          {entry.status}
                        </Badge>
                      </TableCell>
                      <TableCell>{entry.addedBy}</TableCell>
                      <TableCell>{new Date(entry.addedAt).toLocaleDateString()}</TableCell>
                      <TableCell className="text-right">
                        <Button size="sm" variant="ghost">
                          <Trash2 className="size-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Applications Tab */}
        <TabsContent value="applications" className="space-y-4">
          {applications.filter(app => app.status === 'pending').map((application) => (
            <Card key={application.id}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div>
                    <CardTitle>{application.name}</CardTitle>
                    <div className="flex items-center gap-4 mt-2 text-sm text-muted-foreground">
                      {application.discord && (
                        <span className="flex items-center gap-1">
                          <MessageSquare className="size-3" />
                          {application.discord}
                        </span>
                      )}
                      <span className="flex items-center gap-1">
                        <User className="size-3" />
                        Age: {application.age}
                      </span>
                      <span className="flex items-center gap-1">
                        <Clock className="size-3" />
                        {new Date(application.submittedAt).toLocaleString()}
                      </span>
                    </div>
                  </div>
                  <Badge variant="secondary">Pending</Badge>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label>Why do you want to join?</Label>
                    <p className="mt-1 text-sm">{application.reason}</p>
                  </div>
                  <div>
                    <Label>Previous Experience</Label>
                    <p className="mt-1 text-sm">{application.experience}</p>
                  </div>
                </div>

                {/* Custom Fields */}
                {Object.keys(application.customFields).length > 0 && (
                  <>
                    <Separator />
                    <div className="grid grid-cols-2 gap-4">
                      {Object.entries(application.customFields).map(([key, value]) => (
                        <div key={key}>
                          <Label className="capitalize">{key.replace(/([A-Z])/g, ' $1').trim()}</Label>
                          <p className="mt-1 text-sm">{String(value)}</p>
                        </div>
                      ))}
                    </div>
                  </>
                )}

                <div className="flex gap-2 pt-2">
                  <Button
                    onClick={() => handleApproveApplication(application.id)}
                    disabled={isLoading}
                    className="flex-1"
                  >
                    {isLoading && <Loader2 className="size-4 mr-2 animate-spin" />}
                    <CheckCircle className="size-4 mr-2" />
                    Approve
                  </Button>
                  <Button variant="destructive" className="flex-1">
                    <XCircle className="size-4 mr-2" />
                    Reject
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </TabsContent>

        {/* Application Form Tab */}
        <TabsContent value="form" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Application Form Preview</CardTitle>
                  <CardDescription>This is what applicants will see</CardDescription>
                </div>
                <div className="flex gap-2">
                  <Button variant="outline" size="sm" onClick={handleCopyFormLink}>
                    <Copy className="size-4 mr-2" />
                    Copy Link
                  </Button>
                  <Button size="sm" onClick={() => setFormEditorOpen(true)}>
                    <Edit className="size-4 mr-2" />
                    Edit Form
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4 max-w-2xl">
                <div>
                  <h3 className="font-medium">{applicationForm.name}</h3>
                  <p className="text-sm text-muted-foreground">{applicationForm.description}</p>
                </div>

                <Separator />

                {applicationForm.fields.sort((a, b) => a.order - b.order).map((field) => (
                  <div key={field.id} className="space-y-2">
                    <Label>
                      {field.label}
                      {field.required && <span className="text-red-500 ml-1">*</span>}
                    </Label>
                    {field.type === 'text' && (
                      <Input placeholder={field.placeholder} disabled />
                    )}
                    {field.type === 'number' && (
                      <Input type="number" placeholder={field.placeholder} min={field.min} max={field.max} disabled />
                    )}
                    {field.type === 'textarea' && (
                      <Textarea placeholder={field.placeholder} rows={3} disabled />
                    )}
                    {field.type === 'select' && (
                      <Select disabled>
                        <SelectTrigger>
                          <SelectValue placeholder="Select..." />
                        </SelectTrigger>
                        <SelectContent>
                          {field.options?.map((option) => (
                            <SelectItem key={option} value={option}>{option}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    )}
                    {field.type === 'checkbox' && (
                      <div className="flex items-center gap-2">
                        <Switch disabled />
                        <Label>{field.label}</Label>
                      </div>
                    )}
                  </div>
                ))}

                <Button className="w-full" disabled>
                  <Send className="size-4 mr-2" />
                  Submit Application
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Settings Tab */}
        <TabsContent value="settings" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Whitelist Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <Label>Whitelist Enabled</Label>
                  <p className="text-sm text-muted-foreground">Require whitelist approval to join</p>
                </div>
                <Switch checked={applicationForm.enabled} onCheckedChange={(checked) => setApplicationForm(prev => ({ ...prev, enabled: checked }))} />
              </div>

              <Separator />

              <div className="flex items-center justify-between">
                <div>
                  <Label>Require Discord</Label>
                  <p className="text-sm text-muted-foreground">Applicants must provide Discord</p>
                </div>
                <Switch checked={applicationForm.requireDiscord} onCheckedChange={(checked) => setApplicationForm(prev => ({ ...prev, requireDiscord: checked }))} />
              </div>

              <div className="flex items-center justify-between">
                <div>
                  <Label>Require Steam</Label>
                  <p className="text-sm text-muted-foreground">Applicants must provide Steam ID</p>
                </div>
                <Switch checked={applicationForm.requireSteam} onCheckedChange={(checked) => setApplicationForm(prev => ({ ...prev, requireSteam: checked }))} />
              </div>

              <Separator />

              <div className="space-y-2">
                <Label>Minimum Age</Label>
                <Input type="number" value={applicationForm.minAge} onChange={(e) => setApplicationForm(prev => ({ ...prev, minAge: parseInt(e.target.value) }))} />
              </div>

              <div className="flex items-center justify-between">
                <div>
                  <Label>Auto-Approve Applications</Label>
                  <p className="text-sm text-muted-foreground">Automatically approve new applications</p>
                </div>
                <Switch checked={applicationForm.autoApprove} onCheckedChange={(checked) => setApplicationForm(prev => ({ ...prev, autoApprove: checked }))} />
              </div>

              <Button onClick={handleSaveApplicationForm} disabled={isLoading}>
                {isLoading && <Loader2 className="size-4 mr-2 animate-spin" />}
                <Save className="size-4 mr-2" />
                Save Settings
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Form Editor Modal */}
      {formEditorOpen && (
        <div className="fixed inset-0 bg-black/50 dark:bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <Card className="w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <CardHeader>
              <CardTitle>Application Form Builder</CardTitle>
              <CardDescription>Customize your whitelist application form</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Form Info */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Form Name</Label>
                  <Input value={applicationForm.name} onChange={(e) => setApplicationForm(prev => ({ ...prev, name: e.target.value }))} />
                </div>
                <div className="space-y-2">
                  <Label>Description</Label>
                  <Input value={applicationForm.description} onChange={(e) => setApplicationForm(prev => ({ ...prev, description: e.target.value }))} />
                </div>
              </div>

              <Separator />

              {/* Existing Fields */}
              <div>
                <Label className="text-base">Form Fields</Label>
                <div className="mt-3 space-y-2">
                  {applicationForm.fields.sort((a, b) => a.order - b.order).map((field) => (
                    <div key={field.id} className="flex items-center justify-between p-3 border rounded">
                      <div className="flex items-center gap-3">
                        <Hash className="size-4 text-muted-foreground" />
                        <div>
                          <p className="font-medium">{field.label}</p>
                          <p className="text-sm text-muted-foreground">{field.type} {field.required && '• Required'}</p>
                        </div>
                      </div>
                      <Button size="sm" variant="ghost" onClick={() => handleRemoveField(field.id)}>
                        <Trash2 className="size-4" />
                      </Button>
                    </div>
                  ))}
                </div>
              </div>

              <Separator />

              {/* Add New Field */}
              <div>
                <Label className="text-base">Add New Field</Label>
                <div className="mt-3 grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Field Name (code)</Label>
                    <Input placeholder="fieldName" value={newField.name} onChange={(e) => setNewField(prev => ({ ...prev, name: e.target.value }))} />
                  </div>
                  <div className="space-y-2">
                    <Label>Field Label (display)</Label>
                    <Input placeholder="Field Label" value={newField.label} onChange={(e) => setNewField(prev => ({ ...prev, label: e.target.value }))} />
                  </div>
                  <div className="space-y-2">
                    <Label>Field Type</Label>
                    <Select value={newField.type} onValueChange={(value: any) => setNewField(prev => ({ ...prev, type: value }))}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="text">Text</SelectItem>
                        <SelectItem value="textarea">Textarea</SelectItem>
                        <SelectItem value="number">Number</SelectItem>
                        <SelectItem value="select">Select</SelectItem>
                        <SelectItem value="checkbox">Checkbox</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Placeholder</Label>
                    <Input placeholder="Placeholder text..." value={newField.placeholder} onChange={(e) => setNewField(prev => ({ ...prev, placeholder: e.target.value }))} />
                  </div>
                  <div className="col-span-2 flex items-center gap-2">
                    <Switch checked={newField.required} onCheckedChange={(checked) => setNewField(prev => ({ ...prev, required: checked }))} />
                    <Label>Required Field</Label>
                  </div>
                </div>
                <Button className="mt-4" onClick={handleAddCustomField}>
                  <Plus className="size-4 mr-2" />
                  Add Field
                </Button>
              </div>

              <div className="flex gap-2 pt-4">
                <Button variant="outline" className="flex-1" onClick={() => setFormEditorOpen(false)}>
                  Cancel
                </Button>
                <Button className="flex-1" onClick={handleSaveApplicationForm} disabled={isLoading}>
                  {isLoading && <Loader2 className="size-4 mr-2 animate-spin" />}
                  <Save className="size-4 mr-2" />
                  Save Form
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}