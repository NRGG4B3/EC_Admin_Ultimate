/**
 * Authentication and authorization middleware
 */

import jwt from 'jsonwebtoken';
import { createLogger } from '../utils/logger.js';

const logger = createLogger('auth');
const JWT_SECRET = process.env.JWT_SECRET || 'default-secret-change-me';
const API_MASTER_KEY = process.env.API_MASTER_KEY;

/**
 * Verify API key from header
 */
export function verifyAPIKey(req, res, next) {
  const apiKey = req.headers['x-api-key'];

  if (!apiKey) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'API key required',
    });
  }

  // Verify against master key or service-specific keys
  if (apiKey === API_MASTER_KEY) {
    req.apiKeyValid = true;
    req.apiKeyType = 'master';
    return next();
  }

  // Check service-specific keys
  const serviceKeys = {
    globalBan: process.env.GLOBAL_BAN_API_KEY,
    nrgStaff: process.env.NRG_STAFF_API_KEY,
    aiAnalytics: process.env.AI_ANALYTICS_API_KEY,
    updateChecker: process.env.UPDATE_CHECKER_API_KEY,
    selfHeal: process.env.SELF_HEAL_API_KEY,
    remoteAdmin: process.env.REMOTE_ADMIN_API_KEY,
    monitoring: process.env.MONITORING_API_KEY,
  };

  for (const [service, key] of Object.entries(serviceKeys)) {
    if (apiKey === key) {
      req.apiKeyValid = true;
      req.apiKeyType = service;
      return next();
    }
  }

  logger.warn('Invalid API key attempt', {
    ip: req.ip,
    path: req.path,
  });

  return res.status(401).json({
    error: 'Unauthorized',
    message: 'Invalid API key',
  });
}

/**
 * Authenticate user via JWT token
 */
export function authenticate(req, res, next) {
  const token = req.cookies?.token || req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Authentication required',
    });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    logger.warn('Invalid token', {
      ip: req.ip,
      error: error.message,
    });

    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or expired token',
    });
  }
}

/**
 * Require host/admin access (for control panel routes)
 */
export function requireHostAccess(req, res, next) {
  // First check API key
  if (!req.apiKeyValid && !req.user) {
    return verifyAPIKey(req, res, () => {
      if (!req.apiKeyValid || req.apiKeyType !== 'master') {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'Host access required',
        });
      }
      next();
    });
  }

  // If user is authenticated, check role
  if (req.user && req.user.role !== 'host') {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Host access required',
    });
  }

  next();
}

/**
 * Optional authentication (doesn't fail if no token)
 */
export function optionalAuth(req, res, next) {
  const token = req.cookies?.token || req.headers.authorization?.replace('Bearer ', '');

  if (token) {
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      req.user = decoded;
    } catch (error) {
      // Silently fail, user will be undefined
    }
  }

  next();
}

/**
 * Check if request is from allowed IP (for web admin exposure control)
 */
export function checkAllowedIP(req, res, next) {
  if (process.env.WEB_ADMIN_EXPOSED !== 'true') {
    return next();
  }

  const allowedIPs = process.env.WEB_ADMIN_ALLOWED_IPS?.split(',') || [];
  const clientIP = req.ip || req.connection.remoteAddress;

  if (allowedIPs.length === 0 || allowedIPs.includes(clientIP)) {
    return next();
  }

  logger.warn('Blocked IP attempt to access web admin', {
    ip: clientIP,
    path: req.path,
  });

  return res.status(403).json({
    error: 'Forbidden',
    message: 'Access denied from your IP address',
  });
}

export default {
  verifyAPIKey,
  authenticate,
  requireHostAccess,
  optionalAuth,
  checkAllowedIP,
};
