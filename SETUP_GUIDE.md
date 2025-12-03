# EC_Admin_Ultimate - Setup Guide

## Prerequisites

Before running setup, ensure you have:

- **Node.js 16+** - [Download](https://nodejs.org/)
- **npm 7+** (comes with Node.js)
- **PowerShell 5.0+** (for ZIP creation)
- **Windows (for .bat files)** or Linux/Mac (use equivalent shell scripts)

Verify installation:
```bash
node --version
npm --version
```

## Quick Setup

### Step 1: Run Setup Script

Navigate to the project root and run:

```bash
cd host
setup.bat
```

This will automatically:
1. ✓ Check Node.js and npm
2. ✓ Install UI dependencies
3. ✓ Build the UI with Vite
4. ✓ Install Host API dependencies
5. ✓ Create release package
6. ✓ Generate ZIP archive
7. ✓ Create `.env` configuration file

### Step 2: Configure Host API

Edit `.env` file for Host API:

```bash
host\node-server\.env
```

Update these values:
- `DB_HOST` - Your database host (default: localhost)
- `DB_PORT` - Database port (default: 3306)
- `DB_NAME` - Database name (default: ec_admin_host)
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password
- `JWT_SECRET` - Random JWT secret (generate a new one)
- `API_KEY` - API key for authentication

### Step 3: Start the Server

```bash
host\start.bat
```

The server will:
- Start Node.js API server on port 30121
- Load configuration from `.env`
- Connect to database
- Serve static UI files

## Build Process Explained

### UI Build (Vite)

The setup script builds the React UI using Vite:

```bash
cd ui
npm install      # Install dependencies
npm run build    # Build for production
```

This creates the optimized `ui/dist` folder containing:
- `index.html` - Main entry point
- `assets/` - JavaScript bundles
- `assets/` - CSS stylesheets
- `assets/` - Images and fonts

**Output:** `ui/dist/` folder (~500KB-2MB minified)

### API Build

Host Node.js server dependencies are installed:

```bash
cd host/node-server
npm install --production  # Production dependencies only
```

## Troubleshooting

### "UI didn't open" / "UI is blank"

**Cause:** UI dist files not found or not properly packaged

**Fix:**
1. Verify `ui/dist/index.html` exists after setup
2. Run setup again: `host\setup.bat`
3. Check for npm install errors in console output

**Manual fix:**
```bash
cd ui
npm install
npm run build
cd ..
```

### "npm not found"

**Cause:** Node.js not installed or PATH not updated

**Fix:**
1. Download Node.js from https://nodejs.org/
2. Install with default settings (adds npm to PATH)
3. Restart terminal/command prompt
4. Verify: `npm --version`

### "Port 30121 already in use"

**Cause:** Host API already running on that port

**Fix:**
1. Stop other EC_Admin instances
2. Or change port in `.env`: `PORT=30122`
3. Restart with `host\start.bat`

### "Database connection failed"

**Cause:** `.env` database credentials incorrect

**Fix:**
1. Verify database is running
2. Check credentials in `.env`
3. Test connection manually:
   ```bash
   mysql -h localhost -u root -p ec_admin_host
   ```

### "ZIP creation failed"

**Cause:** PowerShell execution policy restricted

**Fix:**
1. Run PowerShell as Administrator
2. Execute: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Run setup again

## File Structure After Setup

```
EC_Admin_Ultimate/
├── client/                 # Client scripts
├── server/                 # Server scripts
├── shared/                 # Shared resources
├── sql/                    # Database schemas
├── ui/
│   ├── src/               # React source code
│   ├── dist/              # Built UI (for FiveM)
│   ├── package.json
│   └── tsconfig.json
├── host/
│   ├── node-server/       # Host API server
│   ├── release/           # Release package
│   ├── setup.bat          # Setup script (this file)
│   ├── start.bat          # Start script
│   └── stop.bat           # Stop script
├── fxmanifest.lua         # FiveM manifest
└── config.lua             # Main configuration
```

## Deployment

After setup completes:

1. **Release package created:** `host/release/EC_Admin_Ultimate/`
2. **ZIP archive created:** `release.zip`

### To deploy:

1. Upload `release.zip` to your FiveM server's `resources` folder
2. Extract the ZIP file
3. Add to `server.cfg`:
   ```
   ensure EC_Admin_Ultimate
   ```
4. Restart server

## Advanced Options

### Build UI manually

```bash
cd ui
npm install
npm run build          # Production build
npm run dev            # Development with hot reload
```

### Clean and rebuild everything

```bash
cd host
rmdir /s /q ui\node_modules
rmdir /s /q host\node-server\node_modules
rmdir /s /q host\release
del release.zip
setup.bat              # Full rebuild
```

### Start Host API manually

```bash
cd host/node-server
npm install --production
node index.js
```

## Support

If you encounter issues:

1. Check the console output for specific error messages
2. Verify all prerequisites are installed
3. Review `.env` configuration
4. Check logs in `host/logs/` folder
5. Ensure sufficient disk space for builds

## Next Steps

1. ✓ Run `host/setup.bat` - Complete
2. ✓ Configure `host/node-server/.env` - Required
3. ✓ Run `host/start.bat` - To start server
4. ✓ Upload to FiveM server - When ready

---

**Version:** 1.0  
**Last Updated:** December 3, 2025  
**UI Framework:** React 18.3.1 + Vite + TypeScript  
**API Runtime:** Node.js 16+  
