// EC Admin Ultimate - Players API Routes
// Routes for player data (used by admin menu)

const express = require('express');
const router = express.Router();

// Mock database connection
// const db = require('../db');

// ============================================================================
// PLAYERS
// ============================================================================

// Get all players (live data from FiveM server)
router.get('/', async (req, res) => {
  try {
    // In production, this would query the FiveM server or cache
    // For now, return empty array (NO MOCK DATA)
    
    res.json({
      players: [] // Will be populated from FiveM server
    });
  } catch (error) {
    console.error('Error getting players:', error);
    res.status(500).json({ error: 'Failed to get players' });
  }
});

// Get player by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Query FiveM server for specific player
    
    res.json({
      player: null // Will be populated from FiveM server
    });
  } catch (error) {
    console.error('Error getting player:', error);
    res.status(500).json({ error: 'Failed to get player' });
  }
});

module.exports = router;
