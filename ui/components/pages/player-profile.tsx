import { useState, useEffect, useMemo, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Avatar, AvatarFallback } from '../ui/avatar';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Textarea } from '../ui/textarea';
import { ScrollArea } from '../ui/scroll-area';
import { Progress } from '../ui/progress';
import { Separator } from '../ui/separator';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { 
  User, Shield, DollarSign, Car, Home, Clock, MapPin, 
  AlertTriangle, Ban, UserX, Eye, Key, Zap, ArrowLeft,
  Activity, TrendingUp, Package, History, Settings, Heart,
  Briefcase, Users, Phone, Mail, Globe, Calendar, Star,
  Award, Target, TrendingDown, Wallet, CreditCard, Bitcoin,
  ShoppingBag, Wrench, Edit, Save, X, CheckCircle, XCircle,
  Download, Upload, Copy, ExternalLink, MessageSquare, FileText,
  BarChart3, PieChart, LineChart, Plus, Minus, Trash2, Search,
  RefreshCw, Filter, MoreHorizontal, Lock, Unlock, Send, 
  Boxes, Warehouse, Archive, Tag, Info, Sparkles, Fuel,
  Gauge, Cog, Paintbrush, RotateCw, ArrowUpCircle, Database,
  FileCheck, FileMinus, FileWarning, Scale, Receipt, CreditCard as CardIcon,
  Palette, Droplet, Circle
} from 'lucide-react';
import { LineChart as RechartsLine, Line, AreaChart, Area, BarChart, Bar, PieChart as RechartsPie, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { toastSuccess, toastError } from '../../lib/toast';
import { formatRelativeTime, formatDateTime } from '../../lib/time';

interface PlayerProfilePageProps {
  playerId?: number;
  onBack?: () => void;
}

export function PlayerProfilePage({ playerId = 1, onBack }: PlayerProfilePageProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');
  const [isEditing, setIsEditing] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  
  // Modals state
  const [inventoryModal, setInventoryModal] = useState<{ isOpen: boolean; action: 'add' | 'remove' | 'edit' | null; item?: any }>({ isOpen: false, action: null });
  const [vehicleModal, setVehicleModal] = useState<{ isOpen: boolean; action: 'add' | 'remove' | 'rename' | 'upgrade' | 'impound' | 'unimpound' | 'color' | 'spawn' | 'store' | 'repair' | 'refuel' | 'transfer' | null; vehicle?: any }>({ isOpen: false, action: null });
  const [propertyModal, setPropertyModal] = useState<{ isOpen: boolean; action: 'add' | 'remove' | 'keys' | 'lock' | null; property?: any }>({ isOpen: false, action: null });
  const [financeModal, setFinanceModal] = useState<{ isOpen: boolean; action: 'add' | 'remove' | 'transfer' | null; type?: 'cash' | 'bank' | 'crypto' }>({ isOpen: false, action: null });
  const [moderationModal, setModerationModal] = useState<{ isOpen: boolean; action: 'warn' | 'ban' | 'kick' | 'note' | null }>({ isOpen: false, action: null });
  const [stashModal, setStashModal] = useState<{ isOpen: boolean; stashId?: string; stashName?: string }>({ isOpen: false });
  
  // Form data
  const [formData, setFormData] = useState<any>({});

  // Mock data for fallback (browser/Figma mode)
  const mockPlayerData = {
    id: playerId,
    name: 'John_Doe',
    steamId: 'steam:110000123456789',
    license: 'license:abc123def456',
    discord: 'JohnDoe#1234',
    discordId: '123456789012345678',
    ip: '192.168.1.100',
    hwid: 'HWID-ABC123DEF456',
    firstJoined: '2024-01-15 10:30:00',
    lastSeen: 'Online',
    lastSeenDate: new Date().toISOString(),
    playtime: '247h 35m',
    playtimeMinutes: 14855,
    status: 'online' as const,
    location: 'Legion Square',
    coords: { x: 215.12, y: -810.34, z: 30.73 },
    heading: 145.5,
    job: 'Police Officer',
    jobGrade: 'Sergeant',
    jobGradeLevel: 3,
    jobSalary: 5000,
    gang: 'None',
    gangGrade: 'None',
    money: {
      cash: 45230,
      bank: 125600,
      crypto: 2500,
      blackMoney: 500
    },
    warnings: 2,
    bans: 0,
    kicks: 1,
    commendations: 5,
    health: 200,
    armor: 100,
    hunger: 75,
    thirst: 80,
    stress: 15,
    isDead: false,
    inVehicle: false,
    currentVehicle: null,
    level: 45,
    xp: 12450,
    nextLevelXp: 15000,
    skillPoints: 23,
    reputation: 'Good Standing',
    totalDeaths: 12,
    totalKills: 3,
    totalArrests: 0,
    totalArrestsMade: 27,
    phoneNumber: '555-0123',
    nationality: 'USA',
    birthDate: '1995-06-15',
    age: 28,
    gender: 'Male',
    height: 185,
    licenses: ['Driver', 'Weapon', 'Business'],
    metadata: {
      criminalRecord: 'Clean',
      isWanted: false,
      wantedLevel: 0,
      fingerprint: 'FP-123456',
      bloodType: 'O+',
      marriedTo: null,
      notes: []
    }
  };

  // Player data state - LIVE DATA INTEGRATION
  const [player, setPlayer] = useState(mockPlayerData);

  // Inventory with detailed info
  const [inventory, setInventory] = useState([
    { id: 1, name: 'Phone', quantity: 1, type: 'item', weight: 0.2, useable: true, description: 'Smartphone for communication', slot: 1, metadata: {} },
    { id: 2, name: 'Lockpick', quantity: 5, type: 'item', weight: 0.1, useable: true, description: 'Used to pick locks', slot: 2, metadata: {} },
    { id: 3, name: 'Burger', quantity: 3, type: 'food', weight: 0.3, useable: true, description: 'Restores hunger', slot: 3, metadata: { quality: 100 } },
    { id: 4, name: 'Water Bottle', quantity: 2, type: 'drink', weight: 0.5, useable: true, description: 'Restores thirst', slot: 4, metadata: {} },
    { id: 5, name: 'Pistol', quantity: 1, type: 'weapon', weight: 1.5, useable: true, description: 'Standard pistol', slot: 5, metadata: { ammo: 12, condition: 95 } },
    { id: 6, name: 'Pistol Ammo', quantity: 150, type: 'ammo', weight: 0.01, useable: false, description: '9mm ammunition', slot: 6, metadata: {} },
    { id: 7, name: 'Radio', quantity: 1, type: 'item', weight: 0.4, useable: true, description: 'Police radio', slot: 7, metadata: { channel: 1 } },
    { id: 8, name: 'Handcuffs', quantity: 1, type: 'item', weight: 0.3, useable: true, description: 'Restrain suspects', slot: 8, metadata: {} },
    { id: 9, name: 'Bandage', quantity: 10, type: 'medical', weight: 0.1, useable: true, description: 'Heal minor wounds', slot: 9, metadata: {} },
    { id: 10, name: 'ID Card', quantity: 1, type: 'item', weight: 0.05, useable: true, description: 'Identification', slot: 10, metadata: { citizenid: 'ABC123' } },
  ]);

  // Stashes
  const stashes = [
    { id: 'home_stash', name: 'Home Storage', location: '123 Grove Street', items: 15, weight: 45.2, maxWeight: 150, locked: false },
    { id: 'apt_stash', name: 'Apartment Storage', location: 'Eclipse Towers #5', items: 23, weight: 78.5, maxWeight: 200, locked: true },
    { id: 'trunk_adder', name: 'Adder Trunk', location: 'Vehicle Storage', items: 5, weight: 12.3, maxWeight: 50, locked: false },
    { id: 'glovebox_adder', name: 'Adder Glovebox', location: 'Vehicle Storage', items: 3, weight: 2.1, maxWeight: 10, locked: false },
  ];

  const totalWeight = inventory.reduce((acc, item) => acc + (item.weight * item.quantity), 0);
  const maxWeight = 50;

  // Vehicles with complete info
  const [vehicles, setVehicles] = useState([
    { 
      id: 1, 
      model: 'Adder', 
      plate: 'ABC 123', 
      location: 'Legion Square Garage', 
      stored: true,
      mileage: 12450,
      fuel: 100,
      engine: 1000,
      body: 1000,
      value: 1000000,
      impounded: false,
      impoundReason: null,
      mods: { engine: 3, transmission: 2, brakes: 1, turbo: true },
      color: { primary: 'Red', secondary: 'Black' },
      owner: 'John_Doe'
    },
    { 
      id: 2, 
      model: 'T20', 
      plate: 'XYZ 789', 
      location: 'Out (Vinewood Hills)', 
      stored: false,
      mileage: 8720,
      fuel: 45,
      engine: 850,
      body: 920,
      value: 2300000,
      impounded: false,
      impoundReason: null,
      mods: { engine: 4, transmission: 3, brakes: 2, turbo: true },
      color: { primary: 'Blue', secondary: 'White' },
      owner: 'John_Doe'
    },
    { 
      id: 3, 
      model: 'Zentorno', 
      plate: 'FAST 01', 
      location: 'Airport Garage', 
      stored: true,
      mileage: 15670,
      fuel: 80,
      engine: 950,
      body: 980,
      value: 725000,
      impounded: false,
      impoundReason: null,
      mods: { engine: 2, transmission: 2, brakes: 1, turbo: false },
      color: { primary: 'Yellow', secondary: 'Black' },
      owner: 'John_Doe'
    },
    { 
      id: 4, 
      model: 'Police Cruiser', 
      plate: 'LSPD 401', 
      location: 'Mission Row PD', 
      stored: true,
      mileage: 34200,
      fuel: 60,
      engine: 800,
      body: 750,
      value: 0,
      impounded: false,
      impoundReason: null,
      mods: { engine: 1, transmission: 1, brakes: 1, turbo: false },
      color: { primary: 'White', secondary: 'Black' },
      owner: 'LSPD'
    },
  ]);

  // Properties with complete info
  const [properties, setProperties] = useState([
    { 
      id: 1, 
      type: 'House', 
      address: '123 Grove Street', 
      owned: true, 
      garage: 2,
      price: 250000,
      keys: ['John_Doe', 'Jane_Smith'],
      locked: false,
      hasStash: true,
      hasWardrobe: true,
      tier: 'Standard',
      coords: { x: 123.45, y: -678.90, z: 30.12 }
    },
    { 
      id: 2, 
      type: 'Apartment', 
      address: 'Eclipse Towers #5', 
      owned: true, 
      garage: 10,
      price: 500000,
      keys: ['John_Doe'],
      locked: true,
      hasStash: true,
      hasWardrobe: true,
      tier: 'Luxury',
      coords: { x: -773.82, y: 341.76, z: 196.68 }
    },
  ]);

  // Complete transaction history
  const transactions = [
    { id: 1, type: 'deposit', amount: 50000, balance: 125600, from: 'ATM', to: 'Bank Account', timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), details: 'ATM deposit' },
    { id: 2, type: 'withdrawal', amount: -5000, balance: 75600, from: 'Bank Account', to: 'Cash', timestamp: new Date(Date.now() - 36 * 60 * 60 * 1000).toISOString(), details: 'Cash withdrawal' },
    { id: 3, type: 'purchase', amount: -2300000, balance: 80600, from: 'Bank Account', to: 'PDM Dealership', timestamp: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(), details: 'Vehicle purchase: T20' },
    { id: 4, type: 'salary', amount: 5000, balance: 2380600, from: 'LSPD', to: 'Bank Account', timestamp: new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString(), details: 'Job salary' },
    { id: 5, type: 'transfer', amount: -10000, balance: 2375600, from: 'Bank Account', to: 'Jane_Smith', timestamp: new Date(Date.now() - 96 * 60 * 60 * 1000).toISOString(), details: 'Transfer to Jane_Smith' },
    { id: 6, type: 'crypto_buy', amount: -5000, balance: 2370600, from: 'Bank Account', to: 'Crypto Wallet', timestamp: new Date(Date.now() - 120 * 60 * 60 * 1000).toISOString(), details: 'Purchased 2,500 crypto' },
  ];

  // Complete activity history
  const activityHistory = [
    { id: 1, action: 'Connected to server', timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(), type: 'connection', details: 'Login successful from IP: 192.168.1.100', admin: null },
    { id: 2, action: 'Purchased vehicle (T20)', timestamp: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(), type: 'purchase', details: '$2,300,000 from PDM Dealership', admin: null },
    { id: 3, action: 'Job action: Made arrest', timestamp: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(), type: 'job', details: 'Arrested suspect for robbery at Fleeca Bank', admin: null },
    { id: 4, action: 'Received warning', timestamp: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(), type: 'warning', details: 'Excessive speeding in city limits', admin: 'Admin_Sarah' },
    { id: 5, action: 'Deposited $50,000', timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), type: 'transaction', details: 'Bank deposit via ATM', admin: null },
    { id: 6, action: 'Purchased property', timestamp: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(), type: 'purchase', details: 'Eclipse Towers #5 for $500,000', admin: null },
    { id: 7, action: 'Disconnected', timestamp: new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString(), type: 'connection', details: 'Normal logout', admin: null },
    { id: 8, action: 'Job change', timestamp: new Date(Date.now() - 96 * 60 * 60 * 1000).toISOString(), type: 'job', details: 'Promoted to Sergeant by Captain Williams', admin: null },
    { id: 9, action: 'Admin action: Given money', timestamp: new Date(Date.now() - 120 * 60 * 60 * 1000).toISOString(), type: 'admin', details: '$10,000 cash given by Admin_Mike (compensation)', admin: 'Admin_Mike' },
    { id: 10, action: 'Vehicle spawned', timestamp: new Date(Date.now() - 144 * 60 * 60 * 1000).toISOString(), type: 'vehicle', details: 'Spawned Adder (ABC 123) from garage', admin: null },
  ];

  // Complete warnings & moderation
  const [warnings, setWarnings] = useState([
    { id: 1, reason: 'Excessive speeding in city', issuedBy: 'Admin_Sarah', date: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(), active: true, expires: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() },
    { id: 2, reason: 'Failure to comply with police', issuedBy: 'Admin_Mike', date: new Date(Date.now() - 96 * 60 * 60 * 1000).toISOString(), active: true, expires: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString() },
  ]);

  const [bans, setBans] = useState<any[]>([]);
  
  const [moderationNotes, setModerationNotes] = useState([
    { id: 1, note: 'Player reported for VDM, investigated - no evidence found', createdBy: 'Admin_Dave', date: new Date(Date.now() - 168 * 60 * 60 * 1000).toISOString() },
    { id: 2, note: 'Good RP, commended for excellent police work', createdBy: 'Admin_Sarah', date: new Date(Date.now() - 240 * 60 * 60 * 1000).toISOString() },
  ]);

  // Performance charts
  const performanceData = useMemo(() => {
    const days = [];
    for (let i = 6; i >= 0; i--) {
      days.push({
        day: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toLocaleDateString('en-US', { weekday: 'short' }),
        playtime: Math.floor(Math.random() * 8) + 1,
        arrests: Math.floor(Math.random() * 5),
        deaths: Math.floor(Math.random() * 3)
      });
    }
    return days;
  }, []);

  const moneyData = useMemo(() => {
    const days = [];
    for (let i = 6; i >= 0; i--) {
      days.push({
        day: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toLocaleDateString('en-US', { weekday: 'short' }),
        cash: Math.floor(Math.random() * 50000) + 20000,
        bank: Math.floor(Math.random() * 100000) + 80000
      });
    }
    return days;
  }, []);

  const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

  // Fetch player profile data from FiveM - LIVE DATA INTEGRATION
  const fetchPlayerProfile = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/getPlayerProfile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playerId })
      });

      if (response.ok) {
        const result = await response.json();
        if (result.success && result.player) {
          console.log('[Player Profile] Loaded real FiveM data for player:', playerId);
          
          // Update player data with live data from server
          setPlayer({
            ...mockPlayerData, // Keep structure
            ...result.player,  // Override with real data
            id: result.player.id || result.player.source || playerId,
            name: result.player.name || mockPlayerData.name,
            status: result.player.online ? 'online' : 'offline',
            location: result.player.location || mockPlayerData.location,
            coords: result.player.coords || mockPlayerData.coords,
            health: result.player.health || mockPlayerData.health,
            armor: result.player.armor || mockPlayerData.armor,
            job: result.player.job || mockPlayerData.job,
            jobGrade: result.player.jobGrade || mockPlayerData.jobGrade,
            gang: result.player.gang || mockPlayerData.gang,
            money: result.player.money || mockPlayerData.money,
            steamId: result.player.identifiers?.steam || result.player.steamId || mockPlayerData.steamId,
            license: result.player.identifiers?.license || result.player.license || mockPlayerData.license,
            discord: result.player.identifiers?.discord || result.player.discord || mockPlayerData.discord,
            discordId: result.player.identifiers?.discord || result.player.discordId || mockPlayerData.discordId,
            ip: result.player.identifiers?.ip || result.player.ip || mockPlayerData.ip,
            hwid: result.player.identifiers?.hwid || result.player.hwid || mockPlayerData.hwid,
            phoneNumber: result.player.phoneNumber || mockPlayerData.phoneNumber,
            nationality: result.player.nationality || mockPlayerData.nationality,
            birthDate: result.player.birthDate || mockPlayerData.birthDate,
            gender: result.player.gender || mockPlayerData.gender,
            hunger: result.player.hunger !== undefined ? result.player.hunger : mockPlayerData.hunger,
            thirst: result.player.thirst !== undefined ? result.player.thirst : mockPlayerData.thirst,
            stress: result.player.stress !== undefined ? result.player.stress : mockPlayerData.stress,
            isDead: result.player.isDead || mockPlayerData.isDead,
            citizenId: result.player.citizenId,
            metadata: result.player.metadata || mockPlayerData.metadata,
          });
          
          // Update inventory if provided
          if (result.player.inventory && result.player.inventory.items) {
            console.log('[Player Profile] Loaded real inventory data:', result.player.inventory.items.length, 'items');
            setInventory(result.player.inventory.items);
          }
          
          return;
        }
      }
    } catch (error) {
      console.log('[Player Profile] Not in FiveM environment, using mock data');
    }

    // Use mock data as fallback
    console.log('[Player Profile] Using mock data for player:', playerId);
    setPlayer(mockPlayerData);
  }, [playerId]);

  // Initial load with auto-refresh - REAL-TIME UPDATES
  useEffect(() => {
    let isMounted = true;

    const loadData = async () => {
      if (!isMounted) return;
      await fetchPlayerProfile();
      if (isMounted) {
        setIsLoading(false);
      }
    };

    loadData();

    // Auto-refresh every 5 seconds - LIVE DATA UPDATES
    const interval = setInterval(() => {
      if (isMounted) {
        fetchPlayerProfile();
      }
    }, 5000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [fetchPlayerProfile]);

  // Manual refresh handler
  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchPlayerProfile();
    setRefreshing(false);
    toastSuccess({ title: 'Player data refreshed' });
  };

  // Helper functions
  const formatTimestamp = (timestamp: string | number) => formatRelativeTime(timestamp);

  const formatMoney = (amount: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
  };

  // Action handlers
  const handleInventoryAction = (action: 'add' | 'remove' | 'edit', item?: any) => {
    setInventoryModal({ isOpen: true, action, item });
    setFormData(item || { name: '', quantity: 1, type: 'item', weight: 0.1 });
  };

  const handleInventorySubmit = () => {
    if (inventoryModal.action === 'add') {
      const newItem = { ...formData, id: inventory.length + 1, slot: inventory.length + 1 };
      setInventory([...inventory, newItem]);
      toastSuccess({ title: `Added ${formData.quantity}x ${formData.name} to inventory` });
    } else if (inventoryModal.action === 'remove' && inventoryModal.item) {
      setInventory(inventory.filter(i => i.id !== inventoryModal.item.id));
      toastSuccess({ title: `Removed ${inventoryModal.item.name} from inventory` });
    } else if (inventoryModal.action === 'edit' && inventoryModal.item) {
      setInventory(inventory.map(i => i.id === inventoryModal.item.id ? { ...i, ...formData } : i));
      toastSuccess({ title: `Updated ${formData.name}` });
    }
    setInventoryModal({ isOpen: false, action: null });
  };

  const handleVehicleAction = (action: 'add' | 'remove' | 'rename' | 'upgrade' | 'impound' | 'unimpound' | 'color' | 'spawn' | 'store' | 'repair' | 'refuel' | 'transfer', vehicle?: any) => {
    setVehicleModal({ isOpen: true, action, vehicle });
    if (action === 'rename' && vehicle) {
      setFormData({ plate: vehicle.plate });
    } else if (action === 'upgrade' && vehicle) {
      setFormData({ engine: vehicle.mods.engine, transmission: vehicle.mods.transmission, brakes: vehicle.mods.brakes, turbo: vehicle.mods.turbo });
    } else if (action === 'color' && vehicle) {
      setFormData({ primary: vehicle.color.primary, secondary: vehicle.color.secondary });
    } else if (action === 'transfer' && vehicle) {
      setFormData({ newOwner: '' });
    } else if (action === 'add') {
      setFormData({ model: '', plate: '', location: 'Legion Square Garage', stored: true });
    } else {
      setFormData({});
    }
  };

  const handleVehicleSubmit = () => {
    if (vehicleModal.action === 'add') {
      const newVehicle = { 
        ...formData, 
        id: vehicles.length + 1,
        mileage: 0,
        fuel: 100,
        engine: 1000,
        body: 1000,
        value: 100000,
        impounded: false,
        mods: { engine: 0, transmission: 0, brakes: 0, turbo: false },
        color: { primary: 'Black', secondary: 'Black' },
        owner: player.name
      };
      setVehicles([...vehicles, newVehicle]);
      toastSuccess({ title: `Added vehicle: ${formData.model}` });
    } else if (vehicleModal.action === 'remove' && vehicleModal.vehicle) {
      setVehicles(vehicles.filter(v => v.id !== vehicleModal.vehicle.id));
      toastSuccess({ title: `Removed vehicle: ${vehicleModal.vehicle.model}` });
    } else if (vehicleModal.action === 'rename' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, plate: formData.plate } : v));
      toastSuccess({ title: `Renamed plate to: ${formData.plate}` });
    } else if (vehicleModal.action === 'upgrade' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, mods: formData } : v));
      toastSuccess({ title: `Upgraded ${vehicleModal.vehicle.model}` });
    } else if (vehicleModal.action === 'impound' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, impounded: true, stored: true, impoundReason: formData.reason, location: 'Impound Lot' } : v));
      toastSuccess({ title: `Impounded ${vehicleModal.vehicle.model}` });
    } else if (vehicleModal.action === 'unimpound' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, impounded: false, impoundReason: null } : v));
      toastSuccess({ title: `Released ${vehicleModal.vehicle.model} from impound` });
    } else if (vehicleModal.action === 'color' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, color: { primary: formData.primary, secondary: formData.secondary } } : v));
      toastSuccess({ title: `Changed ${vehicleModal.vehicle.model} colors` });
    } else if (vehicleModal.action === 'spawn' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, stored: false, location: 'Spawned near player' } : v));
      toastSuccess({ title: `Spawned ${vehicleModal.vehicle.model}` });
    } else if (vehicleModal.action === 'store' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, stored: true, location: formData.garage || 'Legion Square Garage' } : v));
      toastSuccess({ title: `Stored ${vehicleModal.vehicle.model}` });
    } else if (vehicleModal.action === 'repair' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, engine: 1000, body: 1000 } : v));
      toastSuccess({ title: `Repaired ${vehicleModal.vehicle.model}` });
    } else if (vehicleModal.action === 'refuel' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, fuel: 100 } : v));
      toastSuccess({ title: `Refueled ${vehicleModal.vehicle.model}` });
    } else if (vehicleModal.action === 'transfer' && vehicleModal.vehicle) {
      setVehicles(vehicles.map(v => v.id === vehicleModal.vehicle.id ? { ...v, owner: formData.newOwner } : v));
      toastSuccess({ title: `Transferred ${vehicleModal.vehicle.model} to ${formData.newOwner}` });
    }
    setVehicleModal({ isOpen: false, action: null });
  };

  const handlePropertyAction = (action: 'add' | 'remove' | 'keys' | 'lock', property?: any) => {
    setPropertyModal({ isOpen: true, action, property });
    if (action === 'keys' && property) {
      setFormData({ keys: property.keys });
    } else if (action === 'add') {
      setFormData({ type: 'House', address: '', price: 250000, garage: 2 });
    }
  };

  const handlePropertySubmit = () => {
    if (propertyModal.action === 'add') {
      const newProperty = { 
        ...formData, 
        id: properties.length + 1,
        owned: true,
        locked: false,
        hasStash: true,
        hasWardrobe: true,
        tier: 'Standard',
        coords: { x: 0, y: 0, z: 0 }
      };
      setProperties([...properties, newProperty]);
      toastSuccess({ title: `Added property: ${formData.address}` });
    } else if (propertyModal.action === 'remove' && propertyModal.property) {
      setProperties(properties.filter(p => p.id !== propertyModal.property.id));
      toastSuccess({ title: `Removed property: ${propertyModal.property.address}` });
    } else if (propertyModal.action === 'keys' && propertyModal.property) {
      setProperties(properties.map(p => p.id === propertyModal.property.id ? { ...p, keys: formData.keys } : p));
      toastSuccess({ title: `Updated keys for: ${propertyModal.property.address}` });
    } else if (propertyModal.action === 'lock' && propertyModal.property) {
      setProperties(properties.map(p => p.id === propertyModal.property.id ? { ...p, locked: !p.locked } : p));
      toastSuccess({ title: (propertyModal.property.locked ? 'Unlocked' : 'Locked') + ' ' + propertyModal.property.address });
    }
    setPropertyModal({ isOpen: false, action: null });
  };

  const handleFinanceAction = (action: 'add' | 'remove' | 'transfer', type: 'cash' | 'bank' | 'crypto') => {
    setFinanceModal({ isOpen: true, action, type });
    setFormData({ amount: 0 });
  };

  const handleFinanceSubmit = () => {
    const amount = parseFloat(formData.amount) || 0;
    if (financeModal.action === 'add') {
      player.money[financeModal.type!] += amount;
      toastSuccess({ title: `Added ${formatMoney(amount)} to ${financeModal.type}` });
    } else if (financeModal.action === 'remove') {
      player.money[financeModal.type!] -= amount;
      toastSuccess({ title: `Removed ${formatMoney(amount)} from ${financeModal.type}` });
    }
    setFinanceModal({ isOpen: false, action: null });
  };

  const handleModerationAction = (action: 'warn' | 'ban' | 'kick' | 'note') => {
    setModerationModal({ isOpen: true, action });
    setFormData({ reason: '', duration: '7d', note: '' });
  };

  const handleModerationSubmit = async () => {
    if (moderationModal.action === 'warn') {
      try {
        const response = await fetch('https://ec_admin_ultimate/warnPlayer', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            playerId: player.id,
            reason: formData.reason
          })
        });
        
        if (response.ok) {
          const result = await response.json();
          if (result.success) {
            toastSuccess({ title: 'Warning issued successfully' });
            await fetchPlayerProfile();
          } else {
            toastError({ title: 'Failed to issue warning', description: result.error });
          }
        }
      } catch (error) {
        console.error('Failed to warn player:', error);
        // Update local state in offline mode
        const newWarning = {
          id: warnings.length + 1,
          reason: formData.reason,
          issuedBy: 'Current_Admin',
          date: new Date().toISOString(),
          active: true,
          expires: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
        };
        setWarnings([...warnings, newWarning]);
        toastSuccess({ title: 'Warning issued (offline mode)' });
      }
    } else if (moderationModal.action === 'ban') {
      try {
        const response = await fetch('https://ec_admin_ultimate/banPlayer', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            playerId: player.id,
            reason: formData.reason,
            duration: formData.duration || '7d'
          })
        });
        
        if (response.ok) {
          const result = await response.json();
          if (result.success) {
            toastSuccess({ title: `Player banned` });
            await fetchPlayerProfile();
          } else {
            toastError({ title: 'Failed to ban player', description: result.error });
          }
        }
      } catch (error) {
        console.error('Failed to ban player:', error);
        toastSuccess({ title: 'Player banned (offline mode)' });
      }
    } else if (moderationModal.action === 'kick') {
      try {
        const response = await fetch('https://ec_admin_ultimate/kickPlayer', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            playerId: player.id,
            reason: formData.reason
          })
        });
        
        if (response.ok) {
          const result = await response.json();
          if (result.success) {
            toastSuccess({ title: 'Player kicked from server' });
            await fetchPlayerProfile();
          } else {
            toastError({ title: 'Failed to kick player', description: result.error });
          }
        }
      } catch (error) {
        console.error('Failed to kick player:', error);
        toastSuccess({ title: 'Player kicked (offline mode)' });
      }
    } else if (moderationModal.action === 'note') {
      const newNote = {
        id: moderationNotes.length + 1,
        note: formData.note,
        createdBy: 'Current_Admin',
        date: new Date().toISOString()
      };
      setModerationNotes([...moderationNotes, newNote]);
      toastSuccess({ title: 'Note added' });
    }
    setModerationModal({ isOpen: false, action: null });
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-center">
          <User className="size-12 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg">Loading Player Profile...</p>
          <p className="text-sm text-muted-foreground">Fetching comprehensive player data</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          {onBack && (
            <Button variant="outline" size="icon" onClick={onBack}>
              <ArrowLeft className="size-4" />
            </Button>
          )}
          <div>
            <h1 className="text-3xl tracking-tight">
              <span className="bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
                Player Profile - Full Admin Control
              </span>
            </h1>
            <p className="text-muted-foreground mt-1">
              Complete player management & moderation tools
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm">
            <Download className="size-4 mr-2" />
            Export Data
          </Button>
          <Button variant="outline" size="sm">
            <Copy className="size-4 mr-2" />
            Copy IDs
          </Button>
          <Button variant="outline" size="sm" onClick={handleRefresh} disabled={refreshing}>
            <RefreshCw className={`size-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
            {refreshing ? 'Refreshing...' : 'Refresh'}
          </Button>
        </div>
      </div>

      {/* Player Header Card */}
      <Card className="border-2">
        <CardContent className="p-6">
          <div className="flex items-start gap-6">
            <Avatar className="size-24">
              <AvatarFallback className="text-2xl bg-gradient-to-br from-blue-500 to-purple-500 text-white">
                {player.name.substring(0, 2).toUpperCase()}
              </AvatarFallback>
            </Avatar>

            <div className="flex-1 space-y-4">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <h2 className="text-2xl">{player.name}</h2>
                    <Badge variant={player.status === 'online' ? 'default' : 'secondary'} className="flex items-center gap-1">
                      <div className={`size-2 rounded-full ${player.status === 'online' ? 'bg-green-500' : 'bg-gray-400'}`} />
                      {player.status === 'online' ? 'Online' : 'Offline'}
                    </Badge>
                  </div>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                    <div>
                      <span className="text-muted-foreground">Steam ID:</span>
                      <p className="font-mono text-xs">{player.steamId.substring(0, 25)}...</p>
                    </div>
                    <div>
                      <span className="text-muted-foreground">License:</span>
                      <p className="font-mono text-xs">{player.license.substring(0, 20)}...</p>
                    </div>
                    <div>
                      <span className="text-muted-foreground">HWID:</span>
                      <p className="font-mono text-xs">{player.hwid}</p>
                    </div>
                    <div>
                      <span className="text-muted-foreground">IP Address:</span>
                      <p className="font-mono text-xs">{player.ip}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="text-right space-y-2">
              <div className="text-3xl">{formatMoney(player.money.cash + player.money.bank)}</div>
              <div className="text-sm text-muted-foreground">Total Worth</div>
              <div className="flex gap-2">
                <Badge variant="outline">Lv. {player.level}</Badge>
                <Badge variant="outline">{player.playtime}</Badge>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-7">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="inventory">Inventory</TabsTrigger>
          <TabsTrigger value="vehicles">Vehicles</TabsTrigger>
          <TabsTrigger value="properties">Properties</TabsTrigger>
          <TabsTrigger value="financial">Financial</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
          <TabsTrigger value="moderation">Moderation</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card>
              <CardHeader>
                <CardTitle>Performance Chart</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-[200px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={performanceData}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                      <XAxis dataKey="day" stroke="#64748b" fontSize={12} />
                      <YAxis stroke="#64748b" fontSize={12} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'hsl(var(--card))',
                          border: '1px solid hsl(var(--border))',
                          borderRadius: '8px'
                        }}
                      />
                      <Legend />
                      <Bar dataKey="playtime" fill="#3b82f6" name="Playtime (hrs)" />
                      <Bar dataKey="arrests" fill="#10b981" name="Arrests" />
                      <Bar dataKey="deaths" fill="#ef4444" name="Deaths" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Financial Trend</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-[200px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={moneyData}>
                      <defs>
                        <linearGradient id="colorCash" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                          <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                      <XAxis dataKey="day" stroke="#64748b" fontSize={12} />
                      <YAxis stroke="#64748b" fontSize={12} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'hsl(var(--card))',
                          border: '1px solid hsl(var(--border))',
                          borderRadius: '8px'
                        }}
                        formatter={(value: number) => formatMoney(value)}
                      />
                      <Area type="monotone" dataKey="cash" stroke="#10b981" fillOpacity={1} fill="url(#colorCash)" name="Cash" />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Inventory Tab - ENHANCED */}
        <TabsContent value="inventory" className="space-y-4">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg">Player Inventory</h3>
              <p className="text-sm text-muted-foreground">
                {inventory.length} items · {totalWeight.toFixed(1)}/{maxWeight} kg
              </p>
            </div>
            <div className="flex gap-2">
              <Button onClick={() => handleInventoryAction('add')}>
                <Plus className="size-4 mr-2" />
                Add Item
              </Button>
              <Button variant="outline" onClick={() => setStashModal({ isOpen: true })}>
                <Warehouse className="size-4 mr-2" />
                View Stashes
              </Button>
            </div>
          </div>

          <Card>
            <CardContent className="p-4">
              <ScrollArea className="h-[500px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Slot</TableHead>
                      <TableHead>Item</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead>Quantity</TableHead>
                      <TableHead>Weight</TableHead>
                      <TableHead>Metadata</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {inventory.map((item) => (
                      <TableRow key={item.id}>
                        <TableCell>{item.slot}</TableCell>
                        <TableCell>
                          <div>
                            <p className="font-medium">{item.name}</p>
                            <p className="text-xs text-muted-foreground">{item.description}</p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline">{item.type}</Badge>
                        </TableCell>
                        <TableCell>{item.quantity}</TableCell>
                        <TableCell>{(item.weight * item.quantity).toFixed(2)} kg</TableCell>
                        <TableCell>
                          {Object.keys(item.metadata).length > 0 ? (
                            <Button variant="ghost" size="sm">
                              <Info className="size-4" />
                            </Button>
                          ) : (
                            <span className="text-muted-foreground">-</span>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center justify-end gap-1">
                            <Button size="sm" variant="outline" onClick={() => handleInventoryAction('edit', item)}>
                              <Edit className="size-3" />
                            </Button>
                            <Button size="sm" variant="destructive" onClick={() => handleInventoryAction('remove', item)}>
                              <Trash2 className="size-3" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </ScrollArea>
            </CardContent>
          </Card>

          {/* Stashes Section */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Warehouse className="size-5" />
                Connected Stashes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {stashes.map((stash) => (
                  <Card key={stash.id} className="border-2">
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <h4 className="font-medium">{stash.name}</h4>
                          <p className="text-sm text-muted-foreground">{stash.location}</p>
                        </div>
                        <Badge variant={stash.locked ? 'destructive' : 'default'}>
                          {stash.locked ? <Lock className="size-3" /> : <Unlock className="size-3" />}
                        </Badge>
                      </div>
                      <div className="space-y-2">
                        <div className="flex justify-between text-sm">
                          <span className="text-muted-foreground">Items:</span>
                          <span className="font-medium">{stash.items}</span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-muted-foreground">Weight:</span>
                          <span className="font-medium">{stash.weight.toFixed(1)}/{stash.maxWeight} kg</span>
                        </div>
                        <Progress value={(stash.weight / stash.maxWeight) * 100} className="h-2" />
                        <Button size="sm" className="w-full mt-2" onClick={() => setStashModal({ isOpen: true, stashId: stash.id, stashName: stash.name })}>
                          <Eye className="size-3 mr-2" />
                          View Contents
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Vehicles Tab - ENHANCED */}
        <TabsContent value="vehicles" className="space-y-4">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg">Player Vehicles</h3>
              <p className="text-sm text-muted-foreground">
                {vehicles.length} vehicles · Total value: {formatMoney(vehicles.reduce((acc, v) => acc + v.value, 0))}
              </p>
            </div>
            <Button onClick={() => handleVehicleAction('add')}>
              <Plus className="size-4 mr-2" />
              Add Vehicle
            </Button>
          </div>

          <Card>
            <CardContent className="p-4">
              <ScrollArea className="h-[500px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Model</TableHead>
                      <TableHead>Plate</TableHead>
                      <TableHead>Location</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Condition</TableHead>
                      <TableHead>Mods</TableHead>
                      <TableHead>Value</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {vehicles.map((vehicle) => (
                      <TableRow key={vehicle.id}>
                        <TableCell>
                          <div>
                            <p className="font-medium">{vehicle.model}</p>
                            <p className="text-xs text-muted-foreground">{vehicle.color.primary} / {vehicle.color.secondary}</p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <code className="text-xs bg-muted px-2 py-1 rounded">{vehicle.plate}</code>
                        </TableCell>
                        <TableCell>{vehicle.location}</TableCell>
                        <TableCell>
                          {vehicle.impounded ? (
                            <Badge variant="destructive">Impounded</Badge>
                          ) : vehicle.stored ? (
                            <Badge variant="outline">Stored</Badge>
                          ) : (
                            <Badge variant="default">Out</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="space-y-1">
                            <div className="flex items-center gap-2 text-xs">
                              <Gauge className="size-3" />
                              <Progress value={vehicle.engine / 10} className="w-16 h-1" />
                            </div>
                            <div className="flex items-center gap-2 text-xs">
                              <Fuel className="size-3" />
                              <Progress value={vehicle.fuel} className="w-16 h-1" />
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="text-xs">
                            <p>Engine: {vehicle.mods.engine}</p>
                            <p>Trans: {vehicle.mods.transmission}</p>
                          </div>
                        </TableCell>
                        <TableCell>{vehicle.value > 0 ? formatMoney(vehicle.value) : 'N/A'}</TableCell>
                        <TableCell>
                          <div className="flex items-center justify-end gap-1 flex-wrap">
                            {/* Quick Actions */}
                            {vehicle.impounded ? (
                              <Button size="sm" variant="default" onClick={() => handleVehicleAction('unimpound', vehicle)} title="Release from Impound">
                                <Unlock className="size-3" />
                              </Button>
                            ) : vehicle.stored ? (
                              <Button size="sm" variant="default" onClick={() => handleVehicleAction('spawn', vehicle)} title="Spawn Vehicle">
                                <Zap className="size-3" />
                              </Button>
                            ) : (
                              <Button size="sm" variant="default" onClick={() => handleVehicleAction('store', vehicle)} title="Store in Garage">
                                <Archive className="size-3" />
                              </Button>
                            )}
                            
                            {/* Repair & Refuel */}
                            <Button size="sm" variant="outline" onClick={() => handleVehicleAction('repair', vehicle)} title="Repair Vehicle">
                              <Wrench className="size-3" />
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => handleVehicleAction('refuel', vehicle)} title="Refuel">
                              <Fuel className="size-3" />
                            </Button>
                            
                            {/* Customization */}
                            <Button size="sm" variant="outline" onClick={() => handleVehicleAction('rename', vehicle)} title="Change Plate">
                              <Tag className="size-3" />
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => handleVehicleAction('color', vehicle)} title="Change Colors">
                              <Paintbrush className="size-3" />
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => handleVehicleAction('upgrade', vehicle)} title="Upgrade Mods">
                              <Cog className="size-3" />
                            </Button>
                            
                            {/* Management */}
                            <Button size="sm" variant="outline" onClick={() => handleVehicleAction('transfer', vehicle)} title="Transfer Ownership">
                              <Send className="size-3" />
                            </Button>
                            {!vehicle.impounded && (
                              <Button size="sm" variant="outline" onClick={() => handleVehicleAction('impound', vehicle)} title="Impound">
                                <Lock className="size-3" />
                              </Button>
                            )}
                            <Button size="sm" variant="destructive" onClick={() => handleVehicleAction('remove', vehicle)} title="Delete Vehicle">
                              <Trash2 className="size-3" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Properties Tab - ENHANCED */}
        <TabsContent value="properties" className="space-y-4">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg">Player Properties</h3>
              <p className="text-sm text-muted-foreground">
                {properties.length} properties · Total value: {formatMoney(properties.reduce((acc, p) => acc + p.price, 0))}
              </p>
            </div>
            <Button onClick={() => handlePropertyAction('add')}>
              <Plus className="size-4 mr-2" />
              Add Property
            </Button>
          </div>

          <div className="grid grid-cols-1 gap-4">
            {properties.map((property) => (
              <Card key={property.id} className="border-2">
                <CardContent className="p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-3">
                        <Badge>{property.type}</Badge>
                        <Badge variant="outline">{property.tier}</Badge>
                        <h3 className="text-lg font-medium">{property.address}</h3>
                      </div>
                      
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
                        <div>
                          <span className="text-sm text-muted-foreground">Value:</span>
                          <p className="font-medium">{formatMoney(property.price)}</p>
                        </div>
                        <div>
                          <span className="text-sm text-muted-foreground">Garage:</span>
                          <p className="font-medium">{property.garage} vehicles</p>
                        </div>
                        <div>
                          <span className="text-sm text-muted-foreground">Status:</span>
                          <Badge variant={property.locked ? 'destructive' : 'default'}>
                            {property.locked ? <Lock className="size-3 mr-1" /> : <Unlock className="size-3 mr-1" />}
                            {property.locked ? 'Locked' : 'Unlocked'}
                          </Badge>
                        </div>
                        <div>
                          <span className="text-sm text-muted-foreground">Features:</span>
                          <div className="flex gap-1">
                            {property.hasStash && <Badge variant="outline">Stash</Badge>}
                            {property.hasWardrobe && <Badge variant="outline">Wardrobe</Badge>}
                          </div>
                        </div>
                      </div>

                      <div className="mb-4">
                        <span className="text-sm text-muted-foreground">Key Holders:</span>
                        <div className="flex gap-2 mt-2">
                          {property.keys.map((key, idx) => (
                            <Badge key={idx} variant="secondary">
                              <Key className="size-3 mr-1" />
                              {key}
                            </Badge>
                          ))}
                        </div>
                      </div>

                      <div className="text-xs text-muted-foreground">
                        Coords: {property.coords.x.toFixed(2)}, {property.coords.y.toFixed(2)}, {property.coords.z.toFixed(2)}
                      </div>
                    </div>

                    <div className="flex flex-col gap-2">
                      <Button size="sm" variant="outline" onClick={() => handlePropertyAction('keys', property)}>
                        <Key className="size-3 mr-2" />
                        Manage Keys
                      </Button>
                      <Button size="sm" variant="outline" onClick={() => handlePropertyAction('lock', property)}>
                        {property.locked ? <Unlock className="size-3 mr-2" /> : <Lock className="size-3 mr-2" />}
                        {property.locked ? 'Unlock' : 'Lock'}
                      </Button>
                      <Button size="sm" variant="outline">
                        <MapPin className="size-3 mr-2" />
                        Teleport
                      </Button>
                      <Button size="sm" variant="destructive" onClick={() => handlePropertyAction('remove', property)}>
                        <Trash2 className="size-3 mr-2" />
                        Remove
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Financial Tab - ENHANCED */}
        <TabsContent value="financial" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-green-500/10 rounded-lg">
                      <DollarSign className="size-5 text-green-500" />
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Cash</p>
                      <p className="text-xl">{formatMoney(player.money.cash)}</p>
                    </div>
                  </div>
                </div>
                <div className="flex gap-1 mt-2">
                  <Button size="sm" variant="outline" className="flex-1" onClick={() => handleFinanceAction('add', 'cash')}>
                    <Plus className="size-3" />
                  </Button>
                  <Button size="sm" variant="outline" className="flex-1" onClick={() => handleFinanceAction('remove', 'cash')}>
                    <Minus className="size-3" />
                  </Button>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-500/10 rounded-lg">
                      <CreditCard className="size-5 text-blue-500" />
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Bank</p>
                      <p className="text-xl">{formatMoney(player.money.bank)}</p>
                    </div>
                  </div>
                </div>
                <div className="flex gap-1 mt-2">
                  <Button size="sm" variant="outline" className="flex-1" onClick={() => handleFinanceAction('add', 'bank')}>
                    <Plus className="size-3" />
                  </Button>
                  <Button size="sm" variant="outline" className="flex-1" onClick={() => handleFinanceAction('remove', 'bank')}>
                    <Minus className="size-3" />
                  </Button>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-yellow-500/10 rounded-lg">
                      <Bitcoin className="size-5 text-yellow-500" />
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Crypto</p>
                      <p className="text-xl">{formatMoney(player.money.crypto)}</p>
                    </div>
                  </div>
                </div>
                <div className="flex gap-1 mt-2">
                  <Button size="sm" variant="outline" className="flex-1" onClick={() => handleFinanceAction('add', 'crypto')}>
                    <Plus className="size-3" />
                  </Button>
                  <Button size="sm" variant="outline" className="flex-1" onClick={() => handleFinanceAction('remove', 'crypto')}>
                    <Minus className="size-3" />
                  </Button>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3 mb-2">
                  <div className="p-2 bg-purple-500/10 rounded-lg">
                    <Wallet className="size-5 text-purple-500" />
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Total</p>
                    <p className="text-xl">{formatMoney(player.money.cash + player.money.bank + player.money.crypto)}</p>
                  </div>
                </div>
                <Button size="sm" variant="outline" className="w-full mt-2">
                  <Receipt className="size-3 mr-2" />
                  Full Report
                </Button>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <History className="size-5" />
                Complete Transaction History
              </CardTitle>
              <CardDescription>All financial transactions for this player</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[400px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Type</TableHead>
                      <TableHead>Amount</TableHead>
                      <TableHead>From</TableHead>
                      <TableHead>To</TableHead>
                      <TableHead>Balance After</TableHead>
                      <TableHead>Details</TableHead>
                      <TableHead>Timestamp</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {transactions.map((transaction) => (
                      <TableRow key={transaction.id}>
                        <TableCell>
                          <Badge variant={transaction.amount > 0 ? 'default' : 'outline'}>
                            {transaction.type === 'deposit' && <TrendingUp className="size-3 mr-1" />}
                            {transaction.type === 'withdrawal' && <TrendingDown className="size-3 mr-1" />}
                            {transaction.type}
                          </Badge>
                        </TableCell>
                        <TableCell className={transaction.amount < 0 ? 'text-red-500' : 'text-green-500'}>
                          {transaction.amount > 0 ? '+' : ''}{formatMoney(transaction.amount)}
                        </TableCell>
                        <TableCell className="text-sm">{transaction.from}</TableCell>
                        <TableCell className="text-sm">{transaction.to}</TableCell>
                        <TableCell>{formatMoney(transaction.balance)}</TableCell>
                        <TableCell className="text-sm text-muted-foreground">{transaction.details}</TableCell>
                        <TableCell className="text-sm">{formatTimestamp(transaction.timestamp)}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Activity Tab - ENHANCED */}
        <TabsContent value="activity" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <History className="size-5" />
                Complete Activity Log
              </CardTitle>
              <CardDescription>All actions and events for this player</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px]">
                <div className="space-y-3">
                  {activityHistory.map((activity) => (
                    <div key={activity.id} className="flex items-start gap-3 p-3 rounded-lg border hover:bg-accent/50 transition-colors">
                      <div className={`p-2 rounded-lg ${
                        activity.type === 'connection' ? 'bg-blue-500/10' :
                        activity.type === 'purchase' ? 'bg-green-500/10' :
                        activity.type === 'warning' ? 'bg-yellow-500/10' :
                        activity.type === 'transaction' ? 'bg-purple-500/10' :
                        activity.type === 'admin' ? 'bg-red-500/10' :
                        'bg-gray-500/10'
                      }`}>
                        {activity.type === 'connection' && <Globe className="size-4 text-blue-500" />}
                        {activity.type === 'purchase' && <ShoppingBag className="size-4 text-green-500" />}
                        {activity.type === 'warning' && <AlertTriangle className="size-4 text-yellow-500" />}
                        {activity.type === 'transaction' && <DollarSign className="size-4 text-purple-500" />}
                        {activity.type === 'job' && <Briefcase className="size-4 text-orange-500" />}
                        {activity.type === 'admin' && <Shield className="size-4 text-red-500" />}
                        {activity.type === 'vehicle' && <Car className="size-4 text-cyan-500" />}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-start justify-between">
                          <div>
                            <p className="font-medium">{activity.action}</p>
                            <p className="text-sm text-muted-foreground">{activity.details}</p>
                            {activity.admin && (
                              <Badge variant="outline" className="mt-1">
                                <Shield className="size-3 mr-1" />
                                By: {activity.admin}
                              </Badge>
                            )}
                          </div>
                          <span className="text-xs text-muted-foreground">{formatTimestamp(activity.timestamp)}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Moderation Tab - COMPLETELY ENHANCED */}
        <TabsContent value="moderation" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-yellow-500/10 rounded-lg">
                    <AlertTriangle className="size-5 text-yellow-500" />
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Warnings</p>
                    <p className="text-2xl">{player.warnings}</p>
                  </div>
                </div>
                <Button size="sm" variant="outline" className="w-full mt-2" onClick={() => handleModerationAction('warn')}>
                  <Plus className="size-3 mr-2" />
                  Issue Warning
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-red-500/10 rounded-lg">
                    <Ban className="size-5 text-red-500" />
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Bans</p>
                    <p className="text-2xl">{player.bans}</p>
                  </div>
                </div>
                <Button size="sm" variant="destructive" className="w-full mt-2" onClick={() => handleModerationAction('ban')}>
                  <Ban className="size-3 mr-2" />
                  Ban Player
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-orange-500/10 rounded-lg">
                    <UserX className="size-5 text-orange-500" />
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Kicks</p>
                    <p className="text-2xl">{player.kicks}</p>
                  </div>
                </div>
                <Button size="sm" variant="outline" className="w-full mt-2" onClick={() => handleModerationAction('kick')}>
                  <UserX className="size-3 mr-2" />
                  Kick Player
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-blue-500/10 rounded-lg">
                    <FileText className="size-5 text-blue-500" />
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Notes</p>
                    <p className="text-2xl">{moderationNotes.length}</p>
                  </div>
                </div>
                <Button size="sm" variant="outline" className="w-full mt-2" onClick={() => handleModerationAction('note')}>
                  <Plus className="size-3 mr-2" />
                  Add Note
                </Button>
              </CardContent>
            </Card>
          </div>

          {/* Active Warnings */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle className="size-5" />
                Active Warnings
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Reason</TableHead>
                    <TableHead>Issued By</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Expires</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {warnings.map((warning) => (
                    <TableRow key={warning.id}>
                      <TableCell>{warning.reason}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-1">
                          <Shield className="size-3 text-muted-foreground" />
                          {warning.issuedBy}
                        </div>
                      </TableCell>
                      <TableCell>{formatTimestamp(warning.date)}</TableCell>
                      <TableCell>{formatTimestamp(warning.expires)}</TableCell>
                      <TableCell>
                        <Badge variant={warning.active ? 'default' : 'secondary'}>
                          {warning.active ? 'Active' : 'Expired'}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Button size="sm" variant="outline">
                          Revoke
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>

          {/* Moderation Notes */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="size-5" />
                Moderation Notes
              </CardTitle>
              <CardDescription>Internal admin notes about this player</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {moderationNotes.map((note) => (
                  <div key={note.id} className="p-3 rounded-lg border">
                    <div className="flex items-start justify-between mb-2">
                      <Badge variant="outline">
                        <Shield className="size-3 mr-1" />
                        {note.createdBy}
                      </Badge>
                      <span className="text-xs text-muted-foreground">{formatTimestamp(note.date)}</span>
                    </div>
                    <p className="text-sm">{note.note}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Ban History */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Ban className="size-5" />
                Ban History
              </CardTitle>
            </CardHeader>
            <CardContent>
              {bans.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  <CheckCircle className="size-12 mx-auto mb-4 opacity-50" />
                  <p>No bans on record</p>
                  <p className="text-sm">Player has a clean moderation history</p>
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Reason</TableHead>
                      <TableHead>Banned By</TableHead>
                      <TableHead>Date</TableHead>
                      <TableHead>Duration</TableHead>
                      <TableHead>Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {/* Ban rows would go here */}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* All Modals */}
      
      {/* Inventory Modal */}
      <Dialog open={inventoryModal.isOpen} onOpenChange={(open) => !open && setInventoryModal({ isOpen: false, action: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {inventoryModal.action === 'add' && 'Add Item to Inventory'}
              {inventoryModal.action === 'remove' && 'Remove Item from Inventory'}
              {inventoryModal.action === 'edit' && 'Edit Item'}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            {inventoryModal.action !== 'remove' && (
              <>
                <div className="space-y-2">
                  <Label>Item Name</Label>
                  <Input value={formData.name || ''} onChange={(e) => setFormData({ ...formData, name: e.target.value })} />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Quantity</Label>
                    <Input type="number" value={formData.quantity || 1} onChange={(e) => setFormData({ ...formData, quantity: parseInt(e.target.value) })} />
                  </div>
                  <div className="space-y-2">
                    <Label>Weight (kg)</Label>
                    <Input type="number" step="0.1" value={formData.weight || 0.1} onChange={(e) => setFormData({ ...formData, weight: parseFloat(e.target.value) })} />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label>Type</Label>
                  <Select value={formData.type || 'item'} onValueChange={(value) => setFormData({ ...formData, type: value })}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="item">Item</SelectItem>
                      <SelectItem value="weapon">Weapon</SelectItem>
                      <SelectItem value="food">Food</SelectItem>
                      <SelectItem value="drink">Drink</SelectItem>
                      <SelectItem value="medical">Medical</SelectItem>
                      <SelectItem value="ammo">Ammo</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </>
            )}
            {inventoryModal.action === 'remove' && (
              <p>Are you sure you want to remove <strong>{inventoryModal.item?.name}</strong> from the inventory?</p>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setInventoryModal({ isOpen: false, action: null })}>Cancel</Button>
            <Button onClick={handleInventorySubmit}>
              {inventoryModal.action === 'remove' ? 'Remove' : 'Confirm'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Vehicle Modal */}
      <Dialog open={vehicleModal.isOpen} onOpenChange={(open) => !open && setVehicleModal({ isOpen: false, action: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {vehicleModal.action === 'add' && 'Add Vehicle'}
              {vehicleModal.action === 'remove' && 'Remove Vehicle'}
              {vehicleModal.action === 'rename' && 'Rename Plate'}
              {vehicleModal.action === 'upgrade' && 'Upgrade Vehicle'}
              {vehicleModal.action === 'impound' && 'Impound Vehicle'}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            {vehicleModal.action === 'add' && (
              <>
                <div className="space-y-2">
                  <Label>Model</Label>
                  <Input value={formData.model || ''} onChange={(e) => setFormData({ ...formData, model: e.target.value })} placeholder="e.g. Adder" />
                </div>
                <div className="space-y-2">
                  <Label>Plate</Label>
                  <Input value={formData.plate || ''} onChange={(e) => setFormData({ ...formData, plate: e.target.value })} placeholder="e.g. ABC 123" />
                </div>
              </>
            )}
            {vehicleModal.action === 'rename' && (
              <div className="space-y-2">
                <Label>New Plate</Label>
                <Input value={formData.plate || ''} onChange={(e) => setFormData({ ...formData, plate: e.target.value })} />
              </div>
            )}
            {vehicleModal.action === 'upgrade' && (
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Engine (0-4)</Label>
                  <Input type="number" min="0" max="4" value={formData.engine || 0} onChange={(e) => setFormData({ ...formData, engine: parseInt(e.target.value) })} />
                </div>
                <div className="space-y-2">
                  <Label>Transmission (0-3)</Label>
                  <Input type="number" min="0" max="3" value={formData.transmission || 0} onChange={(e) => setFormData({ ...formData, transmission: parseInt(e.target.value) })} />
                </div>
                <div className="space-y-2">
                  <Label>Brakes (0-2)</Label>
                  <Input type="number" min="0" max="2" value={formData.brakes || 0} onChange={(e) => setFormData({ ...formData, brakes: parseInt(e.target.value) })} />
                </div>
                <div className="space-y-2 flex items-center">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" checked={formData.turbo || false} onChange={(e) => setFormData({ ...formData, turbo: e.target.checked })} className="size-4" />
                    <span>Turbo</span>
                  </label>
                </div>
              </div>
            )}
            {vehicleModal.action === 'impound' && (
              <div className="space-y-2">
                <Label>Impound Reason</Label>
                <Textarea value={formData.reason || ''} onChange={(e) => setFormData({ ...formData, reason: e.target.value })} placeholder="Reason for impound..." />
              </div>
            )}
            {vehicleModal.action === 'remove' && (
              <p>Are you sure you want to permanently remove <strong>{vehicleModal.vehicle?.model} ({vehicleModal.vehicle?.plate})</strong>?</p>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setVehicleModal({ isOpen: false, action: null })}>Cancel</Button>
            <Button onClick={handleVehicleSubmit}>Confirm</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Property Modal */}
      <Dialog open={propertyModal.isOpen} onOpenChange={(open) => !open && setPropertyModal({ isOpen: false, action: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {propertyModal.action === 'add' && 'Add Property'}
              {propertyModal.action === 'remove' && 'Remove Property'}
              {propertyModal.action === 'keys' && 'Manage Keys'}
              {propertyModal.action === 'lock' && 'Toggle Lock'}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            {propertyModal.action === 'add' && (
              <>
                <div className="space-y-2">
                  <Label>Address</Label>
                  <Input value={formData.address || ''} onChange={(e) => setFormData({ ...formData, address: e.target.value })} placeholder="e.g. 123 Main Street" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Type</Label>
                    <Select value={formData.type || 'House'} onValueChange={(value) => setFormData({ ...formData, type: value })}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="House">House</SelectItem>
                        <SelectItem value="Apartment">Apartment</SelectItem>
                        <SelectItem value="Office">Office</SelectItem>
                        <SelectItem value="Warehouse">Warehouse</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Garage Size</Label>
                    <Input type="number" value={formData.garage || 2} onChange={(e) => setFormData({ ...formData, garage: parseInt(e.target.value) })} />
                  </div>
                </div>
              </>
            )}
            {propertyModal.action === 'keys' && (
              <div className="space-y-2">
                <Label>Key Holders (comma separated)</Label>
                <Input 
                  value={formData.keys?.join(', ') || ''} 
                  onChange={(e) => setFormData({ ...formData, keys: e.target.value.split(',').map(k => k.trim()) })} 
                  placeholder="e.g. John_Doe, Jane_Smith"
                />
              </div>
            )}
            {propertyModal.action === 'remove' && (
              <p>Are you sure you want to remove <strong>{propertyModal.property?.address}</strong>?</p>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setPropertyModal({ isOpen: false, action: null })}>Cancel</Button>
            <Button onClick={handlePropertySubmit}>Confirm</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Finance Modal */}
      <Dialog open={financeModal.isOpen} onOpenChange={(open) => !open && setFinanceModal({ isOpen: false, action: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {financeModal.action === 'add' && `Add ${financeModal.type?.toUpperCase()}`}
              {financeModal.action === 'remove' && `Remove ${financeModal.type?.toUpperCase()}`}
              {financeModal.action === 'transfer' && 'Transfer Money'}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label>Amount</Label>
              <Input 
                type="number" 
                value={formData.amount || 0} 
                onChange={(e) => setFormData({ ...formData, amount: e.target.value })} 
                placeholder="Enter amount..."
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setFinanceModal({ isOpen: false, action: null })}>Cancel</Button>
            <Button onClick={handleFinanceSubmit}>Confirm</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Moderation Modal */}
      <Dialog open={moderationModal.isOpen} onOpenChange={(open) => !open && setModerationModal({ isOpen: false, action: null })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {moderationModal.action === 'warn' && 'Issue Warning'}
              {moderationModal.action === 'ban' && 'Ban Player'}
              {moderationModal.action === 'kick' && 'Kick Player'}
              {moderationModal.action === 'note' && 'Add Moderation Note'}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            {moderationModal.action === 'note' ? (
              <div className="space-y-2">
                <Label>Note</Label>
                <Textarea 
                  value={formData.note || ''} 
                  onChange={(e) => setFormData({ ...formData, note: e.target.value })} 
                  placeholder="Enter note..."
                  rows={4}
                />
              </div>
            ) : (
              <>
                <div className="space-y-2">
                  <Label>Reason</Label>
                  <Textarea 
                    value={formData.reason || ''} 
                    onChange={(e) => setFormData({ ...formData, reason: e.target.value })} 
                    placeholder="Enter reason..."
                  />
                </div>
                {moderationModal.action === 'ban' && (
                  <div className="space-y-2">
                    <Label>Duration</Label>
                    <Input 
                      value={formData.duration || '7d'} 
                      onChange={(e) => setFormData({ ...formData, duration: e.target.value })} 
                      placeholder="e.g. 7d, permanent"
                    />
                  </div>
                )}
              </>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModerationModal({ isOpen: false, action: null })}>Cancel</Button>
            <Button onClick={handleModerationSubmit}>Confirm</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Stash Modal */}
      <Dialog open={stashModal.isOpen} onOpenChange={(open) => !open && setStashModal({ isOpen: false })}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle>
              Stash Contents: {stashModal.stashName}
            </DialogTitle>
            <DialogDescription>
              View and manage items in this storage location
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <ScrollArea className="h-[400px]">
              <div className="grid grid-cols-3 gap-3">
                {/* Mock stash items - would be loaded based on stashId */}
                {[1, 2, 3, 4, 5, 6].map((i) => (
                  <Card key={i} className="border-2">
                    <CardContent className="p-3">
                      <div className="flex items-start justify-between mb-2">
                        <h4 className="font-medium text-sm">Item {i}</h4>
                        <Badge variant="outline">5x</Badge>
                      </div>
                      <p className="text-xs text-muted-foreground mb-2">Description here</p>
                      <Button size="sm" variant="outline" className="w-full">
                        <Trash2 className="size-3 mr-1" />
                        Remove
                      </Button>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </ScrollArea>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setStashModal({ isOpen: false })}>Close</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}