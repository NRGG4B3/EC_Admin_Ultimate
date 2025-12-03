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
  Package, Users, Search, Plus, Trash2, Edit, RefreshCw, 
  Box, Weight, Grid3x3, User, AlertTriangle, CheckCircle,
  ShoppingBag, Archive, Boxes, Filter, X
} from 'lucide-react';
import { toastSuccess, toastError } from '../../lib/toast';

interface InventoryPageProps {
  liveData: any;
}

interface Player {
  id: number;
  name: string;
  citizenid: string;
  itemCount: number;
  weight: number;
  maxWeight: number;
  online: boolean;
}

interface InventoryItem {
  slot: number;
  name: string;
  amount: number;
  info: any;
  weight: number;
  type: string;
  unique: boolean;
  useable: boolean;
  image: string;
  label: string;
}

interface Inventory {
  items: InventoryItem[];
  weight: number;
  maxWeight: number;
  slots: number;
  maxSlots: number;
}

interface ItemDefinition {
  name: string;
  label: string;
  weight: number;
  type: string;
  image: string;
  unique: boolean;
  useable: boolean;
  description: string;
}

interface InventoryData {
  players: Player[];
  items: { [key: string]: ItemDefinition };
  stats: {
    totalPlayers: number;
    totalItems: number;
    totalWeight: number;
    uniqueItems: number;
  };
  inventorySystem: string;
}

export function InventoryPage({ liveData }: InventoryPageProps) {
  const [activeTab, setActiveTab] = useState('players');
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [data, setData] = useState<InventoryData | null>(null);
  const [selectedPlayer, setSelectedPlayer] = useState<Player | null>(null);
  const [selectedInventory, setSelectedInventory] = useState<Inventory | null>(null);
  const [itemFilter, setItemFilter] = useState<string>('all');

  // Modals
  const [giveItemModal, setGiveItemModal] = useState(false);
  const [removeItemModal, setRemoveItemModal] = useState<{ isOpen: boolean; item?: InventoryItem }>({ isOpen: false });
  const [editItemModal, setEditItemModal] = useState<{ isOpen: boolean; item?: InventoryItem }>({ isOpen: false });
  const [clearConfirmModal, setClearConfirmModal] = useState(false);
  const [spawnItemModal, setSpawnItemModal] = useState<{ isOpen: boolean; item?: ItemDefinition }>({ isOpen: false });

  const [formData, setFormData] = useState<any>({});

  // Fetch inventory data
  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('https://ec_admin_ultimate/inventory:getData', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });

      if (response.ok) {
        // Data will be received via NUI message
      }
    } catch (error) {
      console.log('[Inventory] Not in FiveM environment');
    }
  }, []);

  // Fetch player inventory
  const fetchPlayerInventory = useCallback(async (playerId: number) => {
    try {
      const response = await fetch('https://ec_admin_ultimate/inventory:getPlayerInventory', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playerId })
      });

      if (response.ok) {
        // Data will be received via NUI message
      }
    } catch (error) {
      console.log('[Inventory] Failed to fetch player inventory');
    }
  }, []);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      if (action === 'inventoryData') {
        if (msgData.success) {
          setData(msgData.data);
        }
      } else if (action === 'playerInventory') {
        if (msgData.success) {
          setSelectedInventory(msgData.inventory);
        }
      } else if (action === 'inventoryResponse') {
        if (msgData.success) {
          toastSuccess({ title: msgData.message });
          if (selectedPlayer) {
            fetchPlayerInventory(selectedPlayer.id);
          }
          fetchData();
        } else {
          toastError({ title: msgData.message });
        }
      } else if (action === 'inventoryError') {
        toastError({ title: msgData.message });
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [selectedPlayer, fetchPlayerInventory, fetchData]);

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
      if (selectedPlayer) {
        fetchPlayerInventory(selectedPlayer.id);
      }
    }, 15000);

    return () => clearInterval(interval);
  }, [fetchData, fetchPlayerInventory, selectedPlayer]);

  // Manual refresh
  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    if (selectedPlayer) {
      await fetchPlayerInventory(selectedPlayer.id);
    }
    setRefreshing(false);
    toastSuccess({ title: 'Data refreshed' });
  };

  // Select player
  const handleSelectPlayer = async (player: Player) => {
    setSelectedPlayer(player);
    setActiveTab('inventory');
    await fetchPlayerInventory(player.id);
  };

  // Give item
  const handleGiveItem = async () => {
    if (!selectedPlayer || !formData.itemName || !formData.amount) {
      toastError({ title: 'Please fill all fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/inventory:giveItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: selectedPlayer.id,
          itemName: formData.itemName,
          amount: parseInt(formData.amount),
          metadata: {}
        })
      });

      setGiveItemModal(false);
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to give item' });
    }
  };

  // Remove item
  const handleRemoveItem = async () => {
    if (!selectedPlayer || !removeItemModal.item) return;

    try {
      await fetch('https://ec_admin_ultimate/inventory:removeItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: selectedPlayer.id,
          itemName: removeItemModal.item.name,
          amount: removeItemModal.item.amount,
          slot: removeItemModal.item.slot
        })
      });

      setRemoveItemModal({ isOpen: false });
    } catch (error) {
      toastError({ title: 'Failed to remove item' });
    }
  };

  // Edit item amount
  const handleEditItem = async () => {
    if (!selectedPlayer || !editItemModal.item || !formData.newAmount) return;

    try {
      await fetch('https://ec_admin_ultimate/inventory:setItemAmount', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: selectedPlayer.id,
          itemName: editItemModal.item.name,
          amount: parseInt(formData.newAmount),
          slot: editItemModal.item.slot
        })
      });

      setEditItemModal({ isOpen: false });
      setFormData({});
    } catch (error) {
      toastError({ title: 'Failed to edit item' });
    }
  };

  // Clear inventory
  const handleClearInventory = async () => {
    if (!selectedPlayer) return;

    try {
      await fetch('https://ec_admin_ultimate/inventory:clearInventory', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: selectedPlayer.id
        })
      });

      setClearConfirmModal(false);
    } catch (error) {
      toastError({ title: 'Failed to clear inventory' });
    }
  };

  // Spawn item to player
  const handleSpawnItem = async () => {
    if (!formData.spawnPlayerId || !formData.itemName || !formData.amount) {
      toastError({ title: 'Please fill all fields' });
      return;
    }

    try {
      await fetch('https://ec_admin_ultimate/inventory:giveItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          playerId: parseInt(formData.spawnPlayerId),
          itemName: formData.itemName,
          amount: parseInt(formData.amount),
          metadata: {}
        })
      });

      setSpawnItemModal({ isOpen: false });
      setFormData({});
      toastSuccess({ title: 'Item spawned successfully' });
    } catch (error) {
      toastError({ title: 'Failed to spawn item' });
    }
  };

  // Format weight
  const formatWeight = (weight: number) => {
    return (weight / 1000).toFixed(2) + ' kg';
  };

  // Get data from state
  const players = data?.players || [];
  const items = data?.items || {};
  const stats = data?.stats || {
    totalPlayers: 0,
    totalItems: 0,
    totalWeight: 0,
    uniqueItems: 0
  };
  const inventorySystem = data?.inventorySystem || 'Unknown';

  // Filter players
  const filteredPlayers = players.filter(p =>
    p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.citizenid.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.id.toString().includes(searchTerm)
  );

  // Filter inventory items
  const filteredInventoryItems = selectedInventory?.items.filter(item => {
    if (itemFilter === 'all') return true;
    return item.type === itemFilter;
  }) || [];

  // Get unique item types
  const itemTypes = ['all', 'item', 'weapon'];

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-12">
          <Package className="size-8 mx-auto mb-4 animate-pulse text-primary" />
          <p className="text-lg font-medium">Loading Inventory System...</p>
          <p className="text-sm text-muted-foreground">Fetching inventory data</p>
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
            <Package className="size-8 text-primary" />
            Inventory Management
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage player inventories • System: {inventorySystem}
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
                <Users className="size-6 text-blue-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Online Players</p>
                <p className="text-xl font-bold">{stats.totalPlayers}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-500/10 rounded-lg">
                <Box className="size-6 text-green-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Items</p>
                <p className="text-xl font-bold">{stats.totalItems}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-purple-500/10 rounded-lg">
                <Boxes className="size-6 text-purple-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Unique Items</p>
                <p className="text-xl font-bold">{stats.uniqueItems}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-orange-500/10 rounded-lg">
                <Weight className="size-6 text-orange-500" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground mb-1">Total Weight</p>
                <p className="text-xl font-bold">{formatWeight(stats.totalWeight)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="players" className="flex items-center gap-2">
            <Users className="size-4" />
            Players
          </TabsTrigger>
          <TabsTrigger value="inventory" className="flex items-center gap-2" disabled={!selectedPlayer}>
            <Package className="size-4" />
            Inventory
          </TabsTrigger>
          <TabsTrigger value="items" className="flex items-center gap-2">
            <Box className="size-4" />
            All Items
          </TabsTrigger>
        </TabsList>

        {/* Players Tab */}
        <TabsContent value="players" className="space-y-4 mt-6">
          {/* Search */}
          <div className="flex items-center gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                placeholder="Search players by name, ID, or citizenid..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9"
              />
            </div>
          </div>

          {/* Players Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredPlayers.length === 0 ? (
              <div className="col-span-full text-center py-12 text-muted-foreground">
                <Users className="size-8 mx-auto mb-2 opacity-50" />
                <p>No players found</p>
              </div>
            ) : (
              filteredPlayers.map((player) => (
                <Card key={player.id} className="hover:shadow-lg transition-shadow cursor-pointer">
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div>
                        <CardTitle className="text-lg">{player.name}</CardTitle>
                        <p className="text-sm text-muted-foreground mt-1">ID: {player.id}</p>
                      </div>
                      <Badge variant={player.online ? 'default' : 'secondary'}>
                        {player.online ? 'Online' : 'Offline'}
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-3">
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Items</span>
                      <span className="font-bold">{player.itemCount}</span>
                    </div>
                    <div className="flex justify-between items-center text-sm">
                      <span className="text-muted-foreground">Weight</span>
                      <span className="font-bold">{formatWeight(player.weight)} / {formatWeight(player.maxWeight)}</span>
                    </div>
                    <div className="w-full bg-secondary rounded-full h-2 mt-2">
                      <div 
                        className="bg-primary h-2 rounded-full transition-all"
                        style={{ width: Math.min((player.weight / player.maxWeight) * 100, 100) + '%' }}
                      />
                    </div>
                    <Button 
                      variant="outline" 
                      size="sm" 
                      className="w-full mt-2"
                      onClick={() => handleSelectPlayer(player)}
                    >
                      <Package className="size-4 mr-2" />
                      View Inventory
                    </Button>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* Inventory Tab */}
        <TabsContent value="inventory" className="space-y-4 mt-6">
          {selectedPlayer && selectedInventory && (
            <>
              {/* Player Info */}
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="text-2xl">{selectedPlayer.name}'s Inventory</CardTitle>
                      <CardDescription>ID: {selectedPlayer.id} • {selectedPlayer.citizenid}</CardDescription>
                    </div>
                    <div className="flex gap-2">
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => setGiveItemModal(true)}
                      >
                        <Plus className="size-4 mr-2" />
                        Give Item
                      </Button>
                      <Button 
                        variant="destructive" 
                        size="sm"
                        onClick={() => setClearConfirmModal(true)}
                      >
                        <Trash2 className="size-4 mr-2" />
                        Clear All
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-4 gap-4">
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Items</p>
                      <p className="text-2xl font-bold">{selectedInventory.items.length}</p>
                    </div>
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Slots Used</p>
                      <p className="text-2xl font-bold">{selectedInventory.slots} / {selectedInventory.maxSlots}</p>
                    </div>
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Weight</p>
                      <p className="text-2xl font-bold">{formatWeight(selectedInventory.weight)}</p>
                    </div>
                    <div className="text-center p-4 ec-card-transparent border border-border/30 rounded-lg">
                      <p className="text-sm text-muted-foreground mb-1">Max Weight</p>
                      <p className="text-2xl font-bold">{formatWeight(selectedInventory.maxWeight)}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Item Filter */}
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2">
                  <Filter className="size-4 text-muted-foreground" />
                  <Select value={itemFilter} onValueChange={setItemFilter}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {itemTypes.map(type => (
                        <SelectItem key={type} value={type}>
                          {type.charAt(0).toUpperCase() + type.slice(1)}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                {itemFilter !== 'all' && (
                  <Button variant="ghost" size="sm" onClick={() => setItemFilter('all')}>
                    <X className="size-4 mr-1" />
                    Clear Filter
                  </Button>
                )}
              </div>

              {/* Items Grid */}
              <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
                {filteredInventoryItems.length === 0 ? (
                  <div className="col-span-full text-center py-12 text-muted-foreground">
                    <Package className="size-8 mx-auto mb-2 opacity-50" />
                    <p>No items in inventory</p>
                  </div>
                ) : (
                  filteredInventoryItems.map((item) => (
                    <Card key={item.slot} className="hover:shadow-lg transition-shadow">
                      <CardContent className="p-4 space-y-2">
                        <div className="aspect-square bg-secondary rounded-lg flex items-center justify-center mb-2">
                          <Box className="size-8 text-muted-foreground" />
                        </div>
                        <div>
                          <p className="font-medium text-sm truncate">{item.label}</p>
                          <p className="text-xs text-muted-foreground">x{item.amount}</p>
                          <Badge variant="secondary" className="text-xs mt-1">
                            {item.type}
                          </Badge>
                        </div>
                        <div className="flex gap-1 pt-2">
                          <Button 
                            variant="outline" 
                            size="sm"
                            className="flex-1 p-1 h-7"
                            onClick={() => setEditItemModal({ isOpen: true, item })}
                          >
                            <Edit className="size-3" />
                          </Button>
                          <Button 
                            variant="destructive" 
                            size="sm"
                            className="flex-1 p-1 h-7"
                            onClick={() => setRemoveItemModal({ isOpen: true, item })}
                          >
                            <Trash2 className="size-3" />
                          </Button>
                        </div>
                      </CardContent>
                    </Card>
                  ))
                )}
              </div>
            </>
          )}
        </TabsContent>

        {/* All Items Tab */}
        <TabsContent value="items" className="space-y-4 mt-6">
          {/* Search for items */}
          <div className="flex items-center gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                placeholder="Search items by name or type..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9"
              />
            </div>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Available Items ({Object.keys(items).length})</CardTitle>
              <CardDescription>All registered items in the server - Click Spawn to give to player</CardDescription>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px]">
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                  {Object.values(items)
                    .filter((item) => 
                      searchTerm === '' || 
                      item.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
                      item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                      item.type.toLowerCase().includes(searchTerm.toLowerCase())
                    )
                    .map((item) => (
                    <Card key={item.name} className="hover:shadow-lg transition-shadow">
                      <CardContent className="p-4 space-y-2">
                        <div className="aspect-square bg-secondary rounded-lg flex items-center justify-center mb-2">
                          <Box className="size-8 text-muted-foreground" />
                        </div>
                        <div>
                          <p className="font-medium text-sm truncate">{item.label}</p>
                          <p className="text-xs text-muted-foreground">{item.name}</p>
                          <div className="flex gap-1 mt-2">
                            <Badge variant="secondary" className="text-xs">
                              {item.type}
                            </Badge>
                            <Badge variant="outline" className="text-xs">
                              {formatWeight(item.weight)}
                            </Badge>
                          </div>
                        </div>
                        <Button 
                          variant="default" 
                          size="sm" 
                          className="w-full mt-2"
                          onClick={() => {
                            setSpawnItemModal({ isOpen: true, item });
                            setFormData({ itemName: item.name, amount: '1' });
                          }}
                        >
                          <Plus className="size-3 mr-1" />
                          Spawn Item
                        </Button>
                      </CardContent>
                    </Card>
                  ))}
                </div>
                {Object.values(items).filter((item) => 
                  searchTerm === '' || 
                  item.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
                  item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                  item.type.toLowerCase().includes(searchTerm.toLowerCase())
                ).length === 0 && (
                  <div className="text-center py-12 text-muted-foreground">
                    <Box className="size-8 mx-auto mb-2 opacity-50" />
                    <p>No items found matching "{searchTerm}"</p>
                  </div>
                )}
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Give Item Modal */}
      <Dialog open={giveItemModal} onOpenChange={setGiveItemModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Give Item</DialogTitle>
            <DialogDescription>
              Give an item to {selectedPlayer?.name}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="itemName">Item Name</Label>
              <Select
                value={formData.itemName || ''}
                onValueChange={(value) => setFormData({ ...formData, itemName: value })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select item" />
                </SelectTrigger>
                <SelectContent>
                  {Object.values(items).map((item) => (
                    <SelectItem key={item.name} value={item.name}>
                      {item.label} ({item.name})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="amount">Amount</Label>
              <Input
                id="amount"
                type="number"
                min="1"
                placeholder="Enter amount"
                value={formData.amount || ''}
                onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setGiveItemModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleGiveItem}>
              Give Item
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Remove Item Modal */}
      <Dialog open={removeItemModal.isOpen} onOpenChange={(open) => !open && setRemoveItemModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Remove Item</DialogTitle>
            <DialogDescription>
              Are you sure you want to remove this item?
            </DialogDescription>
          </DialogHeader>

          {removeItemModal.item && (
            <div className="py-4">
              <p className="text-sm">
                <span className="font-medium">{removeItemModal.item.label}</span> x{removeItemModal.item.amount}
              </p>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setRemoveItemModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleRemoveItem}>
              Remove
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Item Modal */}
      <Dialog open={editItemModal.isOpen} onOpenChange={(open) => !open && setEditItemModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Item Amount</DialogTitle>
            <DialogDescription>
              Change the amount of this item
            </DialogDescription>
          </DialogHeader>

          {editItemModal.item && (
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label>Item</Label>
                <p className="text-sm font-medium">{editItemModal.item.label}</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="newAmount">New Amount</Label>
                <Input
                  id="newAmount"
                  type="number"
                  min="1"
                  placeholder={`Current: ${editItemModal.item.amount}`}
                  value={formData.newAmount || ''}
                  onChange={(e) => setFormData({ ...formData, newAmount: e.target.value })}
                />
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditItemModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button onClick={handleEditItem}>
              Save
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Clear Inventory Confirmation Modal */}
      <Dialog open={clearConfirmModal} onOpenChange={setClearConfirmModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Clear Inventory</DialogTitle>
            <DialogDescription>
              Are you sure you want to clear {selectedPlayer?.name}'s entire inventory?
            </DialogDescription>
          </DialogHeader>

          <div className="py-4">
            <div className="flex items-center gap-3 p-4 bg-destructive/10 border border-destructive/20 rounded-lg">
              <AlertTriangle className="size-5 text-destructive" />
              <p className="text-sm text-destructive">
                This action cannot be undone. All items will be permanently removed.
              </p>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setClearConfirmModal(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleClearInventory}>
              Clear Inventory
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Spawn Item Modal */}
      <Dialog open={spawnItemModal.isOpen} onOpenChange={(open) => !open && setSpawnItemModal({ isOpen: false })}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Spawn Item</DialogTitle>
            <DialogDescription>
              Give an item to {selectedPlayer?.name}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="spawnPlayerId">Player ID</Label>
              <Input
                id="spawnPlayerId"
                type="number"
                min="1"
                placeholder="Enter player ID"
                value={formData.spawnPlayerId || ''}
                onChange={(e) => setFormData({ ...formData, spawnPlayerId: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="itemName">Item Name</Label>
              <Select
                value={formData.itemName || ''}
                onValueChange={(value) => setFormData({ ...formData, itemName: value })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select item" />
                </SelectTrigger>
                <SelectContent>
                  {Object.values(items).map((item) => (
                    <SelectItem key={item.name} value={item.name}>
                      {item.label} ({item.name})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="amount">Amount</Label>
              <Input
                id="amount"
                type="number"
                min="1"
                placeholder="Enter amount"
                value={formData.amount || ''}
                onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setSpawnItemModal({ isOpen: false })}>
              Cancel
            </Button>
            <Button onClick={handleSpawnItem}>
              Give Item
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}