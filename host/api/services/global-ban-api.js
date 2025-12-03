/**
 * Global Ban API Service
 * Shared ban database across multiple servers
 */

import express from 'express';
import { verifyAPIKey } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('global-ban');

// In-memory cache (in production, this would use Redis or database)
const banCache = new Map();

/**
 * GET /api/global-ban/check/:identifier
 * Check if a player is globally banned
 */
router.get('/check/:identifier', verifyAPIKey, async (req, res) => {
  const { identifier } = req.params;

  try {
    // Check cache first
    if (banCache.has(identifier)) {
      const ban = banCache.get(identifier);
      return res.json({
        banned: true,
        ban: {
          identifier: ban.identifier,
          reason: ban.reason,
          bannedBy: ban.bannedBy,
          bannedAt: ban.bannedAt,
          expiresAt: ban.expiresAt,
          serverOrigin: ban.serverOrigin,
          severity: ban.severity,
        },
      });
    }

    // Check database (simulated)
    // In production: const ban = await db.query('SELECT * FROM global_bans WHERE identifier = ?', [identifier]);

    res.json({
      banned: false,
      message: 'Player is not globally banned',
    });
  } catch (error) {
    logger.error('Failed to check ban status', { identifier, error: error.message });
    res.status(500).json({
      error: 'Failed to check ban status',
      message: error.message,
    });
  }
});

/**
 * POST /api/global-ban/add
 * Add a player to the global ban list
 */
router.post('/add', verifyAPIKey, async (req, res) => {
  const {
    identifier,
    reason,
    bannedBy,
    duration, // in seconds, 0 = permanent
    severity = 'high',
    evidence = [],
    serverOrigin,
  } = req.body;

  try {
    const ban = {
      id: Date.now().toString(),
      identifier,
      reason,
      bannedBy,
      bannedAt: Date.now(),
      expiresAt: duration > 0 ? Date.now() + (duration * 1000) : null,
      severity,
      evidence,
      serverOrigin,
      active: true,
    };

    // Add to cache
    banCache.set(identifier, ban);

    // In production: await db.query('INSERT INTO global_bans SET ?', ban);

    logger.info('Global ban added', {
      identifier,
      bannedBy,
      severity,
      serverOrigin,
    });

    res.json({
      success: true,
      message: 'Player added to global ban list',
      ban,
    });
  } catch (error) {
    logger.error('Failed to add global ban', { identifier, error: error.message });
    res.status(500).json({
      error: 'Failed to add global ban',
      message: error.message,
    });
  }
});

/**
 * DELETE /api/global-ban/remove/:identifier
 * Remove a player from the global ban list
 */
router.delete('/remove/:identifier', verifyAPIKey, async (req, res) => {
  const { identifier } = req.params;
  const { removedBy, reason } = req.body;

  try {
    banCache.delete(identifier);

    // In production: await db.query('UPDATE global_bans SET active = 0, removedBy = ?, removedAt = ?, removeReason = ? WHERE identifier = ?', 
    //   [removedBy, Date.now(), reason, identifier]);

    logger.info('Global ban removed', {
      identifier,
      removedBy,
      reason,
    });

    res.json({
      success: true,
      message: 'Player removed from global ban list',
    });
  } catch (error) {
    logger.error('Failed to remove global ban', { identifier, error: error.message });
    res.status(500).json({
      error: 'Failed to remove global ban',
      message: error.message,
    });
  }
});

/**
 * GET /api/global-ban/list
 * Get list of all active global bans
 */
router.get('/list', verifyAPIKey, async (req, res) => {
  const { page = 1, limit = 50, severity, serverOrigin } = req.query;

  try {
    let bans = Array.from(banCache.values());

    // Filter by severity
    if (severity) {
      bans = bans.filter(b => b.severity === severity);
    }

    // Filter by server origin
    if (serverOrigin) {
      bans = bans.filter(b => b.serverOrigin === serverOrigin);
    }

    // Pagination
    const start = (page - 1) * limit;
    const end = start + parseInt(limit);
    const paginatedBans = bans.slice(start, end);

    res.json({
      bans: paginatedBans,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: bans.length,
        pages: Math.ceil(bans.length / limit),
      },
    });
  } catch (error) {
    logger.error('Failed to list global bans', { error: error.message });
    res.status(500).json({
      error: 'Failed to list global bans',
      message: error.message,
    });
  }
});

/**
 * GET /api/global-ban/stats
 * Get statistics about global bans
 */
router.get('/stats', verifyAPIKey, (req, res) => {
  const bans = Array.from(banCache.values());
  
  res.json({
    total: bans.length,
    active: bans.filter(b => b.active).length,
    bySeverity: {
      critical: bans.filter(b => b.severity === 'critical').length,
      high: bans.filter(b => b.severity === 'high').length,
      medium: bans.filter(b => b.severity === 'medium').length,
      low: bans.filter(b => b.severity === 'low').length,
    },
    recent: bans
      .sort((a, b) => b.bannedAt - a.bannedAt)
      .slice(0, 10)
      .map(b => ({
        identifier: b.identifier,
        reason: b.reason,
        bannedAt: b.bannedAt,
        severity: b.severity,
      })),
  });
});

export default router;
