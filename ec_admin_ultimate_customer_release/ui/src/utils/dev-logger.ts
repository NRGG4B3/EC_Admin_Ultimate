/**
 * Development Logger Utility
 * Wraps console.log statements to only show in development mode
 * Production builds will have these removed/minified
 */

const isDevelopment = import.meta.env?.DEV ?? false;

/**
 * Development-only logger
 * Only logs in development mode, silent in production
 */
export const devLog = {
  log: (...args: any[]) => {
    if (isDevelopment) {
      console.log(...args);
    }
  },
  
  error: (...args: any[]) => {
    if (isDevelopment) {
      console.error(...args);
    }
  },
  
  warn: (...args: any[]) => {
    if (isDevelopment) {
      console.warn(...args);
    }
  },
  
  info: (...args: any[]) => {
    if (isDevelopment) {
      console.info(...args);
    }
  },
  
  debug: (...args: any[]) => {
    if (isDevelopment) {
      console.debug(...args);
    }
  }
};

/**
 * Always-on logger (for critical errors that should always show)
 * Use sparingly - only for critical errors that need to be visible in production
 */
export const criticalLog = {
  error: (...args: any[]) => {
    console.error('[CRITICAL]', ...args);
  },
  
  warn: (...args: any[]) => {
    console.warn('[CRITICAL]', ...args);
  }
};

