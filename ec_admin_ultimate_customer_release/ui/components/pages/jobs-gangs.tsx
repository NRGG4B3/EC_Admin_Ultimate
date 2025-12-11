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
  Briefcase, Users, Crown, Shield, Plus, Search, DollarSign, Eye, 
  Edit, Trash2, UserPlus, UserMinus, MapPin, Target, RefreshCw, 
  AlertTriangle, CheckCircle, Ban, Building, TrendingUp, TrendingDown,
  ArrowUp, ArrowDown, Wallet, Settings
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';

interface JobsGangsPageProps {
  liveData: any;
}

interface Job {
  name: string;
  label: string;
  totalEmployees: number;
  onlineEmployees: number;
  whitelisted: boolean;
  societyMoney: number;
  type: string;
  grades: any;
}

interface Employee {
  identifier: string;
  citizenid?: string;
  name: string;
  job: string;
  grade: string;
  gradeLevel: number;
  salary: number;
  hired: string;
  online: boolean;
}

interface Gang {
  name: string;
  label: string;
  totalMembers: number;
  onlineMembers: number;
  leader: string;
  territory: string;
  reputation: number;
  color: string;
  grades: any;
  balance: number;
}

interface GangMember {
  identifier: string;
  citizenid?: string;
  name: string;
  gang: string;
  rank: string;
  rankLevel: number;
  joined: string;
  online: boolean;
}

interface JobsGangsData {
  jobs: Job[];
  gangs: Gang[];
  employees: Employee[];
  gangMembers: GangMember[];
  stats: {
    totalJobs: number;
    totalEmployees: number;
    totalGangs: number;
    totalGangMembers: number;
    onlineEmployees: number;
    onlineGangMembers: number;
  };
  framework: string;
}

export function JobsGangsPage({ liveData }: JobsGangsPageProps) {
  const [activeTab, setActiveTab] = useState('jobs');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [data, setData] = useState<JobsGangsData | null>(null);
  const [selectedJob, setSelectedJob] = useState<Job | null>(null);
  const [selectedGang, setSelectedGang] = useState<Gang | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  // Modals
  const [employeeModal, setEmployeeModal] = useState<{ 
    isOpen: boolean; 
    action: 'hire' | 'promote' | 'demote' | 'fire' | null;
    employee?: Employee;
  }>({ isOpen: false, action: null });
  
  const [gangModal, setGangModal] = useState<{ 
    isOpen: boolean; 
    action: 'recruit' | 'promote' | 'demote' | 'remove' | null;
    member?: GangMember;
  }>({ isOpen: false, action: null });
  
  const [moneyModal, setMoneyModal] = useState<{ 
    isOpen: boolean; 
    type: 'job' | 'gang' | null;
    target?: Job | Gang;
  }>({ isOpen: false, type: null });

  const [createJobModal, setCreateJobModal] = useState(false);
  const [createGangModal, setCreateGangModal] = useState(false);
  const [deleteConfirmModal, setDeleteConfirmModal] = useState<{
    isOpen: boolean;
    type: 'job' | 'gang' | null;
    target?: Job | Gang;
  }>({ isOpen: false, type: null });

  const [formData, setFormData] = useState<any>({});

  // Fetch jobs & gangs data from FiveM
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:getData', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          setData(result.data);
        }
      }
    } catch (error) {
      console.log('[Jobs & Gangs] Not in FiveM environment');
    }
  }, []);

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

  // Hire employee
  const handleHireEmployee = async () => {
    if (!formData.playerId || !formData.jobName) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:hirePlayer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.playerId),
          jobName: formData.jobName,
          gradeLevel: parseInt(formData.gradeLevel) || 0
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setEmployeeModal({ isOpen: false, action: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to hire employee' });
    }
  };

  // Promote employee
  const handlePromoteEmployee = async () => {
    if (!employeeModal.employee) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:promoteEmployee', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.playerId),
          newGrade: parseInt(formData.newGrade)
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setEmployeeModal({ isOpen: false, action: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to promote employee' });
    }
  };

  // Demote employee
  const handleDemoteEmployee = async () => {
    if (!employeeModal.employee) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:demoteEmployee', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.playerId),
          newGrade: parseInt(formData.newGrade)
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setEmployeeModal({ isOpen: false, action: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to demote employee' });
    }
  };

  // Fire employee
  const handleFireEmployee = async () => {
    if (!employeeModal.employee) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:fireEmployee', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.playerId),
          reason: formData.reason || 'No reason provided'
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setEmployeeModal({ isOpen: false, action: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to fire employee' });
    }
  };

  // Recruit gang member
  const handleRecruitMember = async () => {
    if (!formData.playerId || !formData.gangName) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:recruitGangMember', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.playerId),
          gangName: formData.gangName,
          rankLevel: parseInt(formData.rankLevel) || 0
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setGangModal({ isOpen: false, action: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to recruit member' });
    }
  };

  // Promote gang member
  const handlePromoteMember = async () => {
    if (!gangModal.member) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:promoteGangMember', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.playerId),
          newRank: parseInt(formData.newRank)
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setGangModal({ isOpen: false, action: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to promote member' });
    }
  };

  // Demote gang member
  const handleDemoteMember = async () => {
    if (!gangModal.member) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:demoteGangMember', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.playerId),
          newRank: parseInt(formData.newRank)
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setGangModal({ isOpen: false, action: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to demote member' });
    }
  };

  // Remove gang member
  const handleRemoveMember = async () => {
    if (!gangModal.member) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:removeGangMember', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.playerId),
          reason: formData.reason || 'No reason provided'
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setGangModal({ isOpen: false, action: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to remove member' });
    }
  };

  // Manage society money
  const handleManageMoney = async () => {
    if (!moneyModal.target || !formData.amount) return;

    const endpoint = moneyModal.type === 'job' 
      ? 'jobs-gangs:setSocietyMoney' 
      : 'jobs-gangs:setGangMoney';

    try {
      const response = await fetch(`https://ec_admin_ultimate/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          [moneyModal.type === 'job' ? 'jobName' : 'gangName']: (moneyModal.target as any).name,
          amount: parseInt(formData.amount)
        })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          toastSuccess(result.message);
          setMoneyModal({ isOpen: false, type: null });
          setFormData({});
          await fetchData();
        } else {
          toastError(result.message);
        }
      }
    } catch (error) {
      toastError({ title: 'Failed to manage money' });
    }
  };

  // Create Job
  const handleCreateJob = async () => {
    if (!formData.jobName || !formData.jobLabel) {
      toastError({ title: 'Job name and label are required' });
      return;
    }

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:createJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.jobName,
          label: formData.jobLabel,
          type: formData.jobType || 'none'
        })
      });

      if (response.ok) {
        toastSuccess({ title: 'Job created successfully!' });
        setCreateJobModal(false);
        setFormData({});
        await fetchData();
      }
    } catch (error) {
      toastError({ title: 'Failed to create job' });
    }
  };

  // Delete Job
  const handleDeleteJob = async () => {
    if (!deleteConfirmModal.target) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:deleteJob', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: (deleteConfirmModal.target as Job).name
        })
      });

      if (response.ok) {
        toastSuccess({ title: 'Job deleted successfully!' });
        setDeleteConfirmModal({ isOpen: false, type: null });
        setSelectedJob(null);
        setActiveTab('jobs');
        await fetchData();
      }
    } catch (error) {
      toastError({ title: 'Failed to delete job' });
    }
  };

  // Create Gang
  const handleCreateGang = async () => {
    if (!formData.gangName || !formData.gangLabel) {
      toastError({ title: 'Gang name and label are required' });
      return;
    }

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:createGang', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.gangName,
          label: formData.gangLabel
        })
      });

      if (response.ok) {
        toastSuccess({ title: 'Gang created successfully!' });
        setCreateGangModal(false);
        setFormData({});
        await fetchData();
      }
    } catch (error) {
      toastError({ title: 'Failed to create gang' });
    }
  };

  // Delete Gang
  const handleDeleteGang = async () => {
    if (!deleteConfirmModal.target) return;

    try {
      const response = await fetch('https://ec_admin_ultimate/jobs-gangs:deleteGang', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: (deleteConfirmModal.target as Gang).name
        })
      });

      if (response.ok) {
        toastSuccess({ title: 'Gang deleted successfully!' });
        setDeleteConfirmModal({ isOpen: false, type: null });
        setSelectedGang(null);
        setActiveTab('gangs');
        await fetchData();
      }
    } catch (error) {
      toastError({ title: 'Failed to delete gang' });
    }
  };

  // Format currency
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  // Get data from state
  const jobs = data?.jobs || [];
  const gangs = data?.gangs || [];
  const employees = data?.employees || [];
  const gangMembers = data?.gangMembers || [];
  const stats = data?.stats || {
    totalJobs: 0,
    totalEmployees: 0,
    totalGangs: 0,
    totalGangMembers: 0,
    onlineEmployees: 0,
    onlineGangMembers: 0
  };
  const framework = data?.framework || 'Unknown';

  // Filter data
  const filteredJobs = jobs.filter(j => 
    j.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
    j.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredGangs = gangs.filter(g => 
    g.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
    g.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const selectedEmployees = selectedJob 
    ? employees.filter(e => e.job === selectedJob.name)
    : [];

  const selectedGangMembers = selectedGang 
    ? gangMembers.filter(m => m.gang === selectedGang.name)
    : [];

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Briefcase className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading Jobs & Gangs...</p>
          <p className="text-sm text-muted-foreground">Fetching employment data</p>
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
            <Briefcase className="size-8 text-primary" />
            Jobs & Gangs Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage server jobs and gangs • Framework: {framework}
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
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-500/10 rounded-lg">
                <Briefcase className="size-6 text-blue-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Jobs</p>
                <p className="text-xl font-bold">{stats.totalJobs}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-500/10 rounded-lg">
                <Users className="size-6 text-green-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Employees</p>
                <p className="text-xl font-bold">{stats.totalEmployees}</p>
                <p className="text-xs text-muted-foreground">{stats.onlineEmployees} online</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-purple-500/10 rounded-lg">
                <Crown className="size-6 text-purple-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Gangs</p>
                <p className="text-xl font-bold">{stats.totalGangs}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-orange-500/10 rounded-lg">
                <Shield className="size-6 text-orange-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Gang Members</p>
                <p className="text-xl font-bold">{stats.totalGangMembers}</p>
                <p className="text-xs text-muted-foreground">{stats.onlineGangMembers} online</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="jobs" className="flex items-center gap-2">
            <Briefcase className="size-4" />
            Jobs
          </TabsTrigger>
          <TabsTrigger value="job-details" className="flex items-center gap-2" disabled={!selectedJob}>
            <Building className="size-4" />
            Job Details
          </TabsTrigger>
          <TabsTrigger value="gangs" className="flex items-center gap-2">
            <Crown className="size-4" />
            Gangs
          </TabsTrigger>
          <TabsTrigger value="gang-details" className="flex items-center gap-2" disabled={!selectedGang}>
            <Shield className="size-4" />
            Gang Details
          </TabsTrigger>
        </TabsList>

        {/* Jobs Tab */}
        <TabsContent value="jobs" className="space-y-4 mt-6">
          {/* Search */}
          <div className="flex items-center gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                placeholder="Search jobs..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9"
              />
            </div>
            <Button onClick={() => setCreateJobModal(true)}>
              <Plus className="size-4 mr-2" />
              Create Job
            </Button>
          </div>

          {/* Jobs Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredJobs.length === 0 ? (
              <div className="col-span-full text-center py-12 text-muted-foreground">
                <Briefcase className="size-8 mx-auto mb-2 opacity-50" />
                <p>No jobs found</p>
              </div>
            ) : (
              filteredJobs.map((job) => (
                <Card key={job.name} className="hover:shadow-lg transition-shadow cursor-pointer">
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div>
                        <CardTitle className="text-lg">{job.label}</CardTitle>
                        <p className="text-sm text-muted-foreground mt-1">{job.type}</p>
                      </div>
                      {job.whitelisted && (
                        <Badge variant="secondary">
                          <Shield className="size-3 mr-1" />
                          Whitelisted
                        </Badge>
                      )}
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-3">
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Employees</span>
                      <span className="font-bold">{job.totalEmployees} ({job.onlineEmployees} online)</span>
                    </div>
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Society Money</span>
                      <span className="font-bold text-green-600">{formatCurrency(job.societyMoney)}</span>
                    </div>
                    <div className="flex gap-2 pt-2">
                      <Button 
                        variant="outline" 
                        size="sm" 
                        className="flex-1"
                        onClick={() => {
                          setSelectedJob(job);
                          setActiveTab('job-details');
                        }}
                      >
                        <Eye className="size-4 mr-1" />
                        View
                      </Button>
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => setMoneyModal({ isOpen: true, type: 'job', target: job })}
                      >
                        <Wallet className="size-4" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Job Details Tab */}
        <TabsContent value="job-details" className="space-y-4 mt-6">
          {selectedJob && (
            <>
              {/* Job Info */}
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="text-2xl">{selectedJob.label}</CardTitle>
                      <CardDescription>{selectedJob.type} • {selectedJob.name}</CardDescription>
                    </div>
                    <div className="flex gap-2">
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => setMoneyModal({ isOpen: true, type: 'job', target: selectedJob })}
                      >
                        <Wallet className="size-4 mr-2" />
                        Manage Money
                      </Button>
                      <Button 
                        variant="destructive" 
                        size="sm"
                        onClick={() => handleFireAll(selectedJob)}
                      >
                        <Trash2 className="size-4 mr-2" />
                        Fire All
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-3 gap-4">
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Total Employees</p>
                      <p className="text-2xl font-bold">{selectedJob.totalEmployees}</p>
                    </div>
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Online</p>
                      <p className="text-2xl font-bold text-green-600">{selectedJob.onlineEmployees}</p>
                    </div>
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Society Balance</p>
                      <p className="text-2xl font-bold">{formatCurrency(selectedJob.societyMoney)}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Employees List */}
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle>Employees ({selectedEmployees.length})</CardTitle>
                    <Button 
                      size="sm"
                      onClick={() => setEmployeeModal({ isOpen: true, action: 'hire' })}
                    >
                      <UserPlus className="size-4 mr-2" />
                      Hire Employee
                    </Button>
                  </div>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-[400px]">
                    <div className="space-y-2">
                      {selectedEmployees.length === 0 ? (
                        <div className="text-center py-12 text-muted-foreground">
                          <Users className="size-8 mx-auto mb-2 opacity-50" />
                          <p>No employees</p>
                        </div>
                      ) : (
                        selectedEmployees.map((employee) => (
                          <div 
                            key={employee.identifier}
                            className="flex items-center justify-between p-4 ec-card-transparent border border-border/30 rounded-lg"
                          >
                            <div className="flex items-center gap-4">
                              <div className={`p-2 rounded ${employee.online ? 'bg-green-500/10' : 'bg-gray-500/10'}`}>
                                <Users className={`size-4 ${employee.online ? 'text-green-500' : 'text-gray-500'}`} />
                              </div>
                              <div>
                                <p className="font-medium">{employee.name}</p>
                                <p className="text-sm text-muted-foreground">
                                  {employee.grade} (Grade {employee.gradeLevel}) • ${employee.salary}/hr
                                </p>
                              </div>
                            </div>
                            <div className="flex gap-2">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setEmployeeModal({ isOpen: true, action: 'promote', employee })}
                              >
                                <ArrowUp className="size-4" />
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setEmployeeModal({ isOpen: true, action: 'demote', employee })}
                              >
                                <ArrowDown className="size-4" />
                              </Button>
                              <Button
                                variant="destructive"
                                size="sm"
                                onClick={() => setEmployeeModal({ isOpen: true, action: 'fire', employee })}
                              >
                                <Trash2 className="size-4" />
                              </Button>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </>
          )}
        </TabsContent>

        {/* Gangs Tab */}
        <TabsContent value="gangs" className="space-y-4 mt-6">
          {/* Search */}
          <div className="flex items-center gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                placeholder="Search gangs..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9"
              />
            </div>
            <Button onClick={() => setCreateGangModal(true)}>
              <Plus className="size-4 mr-2" />
              Create Gang
            </Button>
          </div>

          {/* Gangs Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredGangs.length === 0 ? (
              <div className="col-span-full text-center py-12 text-muted-foreground">
                <Crown className="size-8 mx-auto mb-2 opacity-50" />
                <p>No gangs found</p>
              </div>
            ) : (
              filteredGangs.map((gang) => (
                <Card key={gang.name} className="hover:shadow-lg transition-shadow cursor-pointer">
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div>
                        <CardTitle className="text-lg">{gang.label}</CardTitle>
                        <p className="text-sm text-muted-foreground mt-1">Leader: {gang.leader}</p>
                      </div>
                      <Badge style={{ backgroundColor: gang.color.toLowerCase() }}>
                        {gang.color}
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-3">
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Members</span>
                      <span className="font-bold">{gang.totalMembers} ({gang.onlineMembers} online)</span>
                    </div>
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Reputation</span>
                      <span className="font-bold">{gang.reputation}</span>
                    </div>
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Balance</span>
                      <span className="font-bold text-green-600">{formatCurrency(gang.balance)}</span>
                    </div>
                    <div className="flex gap-2 pt-2">
                      <Button 
                        variant="outline" 
                        size="sm" 
                        className="flex-1"
                        onClick={() => {
                          setSelectedGang(gang);
                          setActiveTab('gang-details');
                        }}
                      >
                        <Eye className="size-4 mr-1" />
                        View
                      </Button>
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => setMoneyModal({ isOpen: true, type: 'gang', target: gang })}
                      >
                        <Wallet className="size-4" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Gang Details Tab */}
        <TabsContent value="gang-details" className="space-y-4 mt-6">
          {selectedGang && (
            <>
              {/* Gang Info */}
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="text-2xl">{selectedGang.label}</CardTitle>
                      <CardDescription>Leader: {selectedGang.leader} • Color: {selectedGang.color}</CardDescription>
                    </div>
                    <div className="flex gap-2">
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => setMoneyModal({ isOpen: true, type: 'gang', target: selectedGang })}
                      >
                        <Wallet className="size-4 mr-2" />
                        Manage Money
                      </Button>
                      <Button 
                        variant="destructive" 
                        size="sm"
                        onClick={() => handleDisbandGang(selectedGang)}
                      >
                        <Ban className="size-4 mr-2" />
                        Disband Gang
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-4 gap-4">
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Total Members</p>
                      <p className="text-2xl font-bold">{selectedGang.totalMembers}</p>
                    </div>
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Online</p>
                      <p className="text-2xl font-bold text-green-600">{selectedGang.onlineMembers}</p>
                    </div>
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Reputation</p>
                      <p className="text-2xl font-bold">{selectedGang.reputation}</p>
                    </div>
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Balance</p>
                      <p className="text-2xl font-bold">{formatCurrency(selectedGang.balance)}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Gang Members List */}
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle>Members ({selectedGangMembers.length})</CardTitle>
                    <Button 
                      size="sm"
                      onClick={() => setGangModal({ isOpen: true, action: 'recruit' })}
                    >
                      <UserPlus className="size-4 mr-2" />
                      Recruit Member
                    </Button>
                  </div>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-[400px]">
                    <div className="space-y-2">
                      {selectedGangMembers.length === 0 ? (
                        <div className="text-center py-12 text-muted-foreground">
                          <Users className="size-8 mx-auto mb-2 opacity-50" />
                          <p>No members</p>
                        </div>
                      ) : (
                        selectedGangMembers.map((member) => (
                          <div 
                            key={member.identifier}
                            className="flex items-center justify-between p-4 ec-card-transparent border border-border/30 rounded-lg"
                          >
                            <div className="flex items-center gap-4">
                              <div className={`p-2 rounded ${member.online ? 'bg-green-500/10' : 'bg-gray-500/10'}`}>
                                <Shield className={`size-4 ${member.online ? 'text-green-500' : 'text-gray-500'}`} />
                              </div>
                              <div>
                                <p className="font-medium">{member.name}</p>
                                <p className="text-sm text-muted-foreground">
                                  {member.rank} (Rank {member.rankLevel})
                                </p>
                              </div>
                            </div>
                            <div className="flex gap-2">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setGangModal({ isOpen: true, action: 'promote', member })}
                              >
                                <ArrowUp className="size-4" />
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setGangModal({ isOpen: true, action: 'demote', member })}
                              >
                                <ArrowDown className="size-4" />
                              </Button>
                              <Button
                                variant="destructive"
                                size="sm"
                                onClick={() => setGangModal({ isOpen: true, action: 'remove', member })}
                              >
                                <UserMinus className="size-4" />
                              </Button>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </>
          )}
        </TabsContent>
      </Tabs>

      {/* Employee Modal */}
      <Dialog open={employeeModal.isOpen} onOpenChange={(open) => !open && setEmployeeModal({ isOpen: false, action: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {employeeModal.action === 'hire' && 'Hire Employee'}
              {employeeModal.action === 'promote' && 'Promote Employee'}
              {employeeModal.action === 'demote' && 'Demote Employee'}
              {employeeModal.action === 'fire' && 'Fire Employee'}
            </DialogTitle>
            <DialogDescription>
              {employeeModal.employee && `Managing ${employeeModal.employee.name}`}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {employeeModal.action === 'hire' && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="playerId">Player ID</Label>
                  <Input
                    id="playerId"
                    type="number"
                    placeholder="Enter player ID"
                    value={formData.playerId || ''}
                    onChange={(e) => setFormData({ ...formData, playerId: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="jobName">Job Name</Label>
                  <Input
                    id="jobName"
                    placeholder="e.g. police"
                    value={formData.jobName || ''}
                    onChange={(e) => setFormData({ ...formData, jobName: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="gradeLevel">Grade Level</Label>
                  <Input
                    id="gradeLevel"
                    type="number"
                    placeholder="0"
                    value={formData.gradeLevel || ''}
                    onChange={(e) => setFormData({ ...formData, gradeLevel: e.target.value })}
                  />
                </div>
              </>
            )}

            {(employeeModal.action === 'promote' || employeeModal.action === 'demote') && employeeModal.employee && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="playerId">Player ID</Label>
                  <Input
                    id="playerId"
                    type="number"
                    placeholder="Enter player ID"
                    value={formData.playerId || ''}
                    onChange={(e) => setFormData({ ...formData, playerId: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="newGrade">New Grade Level</Label>
                  <Input
                    id="newGrade"
                    type="number"
                    placeholder={`Current: ${employeeModal.employee.gradeLevel}`}
                    value={formData.newGrade || ''}
                    onChange={(e) => setFormData({ ...formData, newGrade: e.target.value })}
                  />
                </div>
              </>
            )}

            {employeeModal.action === 'fire' && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="playerId">Player ID</Label>
                  <Input
                    id="playerId"
                    type="number"
                    placeholder="Enter player ID"
                    value={formData.playerId || ''}
                    onChange={(e) => setFormData({ ...formData, playerId: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="reason">Reason</Label>
                  <Textarea
                    id="reason"
                    placeholder="Enter reason for firing"
                    value={formData.reason || ''}
                    onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                  />
                </div>
              </>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEmployeeModal({ isOpen: false, action: null })}>
              Cancel
            </Button>
            <Button 
              onClick={() => {
                if (employeeModal.action === 'hire') handleHireEmployee();
                else if (employeeModal.action === 'promote') handlePromoteEmployee();
                else if (employeeModal.action === 'demote') handleDemoteEmployee();
                else if (employeeModal.action === 'fire') handleFireEmployee();
              }}
            >
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Gang Modal */}
      <Dialog open={gangModal.isOpen} onOpenChange={(open) => !open && setGangModal({ isOpen: false, action: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {gangModal.action === 'recruit' && 'Recruit Gang Member'}
              {gangModal.action === 'promote' && 'Promote Gang Member'}
              {gangModal.action === 'demote' && 'Demote Gang Member'}
              {gangModal.action === 'remove' && 'Remove Gang Member'}
            </DialogTitle>
            <DialogDescription>
              {gangModal.member && `Managing ${gangModal.member.name}`}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {gangModal.action === 'recruit' && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="playerId">Player ID</Label>
                  <Input
                    id="playerId"
                    type="number"
                    placeholder="Enter player ID"
                    value={formData.playerId || ''}
                    onChange={(e) => setFormData({ ...formData, playerId: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="gangName">Gang Name</Label>
                  <Input
                    id="gangName"
                    placeholder="e.g. ballas"
                    value={formData.gangName || ''}
                    onChange={(e) => setFormData({ ...formData, gangName: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="rankLevel">Rank Level</Label>
                  <Input
                    id="rankLevel"
                    type="number"
                    placeholder="0"
                    value={formData.rankLevel || ''}
                    onChange={(e) => setFormData({ ...formData, rankLevel: e.target.value })}
                  />
                </div>
              </>
            )}

            {(gangModal.action === 'promote' || gangModal.action === 'demote') && gangModal.member && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="playerId">Player ID</Label>
                  <Input
                    id="playerId"
                    type="number"
                    placeholder="Enter player ID"
                    value={formData.playerId || ''}
                    onChange={(e) => setFormData({ ...formData, playerId: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="newRank">New Rank Level</Label>
                  <Input
                    id="newRank"
                    type="number"
                    placeholder={`Current: ${gangModal.member.rankLevel}`}
                    value={formData.newRank || ''}
                    onChange={(e) => setFormData({ ...formData, newRank: e.target.value })}
                  />
                </div>
              </>
            )}

            {gangModal.action === 'remove' && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="playerId">Player ID</Label>
                  <Input
                    id="playerId"
                    type="number"
                    placeholder="Enter player ID"
                    value={formData.playerId || ''}
                    onChange={(e) => setFormData({ ...formData, playerId: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="reason">Reason</Label>
                  <Textarea
                    id="reason"
                    placeholder="Enter reason for removal"
                    value={formData.reason || ''}
                    onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                  />
                </div>
              </>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setGangModal({ isOpen: false, action: null })}>
              Cancel
            </Button>
            <Button 
              onClick={() => {
                if (gangModal.action === 'recruit') handleRecruitMember();
                else if (gangModal.action === 'promote') handlePromoteMember();
                else if (gangModal.action === 'demote') handleDemoteMember();
                else if (gangModal.action === 'remove') handleRemoveMember();
              }}
            >
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Money Management Modal */}
      <Dialog open={moneyModal.isOpen} onOpenChange={(open) => !open && setMoneyModal({ isOpen: false, type: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Manage {moneyModal.type === 'job' ? 'Society' : 'Gang'} Money</DialogTitle>
            <DialogDescription>
              {moneyModal.target && `Managing ${(moneyModal.target as any).label}`}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="action">Action</Label>
              <Select
                value={formData.action || 'add'}
                onValueChange={(value) => setFormData({ ...formData, action: value })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select action" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="add">Add Money</SelectItem>
                  <SelectItem value="remove">Remove Money</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="amount">Amount</Label>
              <Input
                id="amount"
                type="number"
                placeholder="Enter amount"
                value={formData.amount || ''}
                onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="reason">Reason</Label>
              <Textarea
                id="reason"
                placeholder="Enter reason"
                value={formData.reason || ''}
                onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setMoneyModal({ isOpen: false, type: null })}>
              Cancel
            </Button>
            <Button onClick={handleManageMoney}>
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Create Job Modal */}
      <Dialog open={createJobModal} onOpenChange={(open) => !open && setCreateJobModal(false)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Job</DialogTitle>
            <DialogDescription>
              Add a new job to the server
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="jobName">Job Name</Label>
              <Input
                id="jobName"
                placeholder="e.g. police"
                value={formData.jobName || ''}
                onChange={(e) => setFormData({ ...formData, jobName: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="jobLabel">Job Label</Label>
              <Input
                id="jobLabel"
                placeholder="e.g. Police Department"
                value={formData.jobLabel || ''}
                onChange={(e) => setFormData({ ...formData, jobLabel: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="jobType">Job Type</Label>
              <Select
                value={formData.jobType || 'none'}
                onValueChange={(value) => setFormData({ ...formData, jobType: value })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">None</SelectItem>
                  <SelectItem value="government">Government</SelectItem>
                  <SelectItem value="private">Private</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setCreateJobModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateJob}>
              Create
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Job Modal */}
      <Dialog open={deleteConfirmModal.isOpen && deleteConfirmModal.type === 'job'} onOpenChange={(open) => !open && setDeleteConfirmModal({ isOpen: false, type: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Job</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this job?
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="jobName">Job Name</Label>
              <Input
                id="jobName"
                placeholder="e.g. police"
                value={deleteConfirmModal.target ? (deleteConfirmModal.target as Job).name : ''}
                readOnly
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirmModal({ isOpen: false, type: null })}>
              Cancel
            </Button>
            <Button onClick={handleDeleteJob} variant="destructive">
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Create Gang Modal */}
      <Dialog open={createGangModal} onOpenChange={(open) => !open && setCreateGangModal(false)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Gang</DialogTitle>
            <DialogDescription>
              Add a new gang to the server
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="gangName">Gang Name</Label>
              <Input
                id="gangName"
                placeholder="e.g. ballas"
                value={formData.gangName || ''}
                onChange={(e) => setFormData({ ...formData, gangName: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="gangLabel">Gang Label</Label>
              <Input
                id="gangLabel"
                placeholder="e.g. Ballas"
                value={formData.gangLabel || ''}
                onChange={(e) => setFormData({ ...formData, gangLabel: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setCreateGangModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateGang}>
              Create
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Gang Modal */}
      <Dialog open={deleteConfirmModal.isOpen && deleteConfirmModal.type === 'gang'} onOpenChange={(open) => !open && setDeleteConfirmModal({ isOpen: false, type: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Gang</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this gang?
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="gangName">Gang Name</Label>
              <Input
                id="gangName"
                placeholder="e.g. ballas"
                value={deleteConfirmModal.target ? (deleteConfirmModal.target as Gang).name : ''}
                readOnly
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirmModal({ isOpen: false, type: null })}>
              Cancel
            </Button>
            <Button onClick={handleDeleteGang} variant="destructive">
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}