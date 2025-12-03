// EC Admin Ultimate - Host Auto-Configuration
// Automatically configures host environment when host folder is detected
// This file is NOT included in customer builds

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

console.log('╔════════════════════════════════════════════════════════╗');
console.log('║   EC Admin Ultimate - Host Auto-Configuration         ║');
console.log('╚════════════════════════════════════════════════════════╝');
console.log('');

// Production host configuration (NRG internal)
const HOST_CONFIG = {
    ip: '45.144.225.227',
    domain: 'ECBetaSolutions.com',
    password: '354*Ea01', // 5-tap unlock password
    port: 3000,
    bind: '127.0.0.1', // SECURITY: localhost only
    fivemPort: 30120
};

// Generate a strong random host secret
function generateHostSecret() {
    return crypto.randomBytes(32).toString('base64');
}

// Check if .env exists
function checkEnvFile() {
    const envPath = path.join(__dirname, '.env');
    const envExamplePath = path.join(__dirname, '.env.example');
    
    if (fs.existsSync(envPath)) {
        console.log('✅ .env file already exists');
        return true;
    }
    
    if (!fs.existsSync(envExamplePath)) {
        console.log('⚠️  .env.example not found, will create default template');
        createEnvExampleFile();
    }
    
    console.log('⚠️  .env file not found, will create from template');
    return false;
}

// Create default .env.example if it doesn't exist
function createEnvExampleFile() {
    const envExamplePath = path.join(__dirname, '.env.example');
    
    const defaultTemplate = `# EC Admin Ultimate - Host Node Server Configuration
# This file is auto-configured when host folder is detected

# SERVER CONFIGURATION
PORT=3000
BIND=127.0.0.1
NODE_ENV=production

# SECURITY - Host API Secret (matches Config.HostApi.secret in config.lua)
HOST_SECRET=YOUR_HOST_SHARED_SECRET_HERE_CHANGE_THIS

# HOST DETAILS (NRG Internal)
HOST_IP=45.144.225.227
HOST_DOMAIN=ECBetaSolutions.com
UNLOCK_PASSWORD=354*Ea01

# DATABASE CONFIGURATION
DB_HOST=45.144.225.227
DB_PORT=3306
DB_USER=ec_admin_host
DB_PASSWORD=your_secure_password_here
DB_NAME=ec_admin_host

# GOOGLE OAUTH (Setup in wizard)
GOOGLE_CLIENT_ID=your_client_id_here.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret_here
GOOGLE_REDIRECT_URI=http://localhost:3000/api/setup/oauth/callback

# LICENSE SERVER (NRG Internal)
LICENSE_API_URL=https://nrg-licenses.example.com/api/v1
LICENSE_API_KEY=your_license_api_key_here

# SESSION & SECURITY
SESSION_SECRET=your_random_session_secret_here_change_this
JWT_SECRET=your_jwt_secret_here_change_this

# RATE LIMITING
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# LOGGING
LOG_LEVEL=info
LOG_FILE=./logs/host-api.log

# API CONFIGURATION
API_TIMEOUT=10000
MAX_PAYLOAD_SIZE=10mb

# FIVEM INTEGRATION
FIVEM_SERVER_IP=45.144.225.227
FIVEM_SERVER_PORT=30120

# MASTER API GATEWAY
MASTER_GATEWAY_URL=http://127.0.0.1:3000
API_GATEWAY_COUNT=20
`;

    fs.writeFileSync(envExamplePath, defaultTemplate);
    console.log('✅ Created .env.example template');
}

// Create .env from template with auto-configuration
function createEnvFile() {
    const envPath = path.join(__dirname, '.env');
    const envExamplePath = path.join(__dirname, '.env.example');
    
    if (fs.existsSync(envPath)) {
        console.log('ℹ️  .env already exists, skipping creation');
        return;
    }
    
    // Read template
    let envContent = fs.readFileSync(envExamplePath, 'utf-8');
    
    // Generate host secret
    const hostSecret = generateHostSecret();
    
    // Replace placeholders with production values
    envContent = envContent
        .replace('PORT=3000', `PORT=${HOST_CONFIG.port}`)
        .replace('BIND=127.0.0.1', `BIND=${HOST_CONFIG.bind}`)
        .replace('YOUR_HOST_SHARED_SECRET_HERE_CHANGE_THIS', hostSecret)
        .replace('localhost', HOST_CONFIG.ip)
        .replace('your_secure_password_here', 'CHANGE_THIS_IN_PRODUCTION')
        .replace('ec_admin_host', 'ec_admin_host');
    
    // Write .env
    fs.writeFileSync(envPath, envContent);
    console.log('✅ Created .env file with auto-configuration');
    
    // Save the secret to a file for config.lua sync
    const secretPath = path.join(__dirname, '.host-secret');
    fs.writeFileSync(secretPath, hostSecret, 'utf-8');
    console.log('✅ Saved host secret to .host-secret');
    
    return hostSecret;
}

// Update config.lua with host secret
function updateConfigLua(hostSecret) {
    const configPath = path.join(__dirname, '..', '..', 'config.lua');
    
    if (!fs.existsSync(configPath)) {
        console.log('⚠️  config.lua not found, will be created by setup wizard');
        return;
    }
    
    let configContent = fs.readFileSync(configPath, 'utf-8');
    
    // Update Config.HostApi.secret
    configContent = configContent.replace(
        /secret = "YOUR_HOST_SHARED_SECRET"/,
        `secret = "${hostSecret}"`
    );
    
    // Enable HostApi if not already enabled
    configContent = configContent.replace(
        /Config\.HostApi = \{[\s\S]*?enabled = false/,
        (match) => match.replace('enabled = false', 'enabled = true')
    );
    
    fs.writeFileSync(configPath, configContent);
    console.log('✅ Updated config.lua with host secret and enabled HostApi');
}

// Main auto-configuration
function autoConfigureHost() {
    console.log('🔧 Starting host auto-configuration...');
    console.log('');
    
    // Check environment
    const envExists = checkEnvFile();
    
    let hostSecret;
    
    if (!envExists) {
        // Create .env with auto-config
        hostSecret = createEnvFile();
        
        // Sync with config.lua
        if (hostSecret) {
            updateConfigLua(hostSecret);
        }
    } else {
        // Read existing secret
        const secretPath = path.join(__dirname, '.host-secret');
        if (fs.existsSync(secretPath)) {
            hostSecret = fs.readFileSync(secretPath, 'utf-8').trim();
            console.log('ℹ️  Using existing host secret');
        } else {
            console.log('⚠️  .env exists but .host-secret missing');
            console.log('⚠️  You may need to manually sync the HOST_SECRET between .env and config.lua');
        }
    }
    
    console.log('');
    console.log('╔════════════════════════════════════════════════════════╗');
    console.log('║   Host Configuration Summary                           ║');
    console.log('╠════════════════════════════════════════════════════════╣');
    console.log(`║   Host IP:        ${HOST_CONFIG.ip.padEnd(33)}║`);
    console.log(`║   Domain:         ${HOST_CONFIG.domain.padEnd(33)}║`);
    console.log(`║   Bind Address:   ${HOST_CONFIG.bind.padEnd(33)}║`);
    console.log(`║   API Port:       ${HOST_CONFIG.port.toString().padEnd(33)}║`);
    console.log(`║   FiveM Port:     ${HOST_CONFIG.fivemPort.toString().padEnd(33)}║`);
    console.log('║   Unlock Password: *** (hidden)                        ║');
    console.log('║   Host Secret:    *** (synced with config.lua)         ║');
    console.log('╠════════════════════════════════════════════════════════╣');
    console.log('║   Security Status:                                     ║');
    console.log('║   ✅ Localhost-only binding                            ║');
    console.log('║   ✅ Secret header protection                          ║');
    console.log('║   ✅ Password-protected unlock (5-tap)                 ║');
    console.log('║   ⚠️  Google OAuth required (setup in wizard)          ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    console.log('');
    console.log('📋 Next Steps:');
    console.log('   1. Run setup.bat to build UI and start wizard');
    console.log('   2. Complete 5-tap unlock with password: ***');
    console.log('   3. Complete Google OAuth in wizard');
    console.log('   4. Enter license key for validation');
    console.log('   5. Build all 20 APIs');
    console.log('');
    console.log('🔒 Customer builds will NOT include:');
    console.log('   - /host/ folder');
    console.log('   - Host configuration details');
    console.log('   - Unlock password');
    console.log('   - Master API keys');
    console.log('');
    
    // Return config for use by server.js
    return {
        ...HOST_CONFIG,
        hostSecret: hostSecret || 'NOT_CONFIGURED'
    };
}

// Export configuration
module.exports = {
    autoConfigureHost,
    HOST_CONFIG,
    generateHostSecret
};

// Run if called directly
if (require.main === module) {
    autoConfigureHost();
}