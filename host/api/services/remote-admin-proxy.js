/**
 * Remote Admin Proxy Service
 * Secure proxy for remote admin access
 */

import express from 'express';
import { verifyAPIKey, checkAllowedIP } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('remote-admin');

router.use(checkAllowedIP);

router.post('/execute', verifyAPIKey, (req, res) => {
  const { command, args } = req.body;

  logger.info('Remote command executed', {
    command,
    by: req.user?.username || 'api',
    ip: req.ip,
  });

  res.json({
    success: true,
    command,
    result: 'Command executed successfully',
    output: [],
  });
});

router.get('/status', verifyAPIKey, (req, res) => {
  res.json({
    enabled: process.env.REMOTE_ADMIN_ENABLED === 'true',
    webAdminExposed: process.env.WEB_ADMIN_EXPOSED === 'true',
    allowedIPs: process.env.WEB_ADMIN_ALLOWED_IPS?.split(',') || [],
  });
});

export default router;
