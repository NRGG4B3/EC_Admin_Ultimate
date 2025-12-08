// EC Admin Ultimate - Complete Admin Panel
// SUPPORTS BOTH LIGHT AND DARK MODES WITH TOGGLE
// ALL REAL DATA - NO MOCKS
import '../global-error-handler';  // ⚠️ CRITICAL: Global error handler (catches ALL errors)
import { useState, useCallback, useEffect, useMemo } from 'react';
import { AppProvider } from '../components/app-context';
import { ErrorBoundary } from '../components/error-boundary';
import { ThemeManager } from '../components/theme-manager';
import { useLiveData, initializeNUI, isEnvBrowser, type LiveData } from '../components/nui-bridge';
import { Topbar } from '../components/admin-topbar';
import { Sidebar } from '../components/admin-sidebar';
import { ToastProvider } from '../components/toast-provider';
import { ModalProvider } from '../components/modal-provider';
import { CommandPalette } from '../components/command-palette';
import { NotificationCenter } from '../components/notification-center';
import { NotificationPopup } from '../components/notification-popup';
import { QuickActionsCenter } from '../components/quick-actions-center';
import type { PageType } from './types';

// ALL PAGES - Eager loading
import { Dashboard } from '../components/pages/dashboard';
import { PlayersPage } from '../components/pages/players';
import { PlayerProfilePage } from '../components/pages/player-profile';
import { VehiclesPage } from '../components/pages/vehicles';
import { SettingsPage } from '../components/pages/settings';
import { AdminProfilePage } from '../components/pages/admin-profile';
import { EconomyGlobalToolsPage } from '../components/pages/economy-global-tools';
import { JobsGangsPage } from '../components/pages/jobs-gangs';
import { InventoryPage } from '../components/pages/inventory';
import { WhitelistPage } from '../components/pages/whitelist-enhanced'; // Fixed: use enhanced version with Settings tab
import { HousingPage } from '../components/pages/housing-optimized';
import { DevToolsPage } from '../components/pages/dev-tools-advanced';
import { HostDashboard } from '../components/pages/host-dashboard';
import { AnticheatPage } from '../components/pages/anticheat';
import { ModerationPage } from '../components/pages/moderation';
import { SystemManagementPage } from '../components/pages/system-management';
import { ServerMonitorPage } from '../components/pages/server-monitor';
import { CommunityPage } from '../components/pages/community';
import { TestingChecklistPage } from '../components/pages/testing-checklist';

// REAL DATA ONLY - Empty initial state, will be filled by server
function getInitialData(): LiveData {
  return {
    playersOnline: 0,
    totalResources: 0,
    cachedVehicles: 0,
    serverTPS: 0,
    memoryUsage: 0,
    networkIn: 0,
    networkOut: 0,
    cpuUsage: 0,
    uptime: 0,
    lastRestart: 0,
    activeEvents: 0,
    database: {
      queries: 0,
      avgResponseTime: 0
    },
    alerts: []
  };
}

export default function App() {
  const [currentPage, setCurrentPage] = useState<PageType>('dashboard');
  const [isCompact, setIsCompact] = useState(false);
  const [isOpen, setIsOpen] = useState(isEnvBrowser()); // Open in browser, closed in FiveM
  const [commandPaletteOpen, setCommandPaletteOpen] = useState(false);
  const [notificationCenterOpen, setNotificationCenterOpen] = useState(false);
  const [quickActionsCenterOpen, setQuickActionsCenterOpen] = useState(false);
  const [selectedPlayerId, setSelectedPlayerId] = useState<number | undefined>();
  const [notificationPopupVisible, setNotificationPopupVisible] = useState(false);
  const [shownAlertIds, setShownAlertIds] = useState<Set<string>>(new Set());
  const [isVPSMode, setIsVPSMode] = useState(isEnvBrowser());
  
  // Initialize with empty data - will be populated by server
  const initialData = getInitialData();
  
  // Use NUI bridge for live data (REAL DATA ONLY)
  const liveData = useLiveData(initialData);

  // Show notification popup when new alerts arrive
  useEffect(() => {
    if (liveData.alerts && Array.isArray(liveData.alerts) && liveData.alerts.length > 0) {
      const newAlerts = liveData.alerts.filter(alert => !shownAlertIds.has(alert.id));
      if (newAlerts.length > 0) {
        setNotificationPopupVisible(true);
        setShownAlertIds(prev => {
          const newSet = new Set(prev);
          newAlerts.forEach(alert => newSet.add(alert.id));
          return newSet;
        });
      }
    }
  }, [liveData.alerts]);

  const handleViewPlayerProfile = useCallback((playerId: number) => {
    setSelectedPlayerId(playerId);
    setCurrentPage('player-profile');
  }, []);

  const handlePageChange = useCallback((page: PageType) => {
    console.log('[App] Navigating to:', page);
    setCurrentPage(page);
  }, []);

  const handleClose = useCallback(() => {
    console.log('[App] handleClose called, isVPSMode:', isVPSMode);
    setIsOpen(false);
    setQuickActionsCenterOpen(false);
    setCommandPaletteOpen(false);
    setNotificationCenterOpen(false);

    if (!isVPSMode) {
      console.log('[App] Setting isOpen to false and calling closePanel callback');
      fetch('https://ec_admin_ultimate/closePanel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      })
        .then(() => console.log('[App] closePanel callback succeeded'))
        .catch((err) => console.log('[App] closePanel callback failed:', err));
    }
  }, [isVPSMode]);

  const handleCloseQuickActions = useCallback(() => {
    console.log('[App] Closing Quick Actions');
    setQuickActionsCenterOpen(false);
    
    // If main menu is NOT open (standalone Quick Actions mode), clear NUI focus
    if (!isOpen && !isVPSMode) {
      console.log('[App] Standalone Quick Actions closed - clearing NUI focus');
      fetch('https://ec_admin_ultimate/closeQuickActions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      }).catch(() => {});
    }
  }, [isOpen, isVPSMode]);

  // Initialize NUI bridge on mount
  useEffect(() => {
    console.log('[EC Admin] Starting initialization...');
    const isBrowser = isEnvBrowser();
    console.log('[EC Admin] Environment:', isBrowser ? 'Browser/VPS' : 'FiveM');
    
    const initialize = async () => {
      try {
        if (isBrowser) {
          console.log('[EC Admin] VPS Admin Mode - Remote access enabled');
          initializeNUI();
          setIsVPSMode(true);
          setIsOpen(true);
        } else {
          console.log('[EC Admin] FiveM Mode - Real data enabled');
          initializeNUI();
          setIsVPSMode(false);
          setIsOpen(false);
        }
      } catch (error) {
        console.error('[EC Admin] Initialization error:', error);
      }
    };
    
    initialize();
  }, []);

  // Listen for NUI visibility messages from Lua
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      try {
        const { action, type, visible, open, openQuickActions } = event.data;
        
        // STRICT: Only process visibility messages in FiveM mode
        if (!isVPSMode) {
          // CRITICAL: ONLY accept EC_SET_VISIBILITY messages
          // This prevents rogue messages from opening the UI
          if (type === 'EC_SET_VISIBILITY') {
            console.log('[EC Admin UI] EC_SET_VISIBILITY - Setting isOpen to:', !!open);
            setIsOpen(!!open);
            
            // If openQuickActions flag is set (F3 keybind), open Quick Actions center
            if (openQuickActions) {
              console.log('[EC Admin UI] F3 triggered - Opening Quick Actions center');
              setQuickActionsCenterOpen(true);
            }
          }
          
          // NEW: Handle standalone Quick Actions (F3) - NO BACKGROUND PANEL
          if (type === 'EC_OPEN_QUICK_ACTIONS_ONLY') {
            console.log('[EC Admin UI] F3 pressed - Opening Quick Actions ONLY (no background panel)');
            setIsOpen(false); // Keep main panel closed
            setQuickActionsCenterOpen(true); // Only open Quick Actions
          }
          
          // NEW: Handle CLOSE Quick Actions standalone (ESC pressed in standalone mode)
          if (type === 'EC_CLOSE_QUICK_ACTIONS_STANDALONE') {
            console.log('[EC Admin UI] ESC pressed in standalone mode - Closing Quick Actions');
            setQuickActionsCenterOpen(false);
          }
          
          // Handle EC_OPEN_QUICK_ACTIONS message (for when menu is already open)
          if (type === 'EC_OPEN_QUICK_ACTIONS') {
            console.log('[EC Admin UI] EC_OPEN_QUICK_ACTIONS - Toggling Quick Actions center');
            setQuickActionsCenterOpen(prev => !prev);
          }
          
          // IGNORE legacy 'setVisible' messages to prevent conflicts
          // All open/close operations MUST use EC_SET_VISIBILITY
        }
      } catch (error) {
        console.error('[EC Admin] Message handling error:', error);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [isVPSMode]);

  // ==========================================
  // GLOBAL KEYBOARD SHORTCUTS
  // ==========================================
  // These work on ALL pages, no conflicts
  // F3 = Quick Actions (handled by Lua)
  // Ctrl+K = Command Palette
  // ESC = Close (handled by Lua)
  // ==========================================
  useEffect(() => {
    const handleGlobalKeyDown = (e: KeyboardEvent) => {
      // Only process if admin panel is open
      if (!isOpen && !isVPSMode && !quickActionsCenterOpen) return;

      // Ctrl+K or Cmd+K - Command Palette (global)
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        console.log('[EC Admin] Ctrl+K pressed - Opening Command Palette');
        setCommandPaletteOpen(true);
        return;
      }

      // F3 - Quick Actions (backup handler for browser mode)
      if (e.key === 'F3' && isVPSMode) {
        e.preventDefault();
        console.log('[EC Admin] F3 pressed (Browser Mode) - Toggling Quick Actions');
        setQuickActionsCenterOpen(prev => !prev);
        return;
      }

      // ESC - Close modals first, then close panel (backup for browser mode)
      if (e.key === 'Escape') {
        e.preventDefault();
        if (quickActionsCenterOpen) {
          console.log('[EC Admin] ESC pressed - Closing Quick Actions');
          setQuickActionsCenterOpen(false);
        } else if (commandPaletteOpen) {
          console.log('[EC Admin] ESC pressed - Closing Command Palette');
          setCommandPaletteOpen(false);
        } else if (notificationCenterOpen) {
          console.log('[EC Admin] ESC pressed - Closing Notification Center');
          setNotificationCenterOpen(false);
        } else {
          console.log('[EC Admin] ESC pressed - Closing Admin Panel');
          handleClose();
        }
        return;
      }
    };

    window.addEventListener('keydown', handleGlobalKeyDown);
    return () => window.removeEventListener('keydown', handleGlobalKeyDown);
  }, [isOpen, isVPSMode, quickActionsCenterOpen, commandPaletteOpen, notificationCenterOpen, handleClose]);

  // ==========================================
  // SMART UI TRANSPARENCY
  // ==========================================
  // Track if mouse is hovering over the UI panel
  // When mouse leaves: UI becomes 30% transparent (can see game behind)
  // When mouse returns: UI becomes fully opaque
  // GRACE PERIOD: First 10 seconds after opening, UI stays solid regardless of mouse position
  const [isMouseOverUI, setIsMouseOverUI] = useState(true);
  const [isTransparencyEnabled, setIsTransparencyEnabled] = useState(false);

  // Start 10-second timer when menu opens
  useEffect(() => {
    if (isOpen || isVPSMode) {
      // Menu just opened - disable transparency for 10 seconds
      setIsTransparencyEnabled(false);
      
      const timer = setTimeout(() => {
        setIsTransparencyEnabled(true);
        console.log('[EC Admin] Smart transparency now active - move mouse off UI to see through it');
      }, 10000); // 10 seconds
      
      return () => clearTimeout(timer);
    } else {
      // Menu closed - reset transparency state
      setIsTransparencyEnabled(false);
    }
  }, [isOpen, isVPSMode]);

  // ==========================================
  // STRICT CLOSE RULES
  // ==========================================
  // ESC key handled by Lua ONLY (nui-bridge.lua)
  // X button closes menu (handled by Topbar component)
  // Click outside does NOT close menu
  // 
  // NOTE: We do NOT handle ESC in React to avoid double-handling
  // Lua detects ESC and sends EC_SET_VISIBILITY message
  // ==========================================

  const renderPage = useMemo(() => {
    const defaultUserPermissions = {
      level: 'admin',
      canViewAI: true,
      canManageDetections: true,
      canBanPlayers: true
    };

    try {
      switch (currentPage) {
        case 'dashboard':
          return <Dashboard liveData={liveData} onOpenQuickActionsCenter={() => setQuickActionsCenterOpen(true)} />;
        case 'host-dashboard':
          return <HostDashboard />;
        case 'players':
          return <PlayersPage liveData={liveData} onNavigateToProfile={handleViewPlayerProfile} />;
        case 'player-profile':
          return <PlayerProfilePage playerId={selectedPlayerId} onBack={() => setCurrentPage('players')} />;
        case 'vehicles':
          return <VehiclesPage liveData={liveData} />;
        case 'anticheat':
          return <AnticheatPage liveData={liveData} userPermissions={defaultUserPermissions} />;
        case 'admin-profile':
          return <AdminProfilePage liveData={liveData} onOpenQuickActionsCenter={() => setQuickActionsCenterOpen(true)} />;
        case 'jobs-gangs':
          return <JobsGangsPage liveData={liveData} />;
        case 'inventory':
          return <InventoryPage liveData={liveData} />;
        case 'economy-global-tools':
          return <EconomyGlobalToolsPage liveData={liveData} />;
        case 'settings':
          return <SettingsPage liveData={liveData} />;
        case 'whitelist':
          return <WhitelistPage liveData={liveData} />; // Fixed: use enhanced version with Settings tab
        case 'housing':
          return <HousingPage liveData={liveData} />;
        case 'dev-tools':
          return <DevToolsPage liveData={liveData} />;
        case 'moderation':
          return <ModerationPage liveData={liveData} />;
        case 'system-management':
          return <SystemManagementPage liveData={liveData} />;
        case 'server-monitor':
          return <ServerMonitorPage liveData={liveData} />;
        case 'community':
          return <CommunityPage liveData={liveData} />;
        case 'testing-checklist':
          return <TestingChecklistPage liveData={liveData} />;
        default:
          return (
            <div className="p-8 text-center">
              <p className="text-muted-foreground">Page not found</p>
            </div>
          );
      }
    } catch (error) {
      console.error('[EC Admin] Page rendering error:', error);
      return (
        <div className="p-8 text-center space-y-4">
          <p className="text-destructive">Error loading page: {currentPage}</p>
          <p className="text-sm text-muted-foreground">Please try switching to a different page.</p>
        </div>
      );
    }
  }, [currentPage, handleViewPlayerProfile, selectedPlayerId]);

  return (
    <ErrorBoundary>
      <AppProvider>
        <ToastProvider>
          <ModalProvider>
            <ThemeManager>
              {/* Theme CSS Variables */}
              <style>{`
                /* Light Mode - Default with White/Light Gradient */
                :root {
                  --background: 0 0% 100%;
                  --foreground: 222 47% 11%;
                  --card: 0 0% 98%;
                  --card-foreground: 222 47% 11%;
                  --popover: 0 0% 100%;
                  --popover-foreground: 222 47% 11%;
                  
                  /* Purple hue accent */
                  --primary: 270 80% 60%;
                  --primary-foreground: 0 0% 100%;
                  --secondary: 270 20% 92%;
                  --secondary-foreground: 270 30% 20%;
                  --muted: 270 15% 96%;
                  --muted-foreground: 270 10% 40%;
                  --accent: 270 80% 60%;
                  --accent-foreground: 0 0% 100%;
                  
                  /* Destructive */
                  --destructive: 0 84% 60%;
                  --destructive-foreground: 0 0% 98%;
                  
                  /* Borders and inputs */
                  --border: 270 15% 85%;
                  --input: 270 15% 90%;
                  --ring: 270 80% 60%;
                  --sidebar-border: 270 15% 85%;
                  --sidebar-foreground: 222 47% 11%;
                  --sidebar-accent: 270 15% 95%;
                  
                  /* Radius */
                  --radius: 0.5rem;
                }
                
                /* Dark Mode - DEEP BLACK with Blue/Purple Gradient */
                .dark {
                  --background: 220 40% 3%;
                  --foreground: 0 0% 100%;
                  --card: 220 40% 5%;
                  --card-foreground: 0 0% 100%;
                  --popover: 220 40% 3%;
                  --popover-foreground: 0 0% 100%;
                  
                  /* Purple hue accent */
                  --primary: 270 80% 65%;
                  --primary-foreground: 0 0% 100%;
                  --secondary: 220 40% 8%;
                  --secondary-foreground: 0 0% 100%;
                  --muted: 220 40% 10%;
                  --muted-foreground: 0 0% 90%;
                  --accent: 270 80% 65%;
                  --accent-foreground: 0 0% 100%;
                  
                  /* Destructive */
                  --destructive: 0 84% 60%;
                  --destructive-foreground: 0 0% 98%;
                  
                  /* Borders and inputs */
                  --border: 220 60% 20%;
                  --input: 220 40% 10%;
                  --ring: 270 80% 65%;
                  --sidebar-border: 220 60% 20%;
                  --sidebar-foreground: 0 0% 100%;
                  --sidebar-accent: 220 40% 8%;
                }
                
                /* Remove card backgrounds - use transparent */
                .ec-card-transparent {
                  background: transparent !important;
                  backdrop-filter: blur(8px);
                }
                
                .dark .ec-card-transparent {
                  background: transparent !important;
                  backdrop-filter: blur(8px);
                }
                
                /* Remove gray shimmer effects */
                .dark .bg-background {
                  background-color: transparent !important;
                }
                
                .dark .bg-card {
                  background-color: transparent !important;
                }
                
                .dark .bg-muted {
                  background-color: hsl(220 40% 10%) !important;
                }
                
                /* Ensure white text in dark mode */
                .dark {
                  color: hsl(0 0% 100%);
                }
                
                /* Optimized border colors */
                .dark .border-border {
                  border-color: hsl(220 60% 20%) !important;
                }
                
                /* SUPER VIBRANT BLUES for dark mode - Optimized */
                .dark .text-blue-400 { color: hsl(210 100% 75%) !important; }
                .dark .text-blue-500 { color: hsl(210 100% 70%) !important; }
                .dark .text-blue-600 { color: hsl(210 100% 65%) !important; }
                .dark .text-purple-400 { color: hsl(270 100% 75%) !important; }
                .dark .text-purple-500 { color: hsl(270 100% 70%) !important; }
                .dark .text-purple-600 { color: hsl(270 100% 65%) !important; }
                
                /* Remove background from inputs in dark mode */
                .dark .bg-background\\/50 {
                  background-color: hsl(220 40% 10% / 0.5) !important;
                }
              `}</style>
              
              {/* Main UI */}
              <div 
                className="fixed inset-0 transition-opacity duration-300 ease-in-out ec-outer-wrapper ec-transparent"
                style={{ 
                  opacity: (isOpen || isVPSMode) ? 1 : 0,
                  pointerEvents: (isOpen || isVPSMode) ? 'auto' : 'none',
                  background: 'transparent',
                  backgroundColor: 'transparent'
                }}
              >
                {/* CENTERED PANEL */}
                <div 
                  className="relative pointer-events-auto ec-panel-wrapper"
                  onMouseEnter={() => setIsMouseOverUI(true)}
                  onMouseLeave={() => setIsMouseOverUI(false)}
                  style={{
                    position: 'fixed',
                    top: '50%',
                    left: '50%',
                    transform: 'translate(-50%, -50%)',
                    width: isCompact ? '80vw' : '90vw',
                    maxWidth: isCompact ? '1400px' : '1600px',
                    height: isCompact ? '80vh' : '90vh',
                    maxHeight: isCompact ? '800px' : '900px',
                    background: 'transparent',
                    backgroundColor: 'transparent',
                    // SMART TRANSPARENCY: Fade to 30% when mouse leaves
                    opacity: isMouseOverUI ? 1 : (isTransparencyEnabled ? 0.3 : 1),
                    transition: 'all 0.3s ease-in-out'
                  }}
                >
                  {/* Main Panel Container with Shadow */}
                  <div className="relative w-full h-full border border-border rounded-lg shadow-2xl overflow-hidden flex flex-col ec-main-panel ec-gradient-bg">
                    {/* Topbar */}
                    <div className="flex-none">
                      <Topbar 
                        currentPage={currentPage}
                        onPageChange={handlePageChange}
                        onToggleCompact={() => setIsCompact(!isCompact)}
                        isCompact={isCompact}
                        onOpenCommandPalette={() => setCommandPaletteOpen(true)}
                        onOpenNotifications={() => setNotificationCenterOpen(true)}
                        onOpenQuickActions={() => setQuickActionsCenterOpen(true)}
                        onNavigateToPage={(page: any) => handlePageChange(page as PageType)}
                        liveData={liveData}
                        onClose={handleClose}
                        isVPSMode={isVPSMode}
                      />
                    </div>

                    {/* Main Content Area */}
                    <div className="flex-1 flex overflow-hidden">
                      {/* Sidebar */}
                      <div className="flex-none">
                        <Sidebar 
                          currentPage={currentPage} 
                          onPageChange={handlePageChange}
                          isCompact={isCompact}
                        />
                      </div>

                      {/* Page Content */}
                      <div className="flex-1 overflow-y-auto">
                        <div className={isCompact ? 'p-4' : 'p-6'}>
                          {renderPage}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Command Palette */}
                <div className="fixed inset-0 z-[9999] pointer-events-none">
                  {commandPaletteOpen && (
                    <div className="pointer-events-auto">
                      <CommandPalette
                        currentPage={currentPage}
                        setCurrentPage={handlePageChange}
                        onClose={() => setCommandPaletteOpen(false)}
                      />
                    </div>
                  )}
                </div>

                {/* Notification Center */}
                <div className="fixed inset-0 z-[9997] pointer-events-none">
                  {notificationCenterOpen && (
                    <div className="pointer-events-auto">
                      <NotificationCenter
                        isOpen={notificationCenterOpen}
                        onClose={() => setNotificationCenterOpen(false)}
                      />
                    </div>
                  )}
                </div>
              </div>

              {/* Quick Actions Center - OUTSIDE main wrapper so F3 works standalone */}
              <div className="fixed inset-0 z-[9998] pointer-events-none">
                {quickActionsCenterOpen && (
                  <div className="pointer-events-auto">
                    <QuickActionsCenter
                      isOpen={quickActionsCenterOpen}
                      onClose={handleCloseQuickActions}
                      onCloseAll={handleClose}
                    />
                  </div>
                )}
              </div>
            </ThemeManager>
          </ModalProvider>
        </ToastProvider>
      </AppProvider>
    </ErrorBoundary>
  );
}