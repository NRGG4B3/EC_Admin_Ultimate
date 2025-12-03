// EC Admin Ultimate - Theme Manager
// SUPPORTS LIGHT, DARK, AND AUTO MODES WITH TOGGLE
import { useEffect, useState, createContext, useContext } from 'react';

export interface ThemeManagerProps {
  children?: React.ReactNode;
}

export type Theme = 'light' | 'dark' | 'auto';

interface ThemeContextType {
  theme: Theme;
  toggleTheme: () => void;
  setTheme: (theme: Theme) => void;
}

const ThemeContext = createContext<ThemeContextType>({
  theme: 'auto',
  toggleTheme: () => {},
  setTheme: () => {}
});

export const useTheme = () => useContext(ThemeContext);

export function ThemeManager({ children }: ThemeManagerProps = {}) {
  const [theme, setTheme] = useState<Theme>('auto');
  const [resolvedTheme, setResolvedTheme] = useState<'light' | 'dark'>('dark');

  // Load theme from localStorage on mount
  useEffect(() => {
    const savedTheme = localStorage.getItem('ec-admin-theme') as Theme;
    if (savedTheme && ['light', 'dark', 'auto'].includes(savedTheme)) {
      setTheme(savedTheme);
    }
  }, []);

  // Listen for system theme changes when in auto mode
  useEffect(() => {
    if (theme !== 'auto') return;

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    
    const updateSystemTheme = (e: MediaQueryListEvent | MediaQueryList) => {
      setResolvedTheme(e.matches ? 'dark' : 'light');
    };

    // Set initial value
    updateSystemTheme(mediaQuery);

    // Listen for changes
    mediaQuery.addEventListener('change', updateSystemTheme);
    return () => mediaQuery.removeEventListener('change', updateSystemTheme);
  }, [theme]);

  // Apply theme to document
  useEffect(() => {
    const root = window.document.documentElement;
    const actualTheme = theme === 'auto' ? resolvedTheme : theme;
    
    // Remove old theme classes
    root.classList.remove('light', 'dark');
    
    // Add new theme class
    root.classList.add(actualTheme);
    
    // Save to localStorage
    localStorage.setItem('ec-admin-theme', theme);
    
    console.log('[ThemeManager] Theme:', theme, '- Resolved:', actualTheme);
  }, [theme, resolvedTheme]);

  const toggleTheme = () => {
    setTheme(prev => {
      if (prev === 'dark') return 'light';
      if (prev === 'light') return 'auto';
      return 'dark'; // auto -> dark
    });
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}