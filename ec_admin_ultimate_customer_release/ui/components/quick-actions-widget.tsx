import { useState, useEffect } from 'react';
import { Button } from './ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from './ui/card';
import { Badge } from './ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from './ui/dialog';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { 
  Zap, Ghost, Shield, MapPin, Eye, Heart, Crosshair, Car, Wrench, Ban, 
  MessageSquare, Users, Radio, Database, RefreshCw, Clock, Sun, Cloud,
  DollarSign, Home, Briefcase, Package, Coffee, Trash2, Volume2, Wind,
  Sparkles, Award, Target, UserPlus, Key, Globe, Wifi, Cpu, HardDrive, Activity
} from 'lucide-react';
import { executeQuickAction } from './admin-quick-actions-modal';
import { useToast } from './use-toast';
import { ALL_QUICK_ACTIONS, type QuickAction } from '../lib/quick-actions-data';

interface QuickActionsWidgetProps {
  variant?: 'dashboard' | 'profile' | 'compact';
  maxActions?: number;
  onOpenQuickActionsCenter?: () => void;
}

// Use shared quick actions data - now shows all 60+ actions!
const allQuickActions = ALL_QUICK_ACTIONS;

const categoryConfig = {
  self: { label: 'Self', color: 'purple', icon: Ghost },
  teleport: { label: 'Teleport', color: 'blue', icon: MapPin },
  player: { label: 'Players', color: 'orange', icon: Users },
  vehicle: { label: 'Vehicles', color: 'green', icon: Car },
  economy: { label: 'Economy', color: 'cyan', icon: DollarSign },
  world: { label: 'World', color: 'yellow', icon: Globe },
  server: { label: 'Server', color: 'red', icon: Radio },
  admin: { label: 'Admin', color: 'pink', icon: Shield }
};

export function QuickActionsWidget({ variant = 'dashboard', maxActions = 12, onOpenQuickActionsCenter }: QuickActionsWidgetProps) {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [inputModalOpen, setInputModalOpen] = useState(false);
  const [selectedAction, setSelectedAction] = useState<QuickAction | null>(null);
  const [inputValue, setInputValue] = useState('');
  const [inputPlayerId, setInputPlayerId] = useState('');
  const { toast: showToast } = useToast();

  // Filter and limit actions based on variant
  const displayedActions = selectedCategory === 'all' 
    ? allQuickActions.slice(0, maxActions)
    : allQuickActions.filter(a => a.category === selectedCategory).slice(0, maxActions);

  const handleActionClick = (action: QuickAction) => {
    if (action.requiresInput) {
      setSelectedAction(action);
      setInputModalOpen(true);
      setInputValue('');
      setInputPlayerId('');
    } else {
      executeQuickAction(action.id, {});
      showToast({
        title: 'Action Executed',
        description: action.label + ' executed successfully',
      });
    }
  };

  const handleInputSubmit = () => {
    if (!selectedAction) return;

    let actionData: any = {};
    
    // Prepare data based on action type
    if (['bring', 'goto', 'revive', 'freeze', 'spectate', 'kick', 'slap', 'give_item', 'strip_weapons', 'set_job', 'give_money', 'set_money', 'check_money', 'give_bank', 'wipe_inventory'].includes(selectedAction.id)) {
      actionData.playerId = parseInt(inputPlayerId) || 1;
    }
    
    if (['kick', 'announce', 'admin_chat'].includes(selectedAction.id)) {
      actionData.message = inputValue;
    }
    
    if (['spawnveh', 'give_item', 'set_job', 'weather', 'time', 'permissions', 'whitelist', 'resource_restart'].includes(selectedAction.id)) {
      actionData.value = inputValue;
    }
    
    if (['give_money', 'set_money', 'give_bank'].includes(selectedAction.id)) {
      actionData.amount = parseInt(inputValue) || 0;
    }

    executeQuickAction(selectedAction.id, actionData);
    
    showToast({
      title: 'Action Executed',
      description: selectedAction.label + ' executed successfully',
    });
    
    setInputModalOpen(false);
    setSelectedAction(null);
  };

  const categories = ['all', ...Object.keys(categoryConfig)] as const;

  return (
    <>
      <Card className="border-border/50 ec-card-transparent">
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="size-8 rounded-lg bg-gradient-to-br from-primary/20 to-primary/10 flex items-center justify-center">
                <Zap className="size-4 text-primary" />
              </div>
              <div>
                <CardTitle className="text-base">Quick Actions</CardTitle>
                <CardDescription className="text-xs">Execute admin actions instantly</CardDescription>
              </div>
            </div>
            <Badge variant="outline" className="text-xs">
              {displayedActions.length} actions
            </Badge>
          </div>
        </CardHeader>
        
        <CardContent className="space-y-3">
          {/* Category Pills */}
          <div className="flex flex-wrap gap-1.5">
            <Button
              size="sm"
              variant={selectedCategory === 'all' ? 'default' : 'ghost'}
              onClick={() => setSelectedCategory('all')}
              className="h-7 px-2 text-xs"
            >
              All
            </Button>
            {Object.entries(categoryConfig).map(([key, config]) => {
              const Icon = config.icon;
              return (
                <Button
                  key={key}
                  size="sm"
                  variant={selectedCategory === key ? 'default' : 'ghost'}
                  onClick={() => setSelectedCategory(key)}
                  className="h-7 px-2 text-xs gap-1"
                >
                  <Icon className="size-3" />
                  {config.label}
                </Button>
              );
            })}
          </div>

          {/* Actions Grid */}
          <div className={`grid gap-2 ${variant === 'compact' ? 'grid-cols-2' : 'grid-cols-3 lg:grid-cols-4'}`}>
            {displayedActions.map((action) => {
              const Icon = action.icon;
              return (
                <Button
                  key={action.id}
                  onClick={() => handleActionClick(action)}
                  variant="outline"
                  className="h-auto flex-col items-start p-3 gap-2 bg-card dark:bg-card border border-border hover:border-primary/80 transition-all group relative overflow-hidden"
                >
                  {/* Gradient overlay on hover */}
                  <div className="absolute inset-0 bg-gradient-to-br from-primary/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                  
                  <div className="relative z-10 w-full">
                    <div className="flex items-center justify-between w-full mb-1">
                      <div className="size-7 rounded-md bg-primary/10 flex items-center justify-center flex-shrink-0">
                        <Icon className="size-3.5 text-primary" />
                      </div>
                      {action.premium && (
                        <Sparkles className="size-3 text-yellow-500" />
                      )}
                    </div>
                    <p className="text-xs font-medium text-left truncate w-full">{action.label}</p>
                    <p className="text-[10px] text-muted-foreground text-left line-clamp-1 w-full">
                      {action.description}
                    </p>
                  </div>
                  
                  {action.requiresInput && (
                    <Badge variant="secondary" className="absolute top-2 right-2 text-[9px] px-1 py-0">
                      Input
                    </Badge>
                  )}
                </Button>
              );
            })}
          </div>

          {/* View All Button */}
          {variant !== 'compact' && allQuickActions.length > maxActions && (
            <Button 
              variant="ghost" 
              size="sm" 
              className="w-full text-xs hover:bg-primary/10 transition-colors"
              onClick={() => {
                if (onOpenQuickActionsCenter) {
                  onOpenQuickActionsCenter();
                } else {
                  console.warn('[Quick Actions] onOpenQuickActionsCenter callback not provided');
                }
              }}
            >
              <Zap className="size-3 mr-1.5" />
              View All {allQuickActions.length} Actions
            </Button>
          )}
        </CardContent>
      </Card>

      {/* Input Modal */}
      <Dialog open={inputModalOpen} onOpenChange={setInputModalOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              {selectedAction && (() => {
                const Icon = selectedAction.icon;
                return <Icon className="size-5 text-primary" />;
              })()}
              {selectedAction?.label}
            </DialogTitle>
            <DialogDescription>
              {selectedAction?.description}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            {/* Player ID Input */}
            {selectedAction && ['bring', 'goto', 'revive', 'freeze', 'spectate', 'kick', 'slap', 'give_item', 'strip_weapons', 'set_job', 'give_money', 'set_money', 'check_money', 'give_bank', 'wipe_inventory'].includes(selectedAction.id) && (
              <div className="space-y-2">
                <Label htmlFor="player-id">Player ID</Label>
                <Input
                  id="player-id"
                  type="number"
                  placeholder="Enter player server ID..."
                  value={inputPlayerId}
                  onChange={(e) => setInputPlayerId(e.target.value)}
                  autoFocus
                />
              </div>
            )}
            
            {/* Text/Number Input */}
            {selectedAction && ['kick', 'announce', 'admin_chat', 'spawnveh', 'give_item', 'set_job', 'weather', 'time', 'permissions', 'whitelist', 'resource_restart'].includes(selectedAction.id) && (
              <div className="space-y-2">
                <Label htmlFor="value">
                  {selectedAction.id === 'kick' && 'Reason'}
                  {selectedAction.id === 'announce' && 'Announcement Message'}
                  {selectedAction.id === 'admin_chat' && 'Message'}
                  {selectedAction.id === 'spawnveh' && 'Vehicle Model'}
                  {selectedAction.id === 'give_item' && 'Item Name'}
                  {selectedAction.id === 'set_job' && 'Job Name'}
                  {selectedAction.id === 'weather' && 'Weather Type'}
                  {selectedAction.id === 'time' && 'Time (0-23)'}
                  {selectedAction.id === 'permissions' && 'Permission'}
                  {selectedAction.id === 'whitelist' && 'Identifier'}
                  {selectedAction.id === 'resource_restart' && 'Resource Name'}
                </Label>
                {['kick', 'announce', 'admin_chat'].includes(selectedAction.id) ? (
                  <Textarea
                    id="value"
                    placeholder="Enter text..."
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    rows={3}
                  />
                ) : (
                  <Input
                    id="value"
                    placeholder="Enter value..."
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                  />
                )}
              </div>
            )}
            
            {/* Amount Input (for money actions) */}
            {selectedAction && ['give_money', 'set_money', 'give_bank'].includes(selectedAction.id) && (
              <div className="space-y-2">
                <Label htmlFor="amount">Amount</Label>
                <Input
                  id="amount"
                  type="number"
                  placeholder="Enter amount..."
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                />
              </div>
            )}
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setInputModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleInputSubmit}>
              {selectedAction && (() => {
                const Icon = selectedAction.icon;
                return <Icon className="size-4 mr-2" />;
              })()}
              Execute
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}