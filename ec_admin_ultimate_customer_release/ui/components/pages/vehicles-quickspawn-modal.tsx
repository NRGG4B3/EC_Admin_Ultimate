import { useState } from 'react';
import { Label } from '../../ui/label';
import { Input } from '../../ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../ui/select';
import { ScrollArea } from '../../ui/scroll-area';
import { Button } from '../../ui/button';
import { Badge } from '../../ui/badge';
import { Car, Search, Sparkles } from 'lucide-react';

interface QuickSpawnModalProps {
  availableVehicles: any[];
  isLoadingVehicles: boolean;
  formData: any;
  setFormData: (data: any) => void;
}

export function QuickSpawnModal({
  availableVehicles,
  isLoadingVehicles,
  formData,
  setFormData
}: QuickSpawnModalProps) {
  const [vehicleSearchTerm, setVehicleSearchTerm] = useState('');
  const [vehicleClassFilter, setVehicleClassFilter] = useState('all');

  // Filter available vehicles
  const filteredAvailableVehicles = availableVehicles.filter(vehicle => {
    const matchesSearch = 
      vehicle.model.toLowerCase().includes(vehicleSearchTerm.toLowerCase()) ||
      vehicle.name.toLowerCase().includes(vehicleSearchTerm.toLowerCase());
    
    const matchesClass = vehicleClassFilter === 'all' || vehicle.class === vehicleClassFilter;
    
    return matchesSearch && matchesClass;
  });

  return (
    <div className="space-y-4">
      <div className="space-y-3">
        <Label>Search Vehicles</Label>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            value={vehicleSearchTerm}
            onChange={(e) => setVehicleSearchTerm(e.target.value)}
            placeholder="Search by model or name..."
            className="pl-10"
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          <Label>Vehicle Class</Label>
          <Select value={vehicleClassFilter} onValueChange={setVehicleClassFilter}>
            <SelectTrigger>
              <SelectValue placeholder="All Classes" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Classes</SelectItem>
              <SelectItem value="compacts">Compacts</SelectItem>
              <SelectItem value="sedans">Sedans</SelectItem>
              <SelectItem value="suvs">SUVs</SelectItem>
              <SelectItem value="coupes">Coupes</SelectItem>
              <SelectItem value="muscle">Muscle</SelectItem>
              <SelectItem value="sportsclassics">Sports Classics</SelectItem>
              <SelectItem value="sports">Sports</SelectItem>
              <SelectItem value="super">Super</SelectItem>
              <SelectItem value="motorcycles">Motorcycles</SelectItem>
              <SelectItem value="offroad">Off-Road</SelectItem>
              <SelectItem value="vans">Vans</SelectItem>
              <SelectItem value="commercial">Commercial</SelectItem>
              <SelectItem value="industrial">Industrial</SelectItem>
              <SelectItem value="utility">Utility</SelectItem>
              <SelectItem value="emergency">Emergency</SelectItem>
              <SelectItem value="planes">Planes</SelectItem>
              <SelectItem value="helicopters">Helicopters</SelectItem>
              <SelectItem value="boats">Boats</SelectItem>
              <SelectItem value="custom">Custom Vehicles</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label>Selected Model</Label>
          <Input
            value={formData.spawnModel || ''}
            onChange={(e) => setFormData({ ...formData, spawnModel: e.target.value })}
            placeholder="Select or type model"
            className="font-mono"
          />
        </div>
      </div>

      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <Label>Available Vehicles ({filteredAvailableVehicles.length})</Label>
          {isLoadingVehicles && (
            <span className="text-xs text-muted-foreground">Loading vehicles...</span>
          )}
        </div>
        <ScrollArea className="h-[400px] border rounded-lg p-2">
          {filteredAvailableVehicles.length === 0 ? (
            <div className="flex items-center justify-center h-full text-muted-foreground">
              <p className="text-sm">No vehicles found</p>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-2">
              {filteredAvailableVehicles.map((veh, index) => (
                <Button
                  key={veh.model + '-' + index}
                  size="sm"
                  variant={formData.spawnModel === veh.model ? 'default' : 'outline'}
                  onClick={() => setFormData({ ...formData, spawnModel: veh.model })}
                >
                  <div className="text-left flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <Car className="size-3 flex-shrink-0" />
                      <p className="font-medium truncate text-sm">{veh.name}</p>
                    </div>
                    <div className="flex items-center gap-2 mt-1">
                      <p className="text-xs text-muted-foreground capitalize">{veh.class}</p>
                      {veh.isCustom && (
                        <Badge variant="secondary" className="text-xs px-1.5 py-0">
                          <Sparkles className="size-2 mr-1" />
                          Custom
                        </Badge>
                      )}
                    </div>
                  </div>
                </Button>
              ))}
            </div>
          )}
        </ScrollArea>
      </div>

      <div className="space-y-3">
        <Label>Owner (Optional)</Label>
        <Input
          value={formData.owner || ''}
          onChange={(e) => setFormData({ ...formData, owner: e.target.value })}
          placeholder="Citizen ID or leave empty"
        />
        <p className="text-xs text-muted-foreground">
          Leave empty to spawn vehicle without owner assignment
        </p>
      </div>
    </div>
  );
}