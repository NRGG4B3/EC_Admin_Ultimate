// EC Admin Ultimate - Metrics API Routes
// Routes for analytics and metrics

const express = require('express');
const router = express.Router();
const os = require('os');

// Mock database connection
// const db = require('../db');

// ============================================================================
// METRICS
// ============================================================================

// Get current metrics (live system data)
router.get('/', async (req, res) => {
  try {
    // Get system metrics
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMem = totalMem - freeMem;
    const memPercent = (usedMem / totalMem) * 100;
    
    // Get CPU usage (simple calculation)
    const cpus = os.cpus();
    let totalIdle = 0;
    let totalTick = 0;
    
    cpus.forEach(cpu => {
      for (let type in cpu.times) {
        totalTick += cpu.times[type];
      }
      totalIdle += cpu.times.idle;
    });
    
    const idle = totalIdle / cpus.length;
    const total = totalTick / cpus.length;
    const cpuPercent = 100 - ~~(100 * idle / total);
    
    // Get uptime
    const uptime = process.uptime();
    
    // TODO: Get player count from FiveM server
    const players = 0;
    
    // TODO: Get ban/report counts from database
    // const banCount = await db.query('SELECT COUNT(*) as count FROM ec_admin_bans WHERE expires IS NULL OR expires > NOW()');
    // const reportCount = await db.query('SELECT COUNT(*) as count FROM ec_admin_reports');
    
    res.json({
      cpu: cpuPercent,
      ram: memPercent,
      players: players,
      uptime: Math.floor(uptime),
      totalBans: 0, // Will come from database
      totalReports: 0 // Will come from database
    });
  } catch (error) {
    console.error('Error getting metrics:', error);
    res.status(500).json({ error: 'Failed to get metrics' });
  }
});

// Get metrics history
router.get('/history', async (req, res) => {
  try {
    const { period = '24h' } = req.query;
    
    // TODO: Query database for historical metrics
    // const history = await db.query(
    //   'SELECT * FROM ec_host_metrics WHERE recorded_at > DATE_SUB(NOW(), INTERVAL ? HOUR) ORDER BY recorded_at ASC',
    //   [period === '24h' ? 24 : 168]
    // );
    
    res.json({
      history: [] // Will be populated from database
    });
  } catch (error) {
    console.error('Error getting metrics history:', error);
    res.status(500).json({ error: 'Failed to get metrics history' });
  }
});

module.exports = router;
