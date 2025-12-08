# EC Admin Ultimate - Complete Testing Checklist

## Pre-Testing Setup

### ✅ Framework Detection
- [ ] Test with **QB-Core** (qb-core)
- [ ] Test with **QBX** (qbx_core)
- [ ] Test with **ESX** (es_extended)
- [ ] Test with **ox_core**
- [ ] Test in **Standalone mode** (no framework)

### ✅ Dependencies
- [ ] Verify `oxmysql` is running
- [ ] Verify `ox_lib` is running
- [ ] Check server console for dependency warnings

### ✅ Configuration
- [ ] Verify correct config loads (host.config.lua vs customer.config.lua)
- [ ] Check `Config.LogNUIErrors = true` is set
- [ ] Verify webhook URLs are configured (if using)
- [ ] Check owner identifiers are set correctly

---

## 1. Resource Startup & Initialization

### Server-Side
- [ ] Resource starts without errors
- [ ] Logger loads first (check console for `[Logger] Centralized logging system loaded`)
- [ ] Framework detection works (check console for `[EC Framework] Detected...`)
- [ ] Database migrations run successfully
- [ ] All server scripts load in correct order
- [ ] No Lua errors in server console

### Client-Side
- [ ] Client scripts load without errors
- [ ] NUI error handler loads (check console for `[NUI Error Handler] NUI error logging system loaded`)
- [ ] Error handler loads (check console for `✅ Client error handler loaded`)
- [ ] No client-side Lua errors

### NUI/UI
- [ ] UI loads without errors
- [ ] No React errors in browser console (F8 in-game)
- [ ] Global error handler is active
- [ ] Error boundary is working

---

## 2. Framework Compatibility Testing

### QB-Core Framework
- [ ] Player data loads correctly (name, job, money)
- [ ] Player actions work (kick, ban, teleport, etc.)
- [ ] Money operations work (add/remove cash/bank)
- [ ] Job/Gang operations work
- [ ] Inventory operations work
- [ ] Vehicle operations work

### QBX Framework
- [ ] Player data loads correctly
- [ ] All QB-Core features work
- [ ] QBX-specific features work (if any)

### ESX Framework
- [ ] Player data loads correctly
- [ ] ESX job system works
- [ ] ESX money system works (money/bank accounts)
- [ ] ESX inventory works
- [ ] ESX vehicle system works

### ox_core Framework
- [ ] Player data loads correctly
- [ ] ox_core identity system works
- [ ] ox_core groups/jobs work
- [ ] ox_core money system works

### Standalone Mode
- [ ] Resource works without any framework
- [ ] Basic player operations work (kick, ban, etc.)
- [ ] No framework-dependent features crash
- [ ] Graceful fallbacks work

---

## 3. UI Pages & Navigation

### Dashboard
- [ ] Page loads without errors
- [ ] Server metrics display correctly (TPS, memory, CPU, etc.)
- [ ] Player count updates in real-time
- [ ] Resource count displays correctly
- [ ] Historical metrics chart loads
- [ ] **Quick Actions Widget displays 16 actions**
- [ ] **Quick Actions work from dashboard**
- [ ] **"View All" button opens Quick Actions Center**
- [ ] No NUI errors in server console

### Players Page
- [ ] Player list loads
- [ ] Player data displays correctly (name, job, ping, etc.)
- [ ] Search/filter works
- [ ] Sorting works
- [ ] Clicking player opens profile
- [ ] Real-time updates work
- [ ] **Player actions (kick, ban) use quick actions system**

### Player Profile
- [ ] Profile loads for selected player
- [ ] All player data displays (job, money, inventory, etc.)
- [ ] Framework-specific data shows correctly
- [ ] **Actions work (kick, ban, teleport) - synced with quick actions**
- [ ] Inventory tab works
- [ ] Vehicle tab works

### Vehicles Page
- [ ] Vehicle list loads
- [ ] Vehicle data displays (model, plate, owner, etc.)
- [ ] Search/filter works
- [ ] Vehicle actions work (delete, teleport, etc.)
- [ ] Spawn vehicle works
- [ ] Real-time updates work
- [ ] **Vehicle actions synced with quick actions**

### Moderation Page
- [ ] Bans list loads
- [ ] Warnings list loads
- [ ] Create ban works
- [ ] Remove ban works
- [ ] Create warning works
- [ ] Reports list loads
- [ ] Report actions work
- [ ] **Ban/Kick actions synced with quick actions**

### Anticheat Page
- [ ] Detection logs load
- [ ] AI detection data displays
- [ ] Detection actions work
- [ ] Settings save correctly

### Settings Page
- [ ] Settings page loads
- [ ] All settings categories work
- [ ] Settings save correctly
- [ ] Settings persist after restart

### Quick Actions
- [ ] **Quick actions panel opens from dashboard**
- [ ] **Quick actions panel opens from menu**
- [ ] **All 60+ quick actions available**
- [ ] **All quick actions work**
- [ ] **Actions execute correctly**
- [ ] **Success/error messages display**
- [ ] **Actions sync across all pages**

### Admin Profile
- [ ] Admin profile loads
- [ ] Profile data displays correctly
- [ ] Update profile works
- [ ] Change password works
- [ ] Preferences save
- [ ] **Quick actions widget works from admin profile**

### Economy & Global Tools
- [ ] Economy stats display
- [ ] Global actions work (give money, items, etc.)
- [ ] Economy tools execute correctly
- [ ] **Money/item actions synced with quick actions**

### Jobs & Gangs
- [ ] Jobs list loads
- [ ] Gangs list loads
- [ ] Set job works
- [ ] Set gang works
- [ ] Framework-specific job/gang data shows

### Inventory Management
- [ ] Player inventory loads
- [ ] Add item works
- [ ] Remove item works
- [ ] Item search works
- [ ] Framework-specific inventory works

### Housing
- [ ] Housing list loads
- [ ] Housing data displays
- [ ] Housing actions work

### Whitelist
- [ ] Whitelist page loads
- [ ] Whitelist entries display
- [ ] Add to whitelist works
- [ ] Remove from whitelist works
- [ ] Whitelist settings work

### Server Monitor
- [ ] Resource list loads
- [ ] Resource status displays correctly
- [ ] Start/stop resource works
- [ ] Restart resource works
- [ ] Server metrics display

### System Management
- [ ] System info displays
- [ ] Performance metrics show
- [ ] System actions work
- [ ] Backup/restore works (if implemented)

### Dev Tools
- [ ] Dev tools page loads
- [ ] Dev tools work correctly
- [ ] No errors in console

### Community
- [ ] Community page loads
- [ ] Community features work

---

## 4. Error Handling & Logging

### NUI Error Logging
- [ ] React errors are caught and logged to server
- [ ] Fetch errors are caught and logged
- [ ] Console errors are caught and logged
- [ ] Unhandled promise rejections are caught
- [ ] All errors appear in server console with `[NUI ERROR]` prefix
- [ ] Error details include stack traces

### Server Error Logging
- [ ] Server errors are logged via Logger
- [ ] Error format is correct
- [ ] Errors include timestamps
- [ ] Log level filtering works

### Client Error Logging
- [ ] Client errors are caught
- [ ] Errors are logged to server
- [ ] Error handler doesn't crash

---

## 5. Permissions & Security

### Permission System
- [ ] Permission checks work
- [ ] Unauthorized actions are blocked
- [ ] Permission levels work correctly
- [ ] Owner permissions work

### Framework Integration
- [ ] Framework admin groups are detected
- [ ] Framework permissions work
- [ ] Standalone permissions work

### Security
- [ ] SQL injection protection works
- [ ] Input validation works
- [ ] XSS protection works (NUI)

---

## 6. Database Operations

### Database Connection
- [ ] Database connects successfully
- [ ] Migrations run on startup
- [ ] No SQL errors

### Data Operations
- [ ] Player data saves correctly
- [ ] Player data loads correctly
- [ ] Ban data saves/loads
- [ ] Warning data saves/loads
- [ ] Settings save/load
- [ ] All tables exist and are correct

---

## 7. Real-Time Updates

### Live Data
- [ ] Dashboard updates in real-time
- [ ] Player list updates in real-time
- [ ] Server metrics update
- [ ] No performance issues with updates

### NUI Callbacks
- [ ] All NUI callbacks respond
- [ ] Callback errors are handled
- [ ] Timeout handling works

---

## 8. Performance Testing

### Server Performance
- [ ] No server lag with admin panel open
- [ ] Resource usage is acceptable
- [ ] Database queries are optimized
- [ ] No memory leaks

### Client Performance
- [ ] No FPS drops with admin panel open
- [ ] UI is responsive
- [ ] No client-side lag

### NUI Performance
- [ ] UI loads quickly
- [ ] No UI freezing
- [ ] Smooth animations
- [ ] Efficient re-renders

---

## 9. Cross-Framework Feature Testing

### Money Operations
- [ ] Add money works (all frameworks)
- [ ] Remove money works (all frameworks)
- [ ] Set money works (all frameworks)
- [ ] Cash and bank work correctly

### Job/Gang Operations
- [ ] Set job works (all frameworks)
- [ ] Set gang works (QB/QBX)
- [ ] Job grade works (all frameworks)

### Inventory Operations
- [ ] Add item works (all frameworks)
- [ ] Remove item works (all frameworks)
- [ ] Framework-specific inventory works

### Vehicle Operations
- [ ] Spawn vehicle works
- [ ] Delete vehicle works
- [ ] Teleport to vehicle works
- [ ] Framework-specific vehicle data works

---

## 10. Edge Cases & Error Scenarios

### Invalid Input
- [ ] Invalid player IDs are handled
- [ ] Invalid amounts are handled
- [ ] Invalid item names are handled
- [ ] Empty inputs are handled

### Missing Data
- [ ] Missing player data is handled
- [ ] Missing framework data is handled
- [ ] Missing config values are handled

### Network Issues
- [ ] Database connection loss is handled
- [ ] NUI callback timeouts are handled
- [ ] API failures are handled

### Framework Issues
- [ ] Framework not detected is handled
- [ ] Framework functions fail gracefully
- [ ] Standalone mode works when framework missing

---

## 11. Host Mode Testing (If Applicable)

### Host Detection
- [ ] Host mode is detected correctly
- [ ] Host config loads correctly
- [ ] Host dashboard is accessible
- [ ] NRG staff detection works

### Host Features
- [ ] Host API works
- [ ] Host dashboard loads
- [ ] Host-specific features work

---

## 12. Configuration Testing

### Config Loading
- [ ] Host config loads in host mode
- [ ] Customer config loads in customer mode
- [ ] Config values are correct
- [ ] Config changes take effect

### Webhooks
- [ ] Webhooks are configured correctly
- [ ] Webhook URLs are valid
- [ ] Webhook toggles work
- [ ] Webhook messages send correctly

---

## 13. Quick Actions Synchronization Testing

### Dashboard Quick Actions
- [ ] Quick actions widget displays on dashboard
- [ ] Actions execute correctly from dashboard
- [ ] Quick Actions Center opens from dashboard
- [ ] All 60+ actions available in center

### Player Actions Sync
- [ ] Kick works from Players page
- [ ] Kick works from Player Profile
- [ ] Kick works from Moderation page
- [ ] Kick works from Quick Actions
- [ ] All kick actions use same system

### Teleport Actions Sync
- [ ] "Teleport to Player" works from Players page
- [ ] "Teleport to Player" works from Player Profile
- [ ] "Teleport to Player" works from Quick Actions
- [ ] "Bring Player" works from all locations
- [ ] "TPM" works from all locations

### Vehicle Actions Sync
- [ ] Spawn vehicle works from Vehicles page
- [ ] Spawn vehicle works from Dashboard
- [ ] Spawn vehicle works from Quick Actions
- [ ] Fix/Delete vehicle works from all locations

### Economy Actions Sync
- [ ] Give money works from Player Profile
- [ ] Give money works from Economy Tools
- [ ] Give money works from Quick Actions
- [ ] All money/item actions sync

---

## 14. Final Verification

### Console Checks
- [ ] No errors in server console
- [ ] No errors in client console (F8)
- [ ] No errors in browser console (if testing UI)
- [ ] All warnings are acceptable

### Functionality
- [ ] All major features work
- [ ] All frameworks work
- [ ] Standalone mode works
- [ ] No critical bugs

### Documentation
- [ ] README is accurate
- [ ] Config comments are clear
- [ ] Code comments are helpful

---

## Testing Notes

**Framework Test Order:**
1. Standalone (no framework)
2. QB-Core
3. QBX
4. ESX
5. ox_core

**Critical Paths to Test:**
1. Resource startup
2. Framework detection
3. Player data loading
4. Basic actions (kick, ban, teleport)
5. Money operations
6. Inventory operations
7. Vehicle operations
8. Error handling
9. **Quick actions synchronization**

**Known Issues to Watch:**
- GetPlayers() returns strings, must use tonumber()
- Framework detection may take a few seconds
- NUI errors should appear in server console
- Some frameworks may have different function names

---

## Post-Testing

- [ ] Document any bugs found
- [ ] Document any framework-specific issues
- [ ] Document performance issues
- [ ] Create bug reports for critical issues
- [ ] Update this checklist with findings

---

**Last Updated:** [Date]  
**Tested By:** [Name]  
**Framework Versions Tested:**
- QB-Core: [Version]
- QBX: [Version]
- ESX: [Version]
- ox_core: [Version]
