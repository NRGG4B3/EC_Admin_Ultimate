-- EC Admin Ultimate Host SQL
-- Auto-installs for host servers (includes all customer tables)

-- Include all tables from customer.sql
-- (You may use a script to run both files, or duplicate here for clarity)

-- Host-specific tables
CREATE TABLE IF NOT EXISTS ec_anticheat_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  playerId VARCHAR(64),
  playerName VARCHAR(64),
  action VARCHAR(128),
  details TEXT,
  timestamp BIGINT,
  detectionType VARCHAR(64),
  severity VARCHAR(32)
);

CREATE TABLE IF NOT EXISTS ec_anticheat_detections (
  id INT AUTO_INCREMENT PRIMARY KEY,
  playerId VARCHAR(64),
  detectionType VARCHAR(64),
  value VARCHAR(128),
  timestamp BIGINT
);

CREATE TABLE IF NOT EXISTS ec_anticheat_chart_data (
  id INT AUTO_INCREMENT PRIMARY KEY,
  labels JSON,
  data JSON,
  detectionTypes JSON
);

CREATE TABLE IF NOT EXISTS ec_anticheat_flags (
  id INT AUTO_INCREMENT PRIMARY KEY,
  playerId VARCHAR(64),
  action VARCHAR(128),
  details TEXT,
  timestamp BIGINT,
  detectionType VARCHAR(64),
  severity VARCHAR(32)
);

-- Add more host-only tables for housing, moderation, system, community, whitelist, settings as needed
