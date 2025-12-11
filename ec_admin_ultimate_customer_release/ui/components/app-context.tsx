import React, { createContext, useContext, ReactNode } from 'react';

export type PageType = 
  | 'dashboard'
  | 'players' 
  | 'player-profile'
  | 'vehicles'
  | 'monitor'
  | 'ai-analytics'
  | 'ai-detection'
  | 'anticheat'
  | 'admin-abuse'
  | 'admin-profile'
  | 'jobs-gangs'
  | 'inventory'
  | 'global-tools'
  | 'settings'
  | 'economy'
  | 'bans-warnings'
  | 'live-map'
  | 'backups'
  | 'security'
  | 'performance'
  | 'communications'
  | 'events'
  | 'whitelist'
  | 'resources'
  | 'housing'
  | 'dev-tools';

interface AppContextType {
  // Add your global state here
  isLoading: boolean;
  isDarkMode: boolean;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export function AppProvider({ children }: { children: ReactNode }) {
  const value: AppContextType = {
    isLoading: false,
    isDarkMode: true, // Default to dark mode
  };

  return (
    <AppContext.Provider value={value}>
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
}