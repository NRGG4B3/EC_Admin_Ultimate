import { useState, useEffect } from 'react';
import { fetchNui } from '../nui-bridge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { 
  Dialog, DialogContent, DialogDescription, DialogFooter, 
  DialogHeader, DialogTitle 
} from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Textarea } from '../ui/textarea';
import { Progress } from '../ui/progress';
import { ScrollArea } from '../ui/scroll-area';
import { Checkbox } from '../ui/checkbox';
import { 
  Car, Plus, Search, Settings, MapPin, Trash2, Eye, Edit, Key, 
  AlertTriangle, Zap, Archive, Wrench, Fuel, Paintbrush, Cog,
  Tag, Send, Lock, Unlock, RotateCcw, Filter, Download,
  TrendingUp, DollarSign, Users, Package, Gauge, Navigation,
  X, Check, FileText, Calendar, Clock, Sliders, History,
  Activity, ShoppingBag, Wallet, Radar, Radio, Sparkles, Rocket
} from 'lucide-react';
import { toast } from 'sonner';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../ui/dropdown-menu';

interface VehiclesPageProps {
  liveData: any;
}

interface Vehicle {
  id: number;
  model: string;
  plate: string;
  owner: string;
  ownerId?: string;
  citizenid?: string;
  location: string;
  garage?: string;
  health: number;
  bodyHealth: number;
  engineHealth: number;
  fuel: number;
  locked: boolean;
  type: string;
  class: string;
  spawned: boolean;
  impounded: boolean;
  impoundReason?: string;
  stored: boolean;
  mods?: {
    engine: number;
    transmission: number;
    turbo: boolean;
    brakes: number;
    suspension: number;
  };
  color?: { primary: string; secondary: string };
  value?: number;
  purchaseDate?: string;
  lastUsed?: string;
  mileage?: number;
  state?: number;
  coords?: { x: number; y: number; z: number };
}

interface VehicleStats {
  totalVehicles: number;
  spawnedVehicles: number;
  ownedVehicles: number;
  impoundedVehicles: number;
  totalValue: number;
}

export function VehiclesPage({ liveData }: VehiclesPageProps) {
  const [activeTab, setActiveTab] = useState('all');
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [stats, setStats] = useState<VehicleStats>({
    totalVehicles: 0,
    spawnedVehicles: 0,
    ownedVehicles: 0,
    impoundedVehicles: 0,
    totalValue: 0
  });
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null);
  const [selectedVehicles, setSelectedVehicles] = useState<Set<number>>(new Set());
  const [actionModal, setActionModal] = useState<{
    isOpen: boolean;
    action: 'spawn' | 'delete' | 'repair' | 'refuel' | 'impound' | 'unimpound' | 'teleport' | 'details' | 'rename' | 'color' | 'upgrade' | 'transfer' | 'store' | 'add' | 'quickspawn' | null;
  }>({ isOpen: false, action: null });
  const [formData, setFormData] = useState<any>({});
  const [filterType, setFilterType] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [expandedRows, setExpandedRows] = useState<Set<number>>(new Set());
  
  // Available vehicles for spawning (all FiveM defaults + custom packs)
  const [availableVehicles, setAvailableVehicles] = useState<any[]>([]);
  const [vehicleSearchTerm, setVehicleSearchTerm] = useState('');
  const [vehicleClassFilter, setVehicleClassFilter] = useState('all');
  const [isLoadingVehicles, setIsLoadingVehicles] = useState(false);

  // Popular vehicles for quick add
  const popularVehicles = [
    { model: 't20', name: 'T20', class: 'Super' },
    { model: 'adder', name: 'Adder', class: 'Super' },
    { model: 'zentorno', name: 'Zentorno', class: 'Super' },
    { model: 'turismor', name: 'Turismo R', class: 'Super' },
    { model: 'osiris', name: 'Osiris', class: 'Super' },
    { model: 'elegy', name: 'Elegy RH8', class: 'Sports' },
    { model: 'jester', name: 'Jester', class: 'Sports' },
    { model: 'massacro', name: 'Massacro', class: 'Sports' },
    { model: 'kuruma', name: 'Kuruma', class: 'Sports' },
    { model: 'dominator', name: 'Dominator', class: 'Muscle' },
    { model: 'gauntlet', name: 'Gauntlet', class: 'Muscle' },
    { model: 'buffalo', name: 'Buffalo', class: 'Sports' },
    { model: 'sultan', name: 'Sultan', class: 'Sports' },
    { model: 'futo', name: 'Futo', class: 'Sports' },
    { model: 'bati', name: 'Bati 801', class: 'Motorcycles' },
    { model: 'akuma', name: 'Akuma', class: 'Motorcycles' },
    { model: 'sanchez', name: 'Sanchez', class: 'Motorcycles' },
    { model: 'bmx', name: 'BMX', class: 'Cycles' },
  ];

  // Load all available vehicles for spawning (strict NUI)
  useEffect(() => {
    const loadAvailableVehicles = async () => {
      setIsLoadingVehicles(true);
      
      try {
        const data = await fetchNui<{ success: boolean; vehicles: any[]; customCount: number }>('getAllVehicles', {}, { success: true, vehicles: [], customCount: 0 });
        if (data && data.success && Array.isArray(data.vehicles)) {
          console.log('[Vehicles] Loaded ' + data.vehicles.length + ' available vehicles (' + (data.customCount || 0) + ' custom)');
          setAvailableVehicles(data.vehicles);
        }
      } catch (error) {
        console.error('[Vehicles] Failed to load available vehicles:', error);
      } finally {
        setIsLoadingVehicles(false);
      }
    };
    
    loadAvailableVehicles();
  }, []);
  
  // Filter available vehicles for quick spawn modal
  const filteredAvailableVehicles = availableVehicles.filter(vehicle => {
    const matchesSearch = 
      vehicle.model.toLowerCase().includes(vehicleSearchTerm.toLowerCase()) ||
      vehicle.name.toLowerCase().includes(vehicleSearchTerm.toLowerCase());
    
    const matchesClass = vehicleClassFilter === 'all' || vehicle.class === vehicleClassFilter;
    
    return matchesSearch && matchesClass;
  });

  // Calculate stats from vehicles
  const calculateStats = (vehicleList: Vehicle[]): VehicleStats => {
    return {
      totalVehicles: vehicleList.length,
      spawnedVehicles: vehicleList.filter(v => v.spawned).length,
      ownedVehicles: vehicleList.length,
      impoundedVehicles: vehicleList.filter(v => v.impounded).length,
      totalValue: vehicleList.reduce((sum, v) => sum + (v.value || 0), 0)
    };
  };

  // Load vehicles (strict NUI - no mocks)
  useEffect(() => {
    const loadVehicles = async () => {
      setIsLoading(true);
      
      try {
        const data = await fetchNui<{ success: boolean; vehicles: Vehicle[]; stats?: VehicleStats; error?: string }>('getVehicles', {}, { success: true, vehicles: [], stats: { totalVehicles: 0, spawnedVehicles: 0, ownedVehicles: 0, impoundedVehicles: 0, totalValue: 0 } });
        if (data && data.success) {
          console.log('[Vehicles] Loaded ' + (data.vehicles?.length || 0) + ' vehicles');
          setVehicles(data.vehicles || []);
          setStats(data.stats || calculateStats(data.vehicles || []));
        } else {
          const errorMsg = data?.error || 'Failed to load vehicles';
          console.error('[Vehicles] CRITICAL ERROR:', errorMsg);
          toast.error(errorMsg);
          setVehicles([]);
          setStats({ totalVehicles: 0, spawnedVehicles: 0, ownedVehicles: 0, impoundedVehicles: 0, totalValue: 0 });
        }
      } catch (error) {
        console.error('[Vehicles] Failed to load vehicles:', error);
        toast.error('Failed to load vehicles. Check server connection.');
        // Show empty state on error
        setVehicles([]);
        setStats({
          totalVehicles: 0,
          spawnedVehicles: 0,
          ownedVehicles: 0,
          impoundedVehicles: 0,
          totalValue: 0
        });
      } finally {
        setIsLoading(false);
      }
    };

    loadVehicles();

    // Set up auto-refresh every 30 seconds (strict NUI)
    const refreshInterval = setInterval(async () => {
      try {
        const data = await fetchNui<{ success: boolean; vehicles: Vehicle[]; stats?: VehicleStats }>('getVehicles', {}, { success: true, vehicles: [], stats: { totalVehicles: 0, spawnedVehicles: 0, ownedVehicles: 0, impoundedVehicles: 0, totalValue: 0 } });
        if (data && data.success) {
          setVehicles(data.vehicles || []);
          setStats(data.stats || calculateStats(data.vehicles || []));
        }
      } catch (error) {
        console.error('[Vehicles] Auto-refresh failed:', error);
      }
    }, 30000);

    return () => clearInterval(refreshInterval);
  }, []);

  // Toggle row expansion
  const toggleRowExpansion = (vehicleId: number) => {
    setExpandedRows(prev => {
      const newSet = new Set(prev);
      if (newSet.has(vehicleId)) {
        newSet.delete(vehicleId);
      } else {
        newSet.add(vehicleId);
      }
      return newSet;
    });
  };

  // Toggle vehicle selection
  const toggleVehicleSelection = (vehicleId: number) => {
    setSelectedVehicles(prev => {
      const newSet = new Set(prev);
      if (newSet.has(vehicleId)) {
        newSet.delete(vehicleId);
      } else {
        newSet.add(vehicleId);
      }
      return newSet;
    });
  };

  // Format money
  const formatMoney = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  // Format date
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  // Filter vehicles
  const filteredVehicles = vehicles.filter(vehicle => {
    const matchesSearch = 
      vehicle.model.toLowerCase().includes(searchTerm.toLowerCase()) ||
      vehicle.plate.toLowerCase().includes(searchTerm.toLowerCase()) ||
      vehicle.owner.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesType = filterType === 'all' || vehicle.class.toLowerCase() === filterType.toLowerCase();
    
    const matchesStatus = 
      filterStatus === 'all' ||
      (filterStatus === 'spawned' && vehicle.spawned) ||
      (filterStatus === 'stored' && vehicle.stored) ||
      (filterStatus === 'impounded' && vehicle.impounded);

    let matchesTab = true;
    if (activeTab === 'spawned') matchesTab = vehicle.spawned;
    else if (activeTab === 'garaged') matchesTab = !vehicle.spawned && !vehicle.impounded;
    else if (activeTab === 'impounded') matchesTab = vehicle.impounded;

    return matchesSearch && matchesType && matchesStatus && matchesTab;
  });

  // Get parent resource name
  const GetParentResourceName = () => {
    if (typeof window !== 'undefined' && (window as any).GetParentResourceName) {
      return (window as any).GetParentResourceName();
    }
    return 'EC_admin_ultimate';
  };

  // Handle vehicle actions
  const handleAction = (action: typeof actionModal.action, vehicle: Vehicle | null = null) => {
    if (vehicle) {
      setSelectedVehicle(vehicle);
    }
    setActionModal({ isOpen: true, action });
    setFormData({
      newPlate: vehicle?.plate || '',
      primaryColor: vehicle?.color?.primary || '',
      secondaryColor: vehicle?.color?.secondary || '',
      engine: vehicle?.mods?.engine || 0,
      transmission: vehicle?.mods?.transmission || 0,
      turbo: vehicle?.mods?.turbo || false,
      brakes: vehicle?.mods?.brakes || 0,
      suspension: vehicle?.mods?.suspension || 0,
      reason: '',
      newOwner: '',
      model: '',
      plate: '',
      spawnModel: ''
    });
  };

  // Enhanced FiveM-integrated action execution
  const executeAction = async () => {
    if (!actionModal.action) return;

    // Real backend actions only (NO MOCKS)
    try {
      const actionEndpoints: Record<string, { callback: string, data: any }> = {
        spawn: { callback: 'spawnVehicle', data: { plate: selectedVehicle?.plate } },
        quickspawn: { callback: 'quickSpawnVehicle', data: { model: formData.spawnModel } },
        delete: { callback: 'deleteVehicle', data: { plate: selectedVehicle?.plate } },
        repair: { callback: 'repairVehicle', data: { plate: selectedVehicle?.plate } },
        refuel: { callback: 'refuelVehicle', data: { plate: selectedVehicle?.plate } },
        impound: { callback: 'impoundVehicle', data: { plate: selectedVehicle?.plate, reason: formData.reason || 'Admin impound' } },
        unimpound: { callback: 'unimpoundVehicle', data: { plate: selectedVehicle?.plate } },
        teleport: { callback: 'teleportToVehicle', data: { plate: selectedVehicle?.plate } },
        rename: { callback: 'renameVehicle', data: { oldPlate: selectedVehicle?.plate, newPlate: formData.newPlate } },
        color: { callback: 'changeVehicleColor', data: { plate: selectedVehicle?.plate, primaryColor: formData.primaryColor, secondaryColor: formData.secondaryColor } },
        upgrade: { callback: 'upgradeVehicle', data: { plate: selectedVehicle?.plate, mods: formData } },
        transfer: { callback: 'transferVehicle', data: { plate: selectedVehicle?.plate, newOwner: formData.newOwner } },
        store: { callback: 'storeVehicle', data: { plate: selectedVehicle?.plate } },
        add: { callback: 'addVehicle', data: { model: formData.model, plate: formData.plate, owner: formData.owner } }
      };

      const actionConfig = actionEndpoints[actionModal.action];
      if (!actionConfig) {
        toast.error('Unknown action');
        return;
      }

      console.log('[Vehicles] Executing action: ' + actionConfig.callback, actionConfig.data);

      // Check if we're in Figma/browser environment
      const isInGame = !!(window as any).GetParentResourceName;
      
      const result = await fetchNui<{ success: boolean; message?: string; error?: string }>(actionConfig.callback, actionConfig.data, { success: true });
      
      if (result.success) {
        toast.success(result.message || 'Action completed successfully');
        
        console.log('[Vehicles] Action completed, refreshing vehicle list...');
        
        const refreshData = await fetchNui<{ success: boolean; vehicles: Vehicle[]; stats?: VehicleStats }>('getVehicles', {}, { success: true, vehicles: [], stats: { totalVehicles: 0, spawnedVehicles: 0, ownedVehicles: 0, impoundedVehicles: 0, totalValue: 0 } });
        if (refreshData && refreshData.success) {
          setVehicles(refreshData.vehicles || []);
          setStats(refreshData.stats || calculateStats(refreshData.vehicles || []));
          console.log('[Vehicles] Refreshed: ' + (refreshData.vehicles?.length || 0) + ' vehicles loaded');
        }
      } else {
        toast.error(result.error || 'Action failed');
      }

      setActionModal({ isOpen: false, action: null });
      setSelectedVehicle(null);
    } catch (error) {
      console.error('[Vehicles] Action failed:', error);
      toast.error('Failed to execute action');
    }
  };

  // Enhanced bulk actions with FiveM integration
  const handleBulkAction = async (action: 'repair' | 'refuel' | 'delete' | 'impound' | 'store') => {
    if (selectedVehicles.size === 0) {
      toast.error('No vehicles selected');
      return;
    }

    const vehicleList = Array.from(selectedVehicles)
      .map(id => vehicles.find(v => v.id === id))
      .filter((v): v is Vehicle => v !== undefined);
    
    // Real bulk action only (NO MOCKS)
    try {
      console.log('[Vehicles] Executing bulk ' + action + ' on ' + vehicleList.length + ' vehicles');
      
      const bulkActionMap: Record<string, string> = {
        repair: 'repairVehicle',
        refuel: 'refuelVehicle',
        delete: 'deleteVehicle',
        impound: 'impoundVehicle',
        store: 'storeVehicle'
      };

      const callback = bulkActionMap[action];
      // @ts-ignore
      const resourceName = (window as any).GetParentResourceName?.() || 'ec_admin_ultimate';
      
      const promises = vehicleList.map(vehicle => 
        fetch('https://' + resourceName + '/' + callback, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            plate: vehicle.plate,
            reason: action === 'impound' ? 'Bulk admin action' : undefined
          })
        })
      );

      const results = await Promise.allSettled(promises);
      const successful = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.length - successful;

      if (failed > 0) {
        toast.error(action.charAt(0).toUpperCase() + action.slice(1) + ' completed on ' + successful + '/' + results.length + ' vehicles (' + failed + ' failed)');
      } else {
        toast.success(action.charAt(0).toUpperCase() + action.slice(1) + ' completed on ' + successful + ' vehicles');
      }

      // Refresh vehicle list
      const refreshResponse = await fetch('https://' + resourceName + '/getVehicles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      const refreshData = await refreshResponse.json();
      if (refreshData.success && refreshData.vehicles) {
        setVehicles(refreshData.vehicles);
        setStats(refreshData.stats || calculateStats(refreshData.vehicles));
      }

      setSelectedVehicles(new Set());
    } catch (error) {
      console.error('[Vehicles] Bulk action failed:', error);
      toast.error('Bulk action failed');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header with Quick Actions */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-3">
            <Car className="size-8 text-primary" />
            Vehicle Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Complete vehicle control and management system
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button
            onClick={() => handleAction('quickspawn')}
            className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700"
          >
            <Rocket className="size-4 mr-2" />
            Quick Spawn Vehicle
          </Button>
          <Button
            onClick={() => handleAction('add')}
            variant="default"
          >
            <Plus className="size-4 mr-2" />
            Add Vehicle
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-500/10 rounded-lg">
                <Car className="size-6 text-blue-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Vehicles</p>
                <p className="text-2xl font-bold">{stats.totalVehicles}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-orange-500/10 rounded-lg">
                <Zap className="size-6 text-orange-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Spawned</p>
                <p className="text-2xl font-bold">{stats.spawnedVehicles}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-500/10 rounded-lg">
                <Archive className="size-6 text-green-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">In Garage</p>
                <p className="text-2xl font-bold">{stats.ownedVehicles - stats.spawnedVehicles - stats.impoundedVehicles}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-red-500/10 rounded-lg">
                <AlertTriangle className="size-6 text-red-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Impounded</p>
                <p className="text-2xl font-bold">{stats.impoundedVehicles}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-purple-500/10 rounded-lg">
                <DollarSign className="size-6 text-purple-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Value</p>
                <p className="text-2xl font-bold">${(stats.totalValue / 1000000).toFixed(1)}M</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters & Search */}
      <Card className="p-4">
        <div className="flex items-center gap-4 flex-wrap">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
            <Input
              placeholder="Search by model, plate, or owner..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
          <Select value={filterType} onValueChange={setFilterType}>
            <SelectTrigger className="w-[180px]">
              <Filter className="size-4 mr-2" />
              <SelectValue placeholder="Vehicle Type" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Types</SelectItem>
              <SelectItem value="compacts">Compacts</SelectItem>
              <SelectItem value="sedans">Sedans</SelectItem>
              <SelectItem value="suvs">SUVs</SelectItem>
              <SelectItem value="coupes">Coupes</SelectItem>
              <SelectItem value="muscle">Muscle</SelectItem>
              <SelectItem value="sports">Sports</SelectItem>
              <SelectItem value="super">Super</SelectItem>
              <SelectItem value="motorcycles">Motorcycles</SelectItem>
              <SelectItem value="emergency">Emergency</SelectItem>
            </SelectContent>
          </Select>
          <Select value={filterStatus} onValueChange={setFilterStatus}>
            <SelectTrigger className="w-[180px]">
              <Sliders className="size-4 mr-2" />
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Status</SelectItem>
              <SelectItem value="spawned">Spawned</SelectItem>
              <SelectItem value="stored">Stored</SelectItem>
              <SelectItem value="impounded">Impounded</SelectItem>
            </SelectContent>
          </Select>
          {selectedVehicles.size > 0 && (
            <>
              <div className="h-8 w-px bg-border" />
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline">
                    <Settings className="size-4 mr-2" />
                    Bulk Actions ({selectedVehicles.size})
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent>
                  <DropdownMenuLabel>Apply to {selectedVehicles.size} vehicles</DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={() => handleBulkAction('repair')}>
                    <Wrench className="size-4 mr-2" />
                    Repair All
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => handleBulkAction('refuel')}>
                    <Fuel className="size-4 mr-2" />
                    Refuel All
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => handleBulkAction('store')}>
                    <Archive className="size-4 mr-2" />
                    Store All
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => handleBulkAction('impound')}>
                    <Lock className="size-4 mr-2" />
                    Impound All
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={() => handleBulkAction('delete')} className="text-destructive">
                    <Trash2 className="size-4 mr-2" />
                    Delete All
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
              <Button variant="outline" onClick={() => setSelectedVehicles(new Set())}>
                <X className="size-4 mr-2" />
                Clear Selection
              </Button>
            </>
          )}
        </div>
      </Card>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="all" className="flex items-center gap-2">
            <Car className="size-4" />
            All Vehicles
          </TabsTrigger>
          <TabsTrigger value="spawned" className="flex items-center gap-2">
            <Zap className="size-4" />
            Spawned
          </TabsTrigger>
          <TabsTrigger value="garaged" className="flex items-center gap-2">
            <Archive className="size-4" />
            Garaged
          </TabsTrigger>
          <TabsTrigger value="impounded" className="flex items-center gap-2">
            <Lock className="size-4" />
            Impounded
          </TabsTrigger>
        </TabsList>

        <TabsContent value={activeTab} className="space-y-4 mt-6">
          <Card>
            <CardHeader className="pb-4">
              <CardTitle className="flex items-center gap-2">
                <Car className="size-5" />
                {activeTab === 'all' && 'All Vehicles'}
                {activeTab === 'spawned' && 'Spawned Vehicles'}
                {activeTab === 'garaged' && 'Vehicles in Garage'}
                {activeTab === 'impounded' && 'Impounded Vehicles'}
              </CardTitle>
              <CardDescription>
                {filteredVehicles.length} vehicles found
                {selectedVehicles.size > 0 && ' • ' + selectedVehicles.size + ' selected'}
              </CardDescription>
            </CardHeader>
            <CardContent className="p-0">
              <ScrollArea className="h-[600px]">
                <div className="space-y-1">
                  {filteredVehicles.map((vehicle) => {
                    const isExpanded = expandedRows.has(vehicle.id);
                    const isSelected = selectedVehicles.has(vehicle.id);
                    
                    return (
                      <div key={vehicle.id} className="border-b last:border-b-0">
                        {/* Main Row */}
                        <div className="flex items-center gap-4 p-4 hover:bg-accent/30 transition-colors">
                          {/* Checkbox */}
                          <Checkbox
                            checked={isSelected}
                            onCheckedChange={() => toggleVehicleSelection(vehicle.id)}
                          />

                          {/* Vehicle Info */}
                          <div className="flex-1 grid grid-cols-6 gap-4 items-center">
                            {/* Model & Plate */}
                            <div className="flex items-center gap-3">
                              <Car className="size-4 text-muted-foreground flex-shrink-0" />
                              <div>
                                <p className="font-medium capitalize">{vehicle.model}</p>
                                <code className="text-xs bg-muted px-1.5 py-0.5 rounded">{vehicle.plate}</code>
                              </div>
                            </div>

                            {/* Owner */}
                            <div className="flex items-center gap-2">
                              <Users className="size-3 text-muted-foreground" />
                              <span className="text-sm truncate">{vehicle.owner}</span>
                            </div>

                            {/* Status */}
                            <div>
                              {vehicle.impounded ? (
                                <Badge variant="destructive" className="px-2.5 py-1">
                                  <Lock className="size-3 mr-1.5" />
                                  Impounded
                                </Badge>
                              ) : vehicle.spawned ? (
                                <Badge variant="default" className="px-2.5 py-1">
                                  <Zap className="size-3 mr-1.5" />
                                  Spawned
                                </Badge>
                              ) : (
                                <Badge variant="outline" className="px-2.5 py-1">
                                  <Archive className="size-3 mr-1.5" />
                                  Garaged
                                </Badge>
                              )}
                            </div>

                            {/* Condition */}
                            <div className="flex items-center gap-2">
                              <Gauge className="size-3 text-muted-foreground" />
                              <div className="flex-1">
                                <Progress value={vehicle.health} className="h-2" />
                              </div>
                              <span className="text-xs min-w-[2.5rem]">{vehicle.health}%</span>
                            </div>

                            {/* Fuel */}
                            <div className="flex items-center gap-2">
                              <Fuel className="size-3 text-muted-foreground" />
                              <div className="flex-1">
                                <Progress value={vehicle.fuel} className="h-2" />
                              </div>
                              <span className="text-xs min-w-[2.5rem]">{vehicle.fuel}%</span>
                            </div>

                            {/* Value */}
                            <div className="text-right">
                              <span className="font-medium text-green-600 text-sm">
                                {vehicle.value ? formatMoney(vehicle.value) : 'N/A'}
                              </span>
                            </div>
                          </div>

                          {/* Expand Button */}
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => toggleRowExpansion(vehicle.id)}
                            className="ml-2"
                          >
                            {isExpanded ? (
                              <X className="size-4" />
                            ) : (
                              <Settings className="size-4" />
                            )}
                          </Button>
                        </div>

                        {/* Expanded Actions */}
                        {isExpanded && (
                          <div className="ec-card-transparent border border-border/30 p-4 border-t">
                            <div className="grid grid-cols-2 gap-4">
                              {/* Quick Actions */}
                              <div>
                                <h4 className="text-sm font-medium mb-3 flex items-center gap-2">
                                  <Zap className="size-4" />
                                  Quick Actions
                                </h4>
                                <div className="grid grid-cols-2 gap-2">
                                  {vehicle.impounded ? (
                                    <Button size="sm" onClick={() => handleAction('unimpound', vehicle)} className="w-full">
                                      <Unlock className="size-3 mr-2" />
                                      Release
                                    </Button>
                                  ) : vehicle.stored ? (
                                    <Button size="sm" onClick={() => handleAction('spawn', vehicle)} className="w-full">
                                      <Zap className="size-3 mr-2" />
                                      Spawn
                                    </Button>
                                  ) : (
                                    <Button size="sm" onClick={() => handleAction('store', vehicle)} className="w-full">
                                      <Archive className="size-3 mr-2" />
                                      Store
                                    </Button>
                                  )}
                                  <Button size="sm" variant="outline" onClick={() => handleAction('repair', vehicle)} className="w-full">
                                    <Wrench className="size-3 mr-2" />
                                    Repair
                                  </Button>
                                  <Button size="sm" variant="outline" onClick={() => handleAction('refuel', vehicle)} className="w-full">
                                    <Fuel className="size-3 mr-2" />
                                    Refuel
                                  </Button>
                                  {vehicle.spawned && (
                                    <Button size="sm" variant="outline" onClick={() => handleAction('teleport', vehicle)} className="w-full">
                                      <MapPin className="size-3 mr-2" />
                                      Teleport
                                    </Button>
                                  )}
                                </div>
                              </div>

                              {/* Management */}
                              <div>
                                <h4 className="text-sm font-medium mb-3 flex items-center gap-2">
                                  <Cog className="size-4" />
                                  Management
                                </h4>
                                <div className="grid grid-cols-2 gap-2">
                                  <Button size="sm" variant="outline" onClick={() => handleAction('details', vehicle)} className="w-full">
                                    <Eye className="size-3 mr-2" />
                                    Details
                                  </Button>
                                  <Button size="sm" variant="outline" onClick={() => handleAction('rename', vehicle)} className="w-full">
                                    <Tag className="size-3 mr-2" />
                                    Plate
                                  </Button>
                                  <Button size="sm" variant="outline" onClick={() => handleAction('color', vehicle)} className="w-full">
                                    <Paintbrush className="size-3 mr-2" />
                                    Colors
                                  </Button>
                                  <Button size="sm" variant="outline" onClick={() => handleAction('upgrade', vehicle)} className="w-full">
                                    <Cog className="size-3 mr-2" />
                                    Mods
                                  </Button>
                                  <Button size="sm" variant="outline" onClick={() => handleAction('transfer', vehicle)} className="w-full">
                                    <Send className="size-3 mr-2" />
                                    Transfer
                                  </Button>
                                  {!vehicle.impounded && (
                                    <Button size="sm" variant="outline" onClick={() => handleAction('impound', vehicle)} className="w-full">
                                      <Lock className="size-3 mr-2" />
                                      Impound
                                    </Button>
                                  )}
                                  <Button size="sm" variant="destructive" onClick={() => handleAction('delete', vehicle)} className="w-full col-span-2">
                                    <Trash2 className="size-3 mr-2" />
                                    Delete Vehicle
                                  </Button>
                                </div>
                              </div>
                            </div>

                            {/* Additional Info */}
                            <div className="mt-4 pt-4 border-t grid grid-cols-4 gap-4 text-sm">
                              <div>
                                <p className="text-muted-foreground">Location</p>
                                <p className="font-medium">{vehicle.location}</p>
                              </div>
                              <div>
                                <p className="text-muted-foreground">Class</p>
                                <p className="font-medium capitalize">{vehicle.class}</p>
                              </div>
                              <div>
                                <p className="text-muted-foreground">Mileage</p>
                                <p className="font-medium">{vehicle.mileage?.toLocaleString() || 0} mi</p>
                              </div>
                              <div>
                                <p className="text-muted-foreground">Last Used</p>
                                <p className="font-medium">{vehicle.lastUsed ? formatDate(vehicle.lastUsed) : 'Never'}</p>
                              </div>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Action Modals */}
      <Dialog open={actionModal.isOpen} onOpenChange={(open) => !open && setActionModal({ isOpen: false, action: null })}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {actionModal.action === 'quickspawn' && 'Quick Spawn Vehicle'}
              {actionModal.action === 'spawn' && 'Spawn Vehicle'}
              {actionModal.action === 'delete' && 'Delete Vehicle'}
              {actionModal.action === 'repair' && 'Repair Vehicle'}
              {actionModal.action === 'refuel' && 'Refuel Vehicle'}
              {actionModal.action === 'impound' && 'Impound Vehicle'}
              {actionModal.action === 'unimpound' && 'Release from Impound'}
              {actionModal.action === 'teleport' && 'Teleport to Vehicle'}
              {actionModal.action === 'details' && 'Vehicle Details'}
              {actionModal.action === 'rename' && 'Change License Plate'}
              {actionModal.action === 'color' && 'Change Colors'}
              {actionModal.action === 'upgrade' && 'Upgrade Mods'}
              {actionModal.action === 'transfer' && 'Transfer Ownership'}
              {actionModal.action === 'store' && 'Store in Garage'}
              {actionModal.action === 'add' && 'Add New Vehicle'}
            </DialogTitle>
            <DialogDescription>
              {actionModal.action === 'quickspawn' && 'Spawn any vehicle by model name near your player'}
              {actionModal.action === 'delete' && 'This action cannot be undone. The vehicle will be permanently removed from the database.'}
              {actionModal.action === 'details' && selectedVehicle && 'Viewing details for ' + selectedVehicle.model + ' (' + selectedVehicle.plate + ')'}
              {actionModal.action === 'add' && 'Create a new vehicle and add it to the database'}
            </DialogDescription>
          </DialogHeader>

          <div className="py-4">
            {/* Quick Spawn Modal */}
            {actionModal.action === 'quickspawn' && (
              <div className="space-y-4">
                <div className="space-y-3">
                  <Label>Vehicle Model</Label>
                  <Input
                    value={formData.spawnModel || ''}
                    onChange={(e) => setFormData({ ...formData, spawnModel: e.target.value })}
                    placeholder="e.g., adder, t20, zentorno"
                  />
                  <p className="text-xs text-muted-foreground">Enter the spawn name of the vehicle (e.g., 'adder' for Adder)</p>
                </div>

                <div className="space-y-3">
                  <Label>Owner (Optional)</Label>
                  <Input
                    value={formData.owner || ''}
                    onChange={(e) => setFormData({ ...formData, owner: e.target.value })}
                    placeholder="Citizen ID or leave empty"
                  />
                </div>

                <div>
                  <Label className="mb-3 block">Popular Vehicles</Label>
                  <div className="grid grid-cols-3 gap-2 max-h-[300px] overflow-y-auto">
                    {popularVehicles.map((veh) => (
                      <Button
                        key={veh.model}
                        size="sm"
                        variant="outline"
                        onClick={() => setFormData({ ...formData, spawnModel: veh.model })}
                        className="justify-start"
                      >
                        <Car className="size-3 mr-2" />
                        <div className="text-left flex-1 min-w-0">
                          <p className="font-medium truncate">{veh.name}</p>
                          <p className="text-xs text-muted-foreground">{veh.class}</p>
                        </div>
                      </Button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Vehicle Details Modal */}
            {actionModal.action === 'details' && selectedVehicle && (
              <div className="space-y-6">
                <div className="grid grid-cols-2 gap-6">
                  <Card>
                    <CardHeader className="pb-4">
                      <CardTitle className="text-sm">Vehicle Information</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-3 text-sm">
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Model:</span>
                        <span className="font-medium capitalize">{selectedVehicle.model}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Plate:</span>
                        <code className="font-medium">{selectedVehicle.plate}</code>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Class:</span>
                        <span className="font-medium">{selectedVehicle.class}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Type:</span>
                        <span className="font-medium capitalize">{selectedVehicle.type}</span>
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="pb-4">
                      <CardTitle className="text-sm">Owner Information</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-3 text-sm">
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Owner:</span>
                        <span className="font-medium">{selectedVehicle.owner}</span>
                      </div>
                      {selectedVehicle.citizenid && (
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Citizen ID:</span>
                          <code className="font-medium text-xs">{selectedVehicle.citizenid}</code>
                        </div>
                      )}
                      {selectedVehicle.purchaseDate && (
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Purchased:</span>
                          <span className="font-medium">{formatDate(selectedVehicle.purchaseDate)}</span>
                        </div>
                      )}
                      {selectedVehicle.value && (
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Value:</span>
                          <span className="font-medium text-green-600">{formatMoney(selectedVehicle.value)}</span>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </div>

                <Card>
                  <CardHeader className="pb-4">
                    <CardTitle className="text-sm">Vehicle Condition</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div>
                      <div className="flex justify-between mb-2">
                        <span className="text-sm">Body Health</span>
                        <span className="text-sm font-medium">{selectedVehicle.health}%</span>
                      </div>
                      <Progress value={selectedVehicle.health} />
                    </div>
                    <div>
                      <div className="flex justify-between mb-2">
                        <span className="text-sm">Engine Health</span>
                        <span className="text-sm font-medium">{Math.round((selectedVehicle.engineHealth / 1000) * 100)}%</span>
                      </div>
                      <Progress value={Math.round((selectedVehicle.engineHealth / 1000) * 100)} />
                    </div>
                    <div>
                      <div className="flex justify-between mb-2">
                        <span className="text-sm">Fuel Level</span>
                        <span className="text-sm font-medium">{selectedVehicle.fuel}%</span>
                      </div>
                      <Progress value={selectedVehicle.fuel} />
                    </div>
                  </CardContent>
                </Card>

                <div className="grid grid-cols-2 gap-6">
                  <Card>
                    <CardHeader className="pb-4">
                      <CardTitle className="text-sm">Colors</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-3 text-sm">
                      {selectedVehicle.color ? (
                        <>
                          <div className="flex justify-between">
                            <span className="text-muted-foreground">Primary:</span>
                            <span className="font-medium">{selectedVehicle.color.primary}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-muted-foreground">Secondary:</span>
                            <span className="font-medium">{selectedVehicle.color.secondary}</span>
                          </div>
                        </>
                      ) : (
                        <p className="text-muted-foreground">No color data</p>
                      )}
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="pb-4">
                      <CardTitle className="text-sm">Location</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-3 text-sm">
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Current:</span>
                        <span className="font-medium">{selectedVehicle.location}</span>
                      </div>
                      {selectedVehicle.garage && (
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Garage:</span>
                          <span className="font-medium">{selectedVehicle.garage}</span>
                        </div>
                      )}
                      {selectedVehicle.mileage && (
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Mileage:</span>
                          <span className="font-medium">{selectedVehicle.mileage.toLocaleString()} mi</span>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </div>

                {selectedVehicle.mods && (
                  <Card>
                    <CardHeader className="pb-4">
                      <CardTitle className="text-sm">Modifications</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="grid grid-cols-3 gap-4 text-sm">
                        <div>
                          <p className="text-muted-foreground mb-1">Engine</p>
                          <p className="font-medium">Level {selectedVehicle.mods.engine}/4</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground mb-1">Transmission</p>
                          <p className="font-medium">Level {selectedVehicle.mods.transmission}/4</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground mb-1">Brakes</p>
                          <p className="font-medium">Level {selectedVehicle.mods.brakes}/3</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground mb-1">Suspension</p>
                          <p className="font-medium">Level {selectedVehicle.mods.suspension}/4</p>
                        </div>
                        <div>
                          <p className="text-muted-foreground mb-1">Turbo</p>
                          <p className="font-medium">{selectedVehicle.mods.turbo ? 'Installed' : 'Not Installed'}</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                )}
              </div>
            )}

            {/* Rename Modal */}
            {actionModal.action === 'rename' && (
              <div className="space-y-4">
                <div className="space-y-3">
                  <Label>Current Plate</Label>
                  <Input value={selectedVehicle?.plate || ''} disabled />
                </div>
                <div className="space-y-3">
                  <Label>New Plate</Label>
                  <Input
                    value={formData.newPlate || ''}
                    onChange={(e) => setFormData({ ...formData, newPlate: e.target.value.toUpperCase() })}
                    placeholder="e.g., XYZ123"
                    maxLength={8}
                  />
                </div>
              </div>
            )}

            {/* Color Change Modal */}
            {actionModal.action === 'color' && (
              <div className="space-y-4">
                <div className="space-y-3">
                  <Label>Primary Color</Label>
                  <Input
                    value={formData.primaryColor || ''}
                    onChange={(e) => setFormData({ ...formData, primaryColor: e.target.value })}
                    placeholder="e.g., Metallic Black"
                  />
                </div>
                <div className="space-y-3">
                  <Label>Secondary Color</Label>
                  <Input
                    value={formData.secondaryColor || ''}
                    onChange={(e) => setFormData({ ...formData, secondaryColor: e.target.value })}
                    placeholder="e.g., Carbon Black"
                  />
                </div>
              </div>
            )}

            {/* Upgrade Modal */}
            {actionModal.action === 'upgrade' && (
              <div className="space-y-5">
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <Label>Engine (Level {formData.engine}/4)</Label>
                    <span className="text-sm text-muted-foreground">{formData.engine}/4</span>
                  </div>
                  <Input
                    type="range"
                    min="0"
                    max="4"
                    value={formData.engine}
                    onChange={(e) => setFormData({ ...formData, engine: parseInt(e.target.value) })}
                  />
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <Label>Transmission (Level {formData.transmission}/3)</Label>
                    <span className="text-sm text-muted-foreground">{formData.transmission}/3</span>
                  </div>
                  <Input
                    type="range"
                    min="0"
                    max="3"
                    value={formData.transmission}
                    onChange={(e) => setFormData({ ...formData, transmission: parseInt(e.target.value) })}
                  />
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <Label>Brakes (Level {formData.brakes}/2)</Label>
                    <span className="text-sm text-muted-foreground">{formData.brakes}/2</span>
                  </div>
                  <Input
                    type="range"
                    min="0"
                    max="2"
                    value={formData.brakes}
                    onChange={(e) => setFormData({ ...formData, brakes: parseInt(e.target.value) })}
                  />
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <Label>Suspension (Level {formData.suspension}/4)</Label>
                    <span className="text-sm text-muted-foreground">{formData.suspension}/4</span>
                  </div>
                  <Input
                    type="range"
                    min="0"
                    max="4"
                    value={formData.suspension}
                    onChange={(e) => setFormData({ ...formData, suspension: parseInt(e.target.value) })}
                  />
                </div>
                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div>
                    <Label>Turbo</Label>
                    <p className="text-sm text-muted-foreground">Install turbocharger</p>
                  </div>
                  <Checkbox
                    checked={formData.turbo}
                    onCheckedChange={(checked) => setFormData({ ...formData, turbo: checked })}
                  />
                </div>
              </div>
            )}

            {/* Transfer Modal */}
            {actionModal.action === 'transfer' && (
              <div className="space-y-4">
                <div className="space-y-3">
                  <Label>Current Owner</Label>
                  <Input value={selectedVehicle?.owner || ''} disabled />
                </div>
                <div className="space-y-3">
                  <Label>New Owner (Citizen ID)</Label>
                  <Input
                    value={formData.newOwner || ''}
                    onChange={(e) => setFormData({ ...formData, newOwner: e.target.value })}
                    placeholder="Enter citizen ID"
                  />
                </div>
              </div>
            )}

            {/* Impound Form */}
            {actionModal.action === 'impound' && (
              <div className="space-y-3">
                <Label>Impound Reason</Label>
                <Textarea
                  value={formData.reason || ''}
                  onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                  placeholder="Enter reason for impounding..."
                  rows={4}
                />
              </div>
            )}

            {/* Add Vehicle Form */}
            {actionModal.action === 'add' && (
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-3">
                    <Label>Vehicle Model</Label>
                    <Input
                      value={formData.model || ''}
                      onChange={(e) => setFormData({ ...formData, model: e.target.value })}
                      placeholder="e.g., adder"
                    />
                  </div>
                  <div className="space-y-3">
                    <Label>License Plate</Label>
                    <Input
                      value={formData.plate || ''}
                      onChange={(e) => setFormData({ ...formData, plate: e.target.value.toUpperCase() })}
                      placeholder="e.g., ABC123"
                      maxLength={8}
                    />
                  </div>
                </div>
                <div className="space-y-3">
                  <Label>Owner (Citizen ID)</Label>
                  <Input
                    value={formData.owner || ''}
                    onChange={(e) => setFormData({ ...formData, owner: e.target.value })}
                    placeholder="Enter citizen ID or leave empty"
                  />
                </div>
              </div>
            )}

            {/* Confirmation Dialogs */}
            {(actionModal.action === 'spawn' || actionModal.action === 'store' || actionModal.action === 'repair' || 
              actionModal.action === 'refuel' || actionModal.action === 'unimpound' || actionModal.action === 'teleport' || 
              actionModal.action === 'delete') && (
              <div className="py-4">
                <p className="text-center text-muted-foreground">
                  {actionModal.action === 'delete' && 'Are you sure you want to permanently delete this vehicle?'}
                  {actionModal.action === 'spawn' && 'The vehicle will be spawned near the owner or admin.'}
                  {actionModal.action === 'store' && 'The vehicle will be stored in the garage.'}
                  {actionModal.action === 'repair' && 'The vehicle will be restored to perfect condition.'}
                  {actionModal.action === 'refuel' && 'The vehicle will be filled to 100% fuel.'}
                  {actionModal.action === 'unimpound' && 'The vehicle will be released and stored in garage.'}
                  {actionModal.action === 'teleport' && 'You will be teleported to the vehicle location.'}
                </p>
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setActionModal({ isOpen: false, action: null })}>
              Cancel
            </Button>
            <Button onClick={executeAction}>
              {actionModal.action === 'details' ? 'Close' : 'Confirm'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
