// EC Admin Ultimate - Multi-Port API Server
// Each API runs on its own dedicated port

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');

// Load AI Detection Engine
const { setupAIDetectionAPI } = require('./ai-detection-engine');

// Load environment
require('dotenv').config({ path: path.join(__dirname, '.env') });

// Load ports configuration
const portsConfig = require('./ports-config.json');

const hostSecret = process.env.HOST_SECRET || '';
const HOST = process.env.HOST || '127.0.0.1';

console.log('');
console.log('╔═══════════════════════════════════════════════════════════════╗');
console.log('║   NRG API SUITE - Multi-Port Architecture                     ║');
console.log('╠═══════════════════════════════════════════════════════════════╣');
console.log(`║   Domain: ${portsConfig.domain.padEnd(50)} ║`);
console.log(`║   IP: ${portsConfig.server_ip.padEnd(54)} ║`);
console.log(`║   Host Secret: ${hostSecret ? '✅ Configured' : '⚠️  Not Set'}                                   ║`);
console.log('╚═══════════════════════════════════════════════════════════════╝');
console.log('');

// Middleware to check host secret
const requireHostSecret = (req, res, next) => {
  const providedSecret = req.get('X-Host-Secret') || req.get('x-host-secret');
  
  if (!hostSecret) {
    console.error('⚠️  HOST_SECRET not configured in .env');
    return res.status(500).json({ error: 'Server configuration error' });
  }
  
  if (!providedSecret) {
    return res.status(401).json({ error: 'Missing host secret' });
  }
  
  if (providedSecret !== hostSecret) {
    return res.status(401).json({ error: 'Invalid host secret' });
  }
  
  next();
};

// Create servers for each API
const servers = [];

portsConfig.apis.forEach((api, index) => {
  const app = express();
  
  // Middleware
  app.use(cors({ origin: '*' }));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  
  // Logging middleware - ALWAYS log requests to stdout for monitoring
  app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${api.name} (Port ${api.port}): ${req.method} ${req.path}`);
    next();
  });
  
  // Optional detailed logging
  if (process.env.DEBUG === 'true') {
    app.use(morgan('combined'));
  }
  
  // Health endpoint (no auth)
  app.get('/health', (req, res) => {
    res.json({
      status: 'ok',
      api: api.name,
      port: api.port,
      endpoint: api.endpoint,
      version: '3.5.0',
      timestamp: new Date().toISOString()
    });
  });
  
  // Root endpoint for this API
  app.get('/', (req, res) => {
    res.json({
      api: api.name,
      port: api.port,
      endpoint: api.endpoint,
      description: api.description,
      version: '3.5.0',
      auth_required: api.auth_required
    });
  });
  
  // API-specific endpoints based on port
  switch(api.port) {
    case 3000: // Main Gateway
      app.get('/api/status', (req, res) => {
        res.json({
          status: 'online',
          version: '3.5.0',
          total_apis: portsConfig.apis.length,
          domain: portsConfig.domain
        });
      });
      break;
      
    case 3001: // Global Ban System
      app.get('/api/global-bans/list', api.auth_required ? requireHostSecret : (req, res, next) => next(), (req, res) => {
        res.json({ success: true, bans: [], total: 0 });
      });
      app.post('/api/global-bans/add', api.auth_required ? requireHostSecret : (req, res, next) => next(), (req, res) => {
        res.json({ success: true, message: 'Ban added' });
      });
      app.get('/api/global-bans/check/:identifier', (req, res) => {
        res.json({ success: true, banned: false });
      });
      // Registration endpoint (no auth required for initial registration)
      app.post('/api/global-bans/register', (req, res) => {
        const { serverName, serverEndpoint } = req.body;
        // Generate API key for this server
        const apiKey = 'gbk_' + Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
        const serverId = 'srv_' + Date.now();
        
        console.log(`[Global Ban API] Server registered: ${serverName}`);
        
        res.json({
          success: true,
          apiKey: apiKey,
          serverId: serverId,
          message: 'Server registered successfully',
          registeredAt: new Date().toISOString()
        });
      });
      break;
      
    case 3002: // AI Detection
      setupAIDetectionAPI(app, requireHostSecret);
      break;
      
    case 3003: // Player Analytics
      app.get('/api/analytics/summary', requireHostSecret, (req, res) => {
        res.json({ success: true, total_players: 0, active_today: 0 });
      });
      app.get('/api/analytics/trends', requireHostSecret, (req, res) => {
        res.json({ success: true, trends: [] });
      });
      break;
      
    case 3004: // Server Metrics
      app.get('/api/metrics/overview', requireHostSecret, (req, res) => {
        res.json({ success: true, cpu: 0, memory: 0, uptime: process.uptime() });
      });
      app.get('/api/metrics/live', requireHostSecret, (req, res) => {
        res.json({ success: true, metrics: {} });
      });
      break;
      
    case 3005: // Report System
      app.get('/api/reports/list', requireHostSecret, (req, res) => {
        res.json({ success: true, reports: [], total: 0 });
      });
      app.post('/api/reports/create', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Report created' });
      });
      break;
      
    case 3006: // Anticheat Sync
      app.get('/api/anticheat/rules', requireHostSecret, (req, res) => {
        res.json({ success: true, rules: [] });
      });
      app.get('/api/anticheat/detections', requireHostSecret, (req, res) => {
        res.json({ success: true, detections: [] });
      });
      break;
      
    case 3007: // Backup Storage
      app.get('/api/backups/list', requireHostSecret, (req, res) => {
        res.json({ success: true, backups: [] });
      });
      app.post('/api/backups/create', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Backup created' });
      });
      break;
      
    case 3008: // Screenshot Storage
      app.get('/api/screenshots/list', requireHostSecret, (req, res) => {
        res.json({ success: true, screenshots: [] });
      });
      app.post('/api/screenshots/upload', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Screenshot uploaded' });
      });
      break;
      
    case 3009: // Webhook Relay
      app.post('/api/webhooks/send', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Webhook sent' });
      });
      app.get('/api/webhooks/status', requireHostSecret, (req, res) => {
        res.json({ success: true, status: 'operational' });
      });
      break;
      
    case 3010: // Global Chat Hub
      app.get('/api/chat/messages', requireHostSecret, (req, res) => {
        res.json({ success: true, messages: [] });
      });
      app.post('/api/chat/send', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Message sent' });
      });
      break;
      
    case 3011: // Player Tracking
      app.get('/api/players/search', requireHostSecret, (req, res) => {
        res.json({ success: true, players: [] });
      });
      app.get('/api/players/:identifier', requireHostSecret, (req, res) => {
        res.json({ success: true, player: {} });
      });
      break;
      
    case 3012: // Server Registry
      app.get('/api/servers/list', requireHostSecret, (req, res) => {
        res.json({ success: true, servers: [], total: 0 });
      });
      app.post('/api/servers/register', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Server registered' });
      });
      break;
      
    case 3013: // License Validation
      app.post('/api/license/validate', (req, res) => {
        res.json({ success: true, valid: true, expires: null });
      });
      app.get('/api/license/info/:key', (req, res) => {
        res.json({ success: true, info: {} });
      });
      break;
      
    case 3014: // Update Checker
      app.get('/api/updates/check', (req, res) => {
        res.json({ success: true, update_available: false, latest: '3.5.0' });
      });
      app.get('/api/updates/changelog', (req, res) => {
        res.json({ success: true, changelog: [] });
      });
      break;
      
    case 3015: // Audit Logging
      app.get('/api/audit/logs', requireHostSecret, (req, res) => {
        res.json({ success: true, logs: [] });
      });
      app.post('/api/audit/log', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Log recorded' });
      });
      break;
      
    case 3016: // Performance Monitor
      app.get('/api/performance/stats', requireHostSecret, (req, res) => {
        res.json({ success: true, stats: {} });
      });
      app.get('/api/performance/history', requireHostSecret, (req, res) => {
        res.json({ success: true, history: [] });
      });
      break;
      
    case 3017: // Resource Hub
      app.get('/api/resources/list', requireHostSecret, (req, res) => {
        res.json({ success: true, resources: [] });
      });
      app.get('/api/resources/download/:id', requireHostSecret, (req, res) => {
        res.json({ success: true, url: '' });
      });
      break;
      
    case 3018: // Emergency Control
      app.post('/api/emergency/shutdown', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Emergency shutdown initiated' });
      });
      app.post('/api/emergency/restart', requireHostSecret, (req, res) => {
        res.json({ success: true, message: 'Emergency restart initiated' });
      });
      break;
      
    case 3019: // Host Dashboard
      // Serve static UI files for host dashboard
      const uiPath = path.join(__dirname, '..', '..', 'ui', 'dist');
      
      // Check if UI build exists
      if (fs.existsSync(uiPath)) {
        console.log(`   📁 Serving UI from: ${uiPath}`);
        app.use(express.static(uiPath));
        
        // SPA fallback - serve index.html for all non-API routes
        app.get('*', (req, res, next) => {
          // Skip API routes
          if (req.path.startsWith('/api/')) {
            return next();
          }
          res.sendFile(path.join(uiPath, 'index.html'));
        });
      } else {
        console.warn(`   ⚠️  UI build not found at: ${uiPath}`);
        console.warn(`   Run: cd ui && npm run build`);
      }
      
      // API endpoints
      app.get('/api/host/dashboard', requireHostSecret, (req, res) => {
        res.json({
          success: true,
          data: {
            totalServers: 0,
            activeServers: 0,
            totalPlayers: 0,
            totalBans: 0
          }
        });
      });
      app.get('/api/host/status', requireHostSecret, (req, res) => {
        res.json({ success: true, status: 'operational' });
      });
      
      // Host mode detection endpoint (no auth required)
      app.get('/api/host/detect', (req, res) => {
        res.json({ 
          isHost: true, 
          mode: 'host',
          version: '3.5.0',
          domain: portsConfig.domain
        });
      });
      break;
  }
  
  // 404 handler
  app.use((req, res) => {
    res.status(404).json({
      error: 'Not Found',
      api: api.name,
      path: req.path
    });
  });
  
  // Error handler
  app.use((err, req, res, next) => {
    console.error(`❌ [${api.name}:${api.port}] Error:`, err.message);
    res.status(err.status || 500).json({
      error: err.message || 'Internal Server Error'
    });
  });
  
  // Start server
  const server = app.listen(api.port, HOST, () => {
    const authIcon = api.auth_required ? '🔒' : '🌐';
    console.log(`${authIcon} [${api.id}/${portsConfig.apis.length}] ${api.name.padEnd(25)} → ${portsConfig.domain}:${api.port}`);
  });
  
  servers.push({ api, server });
});

// Summary
console.log('');
console.log('╔═══════════════════════════════════════════════════════════════╗');
console.log('║   ✅ ALL 20 APIS STARTED SUCCESSFULLY                         ║');
console.log('╠═══════════════════════════════════════════════════════════════╣');
console.log(`║   Total APIs: ${portsConfig.apis.length}                                               ║`);
console.log(`║   Port Range: 3000-3019                                       ║`);
console.log(`║   Bind Address: ${HOST.padEnd(46)} ║`);
console.log('║                                                               ║');
console.log('║   🔒 = Requires X-Host-Secret header                          ║');
console.log('║   🌐 = Public access (no auth)                                ║');
console.log('╚═══════════════════════════════════════════════════════════════╝');
console.log('');
console.log('✅ Ready to accept connections from FiveM!');
console.log('');

// Heartbeat logger - shows server is alive every 30 seconds
setInterval(() => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ♥️  HEARTBEAT - All ${portsConfig.apis.length} APIs running`);
}, 30000);

// Graceful shutdown
const shutdown = () => {
  console.log('\n⚠️  Shutting down all API servers gracefully...');
  servers.forEach(({ api, server }) => {
    console.log(`   Stopping ${api.name}...`);
    server.close();
  });
  console.log('✅ All servers stopped');
  process.exit(0);
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);