// EC Admin Ultimate - Host Node.js Server
// Main entry point for all 20 API services

// Graceful dependency loading
function requireSafe(moduleName) {
  try {
    return require(moduleName);
  } catch (err) {
    console.error(`❌ Failed to load module: ${moduleName}`);
    console.error(`   Install it with: npm install ${moduleName}`);
    process.exit(1);
  }
}

const express = requireSafe('express');
const cors = requireSafe('cors');
const helmet = requireSafe('helmet');
const morgan = requireSafe('morgan');
const { createServer } = require('http');
const fs = require('fs');
const path = require('path');

// Auto-configure host environment if .env doesn't exist
const { autoConfigureHost } = require('./auto-configure');
if (!fs.existsSync(path.join(__dirname, '.env'))) {
  console.log('🔧 First-time setup detected, running auto-configuration...');
  autoConfigureHost();
  console.log('');
}

require('dotenv').config();

const app = express();
const server = createServer(app);

// Middleware
app.use(helmet());

// SECURITY: Remove CORS - this server is localhost-only, accessed via FiveM proxy
// No direct browser access, so no CORS needed
// app.use(cors({ ... }));

app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Host secret middleware - protects all /api/host/* routes
const requireHostSecret = (req, res, next) => {
  const secret = req.get('X-Host-Secret');
  const expectedSecret = process.env.HOST_SECRET;
  
  if (!expectedSecret) {
    console.error('SECURITY WARNING: HOST_SECRET not set in environment!');
    return res.status(500).json({ error: 'Server configuration error' });
  }
  
  if (!secret || secret !== expectedSecret) {
    console.warn('Unauthorized host access attempt from:', req.ip);
    return res.status(401).json({ error: 'Unauthorized - Invalid host secret' });
  }
  
  next();
};

// Import routes
const setupRoutes = require('./routes/setup');
const hostRoutes = require('./routes/host');
const playersRoutes = require('./routes/players');
const bansRoutes = require('./routes/bans');
const metricsRoutes = require('./routes/metrics');

// Mount routes
app.use('/api/setup', setupRoutes);
app.use('/api/host', requireHostSecret, hostRoutes); // ← Protected with secret
app.use('/api/players', playersRoutes);
app.use('/api/bans', bansRoutes);
app.use('/api/metrics', metricsRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start server
const PORT = process.env.PORT || 3000;
const BIND = process.env.BIND || '127.0.0.1'; // SECURITY: localhost only

server.listen(PORT, BIND, () => {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║   EC Admin Ultimate - Host API Server (PRIVATE)       ║');
  console.log('╠════════════════════════════════════════════════════════╣');
  console.log(`║   Bind: ${BIND.padEnd(47)}║`);
  console.log(`║   Port: ${PORT.toString().padEnd(46)}║`);
  console.log(`║   Environment: ${(process.env.NODE_ENV || 'development').padEnd(39)}║`);
  console.log('║   Status: RUNNING ✅                                   ║');
  console.log('║   Access: LOCALHOST ONLY (via FiveM proxy)            ║');
  console.log('╠════════════════════════════════════════════════════════╣');
  console.log('║   Routes:                                              ║');
  console.log('║   - /api/setup           (Setup Wizard)                  ║');
  console.log('║   - /api/host            (API Management)                ║');
  console.log('║   - /api/players         (Player Data)                   ║');
  console.log('║   - /api/bans            (Ban Management)                ║');
  console.log('║   - /api/metrics         (Analytics)                     ║');
  console.log('║   - /health            (Health Check)                  ║');
  console.log('╚════════════════════════════════════════════════════════╝');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

module.exports = app;