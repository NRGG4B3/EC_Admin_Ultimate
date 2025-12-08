# EC Admin Ultimate - Build Instructions

## Overview

This resource has **two build outputs**:
1. **Host Release** - For NRG internal use (includes host/ folder, host.config.lua)
2. **Customer Release** - For distribution (customer.config.lua → config.lua, no host folder)

---

## Quick Start

### Build Both Releases
```batch
build-release.bat
```

This will:
- ✅ Build UI for both host and customer
- ✅ Create customer ZIP (ready for distribution)
- ✅ Keep host files unchanged in workspace

---

## Build Process

### 1. UI Build
- Builds React UI to `ui/dist/`
- Used by both host and customer releases

### 2. Host Release
- **Location:** Current workspace (all files)
- **Config:** `host.config.lua` (unchanged)
- **Includes:** `host/` folder with APIs
- **Ready to use:** Yes, immediately after build

### 3. Customer Release
- **Location:** `ec_admin_ultimate_customer_release/` folder
- **ZIP:** `EC_Admin_Ultimate_Customer_v1.0.0.zip`
- **Config:** `config.lua` (copied from `customer.config.lua`)
- **Excludes:** 
  - ❌ `host/` folder
  - ❌ `host.config.lua`
  - ❌ Build scripts
  - ❌ Documentation files
- **Includes:** API connection documentation

---

## Host API Server

### Location
- **APIs:** `host/api/`
- **Start Script:** `host/start-apis.bat`
- **Stop Script:** `host/stop-apis.bat`

### Starting APIs
```batch
cd host
start-apis.bat
```

This will:
1. Check for Node.js
2. Install dependencies (if needed)
3. Create `.env` from `.env.example` (if needed)
4. Start the API server on port 3000

### Stopping APIs
```batch
cd host
stop-apis.bat
```

This will:
1. Find and stop API server processes
2. Optionally kill all Node.js processes (if needed)

### API Configuration
1. Copy `host/api/.env.example` to `host/api/.env`
2. Configure:
   - `PORT` - API server port (default: 3000)
   - `API_MASTER_KEY` - Master API key for authentication
   - `JWT_SECRET` - JWT signing secret
   - Other service-specific keys (optional)

---

## Customer API Connection

### How It Works
- **Customer servers** connect to **host APIs** via HTTPS
- **No Node.js required** on customer servers
- Customer servers use `config.lua` (from `customer.config.lua`)
- API endpoints: `https://api.ecbetasolutions.com`

### Available APIs
1. **Monitoring API** - Server monitoring and metrics
2. **Global Ban API** - Cross-server ban synchronization
3. **AI Analytics API** - Player behavior analysis
4. **NRG Staff API** - Staff verification
5. **Remote Admin API** - Remote administration
6. **Self-Heal API** - Automatic issue detection
7. **Update Checker API** - Version updates

### Configuration
- Customer `config.lua` is pre-configured with API endpoints
- Customers only need to set their API key
- No additional setup required

---

## File Structure

### Host Release (Workspace)
```
ec_admin_ultimate/
├── host/                    ← Host-only folder
│   ├── api/                 ← Node.js APIs
│   │   ├── server.js        ← Main API server
│   │   ├── package.json     ← Node.js dependencies
│   │   └── services/         ← API services
│   ├── start-apis.bat       ← Start API server
│   └── stop-apis.bat        ← Stop API server
├── host.config.lua          ← Host config (unchanged)
├── customer.config.lua      ← Customer config (source)
├── config.lua               ← Dynamic loader
└── ... (all other files)
```

### Customer Release (ZIP)
```
EC_Admin_Ultimate_Customer_v1.0.0.zip
├── config.lua               ← From customer.config.lua
├── fxmanifest.lua
├── server/                  ← Server scripts
├── client/                  ← Client scripts
├── shared/                  ← Shared scripts
├── ui/dist/                ← Built UI
├── API_CONNECTION.md        ← API documentation
└── ... (all other files)
   ❌ NO host/ folder
   ❌ NO host.config.lua
   ❌ NO build scripts
```

---

## Build Script Details

### `build-release.bat`
- **Purpose:** Unified build for host and customer
- **Outputs:**
  - Host: Workspace files (unchanged)
  - Customer: ZIP file ready for distribution
- **Excludes from customer:**
  - `host/` folder
  - `host.config.lua`
  - Build scripts
  - Documentation files
  - `.env` files

---

## API Server Details

### `host/start-apis.bat`
- Checks Node.js installation
- Installs dependencies (if needed)
- Creates `.env` from `.env.example` (if needed)
- Starts API server

### `host/stop-apis.bat`
- Finds API server processes
- Stops them gracefully
- Option to kill all Node.js processes

### `host/api/server.js`
- Express server
- All 7 API services
- Health check endpoint
- Error handling
- Rate limiting
- CORS enabled

---

## Important Notes

### Host Files
- **Keep original names:** `host.config.lua`, `host/` folder
- **APIs run separately:** Use `start-apis.bat` to start
- **Node.js required:** Only on host server (for APIs)

### Customer Files
- **Config renamed:** `customer.config.lua` → `config.lua`
- **No host folder:** Completely excluded
- **No Node.js needed:** Customers connect to host APIs
- **API endpoints:** Pre-configured in `config.lua`

---

## Troubleshooting

### Build Fails
- Check Node.js is installed: `node --version`
- Check npm is installed: `npm --version`
- Ensure you're in the resource root directory

### API Server Won't Start
- Check Node.js is installed
- Check `host/api/server.js` exists
- Check `host/api/package.json` exists
- Run `npm install` manually in `host/api/`

### Customer ZIP Missing Files
- Check `customer.config.lua` exists
- Verify robocopy completed successfully
- Check ZIP was created in root directory

---

**Last Updated:** [Current Date]  
**Build Script:** `build-release.bat`  
**API Start:** `host/start-apis.bat`  
**API Stop:** `host/stop-apis.bat`
