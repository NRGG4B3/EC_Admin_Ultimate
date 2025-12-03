import { useState, useEffect } from 'react';
import { fetchNui } from './nui-bridge';
import { useTheme } from './theme-manager';
import { 
  Bell, 
  Search, 
  Users, 
  Activity, 
  Minimize2, 
  Maximize2,
  X,
  Command,
  UserCircle,
  Settings,
  Zap,
  Monitor,
  Sun,
  Moon
} from 'lucide-react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { LiveData } from './nui-bridge';

interface TopbarProps {
  currentPage?: string;
  onPageChange?: (page: string) => void;
  onToggleCompact?: () => void;
  isCompact: boolean;
  setIsCompact?: (compact: boolean) => void;
  onClose?: () => void;
  onOpenCommandPalette: () => void;
  onOpenNotifications: () => void;
  onOpenQuickActions: () => void;
  onNavigateToPage: (page: any) => void;
  liveData: LiveData | null;
  isVPSMode?: boolean; // Optional: indicates if running in VPS admin mode (browser)
}

export function Topbar({
  currentPage,
  onPageChange,
  onToggleCompact,
  isCompact,
  setIsCompact,
  onClose,
  onOpenCommandPalette,
  onOpenNotifications,
  onOpenQuickActions,
  onNavigateToPage,
  liveData,
  isVPSMode = false
}: TopbarProps) {
  const [searchFocused, setSearchFocused] = useState(false);
  const { theme, toggleTheme } = useTheme();
  
  // Server logo from settings
  const [serverLogo, setServerLogo] = useState<string | null>(null);
  const [serverName, setServerName] = useState<string>('My FiveM Server');
  
  // Admin profile state - real FiveM data
  const [adminProfile, setAdminProfile] = useState<{
    name: string;
    username: string;
    email: string;
    role: string;
    roleLabel: string;
    avatar: string | null;
    isSuperUser: boolean;
  } | null>(null);
  
  // Quick stats state
  const [quickStats, setQuickStats] = useState<{
    playersOnline: number;
    openReports: number;
    activeBans: number;
    recentAlerts: number;
  } | null>(null);

  // Load admin profile on mount with timeout and fallback
  useEffect(() => {
    // Mock data for fallback
    const mockAdminProfile = {
      success: true,
      data: {
        name: 'Admin',
        username: 'admin',
        email: 'admin@server.com',
        role: 'superadmin',
        roleLabel: 'Super Admin',
        avatar: null,
        isSuperUser: true
      }
    };

    const mockQuickStats = {
      success: true,
      data: {
        playersOnline: liveData?.playersOnline || 0,
        openReports: 0,
        activeBans: 0,
        recentAlerts: liveData?.alerts?.length || 0
      }
    };

    // Load admin profile with 3 second timeout
    fetchNui('topbar:getAdminProfile', {}, mockAdminProfile, 3000)
      .then((response: any) => {
        if (response.success && response.data) {
          console.log('[Topbar] Admin profile loaded:', response.data);
          setAdminProfile(response.data);
        }
      })
      .catch((error) => {
        console.warn('[Topbar] Failed to load admin profile, using fallback:', error.message);
        // Use mock data as fallback
        setAdminProfile(mockAdminProfile.data);
      });
    
    // Load quick stats with 3 second timeout
    fetchNui('topbar:getQuickStats', {}, mockQuickStats, 3000)
      .then((response: any) => {
        if (response.success && response.data) {
          console.log('[Topbar] Quick stats loaded:', response.data);
          setQuickStats(response.data);
        }
      })
      .catch((error) => {
        console.warn('[Topbar] Failed to load quick stats, using fallback:', error.message);
        // Use mock data as fallback
        setQuickStats(mockQuickStats.data);
      });
    
    // Load server settings for logo and name
    const mockSettings = {
      success: true,
      data: {
        general: {
          serverName: 'My FiveM Server',
          serverLogo: ''
        }
      }
    };
    
    fetchNui('settings:getData', {}, mockSettings, 3000)
      .then((response: any) => {
        if (response.success && response.data && response.data.general) {
          console.log('[Topbar] Server settings loaded');
          if (response.data.general.serverLogo) {
            setServerLogo(response.data.general.serverLogo);
          }
          if (response.data.general.serverName) {
            setServerName(response.data.general.serverName);
          }
        }
      })
      .catch((error) => {
        console.warn('[Topbar] Failed to load server settings, using defaults:', error.message);
      });
  }, [liveData]);
  
  // Update quick stats every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      const mockQuickStats = {
        success: true,
        data: {
          playersOnline: liveData?.playersOnline || 0,
          openReports: 0,
          activeBans: 0,
          recentAlerts: liveData?.alerts?.length || 0
        }
      };

      fetchNui('topbar:getQuickStats', {}, mockQuickStats, 3000)
        .then((response: any) => {
          if (response.success && response.data) {
            setQuickStats(response.data);
          }
        })
        .catch(() => {
          // Silent fail - keep existing stats
          console.log('[Topbar] Quick stats update failed, keeping current data');
        });
    }, 30000);
    
    return () => clearInterval(interval);
  }, [liveData]);
  
  // Handle logout - no longer needed for quick actions, but kept for potential future use
  const handleLogout = () => {
    const mockLogoutResponse = {
      success: true,
      message: 'Logged out successfully'
    };

    fetchNui('topbar:logout', {}, mockLogoutResponse, 2000)
      .then((response: any) => {
        if (response.success) {
          console.log('[Topbar] Logout successful');
          onClose();
        }
      })
      .catch((error) => {
        console.warn('[Topbar] Logout request failed/timeout, closing anyway:', error.message);
        // Close anyway - logout is a UI action, doesn't need server confirmation
        onClose();
      });
  };

  const alertCount = liveData?.alerts?.length || 0;
  const criticalAlerts = liveData?.alerts?.filter(alert => alert.severity === 'critical').length || 0;

  return (
    <div 
      className={`flex items-center justify-between border-b border-border ${isCompact ? 'px-3 py-2' : 'px-6 py-4'}`}
    >
      {/* Left Section - Logo & Status */}
      <div className="flex items-center gap-4">
        {/* Logo & Title */}
        <div className={`flex items-center ${isCompact ? 'gap-2' : 'gap-3'}`}>
          <div className="relative">
            {serverLogo ? (
              <div className={`rounded-lg overflow-hidden flex items-center justify-center ${isCompact ? 'size-6' : 'size-8'}`}>
                <img 
                  src={serverLogo} 
                  alt="Server Logo" 
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    // Fallback to default logo if image fails to load
                    e.currentTarget.style.display = 'none';
                    e.currentTarget.parentElement?.classList.add('bg-gradient-to-br', 'from-blue-500', 'to-purple-600');
                  }}
                />
                <div className="absolute -bottom-1 -right-1">
                  <div className={`bg-green-500 rounded-full border-2 border-card animate-pulse ${isCompact ? 'size-2' : 'size-3'}`} />
                </div>
              </div>
            ) : (
              <>
                <div className={`rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center ${isCompact ? 'size-6' : 'size-8'}`}>
                  <Activity className={`text-white ${isCompact ? 'size-3' : 'size-4'}`} />
                </div>
                <div className="absolute -bottom-1 -right-1">
                  <div className={`bg-green-500 rounded-full border-2 border-card animate-pulse ${isCompact ? 'size-2' : 'size-3'}`} />
                </div>
              </>
            )}
          </div>
          
          <div className="flex flex-col">
            <h1 className={`font-semibold leading-none ${isCompact ? 'text-sm' : 'text-lg'}`}>
              <span className="bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
                {serverName}
              </span>
            </h1>
            <span className={`text-muted-foreground ${isCompact ? 'text-[10px]' : 'text-xs'}`}>
              EC Admin Ultimate v1.0.0
            </span>
          </div>
        </div>

        {/* Live Status Indicators */}
        {liveData && (
          <div className={`flex items-center ${isCompact ? 'gap-2 ml-3' : 'gap-4 ml-6'}`}>
            <div className={`flex items-center gap-2 rounded-full bg-green-500/10 border border-green-500/20 ${isCompact ? 'px-2 py-1' : 'px-3 py-1.5'}`}>
              <Users className={isCompact ? 'size-2.5 text-green-400' : 'size-3 text-green-400'} />
              <span className={`font-medium text-green-400 ${isCompact ? 'text-xs' : 'text-sm'}`}>
                {liveData.playersOnline}
              </span>
            </div>
            
            <div className={`flex items-center gap-2 rounded-full bg-blue-500/10 border border-blue-500/20 ${isCompact ? 'px-2 py-1' : 'px-3 py-1.5'}`}>
              <Activity className={isCompact ? 'size-2.5 text-blue-400' : 'size-3 text-blue-400'} />
              <span className={`font-medium text-blue-400 ${isCompact ? 'text-xs' : 'text-sm'}`}>
                {liveData.serverTPS.toFixed(1)} TPS
              </span>
            </div>
            
            <div className={`flex items-center gap-2 rounded-full bg-purple-500/10 border border-purple-500/20 ${isCompact ? 'px-2 py-1' : 'px-3 py-1.5'}`}>
              <div className={`rounded-full bg-purple-400 animate-pulse ${isCompact ? 'size-1.5' : 'size-2'}`} />
              <span className={`font-medium text-purple-400 ${isCompact ? 'text-xs' : 'text-sm'}`}>
                {liveData.memoryUsage.toFixed(1)}% RAM
              </span>
            </div>
          </div>
        )}
      </div>

      {/* Center Section - Search */}
      <div className={`flex-1 ${isCompact ? 'max-w-xs mx-3' : 'max-w-md mx-6'}`}>
        <div className={`relative ${searchFocused ? 'scale-105' : ''}`}>
          <Search className={`absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground ${isCompact ? 'size-3' : 'size-4'}`} />
          <input
            type="text"
            placeholder={isCompact ? 'Search or ⌘K...' : 'Search players, actions, or type ⌘K for commands...'}
            className={`w-full ec-card-transparent border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary ${isCompact ? 'pl-8 pr-10 py-1.5 text-xs' : 'pl-10 pr-12 py-2'}`}
            onFocus={() => setSearchFocused(true)}
            onBlur={() => setSearchFocused(false)}
            onClick={onOpenCommandPalette}
            readOnly
          />
          <div className={`absolute right-3 top-1/2 transform -translate-y-1/2`}>
            <kbd className={`inline-flex items-center gap-1 font-mono ec-card-transparent border border-border/30 rounded ${isCompact ? 'px-1.5 py-0.5 text-[10px]' : 'px-2 py-1 text-xs'}`}>
              <Command className={isCompact ? 'size-2' : 'size-3'} />K
            </kbd>
          </div>
        </div>
      </div>

      {/* Right Section - Actions */}
      <div className={`flex items-center ${isCompact ? 'gap-1' : 'gap-2'}`}>
        {/* Notifications */}
        <Button
          variant="ghost"
          size={isCompact ? 'sm' : 'sm'}
          onClick={onOpenNotifications}
          className={`relative hover:bg-accent ${isCompact ? 'h-7 w-7 p-0' : ''}`}
        >
          <Bell className={isCompact ? 'size-3' : 'size-4'} />
          {alertCount > 0 && (
            <Badge 
              variant={criticalAlerts > 0 ? "destructive" : "secondary"}
              className={`absolute -top-1 -right-1 p-0 flex items-center justify-center ${isCompact ? 'size-4 text-[9px] min-w-4' : 'size-5 text-xs min-w-5'}`}
            >
              {alertCount > 9 ? '9+' : alertCount}
            </Badge>
          )}
        </Button>

        {/* Settings */}
        <Button
          variant="ghost"
          size={isCompact ? 'sm' : 'sm'}
          onClick={() => onNavigateToPage('settings')}
          className={`hover:bg-accent ${isCompact ? 'h-7 w-7 p-0' : ''}`}
        >
          <Settings className={isCompact ? 'size-3' : 'size-4'} />
        </Button>

        {/* View Toggle */}
        <Button
          variant="ghost"
          size={isCompact ? 'sm' : 'sm'}
          onClick={() => {
            if (onToggleCompact) {
              onToggleCompact();
            } else if (setIsCompact) {
              setIsCompact(!isCompact);
            }
          }}
          className={`hover:bg-accent ${isCompact ? 'h-7 w-7 p-0' : ''}`}
        >
          {isCompact ? <Maximize2 className={isCompact ? 'size-3' : 'size-4'} /> : <Minimize2 className={isCompact ? 'size-3' : 'size-4'} />}
        </Button>

        {/* Quick Actions */}
        <Button
          variant="ghost"
          size={isCompact ? 'sm' : 'sm'}
          onClick={onOpenQuickActions}
          className={`hover:bg-accent ${isCompact ? 'h-7 w-7 p-0' : ''}`}
          title="Quick Actions"
        >
          <Zap className={isCompact ? 'size-3' : 'size-4'} />
        </Button>

        {/* Theme Toggle */}
        <Button
          variant="ghost"
          size={isCompact ? 'sm' : 'sm'}
          onClick={toggleTheme}
          className={`hover:bg-accent ${isCompact ? 'h-7 w-7 p-0' : ''}`}
          title={theme === 'dark' ? 'Switch to Light Mode' : theme === 'light' ? 'Switch to Auto Mode' : 'Switch to Dark Mode'}
        >
          {theme === 'dark' ? (
            <Sun className={isCompact ? 'size-3' : 'size-4'} />
          ) : theme === 'light' ? (
            <Monitor className={isCompact ? 'size-3' : 'size-4'} />
          ) : (
            <Moon className={isCompact ? 'size-3' : 'size-4'} />
          )}
        </Button>

        {/* Admin Profile Button - Direct navigation to profile page */}
        <button
          onClick={() => {
            console.log('[Topbar] Navigating to admin profile');
            onNavigateToPage('admin-profile');
          }}
          className={`flex items-center rounded-lg hover:bg-accent transition-colors ${isCompact ? 'gap-1.5 px-2 py-1' : 'gap-2 px-3 py-2'}`}
          title="My Profile"
        >
          <div className={`rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center ${isCompact ? 'size-6' : 'size-8'}`}>
            <UserCircle className={isCompact ? 'size-4 text-white' : 'size-5 text-white'} />
          </div>
          <div className="text-left hidden sm:block">
            <p className={`font-medium ${isCompact ? 'text-xs' : 'text-sm'}`}>{adminProfile?.username || 'Admin'}</p>
            <p className={`text-muted-foreground ${isCompact ? 'text-[10px]' : 'text-xs'}`}>{adminProfile?.roleLabel || 'Loading...'}</p>
          </div>
        </button>

        {/* Close - Only show in FiveM mode, hide in VPS admin mode */}
        {!isVPSMode && (
          <Button
            variant="ghost"
            size={isCompact ? 'sm' : 'sm'}
            onClick={onClose}
            className={`hover:bg-red-500/20 hover:text-red-400 ${isCompact ? 'h-7 w-7 p-0' : ''}`}
            title="Close Panel (ESC)"
          >
            <X className={isCompact ? 'size-3' : 'size-4'} />
          </Button>
        )}
        
        {/* VPS Admin Mode Indicator - Only show in browser */}
        {isVPSMode && (
          <div className={`flex items-center bg-blue-500/10 border border-blue-500/30 rounded-md ${isCompact ? 'gap-1.5 px-2 py-1' : 'gap-2 px-3 py-1.5'}`}>
            <Monitor className={`text-blue-400 ${isCompact ? 'size-3' : 'size-4'}`} />
            <span className={`font-medium text-blue-400 ${isCompact ? 'text-[10px]' : 'text-xs'}`}>VPS Admin Mode</span>
          </div>
        )}
      </div>

      {/* Note: Quick Actions Center is now handled in App.tsx like Notification Center */}
    </div>
  );
}