import { useState, useEffect, useRef } from 'react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { ScrollArea } from './ui/scroll-area';
import { Input } from './ui/input';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from './ui/dialog';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { 
  X, 
  Zap,
  Search,
  Ghost,
  Shield,
  MapPin,
  Eye,
  Heart,
  Crosshair,
  Car,
  Wrench,
  Ban,
  MessageSquare,
  Users,
  Radio,
  Database,
  RefreshCw,
  Settings,
  Clock,
  Star,
  Command,
  TrendingUp,
  Sparkles,
  CheckCircle2,
  ArrowRight,
  AlertTriangle,
  Cloud,
  User
} from 'lucide-react';
import { executeQuickAction } from './admin-quick-actions-modal';
import { PedMenuModal } from './ped-menu-modal';
import { ALL_QUICK_ACTIONS, CATEGORIES, CATEGORY_COLORS, searchActions, type QuickAction } from '../lib/quick-actions-data';

interface QuickActionsCenterProps {
  isOpen: boolean;
  onClose: () => void;
  onCloseAll?: () => void; // Close the entire admin panel (for gameplay actions)
}

// Use shared quick actions data
const quickActions = ALL_QUICK_ACTIONS;

const categoryLabels = CATEGORIES;

const categoryIcons = {
  self: Ghost,
  teleport: MapPin,
  player: Users,
  vehicle: Car,
  server: Radio,
  world: Cloud,
  economy: TrendingUp,
  admin: Shield
};

const categoryColors = CATEGORY_COLORS;

export function QuickActionsCenter({ isOpen, onClose, onCloseAll }: QuickActionsCenterProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('grid');
  const [recentActions, setRecentActions] = useState<string[]>([]);
  const [favoriteActions, setFavoriteActions] = useState<string[]>(['noclip', 'tpm', 'heal']);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [executingAction, setExecutingAction] = useState<string | null>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);
  
  // Toggle states tracking for all toggle actions
  const [toggleStates, setToggleStates] = useState<Record<string, boolean>>({
    noclip: false,
    godmode: false,
    invisible: false,
    stamina: false,
    super_jump: false,
    fast_run: false,
    fast_swim: false,
    boost: false,
    rainbow: false,
    blackout: false,
    freeze_time: false,
    freeze: false, // For freeze player
    spectate: false
  });
  
  // Input modal state
  const [inputModalOpen, setInputModalOpen] = useState(false);
  const [inputModalAction, setInputModalAction] = useState<QuickAction | null>(null);
  const [inputValue, setInputValue] = useState('');
  const [inputPlayerId, setInputPlayerId] = useState('');
  const [inputVehicleName, setInputVehicleName] = useState('');
  const [inputItemName, setInputItemName] = useState('');
  const [inputAmount, setInputAmount] = useState('1');
  const [inputJobName, setInputJobName] = useState('');
  const [inputGrade, setInputGrade] = useState('0');
  
  // Ped menu state
  const [pedMenuOpen, setPedMenuOpen] = useState(false);
  const [pedMenuTargetId, setPedMenuTargetId] = useState<number | null>(null);

  const filteredActions = searchActions(quickActions, searchQuery, selectedCategory);

  // Focus search on open
  useEffect(() => {
    if (isOpen && searchInputRef.current) {
      setTimeout(() => searchInputRef.current?.focus(), 100);
    }
  }, [isOpen]);

  // Keyboard navigation
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      // ESC to close
      if (e.key === 'Escape') {
        onClose();
        // Also send close message to FiveM to remove NUI focus (for standalone mode)
        if (typeof window !== 'undefined') {
          fetch(`https://ec_admin_ultimate/closePanel`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
          }).catch(() => {
            console.log('[Quick Actions] Not in FiveM environment');
          });
        }
        return;
      }

      // Arrow navigation
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setSelectedIndex(prev => Math.min(prev + 1, filteredActions.length - 1));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        setSelectedIndex(prev => Math.max(prev - 1, 0));
      } else if (e.key === 'Enter' && filteredActions[selectedIndex]) {
        e.preventDefault();
        handleActionClick(filteredActions[selectedIndex]);
      }

      // Keyboard shortcuts for actions (when not searching)
      if (!searchQuery && e.key.length === 1 && !e.ctrlKey && !e.metaKey) {
        const action = quickActions.find(a => a.shortcut?.toLowerCase() === e.key.toLowerCase());
        if (action) {
          e.preventDefault();
          handleActionClick(action);
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, selectedIndex, filteredActions, searchQuery]);

  const handleActionClick = async (action: QuickAction) => {
    console.log('[Quick Actions] Executing:', action.id);
    
    // Special handling for ped menu (self)
    if (action.id === 'change_ped') {
      setPedMenuTargetId(null); // null = self
      setPedMenuOpen(true);
      return;
    }
    
    // Special handling for ped menu (other player) - ask for player ID first
    if (action.id === 'change_player_ped') {
      setInputModalAction(action);
      setInputModalOpen(true);
      setInputValue('');
      setInputPlayerId('');
      setInputVehicleName('');
      setInputItemName('');
      setInputAmount('1');
      setInputJobName('');
      setInputGrade('0');
      return;
    }
    
    // If action requires input, open input modal
    if (action.requiresInput) {
      setInputModalAction(action);
      setInputModalOpen(true);
      setInputValue('');
      setInputPlayerId('');
      setInputVehicleName('');
      setInputItemName('');
      setInputAmount('1');
      setInputJobName('');
      setInputGrade('0');
      return;
    }
    
    // Add to recent actions
    setRecentActions(prev => {
      const updated = [action.id, ...prev.filter(id => id !== action.id)].slice(0, 5);
      return updated;
    });

    // Visual feedback
    setExecutingAction(action.id);
    
    // Execute the action via NUI callback
    executeQuickAction(action.id, {}, false); // Don't auto-close via executeQuickAction
    
    // Close the Quick Actions Center if autoClose is enabled
    if (action.autoClose) {
      setTimeout(() => {
        setExecutingAction(null);
        onClose(); // Close Quick Actions modal
        
        // If this was opened in standalone mode (F3), also close the panel
        if (onCloseAll) {
          onCloseAll();
        }
      }, 300);
    } else {
      setTimeout(() => {
        setExecutingAction(null);
      }, 1000);
    }
  };
  
  const handleInputModalSubmit = () => {
    if (!inputModalAction) return;
    
    // Special case: Change Player Ped - open ped menu after getting player ID
    if (inputModalAction.id === 'change_player_ped') {
      const playerId = parseInt(inputPlayerId);
      if (playerId) {
        setPedMenuTargetId(playerId);
        setPedMenuOpen(true);
        setInputModalOpen(false);
        setInputModalAction(null);
      }
      return;
    }
    
    // Add to recent actions
    setRecentActions(prev => {
      const updated = [inputModalAction.id, ...prev.filter(id => id !== inputModalAction.id)].slice(0, 5);
      return updated;
    });
    
    // Prepare action data based on action type
    let actionData: any = {};
    
    switch (inputModalAction.id) {
      case 'bring':
      case 'goto':
      case 'revive':
      case 'freeze':
      case 'spectate':
        actionData.playerId = parseInt(inputPlayerId) || 1;
        break;
      case 'kick':
        actionData.playerId = parseInt(inputPlayerId) || 1;
        actionData.reason = inputValue || 'No reason provided';
        break;
      case 'tp_coords':
        actionData.coords = inputValue || '0, 0, 0';
        break;
      case 'spawnveh':
        actionData.vehicleName = inputVehicleName || 'adder';
        break;
      case 'announce':
        actionData.message = inputValue || 'Server announcement';
        break;
      case 'give_item':
        actionData.itemName = inputItemName || 'water';
        actionData.amount = parseInt(inputAmount) || 1;
        break;
      case 'set_job':
        actionData.jobName = inputJobName || 'unemployed';
        actionData.grade = parseInt(inputGrade) || 0;
        break;
    }
    
    // Execute the action
    executeQuickAction(inputModalAction.id, actionData);
    
    // Close modal and panel
    setInputModalOpen(false);
    setInputModalAction(null);
    if (inputModalAction.autoClose) {
      setTimeout(() => {
        onCloseAll?.();
      }, 300);
    }
  };

  const toggleFavorite = (actionId: string) => {
    setFavoriteActions(prev => 
      prev.includes(actionId) 
        ? prev.filter(id => id !== actionId)
        : [...prev, actionId]
    );
  };

  const categories = Object.keys(categoryLabels) as (keyof typeof categoryLabels)[];

  if (!isOpen) return null;

  // Get favorite and recent action objects
  const favoriteActionsList = favoriteActions
    .map(id => quickActions.find(a => a.id === id))
    .filter(Boolean) as QuickAction[];
  
  const recentActionsList = recentActions
    .map(id => quickActions.find(a => a.id === id))
    .filter(Boolean) as QuickAction[];

  const renderActionCard = (action: QuickAction, index: number, keyPrefix: string = '') => {
    const Icon = action.icon;
    const isFavorite = favoriteActions.includes(action.id);
    const isExecuting = executingAction === action.id;
    const isSelected = index === selectedIndex;
    const isToggleAction = action.id in toggleStates;
    const isActive = isToggleAction && toggleStates[action.id];
    
    return (
      <button
        key={keyPrefix ? `${keyPrefix}-${action.id}` : action.id}
        onClick={() => {
          handleActionClick(action);
          // Toggle the state if it's a toggle action
          if (isToggleAction) {
            setToggleStates(prev => ({
              ...prev,
              [action.id]: !prev[action.id]
            }));
          }
        }}
        onMouseEnter={() => setSelectedIndex(index)}
        className={`
          w-full p-3 rounded-lg border transition-all duration-200 group text-left relative overflow-hidden
          ${isSelected 
            ? 'border-primary/50 bg-primary/5 shadow-lg shadow-primary/10' 
            : 'border-border/50 ec-card-transparent hover:border-border'
          }
          ${isActive ? 'ring-2 ring-green-500/30 border-green-500/50' : ''}
          ${isExecuting ? 'scale-95 opacity-50' : ''}
        `}
      >
        {/* Active indicator for toggle actions */}
        {isActive && (
          <div className="absolute top-2 right-2">
            <div className="relative flex items-center justify-center">
              <div className="absolute size-3 bg-green-500 rounded-full animate-ping opacity-75" />
              <div className="size-2 bg-green-500 rounded-full" />
            </div>
          </div>
        )}

        {/* Executing overlay */}
        {isExecuting && (
          <div className="absolute inset-0 bg-primary/20 backdrop-blur-sm flex items-center justify-center">
            <CheckCircle2 className="size-6 text-primary animate-in scale-in-95 duration-200" />
          </div>
        )}

        {/* Selection indicator */}
        {isSelected && (
          <div className="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-primary/50 via-primary to-primary/50" />
        )}

        <div className="flex items-start gap-3 relative">
          <div className={`
            size-10 rounded-lg flex items-center justify-center flex-shrink-0 transition-all duration-200
            ${isSelected ? 'scale-110 shadow-lg' : 'group-hover:scale-110'}
            ${isActive ? 'bg-green-500/20' : `bg-${action.color}-500/10`}
          `}>
            <Icon className={`size-5 ${isActive ? 'text-green-400' : `text-${action.color}-400`}`} />
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-center justify-between gap-2 mb-1">
              <div className="flex items-center gap-2 flex-1 min-w-0">
                <p className="font-medium truncate">{action.label}</p>
                {isActive && (
                  <Badge variant="outline" className="text-xs border-green-500/50 text-green-500">
                    ON
                  </Badge>
                )}
                {action.premium && (
                  <Sparkles className="size-3 text-yellow-500 flex-shrink-0" />
                )}
              </div>
              <div className="flex items-center gap-1.5 flex-shrink-0">
                {action.shortcut && (
                  <kbd className="px-1.5 py-0.5 text-xs rounded ec-card-transparent border border-border/50 font-mono">
                    {action.shortcut}
                  </kbd>
                )}
                {action.requiresInput && (
                  <Badge variant="outline" className="text-xs">
                    Input
                  </Badge>
                )}
              </div>
            </div>
            <p className="text-sm text-muted-foreground line-clamp-1">
              {action.description}
            </p>
          </div>

          {/* Favorite star */}
          <div
            onClick={(e) => {
              e.stopPropagation();
              toggleFavorite(action.id);
            }}
            className="absolute top-1 right-1 opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
            role="button"
            tabIndex={0}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.stopPropagation();
                toggleFavorite(action.id);
              }
            }}
          >
            <Star 
              className={`size-3.5 ${isFavorite ? 'fill-yellow-500 text-yellow-500' : 'text-muted-foreground'}`} 
            />
          </div>
        </div>
      </button>
    );
  };

  return (
    <>
      <div
        className="fixed inset-0 bg-black/60 dark:bg-black/80 backdrop-blur-md flex items-center justify-end pr-4 z-[9998] pointer-events-auto animate-in fade-in-0 duration-200"
        onClick={(e) => e.target === e.currentTarget && onClose()}
      >
      <div
        className="w-full max-w-lg h-[85vh] backdrop-blur-xl border border-border/50 dark:border-border rounded-2xl shadow-2xl overflow-hidden flex flex-col animate-in slide-in-from-right-full duration-300 ec-gradient-bg"
      >
        {/* Header */}
        <div className="relative p-5 border-b border-border/50">
          <div className="relative">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="size-10 rounded-xl bg-gradient-to-br from-purple-500/20 via-blue-500/20 to-cyan-500/20 flex items-center justify-center shadow-lg">
                  <Zap className="size-5 text-purple-400" />
                </div>
                <div>
                  <h2 className="font-semibold text-lg">Quick Actions</h2>
                  <p className="text-xs text-muted-foreground flex items-center gap-1.5">
                    <Command className="size-3" />
                    {filteredActions.length} actions • Use keyboard shortcuts
                  </p>
                </div>
              </div>
              
              <Button
                size="sm"
                variant="ghost"
                onClick={onClose}
                className="text-muted-foreground hover:text-foreground hover:bg-background/50"
              >
                <X className="size-4" />
              </Button>
            </div>

            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                ref={searchInputRef}
                placeholder="Search actions or press a shortcut key..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9 bg-background border-primary focus:border-primary transition-none"
              />
            </div>
          </div>
        </div>

        {/* Category Filters */}
        <div className="px-4 py-3 border-b border-border/30">
          <div className="w-full overflow-x-auto scrollbar-thin scrollbar-thumb-border scrollbar-track-transparent">
            <div className="flex items-center gap-2 pb-2 min-w-max">
              {categories.map(category => {
                const Icon = category !== 'all' ? categoryIcons[category as keyof typeof categoryIcons] : Zap;
                const isSelected = selectedCategory === category;
                
                return (
                  <Button
                    key={category}
                    size="sm"
                    variant={isSelected ? 'default' : 'ghost'}
                    onClick={() => {
                      setSelectedCategory(category);
                      setSelectedIndex(0);
                    }}
                    className={`
                      text-xs gap-1.5 whitespace-nowrap transition-all duration-200
                      ${isSelected ? 'shadow-md' : ''}
                    `}
                  >
                    <Icon className="size-3.5" />
                    {category === 'all' ? 'All' : categoryLabels[category as keyof typeof categoryLabels].label}
                  </Button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Actions Content */}
        <ScrollArea className="flex-1">
          {filteredActions.length === 0 ? (
            <div className="text-center py-16 px-4">
              <div className="size-16 mx-auto mb-4 rounded-2xl ec-card-transparent border border-border/30 flex items-center justify-center">
                <Search className="size-8 text-muted-foreground/50" />
              </div>
              <p className="text-muted-foreground mb-2">No actions found</p>
              <p className="text-sm text-muted-foreground">
                Try a different search or category
              </p>
            </div>
          ) : (
            <div className="p-4 space-y-4">
              {/* Favorites Section with Horizontal Slider */}
              {!searchQuery && favoriteActionsList.length > 0 && selectedCategory === 'all' && (
                <div className="space-y-2">
                  <div className="flex items-center gap-2 px-2">
                    <Star className="size-3.5 text-yellow-500" />
                    <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wide">Favorites</h3>
                    <Badge variant="outline" className="text-xs ml-auto">{favoriteActionsList.length}</Badge>
                  </div>
                  <div className="w-full overflow-x-auto scrollbar-thin">
                    <div className="flex gap-2 pb-3 min-w-max">
                      {favoriteActionsList.map((action, idx) => {
                        const Icon = action.icon;
                        const isFavorite = favoriteActions.includes(action.id);
                        const isSelected = idx === selectedIndex;
                        const isExecuting = executingAction === action.id;
                        
                        return (
                          <button
                            key={`favorite-${action.id}`}
                            onClick={() => handleActionClick(action)}
                            className={`
                              min-w-[200px] w-[200px] p-3 rounded-lg border transition-all duration-200 group text-left relative overflow-hidden
                              ${isSelected 
                                ? 'border-primary/50 bg-primary/5 shadow-lg shadow-primary/10' 
                                : 'border-border/50 ec-card-transparent hover:border-border'
                              }
                              ${isExecuting ? 'scale-95 opacity-50' : ''}
                            `}
                          >
                            {isExecuting && (
                              <div className="absolute inset-0 bg-primary/20 backdrop-blur-sm flex items-center justify-center">
                                <CheckCircle2 className="size-6 text-primary animate-in scale-in-95 duration-200" />
                              </div>
                            )}
                            
                            <div className="flex items-start gap-3">
                              <div className={`size-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-${action.color}-500/10`}>
                                <Icon className={`size-5 text-${action.color}-400`} />
                              </div>
                              
                              <div className="flex-1 min-w-0">
                                <div className="flex items-center gap-2 mb-1">
                                  <p className="font-medium truncate">{action.label}</p>
                                  {action.premium && <Sparkles className="size-3 text-yellow-500" />}
                                </div>
                                <p className="text-sm text-muted-foreground line-clamp-1">{action.description}</p>
                              </div>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              )}

              {/* Recent Actions Section with Horizontal Slider */}
              {!searchQuery && recentActionsList.length > 0 && selectedCategory === 'all' && (
                <div className="space-y-2">
                  <div className="flex items-center gap-2 px-2">
                    <Clock className="size-3.5 text-blue-500" />
                    <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wide">Recent</h3>
                    <Badge variant="outline" className="text-xs ml-auto">{recentActionsList.length}</Badge>
                  </div>
                  <div className="w-full overflow-x-auto scrollbar-thin">
                    <div className="flex gap-2 pb-3 min-w-max">
                      {recentActionsList.map((action, idx) => {
                        const Icon = action.icon;
                        const isFavorite = favoriteActions.includes(action.id);
                        const isSelected = idx + favoriteActionsList.length === selectedIndex;
                        const isExecuting = executingAction === action.id;
                        
                        return (
                          <button
                            key={`recent-${action.id}`}
                            onClick={() => handleActionClick(action)}
                            className={`
                              min-w-[200px] w-[200px] p-3 rounded-lg border transition-all duration-200 group text-left relative overflow-hidden
                              ${isSelected 
                                ? 'border-primary/50 bg-primary/5 shadow-lg shadow-primary/10' 
                                : 'border-border/50 ec-card-transparent hover:border-border'
                              }
                              ${isExecuting ? 'scale-95 opacity-50' : ''}
                            `}
                          >
                            {isExecuting && (
                              <div className="absolute inset-0 bg-primary/20 backdrop-blur-sm flex items-center justify-center">
                                <CheckCircle2 className="size-6 text-primary animate-in scale-in-95 duration-200" />
                              </div>
                            )}
                            
                            <div className="flex items-start gap-3">
                              <div className={`size-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-${action.color}-500/10`}>
                                <Icon className={`size-5 text-${action.color}-400`} />
                              </div>
                              
                              <div className="flex-1 min-w-0">
                                <div className="flex items-center gap-2 mb-1">
                                  <p className="font-medium truncate">{action.label}</p>
                                  {action.premium && <Sparkles className="size-3 text-yellow-500" />}
                                </div>
                                <p className="text-sm text-muted-foreground line-clamp-1">{action.description}</p>
                              </div>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              )}

              {/* All Actions */}
              <div className="space-y-2">
                {(searchQuery || selectedCategory !== 'all' || (favoriteActionsList.length === 0 && recentActionsList.length === 0)) && (
                  <div className="flex items-center gap-2 px-2">
                    <TrendingUp className="size-3.5 text-primary" />
                    <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
                      {searchQuery ? 'Search Results' : 'All Actions'}
                    </h3>
                  </div>
                )}
                <div className="space-y-2">
                  {filteredActions
                    .filter((action) => {
                      // Skip if already shown in favorites or recent
                      if (!searchQuery && selectedCategory === 'all') {
                        return !favoriteActions.includes(action.id) && !recentActions.includes(action.id);
                      }
                      return true;
                    })
                    .map((action, idx) => {
                      return renderActionCard(action, favoriteActionsList.length + recentActionsList.length + idx, 'all');
                    })}
                </div>
              </div>
            </div>
          )}
        </ScrollArea>

        {/* Enhanced Footer */}
        <div className="p-4 border-t border-border/50 bg-gradient-to-r from-muted/20 via-muted/10 to-muted/20">
          <div className="flex items-center justify-between text-xs">
            <div className="flex items-center gap-3 text-muted-foreground">
              <span className="flex items-center gap-1.5">
                <kbd className="px-1.5 py-0.5 rounded bg-background/50 border border-border/50 font-mono">ESC</kbd>
                Close
              </span>
              <span className="flex items-center gap-1.5">
                <kbd className="px-1.5 py-0.5 rounded bg-background/50 border border-border/50 font-mono">↑↓</kbd>
                Navigate
              </span>
              <span className="flex items-center gap-1.5">
                <kbd className="px-1.5 py-0.5 rounded bg-background/50 border border-border/50 font-mono">↵</kbd>
                Execute
              </span>
            </div>
            <span className="flex items-center gap-1.5 text-muted-foreground">
              <Zap className="size-3" />
              Quick Actions
            </span>
          </div>
        </div>
      </div>
      </div>

      {/* Input Modal for actions requiring input */}
      <Dialog open={inputModalOpen} onOpenChange={setInputModalOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              {inputModalAction && (() => {
                const Icon = inputModalAction.icon;
                return <Icon className="size-5 text-primary" />;
              })()}
              {inputModalAction?.label}
            </DialogTitle>
            <DialogDescription>
              {inputModalAction?.description}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            {/* Player ID Input (for player actions) */}
            {inputModalAction && ['bring', 'goto', 'revive', 'freeze', 'spectate', 'kick', 'change_player_ped'].includes(inputModalAction.id) && (
              <div className="space-y-2">
                <Label htmlFor="player-id">Player ID</Label>
                <Input
                  id="player-id"
                  type="number"
                  placeholder="Enter player ID..."
                  value={inputPlayerId}
                  onChange={(e) => setInputPlayerId(e.target.value)}
                  autoFocus
                />
                <p className="text-xs text-muted-foreground">
                  {inputModalAction.id === 'change_player_ped' 
                    ? 'Enter the player ID to change their ped/skin'
                    : 'Enter the server ID of the player'
                  }
                </p>
              </div>
            )}
            
            {/* Reason Input (for kick) */}
            {inputModalAction?.id === 'kick' && (
              <div className="space-y-2">
                <Label htmlFor="reason">Reason</Label>
                <Textarea
                  id="reason"
                  placeholder="Enter kick reason..."
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  rows={3}
                />
              </div>
            )}
            
            {/* Vehicle Name Input (for spawn vehicle) */}
            {inputModalAction?.id === 'spawnveh' && (
              <div className="space-y-2">
                <Label htmlFor="vehicle-name">Vehicle Model</Label>
                <Input
                  id="vehicle-name"
                  placeholder="e.g., adder, t20, zentorno..."
                  value={inputVehicleName}
                  onChange={(e) => setInputVehicleName(e.target.value)}
                  autoFocus
                />
                <p className="text-xs text-muted-foreground">
                  Popular: adder, t20, zentorno, insurgent, phantom
                </p>
              </div>
            )}
            
            {/* Message Input (for announce) */}
            {inputModalAction?.id === 'announce' && (
              <div className="space-y-2">
                <Label htmlFor="message">Announcement Message</Label>
                <Textarea
                  id="message"
                  placeholder="Enter server announcement..."
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  rows={4}
                  autoFocus
                />
              </div>
            )}
            
            {/* Coordinates Input (for tp_coords) */}
            {inputModalAction?.id === 'tp_coords' && (
              <div className="space-y-2">
                <Label htmlFor="coords">Coordinates (x, y, z)</Label>
                <Input
                  id="coords"
                  placeholder="e.g., 0, 0, 0..."
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  autoFocus
                />
                <p className="text-xs text-muted-foreground">
                  Format: x, y, z
                </p>
              </div>
            )}
            
            {/* Item Name and Amount Input (for give_item) */}
            {inputModalAction?.id === 'give_item' && (
              <div className="space-y-2">
                <Label htmlFor="item-name">Item Name</Label>
                <Input
                  id="item-name"
                  placeholder="e.g., water, bread..."
                  value={inputItemName}
                  onChange={(e) => setInputItemName(e.target.value)}
                  autoFocus
                />
                <p className="text-xs text-muted-foreground">
                  Popular: water, bread, cola, phone
                </p>
                <Label htmlFor="amount">Amount</Label>
                <Input
                  id="amount"
                  type="number"
                  placeholder="Enter amount..."
                  value={inputAmount}
                  onChange={(e) => setInputAmount(e.target.value)}
                />
              </div>
            )}
            
            {/* Job Name and Grade Input (for set_job) */}
            {inputModalAction?.id === 'set_job' && (
              <div className="space-y-2">
                <Label htmlFor="job-name">Job Name</Label>
                <Input
                  id="job-name"
                  placeholder="e.g., unemployed, police..."
                  value={inputJobName}
                  onChange={(e) => setInputJobName(e.target.value)}
                  autoFocus
                />
                <p className="text-xs text-muted-foreground">
                  Popular: unemployed, police, ambulance, mechanic
                </p>
                <Label htmlFor="grade">Grade</Label>
                <Input
                  id="grade"
                  type="number"
                  placeholder="Enter grade..."
                  value={inputGrade}
                  onChange={(e) => setInputGrade(e.target.value)}
                />
              </div>
            )}
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setInputModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleInputModalSubmit}>
              {inputModalAction && (() => {
                const Icon = inputModalAction.icon;
                return <Icon className="size-4 mr-2" />;
              })()}
              Execute
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      
      {/* Ped Menu Modal */}
      <PedMenuModal 
        isOpen={pedMenuOpen} 
        onClose={() => setPedMenuOpen(false)}
        targetPlayerId={pedMenuTargetId}
      />
    </>
  );
}