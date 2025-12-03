# 🎮 EC ADMIN ULTIMATE v3.5.0

**The Ultimate FiveM Admin Panel** - Comprehensive admin solution with F2/F3 menus, real-time data, and complete moderation tools!

---

## 📦 **DISTRIBUTION VERSIONS:**

### **🔵 CUSTOMER VERSION (You're looking at this if no /host/ folder exists)**
- ✅ All admin panel features
- ✅ Complete UI with F2/F3 menus
- ✅ Full moderation system
- ✅ Manual setup required
- ✅ Framework-independent (works standalone)
- ✅ One SQL file installation
- ❌ No /host/ folder (NRG internal only)
- ❌ No automated setup scripts

### **🟢 HOST VERSION (NRG Internal Only)**
- ✅ Everything in Customer version
- ✅ /host/ folder with API infrastructure
- ✅ 20 API gateway system
- ✅ Automated setup.bat
- ✅ Internal NRG tools
- 🔒 **NOT included in customer distribution**

---

## ✨ **FEATURES:**

### **🎮 In-Game Menus**
- **F2** - Full admin panel (all features)
- **F3** - Quick Actions menu (51 quick powers)
- **ESC** - Close any menu (works perfectly)
- Real-time data updates
- Modern, responsive UI

### **⚡ Quick Actions (F3)**
- God Mode, NoClip, Invisible
- Teleport (TPM, Goto, Bring)
- Vehicle spawn/fix/delete
- Heal, armor, stamina
- Weather/time control
- And 40+ more actions!

### **👥 Player Management**
- Live player list
- Ban/Kick/Warn system
- Player profiles
- Spectate mode
- Teleport management
- Action history

### **🚗 Vehicle Management**
- Spawn any vehicle
- Repair/delete vehicles
- Vehicle database
- Custom vehicle pack detection
- Real-time vehicle tracking

### **💰 Economy System**
- Money management (framework-based)
- Transaction logs
- Economy statistics
- Item management

### **🛡️ Moderation**
- Advanced ban system
- Warning system
- Report handling
- Admin action logs
- Player notes

### **📊 Monitoring**
- Real-time server metrics
- Performance graphs
- Resource monitoring
- Player analytics
- AI detection system

### **⚙️ Advanced Features**
- Whitelist system
- Anti-cheat integration
- AI behavior detection
- Admin team management
- Comprehensive logging

---

## 🚀 **ZERO-CONFIG INSTALLATION:**

### ✅ **Step 1: Drop Files** (30 seconds)
```
Place EC_Admin_Ultimate in resources/[nrg]/ folder
```

### ✅ **Step 2: Configure server.cfg** (2 minutes)
```cfg
# MySQL Connection (if not already set)
set mysql_connection_string "mysql://user:password@localhost/database"

# Start EC Admin Ultimate
ensure EC_Admin_Ultimate

# Admin Permissions (optional - defaults work)
add_ace group.admin ec_admin.all allow
add_principal identifier.license:YOUR_LICENSE_HERE group.admin
```

### ✅ **Step 3: Restart Server** (1 minute)
```bash
restart your-server
```

### 🎉 **Done! All 28 tables auto-created!**

**Watch your console:**
```
[EC Admin DB] Auto-creating ALL database tables...
[EC Admin DB] ✓ ec_admin_permissions
[EC Admin DB] ✓ ec_admin_bans
[EC Admin DB] ✓ ec_admin_metrics_history
... (28 tables total)
[EC Admin DB] All 28 tables created/verified successfully
```

**Press F2 in-game** - Admin panel ready immediately!

---

### 📋 **What Gets Auto-Installed:**

- ✅ **28 Database Tables** (auto-created, no SQL import needed!)
- ✅ **Metrics System** (collects data every 60s)
- ✅ **Webhook Tracking** (Discord integration ready)
- ✅ **API Monitoring** (tracks all API calls)
- ✅ **Admin Logs** (full accountability)
- ✅ **Ban/Warn System** (ready to use)
- ✅ **Reports System** (player reports work)

### 🚫 **What You DON'T Need:**

- ❌ Manual SQL import (`sql/ec_admin_ultimate.sql` = reference only)
- ❌ phpMyAdmin/Adminer
- ❌ MySQL command line
- ❌ Table creation commands
- ❌ Migration scripts

**Everything is automatic!** 🎯

---

### � **Updating to New Version:**

```bash
# 1. Replace files (overwrite old folder)
# 2. Restart server
restart EC_Admin_Ultimate
# 3. Done! New tables auto-created if needed
```

**Console shows what's new:**
```
[EC Admin DB] 🆕 Created: 3 NEW tables
[EC Admin DB] 🎉 Database upgraded successfully!
```

**No manual SQL updates needed - EVER!** 🚀

---

### 📖 **Detailed Documentation:**

- **[INSTALLATION.md](INSTALLATION.md)** - Zero-config setup guide
- **[DATABASE_SCHEMA_DOCUMENTATION.md](DATABASE_SCHEMA_DOCUMENTATION.md)** - Database reference
- **[PRODUCTION_READY_IMPLEMENTATION.md](PRODUCTION_READY_IMPLEMENTATION.md)** - Feature documentation

---

## 🎯 **USAGE:**

### **In-Game Controls:**
```
F2                  → Open full admin panel
F3                  → Quick Actions menu
ESC                 → Close any menu
/hud                → Toggle admin panel
/ec_unlock          → Emergency unlock (if stuck)
```

### **Quick Actions (F3):**
```
Most used actions accessible instantly:
• God Mode        • NoClip          • Invisible
• Teleport (TPM)  • Vehicle Spawn   • Heal
• Weather/Time    • And 44+ more!
```

---

## 📋 **REQUIREMENTS:**

### **Essential:**
- ✅ **ox_lib** (latest version)
- ✅ **oxmysql** (latest version)
- ✅ **MySQL/MariaDB** database

### **Optional (Auto-detected):**
- ⭐ **QBCore** - Enhanced features
- ⭐ **ESX** - Enhanced features
- ⭐ **Standalone** - Works without framework!

---

## 🔐 **PERMISSIONS:**

### **Permission Levels:**

```cfg
# Full admin access (recommended)
add_ace group.admin ec_admin.all allow

# Or specific permissions:
add_ace group.moderator ec_admin.players allow      # Player management
add_ace group.moderator ec_admin.ban allow          # Ban/kick
add_ace group.moderator ec_admin.teleport allow     # Teleport
add_ace group.moderator ec_admin.vehicle allow      # Vehicles
add_ace group.moderator ec_admin.noclip allow       # NoClip
add_ace group.moderator ec_admin.god allow          # God mode
```

### **Add Admins:**
```cfg
# By license
add_principal identifier.license:abc123 group.admin

# By Steam
add_principal identifier.steam:110000123456789 group.admin

# By Discord
add_principal identifier.discord:123456789 group.admin
```

---

## 🛠️ **TROUBLESHOOTING:**

### **"Table doesn't exist" errors**
**Fix:**
1. Import `sql/ec_admin_ultimate.sql` into your database
2. Verify `mysql_connection_string` in server.cfg
3. Restart resource

### **"No permission to access admin panel"**
**Fix:**
1. Add your identifier to server.cfg (see Permissions above)
2. Restart server after config changes
3. Rejoin server

### **F2/F3 not working**
**Fix:**
1. Check resource is started: `ensure EC_Admin_Ultimate`
2. Check permissions are set
3. Try `/hud` command
4. Check console for errors

### **Menu stuck / Can't close with ESC**
**Fix:**
1. Press ESC multiple times
2. Try `/ec_unlock` command
3. Restart resource if needed

### **Standalone mode issues**
**Fix:**
- Script works WITHOUT framework
- If you have QBCore/ESX, it will auto-detect
- Ensure SQL file is imported
- Check database connection

---

## 📊 **FRAMEWORK SUPPORT:**

### **Standalone Mode (No Framework)**
```
✅ All core features work
✅ Manual database setup
✅ ACE permission system
✅ Full moderation system
⚠️ Economy features limited (no framework money)
⚠️ Job system disabled (no framework jobs)
```

### **QBCore / QBX**
```
✅ All features work
✅ Auto-detects framework
✅ Enhanced economy features
✅ Job/gang management
✅ Inventory integration
✅ Vehicle ownership tracking
```

### **ESX (Legacy & New)**
```
✅ All features work
✅ Auto-detects framework
✅ Enhanced economy features
✅ Job management
✅ Inventory integration
✅ Society integration
```

---

## 🎨 **UI FEATURES:**

### **Modern Interface:**
- 🎨 Clean, responsive design
- 📱 Works on all screen sizes
- 🌙 Dark mode optimized
- ⚡ Real-time updates
- 🎯 Intuitive navigation

### **Dashboard:**
- 📊 Live server metrics
- 👥 Online player count
- 🚗 Active vehicles
- ⚠️ System alerts
- 📈 Performance graphs

### **Quick Actions (F3):**
- 🎯 51 instant actions
- 🔄 Auto-close on some actions
- ⌨️ Keyboard shortcuts
- 🎮 Gamepad friendly
- 💨 Lightning fast

---

## 📚 **DOCUMENTATION:**

Included files:
- **CUSTOMER_SETUP.md** - Complete setup guide
- **CUSTOMER_FILES_CHECKLIST.md** - File verification
- **sql/ec_admin_ultimate.sql** - Database schema
- **config.lua** - Configuration (inline comments)

---

## 🔄 **VERSION HISTORY:**

### **v3.5.0 (Current - 2024-11-25)**
- ✅ Fixed ALL SQL table name issues (`ec_admin_*` prefix)
- ✅ Fixed ESC closing menus (F2 and F3)
- ✅ Fixed stuck cursor in standalone mode
- ✅ Single SQL file for customers (`sql/ec_admin_ultimate.sql`)
- ✅ Complete customer build script
- ✅ Framework-independent operation
- ✅ Enhanced Quick Actions (F3)
- ✅ Improved NUI focus handling

### **v3.4.0**
- ✅ F3 Quick Actions menu
- ✅ Auto-close on Quick Action execution
- ✅ 51 Quick Actions total
- ✅ Improved UI performance

### **v3.3.0**
- ✅ Complete database refactor
- ✅ Advanced reports system
- ✅ AI detection integration
- ✅ Enhanced monitoring

---

## 🎯 **FEATURE COMPARISON:**

```
┌────────────────────────┬──────────┬──────────┐
│ Feature                │ Customer │ Host     │
├────────────────────────┼──────────┼──────────┤
│ F2 Admin Panel         │ ✅       │ ✅       │
│ F3 Quick Actions       │ ✅       │ ✅       │
│ Player Management      │ ✅       │ ✅       │
│ Vehicle Management     │ ✅       │ ✅       │
│ Moderation System      │ ✅       │ ✅       │
│ Ban/Kick/Warn          │ ✅       │ ✅       │
│ Real-time Updates      │ ✅       │ ✅       │
│ Standalone Support     │ ✅       │ ✅       │
│ Framework Support      │ ✅       │ ✅       │
│ Complete UI            │ ✅       │ ✅       │
├────────────────────────┼──────────┼──────────┤
│ /host/ API Gateway     │ ❌       │ ✅       │
│ Automated Setup        │ ❌       │ ✅       │
│ 20 API Suite           │ ❌       │ ✅       │
│ NRG Internal Tools     │ ❌       │ ✅       │
└────────────────────────┴──────────┴──────────┘
```

---

## 📊 **STATS:**

```
📁 Files:           200+ Lua scripts
📊 Database Tables: 25+ tables
⚡ Quick Actions:   51 actions
🎮 Menu Systems:    F2 (full) + F3 (quick)
🔧 Permissions:     15+ permission nodes
📈 Features:        100+ admin features
```

---

## 🤝 **SUPPORT:**

### **Common Questions:**

**Q: Do I need a framework?**  
A: NO! Works standalone. QBCore/ESX support is optional.

**Q: Which SQL file do I use?**  
A: `sql/ec_admin_ultimate.sql` - That's the ONLY file you need!

**Q: Can I use this on my server?**  
A: YES! Customer version is for server owners.

**Q: Where's the /host/ folder?**  
A: Not included in customer version (NRG internal only).

**Q: Does F3 Quick Actions work?**  
A: YES! Press F3 anytime, ESC to close.

**Q: ESC not closing menus?**  
A: Fixed in v3.5.0! Press ESC once to close any menu.

---

## 📞 **CONTACT:**

- **Support**: https://discord.gg/nrg
- **Documentation**: See CUSTOMER_SETUP.md
- **Updates**: Check regularly for new versions

---

## 📄 **LICENSE:**

Copyright (c) 2024 NRG Studios  
All rights reserved.

**Customer Version** - For use on licensed servers only.

---

## 🎉 **GET STARTED:**

```bash
1. Import sql/ec_admin_ultimate.sql into database
2. Configure server.cfg (database + permissions)
3. Add "ensure EC_Admin_Ultimate.pack" to server.cfg
4. Restart server
5. Press F2 in-game for admin panel
6. Press F3 for Quick Actions
7. Enjoy! 🎮
```

---

## ✨ **FEATURES AT A GLANCE:**

### **Core Systems:**
✅ F2 Full Admin Panel  
✅ F3 Quick Actions (51 actions)  
✅ Real-time player monitoring  
✅ Complete ban/warn system  
✅ Vehicle spawner & management  
✅ Economy tools (framework-based)  
✅ Inventory management  
✅ Job/gang system  
✅ Teleport system  
✅ Spectate mode  
✅ Live server metrics  
✅ Performance monitoring  
✅ Report system  
✅ Admin logs  
✅ Whitelist system  
✅ Anti-cheat integration  

### **Quality of Life:**
✅ ESC closes all menus  
✅ Keyboard shortcuts  
✅ Auto-close Quick Actions  
✅ No stuck cursor  
✅ Clean, modern UI  
✅ Framework-independent  
✅ One SQL file setup  
✅ Clear documentation  

---

**Made with ❤️ by NRG Studios**

**Version 3.5.0** - Customer Distribution  
**Last Updated:** November 25, 2024

---

## 🔧 **QUICK REFERENCE:**

```
KEYBINDS:
  F2        → Full Admin Panel
  F3        → Quick Actions
  ESC       → Close Menu

COMMANDS:
  /hud      → Toggle panel
  /ec_unlock → Emergency unlock

PERMISSIONS:
  ec_admin.all → Full access (recommended)

SQL FILE:
  sql/ec_admin_ultimate.sql → Import this!

SUPPORT:
  discord.gg/nrg
```

---

**🎮 Ready to admin? Press F2 to get started!**
