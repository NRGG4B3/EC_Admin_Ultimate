-- EC Admin Ultimate Host SQL
-- Auto-installs for host servers (includes all customer tables)

-- Include all tables from customer.sql
-- (You may use a script to run both files, or duplicate here for clarity)

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

-- ============================================================================
-- INCLUDE ALL CUSTOMER TABLES
-- ============================================================================
-- The following tables are duplicated from ec_admin_customer.sql for host auto-install
-- (If you update customer.sql, update here too)
CREATE TABLE IF NOT EXISTS ec_admin_permissions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(100) NOT NULL,
  permission_level INT DEFAULT 1,
  permissions TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY identifier_unique (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ec_admin_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_identifier VARCHAR(100) NOT NULL,
  admin_name VARCHAR(100) NOT NULL,
  action VARCHAR(100) NOT NULL,
  target_identifier VARCHAR(100) NULL,
  target_name VARCHAR(100) NULL,
  details TEXT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_admin (admin_identifier),
  INDEX idx_action (action),
  INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- (Add all other customer tables here as needed, see ec_admin_customer.sql)

-- ============================================================================
-- HOUSING TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS ec_housing_properties (
  id INT AUTO_INCREMENT PRIMARY KEY,
  property_id VARCHAR(100) NOT NULL,
  owner_id VARCHAR(100) NOT NULL,
  address VARCHAR(255) NOT NULL,
  value INT DEFAULT 0,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ec_housing_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  property_id VARCHAR(100) NOT NULL,
  buyer_id VARCHAR(100) NOT NULL,
  seller_id VARCHAR(100) NOT NULL,
  price INT DEFAULT 0,
  transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SYSTEM TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS ec_system_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(100) NOT NULL,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ec_system_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  log_type VARCHAR(100) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- COMMUNITY TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS ec_community_events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  event_name VARCHAR(100) NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  event_data TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ec_community_members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  member_id VARCHAR(100) NOT NULL,
  member_name VARCHAR(100) NOT NULL,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- WHITELIST TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS ec_whitelist_applications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  applicant_id VARCHAR(100) NOT NULL,
  applicant_name VARCHAR(100) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ec_whitelist_members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  member_id VARCHAR(100) NOT NULL,
  member_name VARCHAR(100) NOT NULL,
  approved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SETTINGS TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS ec_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(100) NOT NULL,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- GLOBAL TOOLS TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS ec_global_tools (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tool_name VARCHAR(100) NOT NULL,
  tool_data TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
