#!/usr/bin/env node

/**
 * EC Admin Ultimate - FiveM Production Deployment Script
 * 
 * This script takes the Vite build output and prepares it for FiveM deployment
 * by copying backend files and creating the proper directory structure.
 */

import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.dirname(__dirname);

console.log('🚀 Preparing EC Admin Ultimate for FiveM deployment...');

const buildDir = path.join(rootDir, 'dist');
const htmlDir = path.join(buildDir, 'html');

// Create directories
async function createDirectories() {
    const dirs = [
        buildDir,
        path.join(buildDir, 'client'),
        path.join(buildDir, 'server'),
        path.join(buildDir, 'shared')
    ];

    for (const dir of dirs) {
        await fs.mkdir(dir, { recursive: true });
    }
}

// Copy files recursively
async function copyRecursive(src, dest) {
    try {
        const stats = await fs.stat(src);
        
        if (stats.isDirectory()) {
            await fs.mkdir(dest, { recursive: true });
            const files = await fs.readdir(src);
            
            for (const file of files) {
                await copyRecursive(
                    path.join(src, file),
                    path.join(dest, file)
                );
            }
        } else {
            await fs.copyFile(src, dest);
        }
    } catch (error) {
        console.warn(`Warning: Could not copy ${src}: ${error.message}`);
    }
}

// Copy backend files
async function copyBackendFiles() {
    console.log('📁 Copying backend files...');
    
    const backendSrc = path.join(rootDir, '..'); // Go up to get backend files
    
    // Copy all backend files to dist root
    try {
        // Copy server files
        const serverFiles = ['server', 'client', 'shared', 'config.lua', 'config-enhanced.lua', 'fxmanifest.lua', 'install.sql'];
        
        for (const file of serverFiles) {
            const srcPath = path.join(backendSrc, file);
            const destPath = path.join(buildDir, file);
            await copyRecursive(srcPath, destPath);
        }
    } catch (error) {
        console.warn('Warning: Backend directory not found, using fallback files');
        
        // Create minimal fallback files
        await createFallbackFiles();
    }
}

// Create fallback files if backend directory doesn't exist
async function createFallbackFiles() {
    console.log('📝 Creating fallback backend files...');
    
    // Create minimal fxmanifest.lua
    const fxmanifest = `fx_version 'cerulean'
game 'gta5'

author 'NRG Development'
description 'EC Admin Ultimate - Enterprise-Grade FiveM Admin Panel'
version '1.0.0'

lua54 'yes'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

shared_scripts {
    'shared/utils.lua',
    'config.lua'
}

files {
    'html/index.html',
    'html/app.js',
    'html/app.css'
}

ui_page 'html/index.html'

dependencies {
    'mysql-async'
}

exports {
    'GetPlayerPermissionLevel',
    'HasPermission',
    'LogAdminAction'
}`;

    await fs.writeFile(path.join(buildDir, 'fxmanifest.lua'), fxmanifest);

    // Create minimal config.lua
    const config = `Config = {}

Config.Framework = 'auto' -- 'esx', 'qbcore', or 'auto'
Config.Database = 'mysql-async' -- 'mysql-async' or 'oxmysql'

Config.AdminLevels = {
    superadmin = 4,
    admin = 3,
    moderator = 2,
    helper = 1
}

Config.Webhooks = {
    admin_actions = '',
    bans = '',
    warnings = '',
    player_reports = ''
}`;

    await fs.writeFile(path.join(buildDir, 'config.lua'), config);

    // Create minimal client script
    const clientScript = `-- EC Admin Ultimate - Client Script
RegisterCommand('admin', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'setVisible',
        visible = true
    })
end, false)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)`;

    await fs.writeFile(path.join(buildDir, 'client', 'main.lua'), clientScript);

    // Create minimal server script
    const serverScript = `-- EC Admin Ultimate - Server Script
print("^2[EC Admin Ultimate] ^7Server script loaded successfully")

RegisterNetEvent('ec-admin:requestPermissionLevel')
AddEventHandler('ec-admin:requestPermissionLevel', function()
    local source = source
    -- Add your permission logic here
    TriggerClientEvent('ec-admin:permissionLevel', source, 'admin')
end)`;

    await fs.writeFile(path.join(buildDir, 'server', 'main.lua'), serverScript);

    // Create minimal shared utils
    const sharedUtils = `-- EC Admin Ultimate - Shared Utilities
Utils = {}

function Utils.Round(value, decimals)
    local multiplier = 10^(decimals or 0)
    return math.floor(value * multiplier + 0.5) / multiplier
end`;

    await fs.writeFile(path.join(buildDir, 'shared', 'utils.lua'), sharedUtils);
}

// Optimize HTML file for FiveM
async function optimizeHtmlForFiveM() {
    console.log('⚡ Optimizing HTML for FiveM...');
    
    const htmlPath = path.join(htmlDir, 'index.html');
    
    try {
        let htmlContent = await fs.readFile(htmlPath, 'utf8');
        
        // Add FiveM-specific optimizations
        htmlContent = htmlContent.replace(
            '<head>',
            `<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:; connect-src 'self' https://ec-admin-ultimate;">
    <style>
        /* FiveM NUI Optimizations */
        * {
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
            -webkit-user-drag: none;
        }
        
        input, textarea, [contenteditable] {
            -webkit-user-select: text;
            -moz-user-select: text;
            -ms-user-select: text;
            user-select: text;
        }
        
        html, body {
            overflow: hidden;
            margin: 0;
            padding: 0;
            width: 100vw;
            height: 100vh;
            background: transparent;
        }
        
        #root {
            width: 100%;
            height: 100%;
        }
    </style>`
        );

        // Add NUI communication script before closing body tag
        const nuiScript = `
    <script>
        // NUI Communication Setup
        window.addEventListener('message', function(event) {
            const data = event.data;
            
            if (data.type === 'setVisible') {
                document.body.style.display = data.visible ? 'block' : 'none';
            }
            
            if (data.type === 'updateData') {
                window.dispatchEvent(new CustomEvent('fivemDataUpdate', {
                    detail: data.payload
                }));
            }
        });
        
        window.postNUI = function(type, data = {}) {
            fetch(\`https://ec-admin-ultimate/\${type}\`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            }).catch(err => {
                console.warn('NUI POST failed (normal in browser):', err.message);
            });
        };
        
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                event.preventDefault();
                window.postNUI('close');
            }
        });
    </script>`;

        htmlContent = htmlContent.replace('</body>', nuiScript + '\n</body>');
        
        await fs.writeFile(htmlPath, htmlContent);
        
    } catch (error) {
        console.warn('Warning: Could not optimize HTML file:', error.message);
    }
}

// Validate build output
async function validateBuild() {
    console.log('✅ Validating build output...');
    
    const requiredFiles = [
        'fxmanifest.lua',
        'config.lua',
        'client/main.lua',
        'server/main.lua',
        'html/index.html'
    ];

    const missingFiles = [];
    
    for (const file of requiredFiles) {
        const filePath = path.join(buildDir, file);
        try {
            await fs.access(filePath);
        } catch {
            missingFiles.push(file);
        }
    }

    if (missingFiles.length > 0) {
        console.error('❌ Missing required files:', missingFiles);
        process.exit(1);
    }

    // Check if HTML assets exist
    try {
        const htmlFiles = await fs.readdir(htmlDir);
        const hasJs = htmlFiles.some(f => f.endsWith('.js'));
        const hasCss = htmlFiles.some(f => f.endsWith('.css'));
        
        if (!hasJs || !hasCss) {
            console.warn('⚠️  Warning: Missing compiled assets (JS/CSS). Make sure to run "npm run build" first.');
        }
    } catch {
        console.error('❌ HTML directory not found. Build may have failed.');
        process.exit(1);
    }
}

// Main execution
async function main() {
    try {
        await createDirectories();
        await copyBackendFiles();
        await optimizeHtmlForFiveM();
        await validateBuild();
        
        console.log('');
        console.log('✅ FiveM deployment package ready!');
        console.log('📁 Output directory:', buildDir);
        console.log('');
        console.log('🚀 DEPLOYMENT INSTRUCTIONS:');
        console.log('1. Copy the entire "dist" folder to your FiveM resources directory');
        console.log('2. Rename "dist" to "ec-admin-ultimate"');
        console.log('3. Add "ensure ec-admin-ultimate" to your server.cfg');
        console.log('4. Configure database settings if needed');
        console.log('5. Restart your FiveM server');
        console.log('');
        console.log('🎮 In-game: Use F5 or /admin command to open the panel');
        
    } catch (error) {
        console.error('❌ Build failed:', error.message);
        process.exit(1);
    }
}

main();