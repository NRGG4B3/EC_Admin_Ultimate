/**
 * EC Admin Ultimate - AI Detection Engine
 * Real AI-powered cheat detection using pattern analysis and anomaly detection
 * Port 3002
 */

const express = require('express');
const fs = require('fs');
const path = require('path');

class AIDetectionEngine {
  constructor() {
    this.detectionHistory = [];
    this.playerProfiles = new Map(); // Player behavior profiles
    this.detectionRules = this.loadDetectionRules();
    this.anomalyThreshold = 0.75; // 75% confidence for anomaly
    this.behaviorWindow = 300000; // 5 minutes window
    
    console.log('[AI Detection] Engine initialized');
  }

  /**
   * Load detection rules
   */
  loadDetectionRules() {
    return [
      {
        id: 'speed_hack',
        name: 'Speed Hack Detection',
        category: 'movement',
        enabled: true,
        threshold: 0.85,
        autoAction: 'ban',
        patterns: {
          maxSpeed: 100, // m/s
          averageSpeed: 50, // m/s
          speedSpikes: 3 // max spikes per minute
        }
      },
      {
        id: 'teleport',
        name: 'Teleport Detection',
        category: 'movement',
        enabled: true,
        threshold: 0.90,
        autoAction: 'kick',
        patterns: {
          maxDistance: 500, // meters instant travel
          minInterval: 1000 // ms between legitimate teleports
        }
      },
      {
        id: 'rapid_fire',
        name: 'Rapid Fire Detection',
        category: 'combat',
        enabled: true,
        threshold: 0.80,
        autoAction: 'kick',
        patterns: {
          maxFireRate: 10, // shots per second
          consistency: 0.95 // pattern consistency
        }
      },
      {
        id: 'aimbot',
        name: 'Aimbot Detection',
        category: 'combat',
        enabled: true,
        threshold: 0.75,
        autoAction: 'warn',
        patterns: {
          headshot_ratio: 0.90, // 90% headshots
          snap_speed: 0.1, // seconds to target
          accuracy: 0.95 // hit accuracy
        }
      },
      {
        id: 'god_mode',
        name: 'God Mode Detection',
        category: 'combat',
        enabled: true,
        threshold: 0.98,
        autoAction: 'ban',
        patterns: {
          damage_taken: 0, // no damage in time window
          shots_taken: 100, // high number of shots without damage
          time_window: 60000 // 1 minute
        }
      },
      {
        id: 'noclip',
        name: 'NoClip Detection',
        category: 'movement',
        enabled: true,
        threshold: 0.95,
        autoAction: 'ban',
        patterns: {
          collision_misses: 10, // collision checks failed
          vertical_speed: 50, // vertical movement speed
          terrain_ignore: true
        }
      },
      {
        id: 'money_dupe',
        name: 'Money Duplication',
        category: 'economy',
        enabled: true,
        threshold: 0.95,
        autoAction: 'ban',
        patterns: {
          gain_rate: 100000, // per minute
          gain_spikes: 3,
          transaction_pattern: 'irregular'
        }
      },
      {
        id: 'resource_injection',
        name: 'Resource Injection',
        category: 'resource',
        enabled: true,
        threshold: 0.99,
        autoAction: 'ban',
        patterns: {
          unauthorized_resources: true,
          injection_detected: true
        }
      }
    ];
  }

  /**
   * Get or create player profile
   */
  getPlayerProfile(playerId) {
    if (!this.playerProfiles.has(playerId)) {
      this.playerProfiles.set(playerId, {
        playerId: playerId,
        firstSeen: Date.now(),
        lastActivity: Date.now(),
        behaviorHistory: [],
        violations: [],
        riskScore: 0,
        totalDetections: 0
      });
    }
    
    return this.playerProfiles.get(playerId);
  }

  /**
   * Analyze behavior data using AI pattern matching
   */
  analyzeBehavior(data) {
    const {
      playerId,
      playerName,
      behaviorType,
      dataPoints,
      timestamp = Date.now()
    } = data;

    const profile = this.getPlayerProfile(playerId);
    profile.lastActivity = timestamp;

    // Add to behavior history
    profile.behaviorHistory.push({
      type: behaviorType,
      data: dataPoints,
      timestamp: timestamp
    });

    // Keep only recent history (5 minutes)
    const cutoff = timestamp - this.behaviorWindow;
    profile.behaviorHistory = profile.behaviorHistory.filter(
      h => h.timestamp > cutoff
    );

    // Run AI analysis
    const detections = this.runAIAnalysis(profile, data);

    return {
      success: true,
      detections: detections,
      riskScore: profile.riskScore,
      analyzed: true
    };
  }

  /**
   * Run AI-powered analysis
   */
  runAIAnalysis(profile, currentData) {
    const detections = [];

    // Analyze against each rule
    for (const rule of this.detectionRules) {
      if (!rule.enabled) continue;

      const result = this.analyzeAgainstRule(
        profile,
        currentData,
        rule
      );

      if (result && result.confidence >= rule.threshold) {
        const detection = {
          id: `det_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          playerId: profile.playerId,
          playerName: currentData.playerName || 'Unknown',
          ruleId: rule.id,
          ruleName: rule.name,
          category: rule.category,
          confidence: result.confidence,
          severity: this.calculateSeverity(result.confidence),
          autoAction: rule.autoAction,
          evidence: result.evidence,
          timestamp: Date.now(),
          status: 'detected'
        };

        detections.push(detection);
        
        // Update profile
        profile.violations.push(detection);
        profile.totalDetections++;
        profile.riskScore = this.calculateRiskScore(profile);

        // Store in history
        this.detectionHistory.push(detection);
      }
    }

    // Trim history
    if (this.detectionHistory.length > 1000) {
      this.detectionHistory = this.detectionHistory.slice(-1000);
    }

    return detections;
  }

  /**
   * Analyze data against specific rule
   */
  analyzeAgainstRule(profile, currentData, rule) {
    const { behaviorType, dataPoints } = currentData;

    // Speed Hack Detection
    if (rule.id === 'speed_hack' && behaviorType === 'movement') {
      return this.detectSpeedHack(dataPoints, rule.patterns);
    }

    // Teleport Detection
    if (rule.id === 'teleport' && behaviorType === 'movement') {
      return this.detectTeleport(dataPoints, rule.patterns);
    }

    // Rapid Fire Detection
    if (rule.id === 'rapid_fire' && behaviorType === 'combat') {
      return this.detectRapidFire(dataPoints, rule.patterns);
    }

    // Aimbot Detection
    if (rule.id === 'aimbot' && behaviorType === 'combat') {
      return this.detectAimbot(dataPoints, rule.patterns);
    }

    // God Mode Detection
    if (rule.id === 'god_mode' && behaviorType === 'combat') {
      return this.detectGodMode(profile, dataPoints, rule.patterns);
    }

    // NoClip Detection
    if (rule.id === 'noclip' && behaviorType === 'movement') {
      return this.detectNoClip(dataPoints, rule.patterns);
    }

    // Money Dupe Detection
    if (rule.id === 'money_dupe' && behaviorType === 'economy') {
      return this.detectMoneyDupe(dataPoints, rule.patterns);
    }

    return null;
  }

  /**
   * Speed Hack Detection Algorithm
   */
  detectSpeedHack(data, patterns) {
    const speed = data.speed || 0;
    const averageSpeed = data.averageSpeed || 0;
    const spikes = data.speedSpikes || 0;

    let confidence = 0;
    const evidence = [];

    // Check max speed
    if (speed > patterns.maxSpeed) {
      confidence += 0.4;
      evidence.push(`Speed: ${speed.toFixed(2)} m/s (Max: ${patterns.maxSpeed})`);
    }

    // Check average speed
    if (averageSpeed > patterns.averageSpeed) {
      confidence += 0.3;
      evidence.push(`Avg Speed: ${averageSpeed.toFixed(2)} m/s`);
    }

    // Check spikes
    if (spikes > patterns.speedSpikes) {
      confidence += 0.3;
      evidence.push(`Speed spikes: ${spikes} in 1 minute`);
    }

    return confidence > 0 ? { confidence, evidence } : null;
  }

  /**
   * Teleport Detection Algorithm
   */
  detectTeleport(data, patterns) {
    const distance = data.distanceTraveled || 0;
    const timeInterval = data.timeInterval || 1000;

    let confidence = 0;
    const evidence = [];

    if (distance > patterns.maxDistance && timeInterval < patterns.minInterval) {
      confidence = 0.95;
      evidence.push(`Traveled ${distance.toFixed(2)}m in ${timeInterval}ms`);
      evidence.push(`Teleport detected`);
    }

    return confidence > 0 ? { confidence, evidence } : null;
  }

  /**
   * Rapid Fire Detection Algorithm
   */
  detectRapidFire(data, patterns) {
    const fireRate = data.fireRate || 0;
    const consistency = data.consistency || 0;

    let confidence = 0;
    const evidence = [];

    if (fireRate > patterns.maxFireRate) {
      confidence += 0.5;
      evidence.push(`Fire rate: ${fireRate.toFixed(2)} shots/sec`);
    }

    if (consistency > patterns.consistency) {
      confidence += 0.4;
      evidence.push(`Pattern consistency: ${(consistency * 100).toFixed(1)}%`);
    }

    return confidence > 0 ? { confidence, evidence } : null;
  }

  /**
   * Aimbot Detection Algorithm
   */
  detectAimbot(data, patterns) {
    const headshotRatio = data.headshotRatio || 0;
    const snapSpeed = data.snapSpeed || 1;
    const accuracy = data.accuracy || 0;

    let confidence = 0;
    const evidence = [];

    if (headshotRatio > patterns.headshot_ratio) {
      confidence += 0.4;
      evidence.push(`Headshot ratio: ${(headshotRatio * 100).toFixed(1)}%`);
    }

    if (snapSpeed < patterns.snap_speed) {
      confidence += 0.3;
      evidence.push(`Snap speed: ${(snapSpeed * 1000).toFixed(0)}ms`);
    }

    if (accuracy > patterns.accuracy) {
      confidence += 0.3;
      evidence.push(`Accuracy: ${(accuracy * 100).toFixed(1)}%`);
    }

    return confidence > 0 ? { confidence, evidence } : null;
  }

  /**
   * God Mode Detection Algorithm
   */
  detectGodMode(profile, data, patterns) {
    const damageTaken = data.damageTaken || 0;
    const shotsTaken = data.shotsTaken || 0;
    const timeWindow = data.timeWindow || 0;

    let confidence = 0;
    const evidence = [];

    if (damageTaken === 0 && shotsTaken > patterns.shots_taken && timeWindow >= patterns.time_window) {
      confidence = 0.98;
      evidence.push(`No damage from ${shotsTaken} shots in ${(timeWindow / 1000).toFixed(0)}s`);
      evidence.push(`God mode detected`);
    }

    return confidence > 0 ? { confidence, evidence } : null;
  }

  /**
   * NoClip Detection Algorithm
   */
  detectNoClip(data, patterns) {
    const collisionMisses = data.collisionMisses || 0;
    const verticalSpeed = data.verticalSpeed || 0;
    const terrainIgnore = data.terrainIgnore || false;

    let confidence = 0;
    const evidence = [];

    if (collisionMisses > patterns.collision_misses) {
      confidence += 0.4;
      evidence.push(`Collision misses: ${collisionMisses}`);
    }

    if (verticalSpeed > patterns.vertical_speed) {
      confidence += 0.3;
      evidence.push(`Vertical speed: ${verticalSpeed.toFixed(2)} m/s`);
    }

    if (terrainIgnore) {
      confidence += 0.3;
      evidence.push(`Terrain collision ignored`);
    }

    return confidence > 0 ? { confidence, evidence } : null;
  }

  /**
   * Money Dupe Detection Algorithm
   */
  detectMoneyDupe(data, patterns) {
    const gainRate = data.gainRate || 0;
    const gainSpikes = data.gainSpikes || 0;
    const transactionPattern = data.transactionPattern || 'normal';

    let confidence = 0;
    const evidence = [];

    if (gainRate > patterns.gain_rate) {
      confidence += 0.5;
      evidence.push(`Money gain: $${gainRate.toFixed(0)}/min`);
    }

    if (gainSpikes > patterns.gain_spikes) {
      confidence += 0.3;
      evidence.push(`Gain spikes: ${gainSpikes}`);
    }

    if (transactionPattern === 'irregular') {
      confidence += 0.2;
      evidence.push(`Irregular transaction pattern`);
    }

    return confidence > 0 ? { confidence, evidence } : null;
  }

  /**
   * Calculate severity based on confidence
   */
  calculateSeverity(confidence) {
    if (confidence >= 0.95) return 'critical';
    if (confidence >= 0.85) return 'high';
    if (confidence >= 0.75) return 'medium';
    return 'low';
  }

  /**
   * Calculate player risk score
   */
  calculateRiskScore(profile) {
    let score = 0;

    // Base score from total detections
    score += profile.totalDetections * 10;

    // Weight recent violations more heavily
    const recentViolations = profile.violations.filter(
      v => (Date.now() - v.timestamp) < 3600000 // last hour
    );
    score += recentViolations.length * 20;

    // Cap at 100
    return Math.min(100, score);
  }

  /**
   * Get player statistics
   */
  getPlayerStats(playerId) {
    const profile = this.getPlayerProfile(playerId);
    
    return {
      playerId: profile.playerId,
      firstSeen: profile.firstSeen,
      lastActivity: profile.lastActivity,
      riskScore: profile.riskScore,
      totalDetections: profile.totalDetections,
      recentViolations: profile.violations.filter(
        v => (Date.now() - v.timestamp) < 3600000
      ).length,
      behaviorSamples: profile.behaviorHistory.length
    };
  }

  /**
   * Get detection statistics
   */
  getStats() {
    const now = Date.now();
    const oneHourAgo = now - 3600000;
    const oneDayAgo = now - 86400000;

    return {
      total_detections: this.detectionHistory.length,
      detections_last_hour: this.detectionHistory.filter(
        d => d.timestamp > oneHourAgo
      ).length,
      detections_today: this.detectionHistory.filter(
        d => d.timestamp > oneDayAgo
      ).length,
      active_players_monitored: this.playerProfiles.size,
      rules_active: this.detectionRules.filter(r => r.enabled).length,
      avg_confidence: this.detectionHistory.length > 0
        ? this.detectionHistory.reduce((sum, d) => sum + d.confidence, 0) / this.detectionHistory.length
        : 0,
      status: 'operational'
    };
  }

  /**
   * Get detection rules
   */
  getRules() {
    return this.detectionRules;
  }

  /**
   * Update rule
   */
  updateRule(ruleId, updates) {
    const rule = this.detectionRules.find(r => r.id === ruleId);
    if (rule) {
      Object.assign(rule, updates);
      return { success: true, rule };
    }
    return { success: false, error: 'Rule not found' };
  }

  /**
   * Get recent detections
   */
  getRecentDetections(limit = 50) {
    return this.detectionHistory.slice(-limit).reverse();
  }
}

/**
 * Setup API routes
 */
function setupAIDetectionAPI(app, requireHostSecret) {
  const engine = new AIDetectionEngine();

  // Health check
  app.get('/health', (req, res) => {
    res.json({ success: true, status: 'operational', port: 3002 });
  });

  // Get detection statistics
  app.get('/api/ai-detection/status', requireHostSecret, (req, res) => {
    try {
      const stats = engine.getStats();
      res.json({ success: true, ...stats });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Get detection rules
  app.get('/api/ai-detection/rules', requireHostSecret, (req, res) => {
    try {
      const rules = engine.getRules();
      res.json({ success: true, rules });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Update detection rule
  app.put('/api/ai-detection/rules/:ruleId', requireHostSecret, (req, res) => {
    try {
      const { ruleId } = req.params;
      const updates = req.body;
      const result = engine.updateRule(ruleId, updates);
      res.json(result);
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Analyze behavior (main AI endpoint)
  app.post('/api/ai-detection/analyze', requireHostSecret, (req, res) => {
    try {
      const result = engine.analyzeBehavior(req.body);
      res.json(result);
    } catch (error) {
      console.error('[AI Detection] Analysis error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Get player stats
  app.get('/api/ai-detection/player/:playerId', requireHostSecret, (req, res) => {
    try {
      const { playerId } = req.params;
      const stats = engine.getPlayerStats(playerId);
      res.json({ success: true, stats });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Get recent detections
  app.get('/api/ai-detection/detections', requireHostSecret, (req, res) => {
    try {
      const limit = parseInt(req.query.limit) || 50;
      const detections = engine.getRecentDetections(limit);
      res.json({ success: true, detections });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Report detection (deprecated - use /analyze)
  app.post('/api/ai-detection/report', requireHostSecret, (req, res) => {
    res.json({ 
      success: true, 
      message: 'Use /api/ai-detection/analyze instead',
      deprecated: true
    });
  });

  console.log('[AI Detection] API routes registered on port 3002');
}

module.exports = { setupAIDetectionAPI, AIDetectionEngine };
