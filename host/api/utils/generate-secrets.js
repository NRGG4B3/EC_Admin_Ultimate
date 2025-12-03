/**
 * Generate secure secrets for .env file
 */

import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function generateSecret(length = 64) {
  return crypto.randomBytes(length).toString('hex');
}

function generateJWT() {
  return crypto.randomBytes(64).toString('base64');
}

function generateAPIKey() {
  return 'nrg_' + crypto.randomBytes(32).toString('hex');
}

console.log('═══════════════════════════════════════════════════════════');
console.log('  EC Admin Ultimate - Secret Generator');
console.log('  NRG Host Infrastructure');
console.log('═══════════════════════════════════════════════════════════');
console.log('');
console.log('Generated Secrets (add to .env file):');
console.log('');
console.log('# Security Secrets');
console.log(`JWT_SECRET=${generateJWT()}`);
console.log(`API_MASTER_KEY=${generateAPIKey()}`);
console.log(`ENCRYPTION_KEY=${generateSecret(32)}`);
console.log('');
console.log('# Session Secret');
console.log(`SESSION_SECRET=${generateSecret(32)}`);
console.log('');
console.log('# Service API Keys');
console.log(`GLOBAL_BAN_API_KEY=${generateAPIKey()}`);
console.log(`NRG_STAFF_API_KEY=${generateAPIKey()}`);
console.log(`AI_ANALYTICS_API_KEY=${generateAPIKey()}`);
console.log(`UPDATE_CHECKER_API_KEY=${generateAPIKey()}`);
console.log(`SELF_HEAL_API_KEY=${generateAPIKey()}`);
console.log(`REMOTE_ADMIN_API_KEY=${generateAPIKey()}`);
console.log(`MONITORING_API_KEY=${generateAPIKey()}`);
console.log('');
console.log('═══════════════════════════════════════════════════════════');
console.log('⚠️  IMPORTANT: Keep these secrets secure!');
console.log('⚠️  Never commit .env file to version control');
console.log('⚠️  Store securely and rotate regularly');
console.log('═══════════════════════════════════════════════════════════');
console.log('');

// Optionally write to a .env.generated file
const envPath = path.join(__dirname, '../.env.generated');
const envContent = `# Generated: ${new Date().toISOString()}
# COPY THESE TO YOUR .env FILE

# Security Secrets
JWT_SECRET=${generateJWT()}
API_MASTER_KEY=${generateAPIKey()}
ENCRYPTION_KEY=${generateSecret(32)}

# Session Secret
SESSION_SECRET=${generateSecret(32)}

# Service API Keys
GLOBAL_BAN_API_KEY=${generateAPIKey()}
NRG_STAFF_API_KEY=${generateAPIKey()}
AI_ANALYTICS_API_KEY=${generateAPIKey()}
UPDATE_CHECKER_API_KEY=${generateAPIKey()}
SELF_HEAL_API_KEY=${generateAPIKey()}
REMOTE_ADMIN_API_KEY=${generateAPIKey()}
MONITORING_API_KEY=${generateAPIKey()}
`;

fs.writeFileSync(envPath, envContent);
console.log(`✓ Secrets also saved to: ${envPath}`);
console.log('');
