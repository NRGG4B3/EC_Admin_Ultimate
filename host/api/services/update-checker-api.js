/**
 * Update Checker API Service
 * Checks for EC Admin Ultimate updates
 */

import express from 'express';
import { verifyAPIKey } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('update-checker');

const CURRENT_VERSION = '1.0.0';
const LATEST_VERSION = '1.0.0';

router.get('/check', verifyAPIKey, (req, res) => {
  const { currentVersion = CURRENT_VERSION } = req.query;

  const updateAvailable = currentVersion !== LATEST_VERSION;

  res.json({
    currentVersion,
    latestVersion: LATEST_VERSION,
    updateAvailable,
    changelog: updateAvailable ? [
      { version: '1.0.1', changes: ['Bug fixes', 'Performance improvements'] },
    ] : [],
    downloadUrl: updateAvailable ? 'https://updates.nrg-host.com/ec-admin' : null,
  });
});

export default router;
