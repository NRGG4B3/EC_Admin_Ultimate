import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Input } from '../ui/input';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { ScrollArea } from '../ui/scroll-area';
import { 
  Home, Users, Search, Plus, Trash2, Edit, RefreshCw, 
  Building, MapPin, DollarSign, Key, Clock, TrendingUp,
  Lock, Unlock, UserMinus, AlertTriangle, BarChart3,
  X, CheckCircle, Package, Car, Navigation, Eye
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';

interface HousingPageProps {
  liveData: any;
}

interface Property {
  id: string | number;
  name: string;
  label: string;
  type: string;
  address: string;
  owner?: string;
  ownerName: string;
  citizenid?: string;
  price: number;
  owned: boolean;
  garage: number;
  locked: boolean;
  hasKeys: string[];
  coords: { x: number; y: number; z: number };
  tier: number;
  metadata?: any;
}

interface Rental {
  id: string | number;
  property: string;
  propertyName: string;
  tenant: string;
  tenantName: string;
  landlord: string;
  landlordName: string;
  rent: number;
  nextPayment: string;
  status: string;
  dueDate: number;
}

interface Transaction {
  id: string | number;
  property: string;
  propertyName: string;
  buyer: string;
  buyerName: string;
  seller: string;
  sellerName: string;
  price: number;
  date: string;
  timestamp: number;
  type: string;
}

interface HousingData {
  properties: Property[];
  rentals: Rental[];
  transactions: Transaction[];
  stats: {
    totalProperties: number;
    ownedProperties: number;
    vacantProperties: number;
    totalValue: number;
    activeRentals: number;
    monthlyRentIncome: number;
  };
  framework: string;
  housingSystem: string;
}

export function HousingPage({ liveData }: HousingPageProps) {
  const [activeTab, setActiveTab] = useState('properties');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [data, setData] = useState<HousingData | null>(null);
  const [selectedProperty, setSelectedProperty] = useState<Property | null>(null);
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [filterType, setFilterType] = useState<string>('all');

  // Modals
  const [viewModal, setViewModal] = useState<{ isOpen: boolean; property?: Property }>({ isOpen: false });
  const [transferModal, setTransferModal] = useState<{ isOpen: boolean; property?: Property }>({ isOpen: false });
  const [evictModal, setEvictModal] = useState<{ isOpen: boolean; property?: Property }>({ isOpen: false });
  const [deleteModal, setDeleteModal] = useState<{ isOpen: boolean; property?: Property }>({ isOpen: false });
  const [priceModal, setPriceModal] = useState<{ isOpen: boolean; property?: Property }>({ isOpen: false });

  const [formData, setFormData] = useState<any>({});

  // Fetch housing data
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/housing:getData', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        // Data will be received via NUI message
      }
    } catch (error) {
      console.log('[Housing] Not in FiveM environment');
    }
  }, []);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      if (action === 'housingData') {
        if (msgData.success) {
          setData(msgData.data);
        }
      } else if (action === 'housingResponse') {
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

    // Auto-refresh every 20 seconds
    const interval = setInterval(() => {
      fetchData();
    }, 20000);

    return () => clearInterval(interval);
  }, [fetchData]);

  // Manual refresh
  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
    toastSuccess({ title: 'Data refreshed' });
  };

  // Transfer property
  const handleTransferProperty = async () => {
    if (!transferModal.property || !formData.newOwnerId) {
      toastError({ title: 'Please fill all fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/housing:transferProperty', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          propertyId: transferModal.property.id,
          newOwnerId: formData.newOwnerId
        })
      });

      setTransferModal({ isOpen: false });
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to transfer property' });
    }
  };

  // Evict property
  const handleEvictProperty = async () => {
    if (!evictModal.property) return;

    try {
      await fetch('https://ec_admin_ultimate/housing:evictProperty', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          propertyId: evictModal.property.id
        })
      });

      setEvictModal({ isOpen: false });
    } catch (error) {
      toastError({ title: 'Failed to evict property' });
    }
  };

  // Delete property
  const handleDeleteProperty = async () => {
    if (!deleteModal.property) return;

    try {
      await fetch('https://ec_admin_ultimate/housing:deleteProperty', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          propertyId: deleteModal.property.id
        })
      });

      setDeleteModal({ isOpen: false });
    } catch (error) {
      toastError({ title: 'Failed to delete property' });
    }
  };

  // Set price
  const handleSetPrice = async () => {
    if (!priceModal.property || !formData.newPrice) {
      toastError({ title: 'Please enter a price' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/housing:setPropertyPrice', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          propertyId: priceModal.property.id,
          price: parseInt(formData.newPrice)
        })
      });

      setPriceModal({ isOpen: false });
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to set price' });
    }
  };

  // Format currency
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0
    }).format(amount);
  };

  // Format date
  const formatDate = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleDateString();
  };

  // Get data from state
  const properties = data?.properties || [];
  const rentals = data?.rentals || [];
  const transactions = data?.transactions || [];
  const stats = data?.stats || {
    totalProperties: 0,
    ownedProperties: 0,
    vacantProperties: 0,
    totalValue: 0,
    activeRentals: 0,
    monthlyRentIncome: 0
  };
  const framework = data?.framework || 'Unknown';
  const housingSystem = data?.housingSystem || 'Unknown';

  // Filter properties
  const filteredProperties = properties.filter(p => {
    const matchesSearch = p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         p.address.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         p.ownerName.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = filterStatus === 'all' || 
                         (filterStatus === 'owned' && p.owned) ||
                         (filterStatus === 'vacant' && !p.owned);
    
    const matchesType = filterType === 'all' || p.type === filterType;
    
    return matchesSearch && matchesStatus && matchesType;
  });

  // Get unique property types
  const propertyTypes = ['all', ...new Set(properties.map(p => p.type))];

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Home className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading Housing System...</p>
          <p className="text-sm text-muted-foreground">Fetching property data</p>
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
            <Home className="size-8 text-primary" />
            Housing Management
          </h1>
          <p className="text-muted-foreground mt-1">
            {housingSystem} • {framework}
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
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-500/10 rounded-lg">
                <Building className="size-6 text-blue-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Properties</p>
                <p className="text-xl font-bold">{stats.totalProperties}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-500/10 rounded-lg">
                <CheckCircle className="size-6 text-green-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Owned</p>
                <p className="text-xl font-bold">{stats.ownedProperties}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-orange-500/10 rounded-lg">
                <Home className="size-6 text-orange-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Vacant</p>
                <p className="text-xl font-bold">{stats.vacantProperties}</p>
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
                <p className="text-xl font-bold">{formatCurrency(stats.totalValue)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-pink-500/10 rounded-lg">
                <Key className="size-6 text-pink-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Active Rentals</p>
                <p className="text-xl font-bold">{stats.activeRentals}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-cyan-500/10 rounded-lg">
                <TrendingUp className="size-6 text-cyan-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Monthly Rent</p>
                <p className="text-xl font-bold">{formatCurrency(stats.monthlyRentIncome)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="properties" className="flex items-center gap-2">
            <Building className="size-4" />
            Properties ({filteredProperties.length})
          </TabsTrigger>
          <TabsTrigger value="rentals" className="flex items-center gap-2">
            <Key className="size-4" />
            Rentals ({rentals.length})
          </TabsTrigger>
          <TabsTrigger value="transactions" className="flex items-center gap-2">
            <BarChart3 className="size-4" />
            Transactions ({transactions.length})
          </TabsTrigger>
        </TabsList>

        {/* Properties Tab */}
        <TabsContent value="properties" className="space-y-4 mt-6">
          {/* Search & Filters */}
          <div className="flex items-center gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                placeholder="Search properties..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9"
              />
            </div>
            <Select value={filterStatus} onValueChange={setFilterStatus}>
              <SelectTrigger className="w-[150px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="owned">Owned</SelectItem>
                <SelectItem value="vacant">Vacant</SelectItem>
              </SelectContent>
            </Select>
            <Select value={filterType} onValueChange={setFilterType}>
              <SelectTrigger className="w-[150px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {propertyTypes.map(type => (
                  <SelectItem key={type} value={type}>
                    {type.charAt(0).toUpperCase() + type.slice(1)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Properties Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredProperties.length === 0 ? (
              <div className="col-span-full text-center py-12 text-muted-foreground">
                <Building className="size-8 mx-auto mb-2 opacity-50" />
                <p>No properties found</p>
              </div>
            ) : (
              filteredProperties.map((property) => (
                <Card key={property.id} className="hover:shadow-lg transition-shadow">
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div>
                        <CardTitle className="text-lg">{property.label}</CardTitle>
                        <p className="text-sm text-muted-foreground mt-1 flex items-center gap-1">
                          <MapPin className="size-3" />
                          {property.address}
                        </p>
                      </div>
                      <Badge variant={property.owned ? 'default' : 'secondary'}>
                        {property.owned ? 'Owned' : 'Vacant'}
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-3">
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Owner</span>
                      <span className="font-bold">{property.ownerName}</span>
                    </div>
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Price</span>
                      <span className="font-bold">{formatCurrency(property.price)}</span>
                    </div>
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Type</span>
                      <Badge variant="outline">{property.type}</Badge>
                    </div>
                    {property.garage > 0 && (
                      <div className="flex justify-between items-center text-sm">
                        <span className="text-muted-foreground">Garage</span>
                        <Badge variant="outline">
                          <Car className="size-3 mr-1" />
                          {property.garage} spaces
                        </Badge>
                      </div>
                    )}
                    <div className="flex gap-2 pt-2">
                      <Button 
                        variant="outline" 
                        size="sm"
                        className="flex-1"
                        onClick={() => setViewModal({ isOpen: true, property })}
                      >
                        <Eye className="size-4 mr-1" />
                        View
                      </Button>
                      <Button 
                        variant="outline" 
                        size="sm"
                        className="flex-1"
                        onClick={() => setTransferModal({ isOpen: true, property })}
                        disabled={!property.owned}
                      >
                        <Key className="size-4 mr-1" />
                        Transfer
                      </Button>
                    </div>
                    <div className="flex gap-2">
                      <Button 
                        variant="outline" 
                        size="sm"
                        className="flex-1"
                        onClick={() => setPriceModal({ isOpen: true, property })}
                      >
                        <DollarSign className="size-4 mr-1" />
                        Price
                      </Button>
                      {property.owned && (
                        <Button 
                          variant="outline" 
                          size="sm"
                          className="flex-1"
                          onClick={() => setEvictModal({ isOpen: true, property })}
                        >
                          <UserMinus className="size-4 mr-1" />
                          Evict
                        </Button>
                      )}
                      <Button 
                        variant="destructive" 
                        size="sm"
                        onClick={() => setDeleteModal({ isOpen: true, property })}
                      >
                        <Trash2 className="size-4" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Rentals Tab */}
        <TabsContent value="rentals" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Active Rentals</CardTitle>
              <CardDescription>Manage property rentals and payments</CardDescription>
            </CardHeader>
            <CardContent>
              {rentals.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <Key className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No active rentals</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-3">
                    {rentals.map((rental) => (
                      <Card key={rental.id}>
                        <CardContent className="p-4">
                          <div className="flex items-center justify-between">
                            <div className="space-y-1">
                              <p className="font-medium">{rental.propertyName}</p>
                              <p className="text-sm text-muted-foreground">
                                Tenant: {rental.tenantName}
                              </p>
                              <p className="text-sm text-muted-foreground">
                                Landlord: {rental.landlordName}
                              </p>
                            </div>
                            <div className="text-right space-y-1">
                              <p className="font-bold">{formatCurrency(rental.rent)}/mo</p>
                              <Badge variant={rental.status === 'active' ? 'default' : 'destructive'}>
                                {rental.status}
                              </Badge>
                              <p className="text-xs text-muted-foreground">
                                Next: {rental.nextPayment}
                              </p>
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

        {/* Transactions Tab */}
        <TabsContent value="transactions" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Property Transactions</CardTitle>
              <CardDescription>Recent property sales and transfers</CardDescription>
            </CardHeader>
            <CardContent>
              {transactions.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <BarChart3 className="size-8 mx-auto mb-2 opacity-50" />
                  <p>No transactions recorded</p>
                </div>
              ) : (
                <ScrollArea className="h-[600px]">
                  <div className="space-y-3">
                    {transactions.map((trans) => (
                      <Card key={trans.id}>
                        <CardContent className="p-4">
                          <div className="flex items-center justify-between">
                            <div className="space-y-1">
                              <p className="font-medium">{trans.propertyName}</p>
                              <p className="text-sm text-muted-foreground">
                                From: {trans.sellerName}
                              </p>
                              <p className="text-sm text-muted-foreground">
                                To: {trans.buyerName}
                              </p>
                              <p className="text-xs text-muted-foreground">
                                {trans.date}
                              </p>
                            </div>
                            <div className="text-right space-y-1">
                              <p className="font-bold">{formatCurrency(trans.price)}</p>
                              <Badge variant="outline">{trans.type}</Badge>
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
      </Tabs>

      {/* View Modal */}
      <Dialog open={viewModal.isOpen} onOpenChange={(open) => !open && setViewModal({ isOpen: false })}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Property Details</DialogTitle>
            <DialogDescription>
              View property information
            </DialogDescription>
          </DialogHeader>

          {viewModal.property && (
            <div className="space-y-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Name</Label>
                  <p className="font-medium">{viewModal.property.label}</p>
                </div>
                <div>
                  <Label>Type</Label>
                  <p className="font-medium">{viewModal.property.type}</p>
                </div>
                <div>
                  <Label>Address</Label>
                  <p className="font-medium">{viewModal.property.address}</p>
                </div>
                <div>
                  <Label>Owner</Label>
                  <p className="font-medium">{viewModal.property.ownerName}</p>
                </div>
                <div>
                  <Label>Price</Label>
                  <p className="font-medium">{formatCurrency(viewModal.property.price)}</p>
                </div>
                <div>
                  <Label>Garage Spaces</Label>
                  <p className="font-medium">{viewModal.property.garage}</p>
                </div>
                <div>
                  <Label>Coordinates</Label>
                  <p className="font-medium text-xs">
                    X: {viewModal.property.coords.x.toFixed(2)}, 
                    Y: {viewModal.property.coords.y.toFixed(2)}, 
                    Z: {viewModal.property.coords.z.toFixed(2)}
                  </p>
                </div>
                <div>
                  <Label>Status</Label>
                  <Badge variant={viewModal.property.owned ? 'default' : 'secondary'}>
                    {viewModal.property.owned ? 'Owned' : 'Vacant'}
                  </Badge>
                </div>
              </div>
            </div>
          )}

          <DialogFooter>
            <Button onClick={() => setViewModal({ isOpen: false })}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Transfer Modal */}
      <Dialog open={transferModal.isOpen} onOpenChange={(open) => !open && setTransferModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Transfer Property</DialogTitle>
            <DialogDescription>
              Transfer ownership to another player
            </DialogDescription>
          </DialogHeader>

          {transferModal.property && (
            <div className="space-y-4 py-4">
              <div>
                <Label>Property</Label>
                <p className="font-medium">{transferModal.property.label}</p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="newOwnerId">New Owner Citizen ID</Label>
                <Input
                  id="newOwnerId"
                  placeholder="Enter citizen ID"
                  value={formData.newOwnerId || ''}
                  onChange={(e) => setFormData({ ...formData, newOwnerId: e.target.value })}
                />
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setTransferModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button onClick={handleTransferProperty}>
              Transfer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Evict Modal */}
      <Dialog open={evictModal.isOpen} onOpenChange={(open) => !open && setEvictModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Evict Property</DialogTitle>
            <DialogDescription>
              Remove the current owner from this property
            </DialogDescription>
          </DialogHeader>

          {evictModal.property && (
            <div className="py-4">
              <div className="flex items-center gap-3 p-4 bg-destructive/10 border border-destructive/20 rounded-lg">
                <AlertTriangle className="size-5 text-destructive" />
                <div>
                  <p className="font-medium">{evictModal.property.label}</p>
                  <p className="text-sm text-muted-foreground">
                    Owner: {evictModal.property.ownerName}
                  </p>
                </div>
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setEvictModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleEvictProperty}>
              Evict
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Modal */}
      <Dialog open={deleteModal.isOpen} onOpenChange={(open) => !open && setDeleteModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Property</DialogTitle>
            <DialogDescription>
              Permanently delete this property from the database
            </DialogDescription>
          </DialogHeader>

          {deleteModal.property && (
            <div className="py-4">
              <div className="flex items-center gap-3 p-4 bg-destructive/10 border border-destructive/20 rounded-lg">
                <AlertTriangle className="size-5 text-destructive" />
                <div>
                  <p className="font-medium">{deleteModal.property.label}</p>
                  <p className="text-sm text-destructive">
                    This action cannot be undone
                  </p>
                </div>
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDeleteProperty}>
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Price Modal */}
      <Dialog open={priceModal.isOpen} onOpenChange={(open) => !open && setPriceModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Set Property Price</DialogTitle>
            <DialogDescription>
              Update the property price
            </DialogDescription>
          </DialogHeader>

          {priceModal.property && (
            <div className="space-y-4 py-4">
              <div>
                <Label>Property</Label>
                <p className="font-medium">{priceModal.property.label}</p>
                <p className="text-sm text-muted-foreground">
                  Current: {formatCurrency(priceModal.property.price)}
                </p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="newPrice">New Price</Label>
                <Input
                  id="newPrice"
                  type="number"
                  placeholder="Enter new price"
                  value={formData.newPrice || ''}
                  onChange={(e) => setFormData({ ...formData, newPrice: e.target.value })}
                />
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setPriceModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button onClick={handleSetPrice}>
              Save
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
