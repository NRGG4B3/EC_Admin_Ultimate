/**
 * EC Admin Ultimate - Host API Server
 * Main Express server for all customer-facing APIs
 * 
 * This server runs on the NRG Host server and provides APIs for customer servers
 * Customer servers connect via HTTPS to api.ecbetasolutions.com
 */

import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { verifyAPIKey } from './middleware/auth.js';
import { errorHandler } from './middleware/error-handler.js';
import { createLogger } from './utils/logger.js';

// Import API route handlers
import monitoringAPI from './services/monitoring-api.js';
import globalBanAPI from './services/global-ban-api.js';
import aiAnalyticsAPI from './services/ai-analytics-api.js';
import nrgStaffAPI from './services/nrg-staff-api.js';
import remoteAdminProxy from './services/remote-admin-proxy.js';
import selfHealAPI from './services/self-heal-api.js';
import updateCheckerAPI from './services/update-checker-api.js';

const app = express();
const logger = createLogger('server');
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// ============================================================================
// MIDDLEWARE
// ============================================================================

// Security
app.use(helmet({
  contentSecurityPolicy: false, // Allow API responses
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS - Allow customer servers to connect
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key', 'X-Server-ID']
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 1000, // 1000 requests per minute per IP
  message: {
    error: 'Too many requests',
    message: 'Rate limit exceeded. Please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// ============================================================================
// HEALTH CHECK
// ============================================================================

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: Date.now(),
    uptime: process.uptime(),
    version: '1.0.0',
    services: {
      monitoring: 'active',
      globalBan: 'active',
      aiAnalytics: 'active',
      nrgStaff: 'active',
      remoteAdmin: 'active',
      selfHeal: 'active',
      updateChecker: 'active'
    }
  });
});

// ============================================================================
// API ROUTES
// ============================================================================

// Monitoring API
app.use('/api/monitoring', monitoringAPI);

// Global Ban API
app.use('/api/bans', globalBanAPI);

// AI Analytics API
app.use('/api/analytics', aiAnalyticsAPI);

// NRG Staff API
app.use('/api/staff', nrgStaffAPI);

// Remote Admin Proxy API
app.use('/api/admin', remoteAdminProxy);

// Self-Heal API
app.use('/api/self-heal', selfHealAPI);

// Update Checker API
app.use('/api/updates', updateCheckerAPI);

// ============================================================================
// ERROR HANDLING
// ============================================================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
    availableEndpoints: [
      '/health',
      '/api/monitoring',
      '/api/bans',
      '/api/analytics',
      '/api/staff',
      '/api/admin',
      '/api/self-heal',
      '/api/updates'
    ]
  });
});

// Error handler (must be last)
app.use(errorHandler);

// ============================================================================
// SERVER STARTUP
// ============================================================================

app.listen(PORT, HOST, () => {
  logger.info(`Host API Server started`, {
    port: PORT,
    host: HOST,
    environment: process.env.NODE_ENV || 'development'
  });
  
  console.log('');
  console.log('╔═══════════════════════════════════════════════════════════╗');
  console.log('║     EC Admin Ultimate - Host API Server                  ║');
  console.log('╚═══════════════════════════════════════════════════════════╝');
  console.log('');
  console.log(`  Server: http://${HOST}:${PORT}`);
  console.log(`  Health: http://${HOST}:${PORT}/health`);
  console.log('');
  console.log('  Available APIs:');
  console.log('    - Monitoring API: /api/monitoring');
  console.log('    - Global Ban API: /api/bans');
  console.log('    - AI Analytics API: /api/analytics');
  console.log('    - NRG Staff API: /api/staff');
  console.log('    - Remote Admin API: /api/admin');
  console.log('    - Self-Heal API: /api/self-heal');
  console.log('    - Update Checker API: /api/updates');
  console.log('');
  console.log('  Customer servers connect via: https://api.ecbetasolutions.com');
  console.log('');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully...');
  process.exit(0);
});

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception', { error: error.message, stack: error.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled rejection', { reason, promise });
  process.exit(1);
});
