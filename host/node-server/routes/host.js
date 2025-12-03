// EC Admin Ultimate - Host API Routes
// Routes for API key management, IP allowlist, cities, etc.

const express = require('express');
const router = express.Router();
const crypto = require('crypto');

// Mock database connection - replace with actual MySQL connection
// const db = require('../db');

// ============================================================================
// MIDDLEWARE - Auth Check
// ============================================================================

const requireAuth = (req, res, next) => {
  // TODO: Implement JWT token validation
  // For now, just pass through
  next();
};

// ============================================================================
// HOST STATUS
// ============================================================================

router.get('/status', async (req, res) => {
  try {
    // Check if OAuth is complete and license is valid
    // TODO: Check database for actual status
    
    res.json({
      oauthComplete: false, // Check from database
      licenseValid: false,  // Check from database
      licenseKey: null,
      email: null,
      setupComplete: false
    });
  } catch (error) {
    console.error('Error getting host status:', error);
    res.status(500).json({ error: 'Failed to get host status' });
  }
});

// ============================================================================
// API KEYS
// ============================================================================

// List all API keys
router.get('/keys', requireAuth, async (req, res) => {
  try {
    // TODO: Query database
    // const keys = await db.query('SELECT * FROM ec_host_api_keys ORDER BY created_at DESC');
    
    // For now, return empty array (NO MOCK DATA)
    res.json({
      keys: [] // Will be populated from database
    });
  } catch (error) {
    console.error('Error getting API keys:', error);
    res.status(500).json({ error: 'Failed to get API keys' });
  }
});

// Generate new API key
router.post('/keys', requireAuth, async (req, res) => {
  try {
    const { name } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Name is required' });
    }
    
    // Generate secure API key
    const apiKey = 'ec_' + crypto.randomBytes(32).toString('hex');
    
    // TODO: Insert into database
    // await db.query(
    //   'INSERT INTO ec_host_api_keys (key_value, name, created_at) VALUES (?, ?, NOW())',
    //   [apiKey, name]
    // );
    
    res.json({
      success: true,
      key: {
        id: Date.now(), // Temporary - will come from DB
        key: apiKey,
        name: name,
        created_at: new Date().toISOString(),
        last_used: null,
        enabled: true
      }
    });
  } catch (error) {
    console.error('Error generating API key:', error);
    res.status(500).json({ error: 'Failed to generate API key' });
  }
});

// Revoke API key
router.delete('/keys/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Delete from database
    // await db.query('DELETE FROM ec_host_api_keys WHERE id = ?', [id]);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error revoking API key:', error);
    res.status(500).json({ error: 'Failed to revoke API key' });
  }
});

// Rotate API key
router.put('/keys/:id/rotate', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Generate new key
    const newKey = 'ec_' + crypto.randomBytes(32).toString('hex');
    
    // TODO: Update in database
    // await db.query(
    //   'UPDATE ec_host_api_keys SET key_value = ? WHERE id = ?',
    //   [newKey, id]
    // );
    
    res.json({
      success: true,
      key: newKey
    });
  } catch (error) {
    console.error('Error rotating API key:', error);
    res.status(500).json({ error: 'Failed to rotate API key' });
  }
});

// ============================================================================
// IP ALLOWLIST
// ============================================================================

// List IP allowlist
router.get('/ip-allowlist', requireAuth, async (req, res) => {
  try {
    // TODO: Query database
    // const entries = await db.query('SELECT * FROM ec_host_ip_allowlist ORDER BY created_at DESC');
    
    res.json({
      entries: [] // Will be populated from database
    });
  } catch (error) {
    console.error('Error getting IP allowlist:', error);
    res.status(500).json({ error: 'Failed to get IP allowlist' });
  }
});

// Add IP to allowlist
router.post('/ip-allowlist', requireAuth, async (req, res) => {
  try {
    const { ip, label } = req.body;
    
    if (!ip || !label) {
      return res.status(400).json({ error: 'IP and label are required' });
    }
    
    // Validate IP format
    const ipRegex = /^(\d{1,3}\.){3}\d{1,3}$/;
    if (!ipRegex.test(ip)) {
      return res.status(400).json({ error: 'Invalid IP address format' });
    }
    
    // TODO: Insert into database
    // await db.query(
    //   'INSERT INTO ec_host_ip_allowlist (ip, label, enabled, created_at) VALUES (?, ?, 1, NOW())',
    //   [ip, label]
    // );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error adding IP to allowlist:', error);
    res.status(500).json({ error: 'Failed to add IP to allowlist' });
  }
});

// Remove IP from allowlist
router.delete('/ip-allowlist/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Delete from database
    // await db.query('DELETE FROM ec_host_ip_allowlist WHERE id = ?', [id]);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error removing IP from allowlist:', error);
    res.status(500).json({ error: 'Failed to remove IP from allowlist' });
  }
});

// Toggle IP status
router.put('/ip-allowlist/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const { enabled } = req.body;
    
    // TODO: Update in database
    // await db.query(
    //   'UPDATE ec_host_ip_allowlist SET enabled = ? WHERE id = ?',
    //   [enabled ? 1 : 0, id]
    // );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error toggling IP status:', error);
    res.status(500).json({ error: 'Failed to toggle IP status' });
  }
});

// ============================================================================
// CONNECTED CITIES
// ============================================================================

router.get('/cities', requireAuth, async (req, res) => {
  try {
    // TODO: Query database
    // const cities = await db.query('SELECT * FROM ec_host_cities ORDER BY name ASC');
    
    res.json({
      cities: [] // Will be populated from database
    });
  } catch (error) {
    console.error('Error getting cities:', error);
    res.status(500).json({ error: 'Failed to get cities' });
  }
});

// ============================================================================
// LICENSE VALIDATION
// ============================================================================

router.post('/validateLicense', async (req, res) => {
  try {
    const { licenseKey } = req.body;
    
    if (!licenseKey) {
      return res.status(400).json({ error: 'License key is required' });
    }
    
    // TODO: Validate license key with license server
    // For now, accept any key starting with "NRG-"
    const isValid = licenseKey.startsWith('NRG-');
    
    if (isValid) {
      // TODO: Store in database
      // await db.query(
      //   'INSERT INTO ec_host_licenses (license_key, owner_email, status) VALUES (?, ?, ?)',
      //   [licenseKey, req.body.email, 'active']
      // );
      
      res.json({
        valid: true,
        message: 'License validated successfully'
      });
    } else {
      res.status(400).json({
        valid: false,
        error: 'Invalid license key'
      });
    }
  } catch (error) {
    console.error('Error validating license:', error);
    res.status(500).json({ error: 'Failed to validate license' });
  }
});

module.exports = router;
