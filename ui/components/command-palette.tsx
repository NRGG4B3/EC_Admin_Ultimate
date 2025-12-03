import { useState, useEffect, useMemo } from 'react';
// Completely removed motion import to fix framer-motion conflicts
// import { motion } from 'motion/react';
import { Input } from './ui/input';
import { ScrollArea } from './ui/scroll-area';
import { Badge } from './ui/badge';
import type { PageType } from '../src/types';
import {
  Search,
  Users,
  Car,
  Monitor,
  Brain,
  Shield,
  AlertTriangle,
  Briefcase,
  FileText,
  BarChart3,
  Package,
  Wrench,
  Settings,
  DollarSign,
  Ban,
  Map,
  HardDrive,
  Gauge,
  MessageSquare,
  Calendar,
  UserCheck,
  Layers,
  Home,
  Eye,
  Command,
  Navigation,
  Zap,
  LayoutDashboard
} from 'lucide-react';

interface CommandPaletteProps {
  currentPage: PageType;
  setCurrentPage: (page: PageType) => void;
  onClose: () => void;
  onRefreshData?: () => void; // Add callback for data refresh
}

interface Command {
  id: string;
  label: string;
  description: string;
  icon: any;
  action: () => void;
  category: string;
  keywords: string[];
  badge?: string;
}

export function CommandPalette({ currentPage, setCurrentPage, onClose, onRefreshData }: CommandPaletteProps) {
  const [query, setQuery] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);

  const commands: Command[] = useMemo(() => [
    // Navigation Commands
    {
      id: 'nav-dashboard',
      label: 'Dashboard',
      description: 'View server overview and statistics',
      icon: LayoutDashboard,
      action: () => { setCurrentPage('dashboard'); onClose(); },
      category: 'Navigation',
      keywords: ['home', 'overview', 'stats']
    },
    {
      id: 'nav-players',
      label: 'Players',
      description: 'Manage online and offline players',
      icon: Users,
      action: () => { setCurrentPage('players'); onClose(); },
      category: 'Navigation',
      keywords: ['users', 'online', 'manage']
    },
    {
      id: 'nav-vehicles',
      label: 'Vehicles',
      description: 'Monitor and manage server vehicles',
      icon: Car,
      action: () => { setCurrentPage('vehicles'); onClose(); },
      category: 'Navigation',
      keywords: ['cars', 'spawned', 'teleport']
    },
    {
      id: 'nav-monitor',
      label: 'System Monitor',
      description: 'Real-time server performance monitoring',
  icon: Monitor,
  action: () => { setCurrentPage('server-monitor'); onClose(); },
      category: 'Navigation',
      keywords: ['performance', 'cpu', 'memory', 'live']
    },
    {
      id: 'nav-ai-analytics',
      label: 'AI Analytics',
      description: 'Advanced player behavior analysis',
  icon: Brain,
  action: () => { setCurrentPage('anticheat'); onClose(); },
      category: 'Navigation',
      keywords: ['artificial intelligence', 'behavior', 'analysis'],
      badge: 'NEW'
    },
    {
      id: 'nav-anticheat',
      label: 'Anticheat',
      description: 'Configure and monitor anticheat systems',
      icon: Shield,
      action: () => { setCurrentPage('anticheat'); onClose(); },
      category: 'Navigation',
      keywords: ['cheat', 'hack', 'detection', 'security']
    },
    
    // Quick Actions
    {
      id: 'action-refresh',
      label: 'Refresh Data',
      description: 'Manually refresh all live data',
      icon: Zap,
      action: () => { 
        if (onRefreshData) {
          onRefreshData(); 
        } else {
          // Trigger data refresh event instead of full page reload
          window.dispatchEvent(new CustomEvent('ec-admin-refresh-data'));
          console.log('[Command Palette] Triggered data refresh event');
        }
        onClose(); 
      },
      category: 'Actions',
      keywords: ['reload', 'update', 'sync']
    },
    {
      id: 'action-kick-all',
      label: 'Emergency Kick All',
      description: 'Kick all players (emergency only)',
      icon: AlertTriangle,
      action: () => { console.log('Emergency kick all'); onClose(); },
      category: 'Actions',
      keywords: ['emergency', 'disconnect', 'all players']
    },
    {
      id: 'action-restart-warning',
      label: 'Restart Warning',
      description: 'Send server restart warning to all players',
      icon: MessageSquare,
      action: () => { console.log('Restart warning sent'); onClose(); },
      category: 'Actions',
      keywords: ['announce', 'warning', 'restart']
    },
    
    // Settings
    {
      id: 'settings-general',
      label: 'General Settings',
      description: 'Configure general admin panel settings',
      icon: Settings,
      action: () => { setCurrentPage('settings'); onClose(); },
      category: 'Settings',
      keywords: ['config', 'preferences', 'options']
    },
    
    // Help
    {
      id: 'help-shortcuts',
      label: 'Keyboard Shortcuts',
      description: 'View all available keyboard shortcuts',
      icon: Command,
      action: () => { console.log('Show shortcuts'); onClose(); },
      category: 'Help',
      keywords: ['hotkeys', 'keys', 'commands']
    }
  ], [setCurrentPage, onClose, onRefreshData]);

  const filteredCommands = useMemo(() => {
    if (!query.trim()) return commands;
    
    const queryLower = query.toLowerCase();
    return commands.filter(command =>
      command.label.toLowerCase().includes(queryLower) ||
      command.description.toLowerCase().includes(queryLower) ||
      command.keywords.some(keyword => keyword.toLowerCase().includes(queryLower)) ||
      command.category.toLowerCase().includes(queryLower)
    );
  }, [commands, query]);

  // Group commands by category
  const groupedCommands = useMemo(() => {
    const groups: Record<string, Command[]> = {};
    filteredCommands.forEach(command => {
      if (!groups[command.category]) {
        groups[command.category] = [];
      }
      groups[command.category].push(command);
    });
    return groups;
  }, [filteredCommands]);

  // Handle keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
        return;
      }
      
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setSelectedIndex(prev => 
          prev < filteredCommands.length - 1 ? prev + 1 : 0
        );
        return;
      }
      
      if (e.key === 'ArrowUp') {
        e.preventDefault();
        setSelectedIndex(prev => 
          prev > 0 ? prev - 1 : filteredCommands.length - 1
        );
        return;
      }
      
      if (e.key === 'Enter') {
        e.preventDefault();
        if (filteredCommands[selectedIndex]) {
          filteredCommands[selectedIndex].action();
        }
        return;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [filteredCommands, selectedIndex, onClose]);

  // Reset selection when filtered commands change
  useEffect(() => {
    setSelectedIndex(0);
  }, [filteredCommands]);

  return (
    <div
      className="fixed inset-0 bg-black/50 dark:bg-black/70 backdrop-blur-sm flex items-start justify-center pt-[10vh] z-[9999] pointer-events-auto animate-in fade-in-0 duration-200"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="w-full max-w-2xl backdrop-blur-xl border border-border dark:border-border rounded-xl shadow-2xl overflow-hidden ec-gradient-bg"
      >
        {/* Header */}
        <div className="p-4 border-b border-border/20 dark:border-border/10">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-muted-foreground" />
            <Input
              type="text"
              placeholder="Search commands, pages, and actions..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="pl-9 bg-transparent border-none focus:ring-0 text-base"
              autoFocus
            />
          </div>
        </div>

        {/* Commands */}
        <ScrollArea className="max-h-96 p-2">
          {Object.keys(groupedCommands).length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <Search className="size-8 mx-auto mb-3 opacity-50" />
              <p>No commands found</p>
              <p className="text-sm">Try a different search term</p>
            </div>
          ) : (
            <div className="space-y-4">
              {(
                Object.entries(groupedCommands) as [string, Command[]][]
              ).map(([category, categoryCommands]) => (
                <div key={category}>
                  <div className="text-xs font-medium text-muted-foreground px-2 mb-2">
                    {category}
                  </div>
                  <div className="space-y-1">
                    {categoryCommands.map((command, categoryIndex) => {
                      const globalIndex = filteredCommands.indexOf(command);
                      const isSelected = globalIndex === selectedIndex;
                      const Icon = command.icon;
                      
                      return (
                        <button
                          key={command.id}
                          onClick={command.action}
                          className={`
                            w-full flex items-center gap-3 p-3 rounded-lg text-left
                            transition-all duration-150 hover:translate-x-0.5 active:scale-[0.98]
                            ${isSelected 
                              ? 'bg-accent border border-border' 
                              : 'hover:bg-accent/50'
                            }
                          `}
                        >
                          <div className={`
                            size-8 rounded-lg flex items-center justify-center
                            ${isSelected ? 'bg-white/10' : 'ec-card-transparent border border-border/20'}
                          `}>
                            <Icon className="size-4" />
                          </div>
                          
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <span className="font-medium">{command.label}</span>
                              {command.badge && (
                                <Badge variant="outline" className="text-xs px-1.5 py-0">
                                  {command.badge}
                                </Badge>
                              )}
                            </div>
                            <p className="text-sm text-muted-foreground">
                              {command.description}
                            </p>
                          </div>
                          
                          <div className="text-xs text-muted-foreground">
                            ↵
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          )}
        </ScrollArea>

        {/* Footer */}
        <div className="px-4 py-3 border-t border-border/20">
          <div className="flex items-center justify-between text-xs text-muted-foreground">
            <div className="flex items-center gap-4">
              <span>↑↓ Navigate</span>
              <span>↵ Select</span>
              <span>Esc Close</span>
            </div>
            <div>
              {filteredCommands.length} commands
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}