import { Button } from './ui/button';
import { Separator } from './ui/separator';
import { Badge } from './ui/badge';
import { 
  LayoutDashboard, 
  Users, 
  Car, 
  Activity, 
  Brain, 
  Briefcase, 
  Package, 
  Globe, 
  Settings,
  Shield,
  Zap,
  TrendingUp,
  ChevronRight,
  DollarSign,
  AlertTriangle,
  Map,
  Database,
  MessageCircle,
  Calendar,
  UserCheck,
  Server,
  Monitor,
  Building,
  MessageSquare,
  Puzzle,
  Code2,
  ShieldCheck,
  UserX,
  Eye,
  FileText,
  BarChart3,
  UserCog,
  Crown
} from 'lucide-react';
import type { PageType } from '../src/types';
import { useState, useEffect } from 'react';
import { fetchNui } from './nui-bridge';

interface SidebarProps {
  currentPage: PageType;
  onPageChange: (page: PageType) => void;
  isCompact: boolean;
}

const menuItems = [
  { 
    id: 'dashboard' as PageType, 
    icon: LayoutDashboard, 
    label: 'Dashboard', 
    color: 'from-blue-600 to-purple-600',
    bgColor: 'bg-blue-500/10',
    iconColor: 'text-blue-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'host-dashboard' as PageType, 
    icon: Crown, 
    label: 'Host Dashboard', 
    color: 'from-purple-600 via-amber-600 to-pink-600',
    bgColor: 'bg-gradient-to-r from-purple-500/10 via-amber-500/10 to-pink-500/10',
    iconColor: 'text-amber-400',
    count: null,
    hostOnly: true
  },
  { 
    id: 'players' as PageType, 
    icon: Users, 
    label: 'Players', 
    color: 'from-green-600 to-blue-600',
    bgColor: 'bg-green-500/10',
    iconColor: 'text-emerald-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'vehicles' as PageType, 
    icon: Car, 
    label: 'Vehicles', 
    color: 'from-orange-600 to-red-600',
    bgColor: 'bg-orange-500/10',
    iconColor: 'text-orange-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'server-monitor' as PageType, 
    icon: Monitor, 
    label: 'Server Monitor', 
    color: 'from-green-600 to-teal-600',
    bgColor: 'bg-green-500/10',
    iconColor: 'text-cyan-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'economy-global-tools' as PageType, 
    icon: DollarSign, 
    label: 'Economy & Tools', 
    color: 'from-green-600 to-emerald-600',
    bgColor: 'bg-green-500/10',
    iconColor: 'text-green-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'jobs-gangs' as PageType, 
    icon: Briefcase, 
    label: 'Jobs & Gangs', 
    color: 'from-indigo-600 to-blue-600',
    bgColor: 'bg-indigo-500/10',
    iconColor: 'text-indigo-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'inventory' as PageType, 
    icon: Package, 
    label: 'Inventory', 
    color: 'from-purple-600 to-pink-600',
    bgColor: 'bg-purple-500/10',
    iconColor: 'text-purple-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'housing' as PageType, 
    icon: Building, 
    label: 'Housing', 
    color: 'from-emerald-600 to-teal-600',
    bgColor: 'bg-emerald-500/10',
    iconColor: 'text-teal-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'moderation' as PageType, 
    icon: Shield, 
    label: 'Moderation', 
    color: 'from-red-600 to-orange-600',
    bgColor: 'bg-red-500/10',
    iconColor: 'text-red-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'anticheat' as PageType, 
    icon: ShieldCheck, 
    label: 'Anticheat & AI', 
    color: 'from-red-600 to-pink-600',
    bgColor: 'bg-red-500/10',
    iconColor: 'text-rose-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'system-management' as PageType, 
    icon: Settings, 
    label: 'System Mgmt', 
    color: 'from-blue-600 to-purple-600',
    bgColor: 'bg-blue-500/10',
    iconColor: 'text-sky-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'community' as PageType, 
    icon: MessageSquare, 
    label: 'Community', 
    color: 'from-purple-600 to-pink-600',
    bgColor: 'bg-purple-500/10',
    iconColor: 'text-pink-400',
    count: null,
    hostOnly: false
  },
  // NOTE: admin-profile is intentionally excluded from sidebar - accessed programmatically only
  { 
    id: 'whitelist' as PageType, 
    icon: UserCheck, 
    label: 'Whitelist', 
    color: 'from-teal-600 to-green-600',
    bgColor: 'bg-teal-500/10',
    iconColor: 'text-lime-400',
    count: null,
    hostOnly: false
  },
  { 
    id: 'settings' as PageType, 
    icon: Settings, 
    label: 'Settings', 
    color: 'from-gray-600 to-slate-600',
    bgColor: 'bg-gray-500/10',
    iconColor: 'text-slate-400',
    count: null,
    hostOnly: false
  }
];

export function Sidebar({ currentPage, onPageChange, isCompact }: SidebarProps) {
  const [isHostMode, setIsHostMode] = useState(false);
  const [isNRGStaff, setIsNRGStaff] = useState(false);
  const [frameworkLabel, setFrameworkLabel] = useState('Unknown');
  const [dbLabel, setDbLabel] = useState('Unknown');

  const isFiveM = typeof window !== 'undefined' && (window.invokeNative !== undefined || window.location.protocol === 'nui:');

  // Check if host mode is enabled and if user is NRG staff
  useEffect(() => {
    const checkHostAccess = async () => {
      try {
        // In FiveM, check if host folder exists and user has access
        const hostStatus = await fetchNui<{ hostMode: boolean; isNRGStaff: boolean; canAccessHostDashboard: boolean; mode: string }>('checkHostAccess', {});
        
        if (import.meta.env?.DEV) console.log('[Sidebar] Host access check result:', hostStatus);
        
        // Only show host dashboard if:
        // 1. Host mode is enabled (host/ folder exists) OR
        // 2. User is NRG staff (can access from customer servers)
        setIsHostMode(hostStatus.hostMode || false);
        setIsNRGStaff(hostStatus.isNRGStaff || false);
      } catch (error) {
        if (import.meta.env?.DEV) console.error('[Sidebar] Failed to check host access:', error);
        // Default to customer mode (no host access)
        setIsHostMode(false);
        setIsNRGStaff(false);
      }
    };

    if (isFiveM) {
      checkHostAccess();
    } else {
      // Outside FiveM (browser), default to customer mode
      setIsHostMode(false);
      setIsNRGStaff(false);
    }
  }, [isFiveM]);

  // Load system info (framework and database) without any mock fallback
  useEffect(() => {
    const loadSystemInfo = async () => {
      if (!isFiveM) {
        // Outside NUI, don't invent data
        setFrameworkLabel('Unknown');
        setDbLabel('Unknown');
        return;
      }
      try {
        const info = await fetchNui<{ framework: { detected: boolean; type: string }; database: { connected: boolean; type: string } }>(
          'sidebar:getSystemInfo',
          {}
        );
        if (info && info.framework && info.database) {
          const fw = info.framework.type || 'Unknown';
          const db = info.database.type || 'Unknown';
          setFrameworkLabel(fw);
          setDbLabel(db);
        } else {
          setFrameworkLabel('Unknown');
          setDbLabel('Unknown');
        }
      } catch (err) {
        console.error('[Sidebar] Failed to load system info:', err);
        setFrameworkLabel('Unknown');
        setDbLabel('Unknown');
      }
    };
    loadSystemInfo();
  }, [isFiveM]);

  // Filter menu items - hide host-only items if not in host mode or not NRG staff
  const visibleMenuItems = menuItems.filter(item => {
    if (item.id === 'dev-tools') {
      return false; // Dev tools hidden in production
    }
    // Show host-only items only if:
    // 1. Host mode is enabled (host/ folder exists) OR
    // 2. User is NRG staff (can access from customer servers)
    if (item.hostOnly) {
      return isHostMode || isNRGStaff; // Changed from && to || (OR logic)
    }
    return true;
  });

  return (
    <div 
      className={`border-r border-sidebar-border h-full flex flex-col ${isCompact ? 'w-48' : 'w-56'} relative overflow-hidden`}
    >
      {/* Remove animated background shimmer */}
      
      {/* Navigation */}
      <div className="flex-1 relative p-2 space-y-1 pt-3 overflow-y-auto">
        {visibleMenuItems.map((item) => {
          const Icon = item.icon;
          const isActive = currentPage === item.id;
          
          return (
            <Button
              key={item.id}
              variant="ghost"
              data-active={isActive}
              className={`
                w-full justify-start gap-2 ${isCompact ? 'h-8' : 'h-9'} relative overflow-hidden group transition-all duration-300 ease-out
                ${isActive 
                  ? `bg-purple-600 dark:bg-white/10 text-white shadow-lg scale-105 border border-purple-400/40` 
                  : `text-sidebar-foreground hover:bg-purple-500/20 dark:hover:bg-white/5 hover:scale-102 hover:shadow-sm hover:border-foreground/10 border border-transparent`
                }
              `}
              onClick={() => onPageChange(item.id)}
            >
              {/* Remove all shimmer/pulse animations */}
              
              <div className={(isCompact ? 'p-1 rounded-sm' : 'p-1.5 rounded-md') + ' ' + (isActive ? 'bg-white/20' : 'bg-purple-500/10 dark:bg-white/5') + ' transition-all duration-200'}>
                <Icon className={(isCompact ? 'size-3' : 'size-3.5') + ' ' + (isActive ? 'text-white drop-shadow-sm' : item.iconColor) + ' transition-all duration-200'} />
              </div>
              <span className={`truncate relative z-10 flex-1 text-left transition-all duration-200 ${isActive ? 'text-white font-semibold drop-shadow-sm' : ''}`} style={{
                fontSize: isCompact ? '0.75rem' : '0.875rem',
                fontWeight: isActive ? 600 : 500,
                fontFamily: 'var(--font-family)',
                letterSpacing: isActive ? '-0.01em' : 'normal'
              }}>
                {item.label}
              </span>
              {/* Remove trending up icon */}
            </Button>
          );
        })}
      </div>

      {/* Footer */}
      <div className={'relative ' + (isCompact ? 'p-2' : 'p-3') + ' border-t border-sidebar-border space-y-2'}>
        <div className={(isCompact ? 'text-[10px]' : 'text-xs') + ' text-sidebar-foreground/60 space-y-1'}>
          <div className="flex items-center justify-between">
            <span>Build: v1.0.0</span>
            <Badge variant="outline" className={(isCompact ? 'text-[9px] px-1 py-0' : 'text-xs px-2 py-0') + ' bg-blue-500/20 text-blue-400 border-blue-500/30'}>
              {dbLabel}
            </Badge>
          </div>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <div className={(isCompact ? 'size-1.5' : 'size-2') + ' rounded-full bg-green-500'} />
              <span className="truncate">Ready</span>
            </div>
            <Badge variant="outline" className={(isCompact ? 'text-[9px] px-1 py-0' : 'text-xs px-2 py-0') + ' bg-green-500/20 text-green-400 border-green-500/30'}>
              {frameworkLabel}
            </Badge>
          </div>
        </div>
        
        {/* NRG Development Branding - UNCHANGEABLE */}
        <div className="pt-2 border-t border-sidebar-border/50">
          <div className={(isCompact ? 'text-[9px]' : 'text-[10px]') + ' text-sidebar-foreground/40 text-center'}>
            <div className="flex items-center justify-center gap-1">
              <span className="opacity-50">Powered by</span>
              <span className="font-semibold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                NRG Development
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}