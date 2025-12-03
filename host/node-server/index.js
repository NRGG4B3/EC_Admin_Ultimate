// EC Admin Ultimate - Simple Working API Server
// Windows-compatible, works with your current setup

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');

// Load environment
require('dotenv').config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '127.0.0.1';

// Middleware
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS for FiveM
app.use(cors({ origin: '*' }));

// Load host secret
const hostSecret = process.env.HOST_SECRET || '';

console.log('');
console.log('╔════════════════════════════════════════════════════════╗');
console.log('║   EC Admin Ultimate - Host API Server                 ║');
console.log('╠════════════════════════════════════════════════════════╣');
console.log(`║   Bind: ${HOST.padEnd(46)} ║`);
console.log(`║   Port: ${PORT.toString().padEnd(46)} ║`);
console.log(`║   Secret: ${hostSecret ? '✅ Configured' : '⚠️  Not Set'}                             ║`);
console.log('╚════════════════════════════════════════════════════════╝');
console.log('');

// ===========================================================================
// HEALTH ENDPOINTS (NO AUTH REQUIRED)
// ===========================================================================

// Main health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '3.5.0',
    domain: process.env.DOMAIN || 'api.ecbetasolutions.com'
  });
});

// API health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '3.5.0',
    apis: 20,
    domain: process.env.DOMAIN || 'api.ecbetasolutions.com'
  });
});

// API status endpoint
app.get('/api/status', (req, res) => {
  res.json({
    status: 'online',
    version: '3.5.0',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    apis: {
      global_bans: true,
      ai_detection: true,
      analytics: true,
      reports: true,
      anticheat: true,
      // ... rest of APIs
    }
  });
});

// ===========================================================================
// HOST API ENDPOINTS (REQUIRE SECRET HEADER)
// ===========================================================================

// Middleware to check host secret
const requireHostSecret = (req, res, next) => {
  const providedSecret = req.get('X-Host-Secret') || req.get('x-host-secret');
  
  if (!hostSecret) {
    console.error('⚠️  HOST_SECRET not configured in .env');
    return res.status(500).json({ error: 'Server configuration error' });
  }
  
  if (!providedSecret) {
    console.warn('❌ Missing X-Host-Secret header from:', req.ip);
    return res.status(401).json({ error: 'Missing host secret' });
  }
  
  if (providedSecret !== hostSecret) {
    console.warn('❌ Invalid X-Host-Secret from:', req.ip);
    return res.status(401).json({ error: 'Invalid host secret' });
  }
  
  next();
};

// Host dashboard data
app.get('/api/host/dashboard', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    data: {
      totalServers: 0,
      activeServers: 0,
      totalPlayers: 0,
      activePlayers: 0,
      totalBans: 0,
      todayBans: 0,
      apis: {
        total: 20,
        online: 20,
        offline: 0
      }
    }
  });
});

// Host status
app.get('/api/host/status', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    status: 'operational',
    uptime: process.uptime(),
    version: '3.5.0',
    domain: process.env.DOMAIN || 'api.ecbetasolutions.com',
    ip: process.env.SERVER_IP || '45.144.225.227'
  });
});

// ===========================================================================
// GLOBAL BANS API
// ===========================================================================

app.get('/api/host/global-bans/list', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    bans: [],
    total: 0
  });
});

app.post('/api/host/global-bans/add', requireHostSecret, (req, res) => {
  const { identifier, reason, expires_at } = req.body;
  
  if (!identifier || !reason) {
    return res.status(400).json({
      success: false,
      error: 'Missing required fields: identifier, reason'
    });
  }
  
  res.json({
    success: true,
    message: 'Ban added successfully',
    ban: {
      id: Date.now(),
      identifier,
      reason,
      expires_at: expires_at || null,
      created_at: new Date().toISOString()
    }
  });
});

app.delete('/api/host/global-bans/:id', requireHostSecret, (req, res) => {
  const { id } = req.params;
  
  res.json({
    success: true,
    message: `Ban ${id} removed successfully`
  });
});

// ===========================================================================
// AI DETECTION API
// ===========================================================================

app.get('/api/host/ai-detection/status', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    status: 'operational',
    detections_today: 0,
    detections_total: 0
  });
});

app.get('/api/host/ai-detection/rules', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    rules: []
  });
});

// ===========================================================================
// ANALYTICS API
// ===========================================================================

app.get('/api/host/player-analytics/summary', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    data: {
      total_players: 0,
      active_today: 0,
      active_this_week: 0,
      active_this_month: 0,
      new_players_today: 0
    }
  });
});

// ===========================================================================
// METRICS API
// ===========================================================================

app.get('/api/host/metrics/overview', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    metrics: {
      cpu_usage: 0,
      memory_usage: 0,
      disk_usage: 0,
      network_in: 0,
      network_out: 0,
      uptime: process.uptime()
    }
  });
});

// ===========================================================================
// REPORTS API
// ===========================================================================

app.get('/api/host/reports/list', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    reports: [],
    total: 0
  });
});

// ===========================================================================
// LIVE STATUS API
// ===========================================================================

app.get('/api/host/status/servers', requireHostSecret, (req, res) => {
  res.json({
    success: true,
    servers: [],
    total: 0,
    online: 0,
    offline: 0
  });
});

// ===========================================================================
// PLACEHOLDER ENDPOINTS FOR OTHER 15 APIs
// ===========================================================================

const placeholderAPIs = [
  'ai-analytics',
  'anticheat',
  'community',
  'market',
  'backup',
  'performance',
  'audit',
  'whitelist',
  'economy',
  'vehicles',
  'housing',
  'jobs-gangs',
  'discord',
  'webhooks',
  'communications'
];

placeholderAPIs.forEach(apiName => {
  // GET endpoint
  app.get(`/api/host/${apiName}/*`, requireHostSecret, (req, res) => {
    res.json({
      success: true,
      api: apiName,
      path: req.path,
      message: `${apiName} API endpoint`,
      data: {}
    });
  });
  
  // POST endpoint
  app.post(`/api/host/${apiName}/*`, requireHostSecret, (req, res) => {
    res.json({
      success: true,
      api: apiName,
      path: req.path,
      message: `${apiName} API endpoint`,
      data: req.body
    });
  });
});

// ===========================================================================
// ERROR HANDLERS
// ===========================================================================

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'NRG API Gateway',
    version: '3.5.0',
    status: 'operational',
    domain: process.env.DOMAIN || 'api.ecbetasolutions.com',
    apis: 20
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path,
    message: 'This endpoint does not exist'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('❌ Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error'
  });
});

// ===========================================================================
// START SERVER
// ===========================================================================

app.listen(PORT, HOST, () => {
  console.log('');
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║   ✅ API SERVER RUNNING                                ║');
  console.log('╠════════════════════════════════════════════════════════╣');
  console.log(`║   Local:  http://${HOST}:${PORT}                    ║`);
  console.log(`║   Domain: https://${(process.env.DOMAIN || 'api.ecbetasolutions.com').padEnd(33)} ║`);
  console.log('║                                                        ║');
  console.log('║   📊 Endpoints:                                        ║');
  console.log('║   - GET  /health                                       ║');
  console.log('║   - GET  /api/health                                   ║');
  console.log('║   - GET  /api/status                                   ║');
  console.log('║   - GET  /api/host/dashboard  (requires secret)        ║');
  console.log('║   - GET  /api/host/status     (requires secret)        ║');
  console.log('║   - GET  /api/host/*/...      (all 20 APIs)            ║');
  console.log('║                                                        ║');
  console.log('║   🔒 Security:                                         ║');
  console.log(`║   - Host Secret: ${hostSecret ? '✅ Configured' : '⚠️  Not Set'}                      ║`);
  console.log('║   - CORS: Enabled for FiveM                            ║');
  console.log('║   - Rate Limiting: TODO                                ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('✅ Ready to accept connections from FiveM!');
  console.log('');
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n⚠️  Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n⚠️  Shutting down gracefully...');
  process.exit(0);
});
