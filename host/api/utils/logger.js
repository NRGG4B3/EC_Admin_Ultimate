/**
 * Centralized logging utility
 * Simple console logger (can be upgraded to Winston later)
 */

const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const LOG_TO_CONSOLE = process.env.LOG_TO_CONSOLE !== 'false';

const levels = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3
};

const levelColors = {
  error: '\x1b[31m', // Red
  warn: '\x1b[33m',  // Yellow
  info: '\x1b[36m',  // Cyan
  debug: '\x1b[90m'  // Gray
};

const resetColor = '\x1b[0m';

function formatTimestamp() {
  const now = new Date();
  return now.toISOString().replace('T', ' ').substring(0, 19);
}

function shouldLog(level) {
  const currentLevel = levels[LOG_LEVEL] || levels.info;
  return levels[level] <= currentLevel;
}

// Create logger factory
export function createLogger(serviceName) {
  return {
    error(message, meta = {}) {
      if (!shouldLog('error')) return;
      const color = levelColors.error;
      const timestamp = formatTimestamp();
      const metaStr = Object.keys(meta).length > 0 ? ` ${JSON.stringify(meta)}` : '';
      console.error(`${color}[${timestamp}] [${serviceName}] ERROR: ${message}${metaStr}${resetColor}`);
    },
    
    warn(message, meta = {}) {
      if (!shouldLog('warn')) return;
      const color = levelColors.warn;
      const timestamp = formatTimestamp();
      const metaStr = Object.keys(meta).length > 0 ? ` ${JSON.stringify(meta)}` : '';
      console.warn(`${color}[${timestamp}] [${serviceName}] WARN: ${message}${metaStr}${resetColor}`);
    },
    
    info(message, meta = {}) {
      if (!shouldLog('info')) return;
      const color = levelColors.info;
      const timestamp = formatTimestamp();
      const metaStr = Object.keys(meta).length > 0 ? ` ${JSON.stringify(meta)}` : '';
      console.log(`${color}[${timestamp}] [${serviceName}] INFO: ${message}${metaStr}${resetColor}`);
    },
    
    debug(message, meta = {}) {
      if (!shouldLog('debug')) return;
      const color = levelColors.debug;
      const timestamp = formatTimestamp();
      const metaStr = Object.keys(meta).length > 0 ? ` ${JSON.stringify(meta)}` : '';
      console.log(`${color}[${timestamp}] [${serviceName}] DEBUG: ${message}${metaStr}${resetColor}`);
    }
  };
}

export default createLogger('default');
