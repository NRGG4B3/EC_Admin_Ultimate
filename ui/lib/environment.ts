/**
 * EC Admin Ultimate - Environment Manager
 * Handles mode detection and environment configuration
 * SIMPLIFIED: No setup/install - direct mode management
 */

export type EnvironmentMode = 'DEV' | 'HOST' | 'CUSTOMER';

/**
 * Environment Manager
 * Manages application mode (DEV, HOST, CUSTOMER)
 */
export class Environment {
  private static mode: EnvironmentMode | null = null;

  /**
   * Check if running in Figma preview mode
   */
  static isFigmaPreview(): boolean {
    if (typeof window === 'undefined') return false;
    const url = window.location.href;
    return url.includes('localhost') || url.includes('figma') || url.includes('127.0.0.1');
  }

  /**
   * Check if running in FiveM NUI
   */
  static isFiveM(): boolean {
    if (typeof window === 'undefined') return false;
    return !!(window as any).invokeNative || (window as any).__NUI_MODE__ === true;
  }

  /**
   * Check if running in browser (not FiveM)
   */
  static isBrowser(): boolean {
    return !this.isFiveM();
  }

  /**
   * Validate mode string
   */
  private static isValidMode(mode: string): mode is EnvironmentMode {
    return ['DEV', 'HOST', 'CUSTOMER'].includes(mode);
  }

  /**
   * Get current environment mode
   */
  static getMode(): EnvironmentMode {
    if (this.mode) {
      return this.mode;
    }

    // Check localStorage
    try {
      const storedMode = localStorage.getItem('ec_mode');
      if (storedMode && this.isValidMode(storedMode)) {
        this.mode = storedMode as EnvironmentMode;
        console.log('[Environment] Mode from localStorage:', this.mode);
        return this.mode;
      }
    } catch (e) {
      console.warn('[Environment] Failed to read localStorage:', e);
    }

    // Auto-detect based on environment
    if (this.isFigmaPreview()) {
      this.mode = 'DEV';
      console.log('[Environment] Mode auto-detected as DEV (Figma/localhost)');
      return this.mode;
    }

    // Default to CUSTOMER
    this.mode = 'CUSTOMER';
    console.log('[Environment] Mode defaulted to CUSTOMER');
    return this.mode;
  }

  /**
   * Set environment mode
   */
  static setMode(mode: EnvironmentMode): void {
    try {
      localStorage.setItem('ec_mode', mode);
      this.mode = mode;
      console.log('[Environment] Mode set to:', mode);
    } catch (e) {
      console.error('[Environment] Failed to set mode:', e);
    }
  }

  /**
   * Check if in DEV mode
   */
  static isDev(): boolean {
    return this.getMode() === 'DEV';
  }

  /**
   * Check if in HOST mode
   */
  static isHost(): boolean {
    return this.getMode() === 'HOST';
  }

  /**
   * Check if in CUSTOMER mode
   */
  static isCustomer(): boolean {
    return this.getMode() === 'CUSTOMER';
  }

  /**
   * Get mode display name
   */
  static getModeName(): string {
    const mode = this.getMode();
    switch (mode) {
      case 'DEV':
        return 'Development';
      case 'HOST':
        return 'NRG Host';
      case 'CUSTOMER':
        return 'Customer';
      default:
        return 'Unknown';
    }
  }

  /**
   * Get mode color for UI badges
   */
  static getModeColor(): string {
    const mode = this.getMode();
    switch (mode) {
      case 'DEV':
        return 'bg-purple-500/20 text-purple-400 border-purple-500/30';
      case 'HOST':
        return 'bg-orange-500/20 text-orange-400 border-orange-500/30';
      case 'CUSTOMER':
        return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
      default:
        return 'bg-gray-500/20 text-gray-400 border-gray-500/30';
    }
  }

  /**
   * Reset environment
   */
  static reset(): void {
    try {
      localStorage.removeItem('ec_mode');
      this.mode = null;
      console.log('[Environment] Environment reset');
    } catch (e) {
      console.error('[Environment] Failed to reset environment:', e);
    }
  }

  /**
   * Get debug info
   */
  static getDebugInfo(): object {
    return {
      mode: this.getMode(),
      isFigma: this.isFigmaPreview(),
      isFiveM: this.isFiveM(),
      isBrowser: this.isBrowser(),
      location: typeof window !== 'undefined' ? window.location.href : 'N/A'
    };
  }
}

// Export convenience functions
export const getMode = () => Environment.getMode();
export const setMode = (mode: EnvironmentMode) => Environment.setMode(mode);
export const isDev = () => Environment.isDev();
export const isHost = () => Environment.isHost();
export const isCustomer = () => Environment.isCustomer();

// Initialize on load
if (typeof window !== 'undefined') {
  // Log environment info on load (DEV only)
  if (Environment.isDev()) {
    console.log('[Environment] Debug Info:', Environment.getDebugInfo());
  }
  
  // Expose mode switching functions globally
  (window as any).setECAdminMode = (mode: 'DEV' | 'HOST' | 'CUSTOMER') => {
    Environment.setMode(mode);
    console.log(`✅ EC Admin mode set to ${mode}. Reloading...`);
    window.location.reload();
  };
  
  (window as any).getECAdminMode = () => {
    const mode = Environment.getMode();
    console.log(`Current mode: ${mode}`);
    return mode;
  };
  
  console.log('💡 Mode commands: setECAdminMode("HOST") | setECAdminMode("CUSTOMER") | getECAdminMode()');
}
