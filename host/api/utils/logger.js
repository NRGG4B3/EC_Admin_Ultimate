/**
 * Centralized logging utility using Winston
 */

import winston from 'winston';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const LOG_FILE = process.env.LOG_FILE || path.join(__dirname, '../../logs/api.log');
const LOG_TO_CONSOLE = process.env.LOG_TO_CONSOLE !== 'false';

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.printf(({ timestamp, level, message, service, ...meta }) => {
    let log = `${timestamp} [${service || 'API'}] ${level.toUpperCase()}: ${message}`;
    if (Object.keys(meta).length > 0) {
      log += ` ${JSON.stringify(meta)}`;
    }
    return log;
  })
);

// Create transports
const transports = [];

if (LOG_TO_CONSOLE) {
  transports.push(
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        logFormat
      ),
    })
  );
}

// File transport (with rotation)
transports.push(
  new winston.transports.File({
    filename: LOG_FILE,
    maxsize: parseInt(process.env.LOG_MAX_SIZE) || 10485760, // 10MB
    maxFiles: parseInt(process.env.LOG_MAX_FILES) || 7,
    format: logFormat,
  })
);

// Create logger factory
export function createLogger(serviceName) {
  return winston.createLogger({
    level: LOG_LEVEL,
    defaultMeta: { service: serviceName },
    transports,
  });
}

export default createLogger('default');
