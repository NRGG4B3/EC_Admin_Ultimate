import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from './ui/dialog';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { Car, MapPin, Radio, Database, Users, Waypoints } from 'lucide-react';

interface QuickActionModalProps {
  isOpen: boolean;
  onClose: () => void;
  action: 'spawn-vehicle' | 'tp-coords' | 'broadcast' | 'backup' | null;
  onConfirm: (data: any) => void;
}

export function QuickActionModal({ isOpen, onClose, action, onConfirm }: QuickActionModalProps) {
  const [vehicleName, setVehicleName] = useState('');
  const [coords, setCoords] = useState({ x: '', y: '', z: '' });
  const [message, setMessage] = useState('');
  const [backupName, setBackupName] = useState('');

  const handleSubmit = () => {
    const data: any = { action };
    
    switch (action) {
      case 'spawn-vehicle':
        data.vehicleName = vehicleName || 'adder';
        break;
      case 'tp-coords':
        data.coords = {
          x: parseFloat(coords.x) || 0,
          y: parseFloat(coords.y) || 0,
          z: parseFloat(coords.z) || 0
        };
        break;
      case 'broadcast':
        data.message = message || 'Server announcement';
        break;
      case 'backup':
        data.backupName = backupName || `backup_${Date.now()}`;
        break;
    }
    
    onConfirm(data);
    handleClose();
  };

  const handleClose = () => {
    setVehicleName('');
    setCoords({ x: '', y: '', z: '' });
    setMessage('');
    setBackupName('');
    onClose();
  };

  if (!action) return null;

  const renderContent = () => {
    switch (action) {
      case 'spawn-vehicle':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Car className="size-5 text-yellow-500" />
                Spawn Vehicle
              </DialogTitle>
              <DialogDescription>
                Enter the vehicle model name to spawn.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="vehicle-name">Vehicle Model</Label>
                <Input
                  id="vehicle-name"
                  placeholder="e.g., adder, t20, zentorno..."
                  value={vehicleName}
                  onChange={(e) => setVehicleName(e.target.value)}
                />
                <p className="text-xs text-muted-foreground">
                  Common: adder, t20, zentorno, insurgent, phantom
                </p>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button onClick={handleSubmit}>
                <Car className="size-4 mr-2" />
                Spawn Vehicle
              </Button>
            </DialogFooter>
          </>
        );

      case 'tp-coords':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Waypoints className="size-5 text-cyan-500" />
                Teleport to Coordinates
              </DialogTitle>
              <DialogDescription>
                Enter the X, Y, Z coordinates to teleport to.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="grid grid-cols-3 gap-3">
                <div className="space-y-2">
                  <Label htmlFor="coord-x">X</Label>
                  <Input
                    id="coord-x"
                    type="number"
                    placeholder="0.0"
                    value={coords.x}
                    onChange={(e) => setCoords({ ...coords, x: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="coord-y">Y</Label>
                  <Input
                    id="coord-y"
                    type="number"
                    placeholder="0.0"
                    value={coords.y}
                    onChange={(e) => setCoords({ ...coords, y: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="coord-z">Z</Label>
                  <Input
                    id="coord-z"
                    type="number"
                    placeholder="0.0"
                    value={coords.z}
                    onChange={(e) => setCoords({ ...coords, z: e.target.value })}
                  />
                </div>
              </div>
              <p className="text-xs text-muted-foreground">
                Example: Legion Square (215.0, -810.0, 30.7)
              </p>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button onClick={handleSubmit}>
                <MapPin className="size-4 mr-2" />
                Teleport
              </Button>
            </DialogFooter>
          </>
        );

      case 'broadcast':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Radio className="size-5 text-blue-500" />
                Broadcast Message
              </DialogTitle>
              <DialogDescription>
                Send a server-wide announcement to all players.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="broadcast-message">Message</Label>
                <Textarea
                  id="broadcast-message"
                  placeholder="Enter your announcement..."
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  rows={4}
                />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button onClick={handleSubmit}>
                <Radio className="size-4 mr-2" />
                Broadcast
              </Button>
            </DialogFooter>
          </>
        );

      case 'backup':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Database className="size-5 text-indigo-500" />
                Backup Database
              </DialogTitle>
              <DialogDescription>
                Create a backup of the server database.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="backup-name">Backup Name (Optional)</Label>
                <Input
                  id="backup-name"
                  placeholder="Auto-generated if empty..."
                  value={backupName}
                  onChange={(e) => setBackupName(e.target.value)}
                />
                <p className="text-xs text-muted-foreground">
                  Default format: backup_[timestamp]
                </p>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button onClick={handleSubmit}>
                <Database className="size-4 mr-2" />
                Create Backup
              </Button>
            </DialogFooter>
          </>
        );

      default:
        return null;
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent>
        {renderContent()}
      </DialogContent>
    </Dialog>
  );
}

// Helper to execute quick actions
export function executeQuickAction(action: string, data?: any, shouldCloseMenu?: boolean) {
  console.log(`[ADMIN] Executing: ${action}`, data);
  
  // Send to FiveM NUI
  if (typeof window !== 'undefined') {
    fetch(`https://ec_admin_ultimate/quickAction`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, data })
    }).catch(() => {
      // Fallback for non-FiveM environment
      console.log(`[DEV] Quick Action: ${action}`, data);
    });
    
    // If shouldCloseMenu is true, close the entire admin panel
    if (shouldCloseMenu) {
      setTimeout(() => {
        fetch(`https://ec_admin_ultimate/closePanel`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        }).catch(() => {
          console.log(`[DEV] Close panel request sent`);
        });
      }, 300); // Small delay to let action execute first
    }
  }

  // Show toast notification
  const event = new CustomEvent('show-toast', {
    detail: { 
      message: `Action executed: ${action}`, 
      type: 'success' 
    }
  });
  window.dispatchEvent(event);
}