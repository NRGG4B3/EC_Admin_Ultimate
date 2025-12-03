/**
 * NRG Staff API Service
 * Staff verification and permissions for NRG hosted servers
 */

import express from 'express';
import { verifyAPIKey } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('nrg-staff');

// Staff database (in production, this would be a real database)
const staffMembers = new Map([
  ['license:abc123', { 
    identifier: 'license:abc123',
    name: 'Admin1',
    role: 'admin',
    permissions: ['all'],
    active: true,
    joinedAt: Date.now() - 86400000 * 30,
  }],
]);

/**
 * GET /api/nrg-staff/verify/:identifier
 * Verify if a user is NRG staff
 */
router.get('/verify/:identifier', verifyAPIKey, (req, res) => {
  const { identifier } = req.params;

  try {
    const staff = staffMembers.get(identifier);

    if (!staff || !staff.active) {
      return res.json({
        isStaff: false,
        message: 'User is not NRG staff',
      });
    }

    res.json({
      isStaff: true,
      staff: {
        identifier: staff.identifier,
        name: staff.name,
        role: staff.role,
        permissions: staff.permissions,
        joinedAt: staff.joinedAt,
      },
    });
  } catch (error) {
    logger.error('Failed to verify staff', { identifier, error: error.message });
    res.status(500).json({
      error: 'Failed to verify staff status',
      message: error.message,
    });
  }
});

/**
 * GET /api/nrg-staff/permissions/:identifier
 * Get staff permissions
 */
router.get('/permissions/:identifier', verifyAPIKey, (req, res) => {
  const { identifier } = req.params;

  try {
    const staff = staffMembers.get(identifier);

    if (!staff || !staff.active) {
      return res.status(404).json({
        error: 'Staff member not found',
      });
    }

    res.json({
      identifier: staff.identifier,
      role: staff.role,
      permissions: staff.permissions,
      canModerate: staff.permissions.includes('all') || staff.permissions.includes('moderate'),
      canBan: staff.permissions.includes('all') || staff.permissions.includes('ban'),
      canKick: staff.permissions.includes('all') || staff.permissions.includes('kick'),
      canManageServer: staff.permissions.includes('all') || staff.permissions.includes('manage'),
    });
  } catch (error) {
    logger.error('Failed to get permissions', { identifier, error: error.message });
    res.status(500).json({
      error: 'Failed to get permissions',
      message: error.message,
    });
  }
});

/**
 * POST /api/nrg-staff/add
 * Add a new staff member
 */
router.post('/add', verifyAPIKey, (req, res) => {
  const { identifier, name, role, permissions } = req.body;

  try {
    if (staffMembers.has(identifier)) {
      return res.status(409).json({
        error: 'Staff member already exists',
      });
    }

    const staff = {
      identifier,
      name,
      role,
      permissions,
      active: true,
      joinedAt: Date.now(),
      addedBy: req.user?.username || 'system',
    };

    staffMembers.set(identifier, staff);

    logger.info('Staff member added', {
      identifier,
      name,
      role,
      addedBy: staff.addedBy,
    });

    res.json({
      success: true,
      message: 'Staff member added successfully',
      staff,
    });
  } catch (error) {
    logger.error('Failed to add staff', { identifier, error: error.message });
    res.status(500).json({
      error: 'Failed to add staff member',
      message: error.message,
    });
  }
});

/**
 * PUT /api/nrg-staff/update/:identifier
 * Update staff member details
 */
router.put('/update/:identifier', verifyAPIKey, (req, res) => {
  const { identifier } = req.params;
  const { name, role, permissions, active } = req.body;

  try {
    const staff = staffMembers.get(identifier);

    if (!staff) {
      return res.status(404).json({
        error: 'Staff member not found',
      });
    }

    // Update fields
    if (name) staff.name = name;
    if (role) staff.role = role;
    if (permissions) staff.permissions = permissions;
    if (typeof active === 'boolean') staff.active = active;

    staff.updatedAt = Date.now();
    staff.updatedBy = req.user?.username || 'system';

    staffMembers.set(identifier, staff);

    logger.info('Staff member updated', {
      identifier,
      updatedBy: staff.updatedBy,
    });

    res.json({
      success: true,
      message: 'Staff member updated successfully',
      staff,
    });
  } catch (error) {
    logger.error('Failed to update staff', { identifier, error: error.message });
    res.status(500).json({
      error: 'Failed to update staff member',
      message: error.message,
    });
  }
});

/**
 * DELETE /api/nrg-staff/remove/:identifier
 * Remove/deactivate a staff member
 */
router.delete('/remove/:identifier', verifyAPIKey, (req, res) => {
  const { identifier } = req.params;
  const { permanent = false } = req.body;

  try {
    const staff = staffMembers.get(identifier);

    if (!staff) {
      return res.status(404).json({
        error: 'Staff member not found',
      });
    }

    if (permanent) {
      staffMembers.delete(identifier);
      logger.info('Staff member permanently removed', { identifier });
    } else {
      staff.active = false;
      staff.deactivatedAt = Date.now();
      staffMembers.set(identifier, staff);
      logger.info('Staff member deactivated', { identifier });
    }

    res.json({
      success: true,
      message: permanent ? 'Staff member permanently removed' : 'Staff member deactivated',
    });
  } catch (error) {
    logger.error('Failed to remove staff', { identifier, error: error.message });
    res.status(500).json({
      error: 'Failed to remove staff member',
      message: error.message,
    });
  }
});

/**
 * GET /api/nrg-staff/list
 * List all staff members
 */
router.get('/list', verifyAPIKey, (req, res) => {
  const { active, role } = req.query;

  try {
    let staff = Array.from(staffMembers.values());

    // Filter by active status
    if (typeof active !== 'undefined') {
      staff = staff.filter(s => s.active === (active === 'true'));
    }

    // Filter by role
    if (role) {
      staff = staff.filter(s => s.role === role);
    }

    res.json({
      staff: staff.map(s => ({
        identifier: s.identifier,
        name: s.name,
        role: s.role,
        permissions: s.permissions,
        active: s.active,
        joinedAt: s.joinedAt,
      })),
      total: staff.length,
    });
  } catch (error) {
    logger.error('Failed to list staff', { error: error.message });
    res.status(500).json({
      error: 'Failed to list staff members',
      message: error.message,
    });
  }
});

/**
 * POST /api/nrg-staff/log-action
 * Log a staff action for audit trail
 */
router.post('/log-action', verifyAPIKey, (req, res) => {
  const { identifier, action, target, details, serverId } = req.body;

  try {
    const log = {
      id: Date.now().toString(),
      identifier,
      action,
      target,
      details,
      serverId,
      timestamp: Date.now(),
    };

    // In production: await db.query('INSERT INTO staff_actions SET ?', log);

    logger.info('Staff action logged', log);

    res.json({
      success: true,
      message: 'Action logged successfully',
      log,
    });
  } catch (error) {
    logger.error('Failed to log action', { error: error.message });
    res.status(500).json({
      error: 'Failed to log action',
      message: error.message,
    });
  }
});

export default router;
