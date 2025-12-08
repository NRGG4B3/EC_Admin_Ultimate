import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from './ui/dialog';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { Ban, UserX, DollarSign, MapPin, Eye, Trash2, Key, Zap, Shield, AlertTriangle, Gift, Wrench, Heart, Snowflake, MessageSquare, UserCheck } from 'lucide-react';
import { toastSuccess, toastError, toastInfo, toastWarn } from '../lib/toast';
import { executeQuickAction } from './admin-quick-actions-modal';

interface Player {
  id: number;
  name: string;
  identifier: string;
}

interface ActionModalProps {
  isOpen: boolean;
  onClose: () => void;
  player: Player | null;
  action: 'kick' | 'ban' | 'give-money' | 'teleport' | 'spectate' | 'revive' | 'more' | null;
  onConfirm: (data: any) => void;
}

export function AdminActionModal({ isOpen, onClose, player, action, onConfirm }: ActionModalProps) {
  const [reason, setReason] = useState('');
  const [duration, setDuration] = useState('permanent');
  const [amount, setAmount] = useState('');
  const [customDuration, setCustomDuration] = useState('');

  if (!player || !action) return null;

  const handleSubmit = async () => {
    const data: any = { playerId: player.id, playerName: player.name };
    
    // Map actions to quick action IDs
    let quickActionId: string | null = null;
    
    switch (action) {
      case 'kick':
        data.reason = reason || 'No reason provided';
        quickActionId = 'kick';
        break;
      case 'ban':
        data.reason = reason || 'No reason provided';
        data.duration = duration === 'custom' ? customDuration : duration;
        quickActionId = 'ban';
        break;
      case 'give-money':
        data.amount = parseInt(amount) || 0;
        data.type = reason || 'cash'; // cash or bank
        quickActionId = 'give_money';
        break;
      case 'teleport':
        data.type = reason || 'to-player'; // to-player, bring, coords
        // Map teleport types to quick actions
        if (data.type === 'to-player') quickActionId = 'goto';
        else if (data.type === 'bring') quickActionId = 'bring';
        else if (data.type === 'waypoint') quickActionId = 'tpm';
        break;
      case 'revive':
        quickActionId = 'revive';
        break;
      case 'spectate':
        quickActionId = 'spectate';
        break;
    }
    
    // Use quick actions system if action is mapped
    if (quickActionId) {
      await executeQuickAction(quickActionId, data);
      toastSuccess(`Action executed: ${action}`);
    } else {
      // Fallback to onConfirm for custom actions
      onConfirm(data);
    }
    
    handleClose();
  };

  const handleClose = () => {
    setReason('');
    setDuration('permanent');
    setAmount('');
    setCustomDuration('');
    onClose();
  };

  const renderContent = () => {
    switch (action) {
      case 'kick':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <UserX className="size-5 text-orange-500" />
                Kick Player: {player.name}
              </DialogTitle>
              <DialogDescription>
                This will disconnect the player from the server.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="kick-reason">Reason</Label>
                <Textarea
                  id="kick-reason"
                  placeholder="Enter kick reason..."
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  rows={3}
                />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button variant="destructive" onClick={handleSubmit}>
                <UserX className="size-4 mr-2" />
                Kick Player
              </Button>
            </DialogFooter>
          </>
        );

      case 'ban':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Ban className="size-5 text-red-500" />
                Ban Player: {player.name}
              </DialogTitle>
              <DialogDescription>
                This will ban the player from the server.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="ban-reason">Reason</Label>
                <Textarea
                  id="ban-reason"
                  placeholder="Enter ban reason..."
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  rows={3}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="ban-duration">Duration</Label>
                <select
                  id="ban-duration"
                  className="w-full px-3 py-2 rounded-md border border-border bg-background"
                  value={duration}
                  onChange={(e) => setDuration(e.target.value)}
                >
                  <option value="permanent">Permanent</option>
                  <option value="1hour">1 Hour</option>
                  <option value="6hours">6 Hours</option>
                  <option value="1day">1 Day</option>
                  <option value="3days">3 Days</option>
                  <option value="1week">1 Week</option>
                  <option value="1month">1 Month</option>
                  <option value="custom">Custom</option>
                </select>
              </div>
              {duration === 'custom' && (
                <div className="space-y-2">
                  <Label htmlFor="custom-duration">Custom Duration (hours)</Label>
                  <Input
                    id="custom-duration"
                    type="number"
                    placeholder="Enter hours..."
                    value={customDuration}
                    onChange={(e) => setCustomDuration(e.target.value)}
                  />
                </div>
              )}
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button variant="destructive" onClick={handleSubmit}>
                <Ban className="size-4 mr-2" />
                Ban Player
              </Button>
            </DialogFooter>
          </>
        );

      case 'give-money':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <DollarSign className="size-5 text-green-500" />
                Give Money: {player.name}
              </DialogTitle>
              <DialogDescription>
                Add money to the player's account.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="money-amount">Amount</Label>
                <Input
                  id="money-amount"
                  type="number"
                  placeholder="Enter amount..."
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="money-type">Account Type</Label>
                <select
                  id="money-type"
                  className="w-full px-3 py-2 rounded-md border border-border bg-background"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                >
                  <option value="cash">Cash</option>
                  <option value="bank">Bank</option>
                </select>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button onClick={handleSubmit}>
                <DollarSign className="size-4 mr-2" />
                Give Money
              </Button>
            </DialogFooter>
          </>
        );

      case 'teleport':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <MapPin className="size-5 text-blue-500" />
                Teleport: {player.name}
              </DialogTitle>
              <DialogDescription>
                Choose a teleport action.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label>Teleport Action</Label>
                <div className="grid grid-cols-1 gap-2">
                  <Button
                    variant="outline"
                    className="justify-start"
                    onClick={async () => {
                      await executeQuickAction('goto', { playerId: player.id });
                      toastSuccess('Teleported to player');
                      handleClose();
                    }}
                  >
                    Teleport to Player
                  </Button>
                  <Button
                    variant="outline"
                    className="justify-start"
                    onClick={async () => {
                      await executeQuickAction('bring', { playerId: player.id });
                      toastSuccess('Brought player to you');
                      handleClose();
                    }}
                  >
                    Bring Player to Me
                  </Button>
                  <Button
                    variant="outline"
                    className="justify-start"
                    onClick={async () => {
                      await executeQuickAction('tpm', {});
                      toastSuccess('Teleported to waypoint');
                      handleClose();
                    }}
                  >
                    Teleport to Waypoint
                  </Button>
                </div>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
            </DialogFooter>
          </>
        );

      case 'spectate':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Eye className="size-5 text-purple-500" />
                Spectate: {player.name}
              </DialogTitle>
              <DialogDescription>
                Start spectating this player.
              </DialogDescription>
            </DialogHeader>
            <div className="py-4">
              <p className="text-sm text-muted-foreground">
                You will see everything from {player.name}'s perspective. Press ESC to stop spectating.
              </p>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button onClick={handleSubmit}>
                <Eye className="size-4 mr-2" />
                Start Spectating
              </Button>
            </DialogFooter>
          </>
        );

      case 'revive':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Key className="size-5 text-green-500" />
                Revive: {player.name}
              </DialogTitle>
              <DialogDescription>
                Revive this player if they are down.
              </DialogDescription>
            </DialogHeader>
            <div className="py-4">
              <p className="text-sm text-muted-foreground">
                This will instantly revive {player.name} and restore their health.
              </p>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Cancel</Button>
              <Button onClick={handleSubmit}>
                <Key className="size-4 mr-2" />
                Revive Player
              </Button>
            </DialogFooter>
          </>
        );

      case 'more':
        return (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <Wrench className="size-5 text-blue-500" />
                More Actions: {player.name}
              </DialogTitle>
              <DialogDescription>
                Additional administrative actions for this player
              </DialogDescription>
            </DialogHeader>
            <div className="py-4">
              <div className="grid grid-cols-2 gap-3">
                <Button
                  variant="outline"
                  className="justify-start h-auto py-3"
                  onClick={() => {
                    onConfirm({ playerId: player.id, action: 'revive' });
                    handleClose();
                  }}
                >
                  <Heart className="size-4 mr-2 text-green-500" />
                  <div className="text-left">
                    <div className="font-medium">Revive</div>
                    <div className="text-xs text-muted-foreground">Restore health</div>
                  </div>
                </Button>

                <Button
                  variant="outline"
                  className="justify-start h-auto py-3"
                  onClick={() => {
                    onConfirm({ playerId: player.id, action: 'heal' });
                    handleClose();
                  }}
                >
                  <Zap className="size-4 mr-2 text-yellow-500" />
                  <div className="text-left">
                    <div className="font-medium">Heal</div>
                    <div className="text-xs text-muted-foreground">Full health/armor</div>
                  </div>
                </Button>

                <Button
                  variant="outline"
                  className="justify-start h-auto py-3"
                  onClick={() => {
                    onConfirm({ playerId: player.id, action: 'freeze' });
                    handleClose();
                  }}
                >
                  <Snowflake className="size-4 mr-2 text-cyan-500" />
                  <div className="text-left">
                    <div className="font-medium">Freeze</div>
                    <div className="text-xs text-muted-foreground">Stop movement</div>
                  </div>
                </Button>

                <Button
                  variant="outline"
                  className="justify-start h-auto py-3"
                  onClick={() => {
                    onConfirm({ playerId: player.id, action: 'inventory' });
                    handleClose();
                  }}
                >
                  <Gift className="size-4 mr-2 text-purple-500" />
                  <div className="text-left">
                    <div className="font-medium">Inventory</div>
                    <div className="text-xs text-muted-foreground">View items</div>
                  </div>
                </Button>

                <Button
                  variant="outline"
                  className="justify-start h-auto py-3"
                  onClick={() => {
                    onConfirm({ playerId: player.id, action: 'message' });
                    handleClose();
                  }}
                >
                  <MessageSquare className="size-4 mr-2 text-blue-500" />
                  <div className="text-left">
                    <div className="font-medium">Message</div>
                    <div className="text-xs text-muted-foreground">Send DM</div>
                  </div>
                </Button>

                <Button
                  variant="outline"
                  className="justify-start h-auto py-3"
                  onClick={() => {
                    onConfirm({ playerId: player.id, action: 'permissions' });
                    handleClose();
                  }}
                >
                  <Shield className="size-4 mr-2 text-orange-500" />
                  <div className="text-left">
                    <div className="font-medium">Permissions</div>
                    <div className="text-xs text-muted-foreground">Manage roles</div>
                  </div>
                </Button>

                <Button
                  variant="outline"
                  className="justify-start h-auto py-3"
                  onClick={() => {
                    onConfirm({ playerId: player.id, action: 'warn' });
                    handleClose();
                  }}
                >
                  <AlertTriangle className="size-4 mr-2 text-yellow-500" />
                  <div className="text-left">
                    <div className="font-medium">Warn</div>
                    <div className="text-xs text-muted-foreground">Issue warning</div>
                  </div>
                </Button>

                <Button
                  variant="outline"
                  className="justify-start h-auto py-3"
                  onClick={() => {
                    onConfirm({ playerId: player.id, action: 'screenshot' });
                    handleClose();
                  }}
                >
                  <Eye className="size-4 mr-2 text-indigo-500" />
                  <div className="text-left">
                    <div className="font-medium">Screenshot</div>
                    <div className="text-xs text-muted-foreground">Capture screen</div>
                  </div>
                </Button>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleClose}>Close</Button>
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