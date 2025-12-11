// EC Admin Ultimate - Shared Quick Actions Data
// Centralized list of ALL quick actions used across all UI components

import { 
  Ghost, Shield, Eye, Heart, User, MapPin, Users, Crosshair, 
  Target, RefreshCw, Star, Navigation, Zap, Car, Wrench, 
  Trash2, Wind, Paintbrush, Sparkles, Server, Power, 
  AlertTriangle, Ban, UserX, Clock, DollarSign, Package, 
  Home, CloudRain, Sun, Database, Activity, TrendingUp,
  Settings, Code, Terminal, Flame, Snowflake, Moon
} from 'lucide-react';

export interface QuickAction {
  id: string;
  label: string;
  icon: any;
  color: string;
  category: 'self' | 'teleport' | 'player' | 'vehicle' | 'server' | 'economy' | 'world' | 'admin';
  description: string;
  requiresInput?: boolean;
  shortcut?: string;
  premium?: boolean;
  autoClose?: boolean; // Close UI immediately for gameplay actions
  badge?: string;
}

// ============================================================================
// MASTER QUICK ACTIONS LIST - 60+ ACTIONS
// ============================================================================

export const ALL_QUICK_ACTIONS: QuickAction[] = [
  
  // ========================================
  // SELF ACTIONS (12)
  // ========================================
  { 
    id: 'noclip', 
    label: 'NoClip', 
    icon: Ghost, 
    color: 'purple', 
    category: 'self', 
    description: 'Toggle noclip mode with dynamic flips', 
    shortcut: 'N', 
    autoClose: true,
    badge: 'NEW'
  },
  { 
    id: 'godmode', 
    label: 'God Mode', 
    icon: Shield, 
    color: 'green', 
    category: 'self', 
    description: 'Toggle invincibility', 
    shortcut: 'G', 
    autoClose: true 
  },
  { 
    id: 'invisible', 
    label: 'Invisible', 
    icon: Eye, 
    color: 'cyan', 
    category: 'self', 
    description: 'Toggle invisibility', 
    shortcut: 'I', 
    autoClose: true 
  },
  { 
    id: 'heal', 
    label: 'Heal Self', 
    icon: Heart, 
    color: 'red', 
    category: 'self', 
    description: 'Restore health and armor', 
    shortcut: 'H', 
    autoClose: true 
  },
  { 
    id: 'stamina', 
    label: 'Infinite Stamina', 
    icon: TrendingUp, 
    color: 'orange', 
    category: 'self', 
    description: 'Toggle infinite stamina', 
    autoClose: true 
  },
  { 
    id: 'super_jump', 
    label: 'Super Jump', 
    icon: TrendingUp, 
    color: 'purple', 
    category: 'self', 
    description: 'Toggle super jump', 
    autoClose: true 
  },
  { 
    id: 'fast_run', 
    label: 'Fast Run', 
    icon: TrendingUp, 
    color: 'green', 
    category: 'self', 
    description: 'Toggle fast running', 
    autoClose: true 
  },
  { 
    id: 'fast_swim', 
    label: 'Fast Swim', 
    icon: TrendingUp, 
    color: 'blue', 
    category: 'self', 
    description: 'Toggle fast swimming', 
    autoClose: true 
  },
  { 
    id: 'change_ped', 
    label: 'Change Ped/Skin', 
    icon: User, 
    color: 'pink', 
    category: 'self', 
    description: 'Open ped menu to change skin', 
    requiresInput: true 
  },
  { 
    id: 'armor', 
    label: 'Max Armor', 
    icon: Shield, 
    color: 'blue', 
    category: 'self', 
    description: 'Give max armor', 
    autoClose: true 
  },
  { 
    id: 'clean_clothes', 
    label: 'Clean Clothes', 
    icon: Sparkles, 
    color: 'cyan', 
    category: 'self', 
    description: 'Remove dirt from clothes', 
    autoClose: true 
  },
  { 
    id: 'clear_blood', 
    label: 'Clear Blood', 
    icon: Sparkles, 
    color: 'red', 
    category: 'self', 
    description: 'Remove blood effects', 
    autoClose: true 
  },
  
  // ========================================
  // TELEPORT ACTIONS (7)
  // ========================================
  { 
    id: 'tpm', 
    label: 'Teleport to Marker', 
    icon: MapPin, 
    color: 'blue', 
    category: 'teleport', 
    description: 'TP to waypoint', 
    shortcut: 'T', 
    autoClose: true 
  },
  { 
    id: 'bring', 
    label: 'Bring Player', 
    icon: Users, 
    color: 'orange', 
    category: 'teleport', 
    description: 'Bring player to you', 
    requiresInput: true, 
    shortcut: 'B', 
    autoClose: true 
  },
  { 
    id: 'goto', 
    label: 'Go to Player', 
    icon: Crosshair, 
    color: 'pink', 
    category: 'teleport', 
    description: 'Teleport to player', 
    requiresInput: true, 
    shortcut: 'J', 
    autoClose: true 
  },
  { 
    id: 'tp_coords', 
    label: 'TP to Coords', 
    icon: MapPin, 
    color: 'cyan', 
    category: 'teleport', 
    description: 'Teleport to coordinates', 
    requiresInput: true, 
    autoClose: true 
  },
  { 
    id: 'save_location', 
    label: 'Save Location', 
    icon: Star, 
    color: 'yellow', 
    category: 'teleport', 
    description: 'Save current position', 
    autoClose: true 
  },
  { 
    id: 'load_location', 
    label: 'Load Location', 
    icon: Navigation, 
    color: 'yellow', 
    category: 'teleport', 
    description: 'Return to saved position', 
    autoClose: true 
  },
  { 
    id: 'tp_back', 
    label: 'TP Back', 
    icon: RefreshCw, 
    color: 'purple', 
    category: 'teleport', 
    description: 'Return to last location', 
    autoClose: true 
  },

  // ========================================
  // PLAYER ACTIONS (15)
  // ========================================
  { 
    id: 'revive', 
    label: 'Revive Player', 
    icon: Heart, 
    color: 'green', 
    category: 'player', 
    description: 'Revive a player', 
    requiresInput: true 
  },
  { 
    id: 'heal_player', 
    label: 'Heal Player', 
    icon: Heart, 
    color: 'red', 
    category: 'player', 
    description: 'Restore player health', 
    requiresInput: true 
  },
  { 
    id: 'kill_player', 
    label: 'Kill Player', 
    icon: Zap, 
    color: 'red', 
    category: 'player', 
    description: 'Kill a player', 
    requiresInput: true 
  },
  { 
    id: 'freeze', 
    label: 'Freeze Player', 
    icon: Snowflake, 
    color: 'blue', 
    category: 'player', 
    description: 'Freeze/unfreeze player', 
    requiresInput: true 
  },
  { 
    id: 'spectate', 
    label: 'Spectate Player', 
    icon: Eye, 
    color: 'purple', 
    category: 'player', 
    description: 'Watch player POV', 
    requiresInput: true 
  },
  { 
    id: 'kick', 
    label: 'Kick Player', 
    icon: UserX, 
    color: 'orange', 
    category: 'player', 
    description: 'Kick from server', 
    requiresInput: true 
  },
  { 
    id: 'ban', 
    label: 'Ban Player', 
    icon: Ban, 
    color: 'red', 
    category: 'player', 
    description: 'Permanently ban player', 
    requiresInput: true 
  },
  { 
    id: 'warn', 
    label: 'Warn Player', 
    icon: AlertTriangle, 
    color: 'yellow', 
    category: 'player', 
    description: 'Issue warning', 
    requiresInput: true 
  },
  { 
    id: 'slap', 
    label: 'Slap Player', 
    icon: Zap, 
    color: 'orange', 
    category: 'player', 
    description: 'Launch player upward', 
    requiresInput: true 
  },
  { 
    id: 'strip_weapons', 
    label: 'Strip Weapons', 
    icon: Ban, 
    color: 'red', 
    category: 'player', 
    description: 'Remove all weapons', 
    requiresInput: true 
  },
  { 
    id: 'wipe_inventory', 
    label: 'Wipe Inventory', 
    icon: Trash2, 
    color: 'red', 
    category: 'player', 
    description: 'Clear inventory', 
    requiresInput: true 
  },
  { 
    id: 'give_money', 
    label: 'Give Money', 
    icon: DollarSign, 
    color: 'green', 
    category: 'player', 
    description: 'Add cash to player', 
    requiresInput: true 
  },
  { 
    id: 'give_item', 
    label: 'Give Item', 
    icon: Package, 
    color: 'blue', 
    category: 'player', 
    description: 'Give item to player', 
    requiresInput: true 
  },
  { 
    id: 'change_player_ped', 
    label: 'Change Player Ped', 
    icon: User, 
    color: 'pink', 
    category: 'player', 
    description: 'Change another player\'s skin', 
    requiresInput: true 
  },
  { 
    id: 'send_home', 
    label: 'Send Home', 
    icon: Home, 
    color: 'cyan', 
    category: 'player', 
    description: 'TP player to spawn', 
    requiresInput: true 
  },

  // ========================================
  // VEHICLE ACTIONS (10)
  // ========================================
  { 
    id: 'spawn_vehicle', 
    label: 'Spawn Vehicle', 
    icon: Car, 
    color: 'blue', 
    category: 'vehicle', 
    description: 'Spawn any vehicle', 
    requiresInput: true, 
    autoClose: true 
  },
  { 
    id: 'fix_vehicle', 
    label: 'Fix Vehicle', 
    icon: Wrench, 
    color: 'green', 
    category: 'vehicle', 
    description: 'Repair current vehicle', 
    autoClose: true 
  },
  { 
    id: 'delete_vehicle', 
    label: 'Delete Vehicle', 
    icon: Trash2, 
    color: 'red', 
    category: 'vehicle', 
    description: 'Remove nearby vehicle', 
    autoClose: true 
  },
  { 
    id: 'flip_vehicle', 
    label: 'Flip Vehicle', 
    icon: RefreshCw, 
    color: 'purple', 
    category: 'vehicle', 
    description: 'Flip vehicle upright', 
    autoClose: true 
  },
  { 
    id: 'clean_vehicle', 
    label: 'Clean Vehicle', 
    icon: Sparkles, 
    color: 'cyan', 
    category: 'vehicle', 
    description: 'Wash vehicle', 
    autoClose: true 
  },
  { 
    id: 'max_tune', 
    label: 'Max Tune', 
    icon: Settings, 
    color: 'orange', 
    category: 'vehicle', 
    description: 'Max performance upgrades', 
    autoClose: true 
  },
  { 
    id: 'boost', 
    label: 'Toggle Boost', 
    icon: Flame, 
    color: 'red', 
    category: 'vehicle', 
    description: 'Super speed boost', 
    autoClose: true 
  },
  { 
    id: 'rainbow', 
    label: 'Rainbow Paint', 
    icon: Paintbrush, 
    color: 'pink', 
    category: 'vehicle', 
    description: 'Cycling rainbow colors', 
    autoClose: true 
  },
  { 
    id: 'garage_radius', 
    label: 'Garage Radius', 
    icon: Car, 
    color: 'blue', 
    category: 'vehicle', 
    description: 'Send nearby vehicles to garage', 
    requiresInput: true 
  },
  { 
    id: 'garage_all', 
    label: 'Garage All', 
    icon: Car, 
    color: 'red', 
    category: 'vehicle', 
    description: 'Send all vehicles to garage', 
    premium: true 
  },

  // ========================================
  // WORLD ACTIONS (8)
  // ========================================
  { 
    id: 'weather', 
    label: 'Set Weather', 
    icon: CloudRain, 
    color: 'blue', 
    category: 'world', 
    description: 'Change server weather', 
    requiresInput: true 
  },
  { 
    id: 'time', 
    label: 'Set Time', 
    icon: Clock, 
    color: 'orange', 
    category: 'world', 
    description: 'Change server time', 
    requiresInput: true 
  },
  { 
    id: 'blackout', 
    label: 'Toggle Blackout', 
    icon: Moon, 
    color: 'purple', 
    category: 'world', 
    description: 'Turn off all lights', 
    autoClose: true 
  },
  { 
    id: 'clear_area', 
    label: 'Clear Area', 
    icon: Trash2, 
    color: 'red', 
    category: 'world', 
    description: 'Clear nearby entities', 
    autoClose: true 
  },
  { 
    id: 'clear_peds', 
    label: 'Clear All Peds', 
    icon: Users, 
    color: 'orange', 
    category: 'world', 
    description: 'Remove all NPCs', 
    premium: true 
  },
  { 
    id: 'clear_vehicles', 
    label: 'Clear All Vehicles', 
    icon: Car, 
    color: 'red', 
    category: 'world', 
    description: 'Remove all vehicles', 
    premium: true 
  },
  { 
    id: 'freeze_weather', 
    label: 'Freeze Weather', 
    icon: Snowflake, 
    color: 'cyan', 
    category: 'world', 
    description: 'Lock current weather' 
  },
  { 
    id: 'freeze_time', 
    label: 'Freeze Time', 
    icon: Clock, 
    color: 'purple', 
    category: 'world', 
    description: 'Stop time progression' 
  },

  // ========================================
  // SERVER ACTIONS (8)
  // ========================================
  { 
    id: 'restart_resource', 
    label: 'Restart Resource', 
    icon: RefreshCw, 
    color: 'orange', 
    category: 'server', 
    description: 'Restart a resource', 
    requiresInput: true, 
    premium: true 
  },
  { 
    id: 'start_resource', 
    label: 'Start Resource', 
    icon: Power, 
    color: 'green', 
    category: 'server', 
    description: 'Start a resource', 
    requiresInput: true, 
    premium: true 
  },
  { 
    id: 'stop_resource', 
    label: 'Stop Resource', 
    icon: Power, 
    color: 'red', 
    category: 'server', 
    description: 'Stop a resource', 
    requiresInput: true, 
    premium: true 
  },
  { 
    id: 'announcement', 
    label: 'Server Announcement', 
    icon: AlertTriangle, 
    color: 'yellow', 
    category: 'server', 
    description: 'Broadcast message', 
    requiresInput: true 
  },
  { 
    id: 'reload_eyes', 
    label: 'Reload Eyes', 
    icon: Eye, 
    color: 'cyan', 
    category: 'server', 
    description: 'Soft player reload', 
    autoClose: true 
  },
  { 
    id: 'exec_command', 
    label: 'Execute Command', 
    icon: Terminal, 
    color: 'purple', 
    category: 'server', 
    description: 'Run server command', 
    requiresInput: true, 
    premium: true 
  },
  { 
    id: 'run_code', 
    label: 'Run Code', 
    icon: Code, 
    color: 'red', 
    category: 'server', 
    description: 'Execute Lua code', 
    requiresInput: true, 
    premium: true 
  },
  { 
    id: 'refresh_db', 
    label: 'Refresh Database', 
    icon: Database, 
    color: 'green', 
    category: 'server', 
    description: 'Reload database connections', 
    premium: true 
  },
];

// ============================================================================
// CATEGORY HELPERS
// ============================================================================

export const CATEGORIES = {
  all: { label: 'All Actions', icon: Zap },
  self: { label: 'Self', icon: User },
  teleport: { label: 'Teleport', icon: MapPin },
  player: { label: 'Player', icon: Users },
  vehicle: { label: 'Vehicle', icon: Car },
  world: { label: 'World', icon: CloudRain },
  server: { label: 'Server', icon: Server },
  economy: { label: 'Economy', icon: DollarSign },
  admin: { label: 'Admin', icon: Shield },
};

export const CATEGORY_COLORS = {
  self: 'text-purple-400 bg-purple-500/10',
  teleport: 'text-blue-400 bg-blue-500/10',
  player: 'text-orange-400 bg-orange-500/10',
  vehicle: 'text-green-400 bg-green-500/10',
  server: 'text-yellow-400 bg-yellow-500/10',
  world: 'text-cyan-400 bg-cyan-500/10',
  economy: 'text-emerald-400 bg-emerald-500/10',
  admin: 'text-red-400 bg-red-500/10',
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

export function getActionsByCategory(category: string): QuickAction[] {
  if (category === 'all') return ALL_QUICK_ACTIONS;
  return ALL_QUICK_ACTIONS.filter(action => action.category === category);
}

export function getActionById(id: string): QuickAction | undefined {
  return ALL_QUICK_ACTIONS.find(action => action.id === id);
}

export function searchActions(actions: QuickAction[], query: string, category: string = 'all'): QuickAction[] {
  // Handle empty or invalid query
  if (!query || typeof query !== 'string') {
    // If no search query, just filter by category
    if (category === 'all') {
      return actions;
    }
    return actions.filter(action => action.category === category);
  }
  
  const lowerQuery = query.toLowerCase();
  
  return actions.filter(action => {
    // Filter by category first
    const matchesCategory = category === 'all' || action.category === category;
    if (!matchesCategory) return false;
    
    // Then filter by search query
    return action.label.toLowerCase().includes(lowerQuery) ||
      action.description.toLowerCase().includes(lowerQuery) ||
      action.id.toLowerCase().includes(lowerQuery);
  });
}

export function getFavoriteActions(favoriteIds: string[]): QuickAction[] {
  return ALL_QUICK_ACTIONS.filter(action => favoriteIds.includes(action.id));
}

export function getRecentActions(recentIds: string[]): QuickAction[] {
  return recentIds
    .map(id => ALL_QUICK_ACTIONS.find(action => action.id === id))
    .filter((action): action is QuickAction => action !== undefined);
}

// ============================================================================
// EXPORT TOTALS
// ============================================================================

export const ACTION_COUNTS = {
  total: ALL_QUICK_ACTIONS.length,
  self: getActionsByCategory('self').length,
  teleport: getActionsByCategory('teleport').length,
  player: getActionsByCategory('player').length,
  vehicle: getActionsByCategory('vehicle').length,
  world: getActionsByCategory('world').length,
  server: getActionsByCategory('server').length,
};

console.log(`[EC Admin] Loaded ${ACTION_COUNTS.total} quick actions across ${Object.keys(CATEGORIES).length - 1} categories`);