# EC Admin Ultimate - Critical Setup Guide

## Problems Fixed This Session

✅ **Missing SQL Tables** - Fixed with auto-migration script
✅ **Webhook Spam (429 errors)** - Fixed with rate limiting  
✅ **Missing host-revenue-callbacks.lua** - Created
✅ **Database auto-setup** - Now runs automatically on startup
✅ **Export warnings** - host-api-connector loads before host-nrg-auth

## What You Need To Do

### 1. Run Setup Script (If Haven't Already)

```bash
cd host
setup-final.bat
```

This will:
- ✓ Build the UI
- ✓ Install dependencies  
- ✓ Create release package
- ✓ Create .env file

### 2. Configure Database in `.env`

**File:** `host/node-server/.env`

```
DB_HOST=localhost      # Your MySQL server IP/hostname
DB_PORT=3306           # MySQL port (default 3306)
DB_USER=root           # MySQL username
DB_PASSWORD=password   # Your MySQL password
DB_NAME=qbox_00bad4    # Your database name
```

### 3. Import SQL (One-Time Setup)

**Option A: Automatic (Recommended)**
- Just start the server, SQL will auto-import!
- The new `sql-auto-migration.lua` runs automatically

**Option B: Manual**
- Import `sql/ec_admin_ultimate.sql` into your database manually
- Run: `mysql -h localhost -u root -p yourdb < sql/ec_admin_ultimate.sql`

### 4. Start the Server

```bash
host/start.bat
```

Wait 10-15 seconds for:
- ✓ Database connection  
- ✓ SQL tables created
- ✓ Admin panel ready

### 5. Test Admin Access

In-game, press the admin menu key (configured in `config.lua`).

You should see:
- ✓ Dashboard loads (NO "host dashboard not found")
- ✓ No SQL errors in console  
- ✓ UI displays properly

---

## File Changes Made This Session

### New Files Created
1. **`server/host-revenue-callbacks.lua`** - Revenue tracking callbacks (was missing)
2. **`server/database/sql-auto-migration.lua`** - Auto-imports SQL schemas on startup

### Files Modified
1. **`fxmanifest.lua`** - Added sql-auto-migration.lua to load order
2. **`server/action-logger.lua`** - Added webhook rate limiting to prevent 429 errors
3. **`ui/package.json`** - Added `cssesc` dependency for build system

### Known Issues Fixed
| Issue | Solution | Status |
|-------|----------|--------|
| "Unknown column 'category' in 'field list'" | SQL auto-migration creates table | ✅ |
| "Webhook spam - 429 errors" | Rate limit webhooks to 1/second | ✅ |
| "server_script not found: host-revenue-callbacks.lua" | Created the file | ✅ |
| "No export CallHostAPI" | File loads in correct order | ✅ |
| "UI not visible / Dashboard blank" | UI now builds automatically | ✅ |

---

## Database Tables Created Automatically

When server starts, these tables are created:

```
✓ ec_admin_permissions - Admin permissions
✓ ec_admin_action_logs - Action logging  
✓ ec_admin_logs - General logs
✓ ec_admin_config - Config storage
✓ ec_admin_bans - Ban system
✓ ec_admin_anticheat_logs - Anticheat logs
✓ ec_admin_ai_detections - AI detection data
✓ + 20+ more tables
```

---

## Troubleshooting

### Problem: "Unknown column 'category'"

**Solution:**
1. Check that `sql/ec_admin_ultimate.sql` exists
2. Check server console for migration messages
3. Manually import SQL:
   ```bash
   mysql -h localhost -u root -p qbox_00bad4 < sql/ec_admin_ultimate.sql
   ```

### Problem: Webhook Still Spamming

**Solution:**
1. Check `config.lua` - disable menu click logging:
   ```lua
   Config.Discord.logMenuClicks = false
   ```
2. Or disable webhooks entirely:
   ```lua
   Config.Discord.enabled = false
   ```

### Problem: "No host dashboard at all in city"

**Solution:**
1. Check `config.lua` - ensure menu key is set:
   ```lua
   Config.MenuKey = 'F10'  -- or your preferred key
   ```
2. Make sure you're logged in as admin
3. Check permissions in database:
   ```sql
   SELECT * FROM ec_admin_permissions WHERE identifier='your_identifier';
   ```

### Problem: UI still blank

**Solution:**
1. Verify UI built: `ui/dist/index.html` should exist
2. If not, run setup again:
   ```bash
   cd host && setup-final.bat
   ```
3. Check release package includes UI:
   ```bash
   dir host\release\EC_Admin_Ultimate\ui\dist
   ```

---

## Performance Optimization

### Webhook Rate Limiting (Now Enabled)
- Maximum 1 webhook send per second
- Prevents Discord 429 "Too Many Requests" errors
- Queues are automatically managed

### Database Queries
- All logged via oxmysql for reliability
- Failed queries don't crash the server
- Check console for any errors

---

## Next Steps

1. **Configure your framework** - Edit `config.lua`
2. **Add admin staff** - Through admin panel or manually
3. **Set webhook URL** - For Discord logging
4. **Start testing** - Use test players to verify functionality

---

## Support Files

- 📖 `SETUP_GUIDE.md` - Detailed setup documentation
- 📋 `QUICK_START.md` - Quick reference guide
- 📝 `host/README_SETUP.md` - Setup scripts reference
- ✅ `SETUP_COMPLETE.md` - All changes summary

**Status: ✅ System Ready to Use**
