# 📋 EC Admin Ultimate - Action Logger Documentation

## Overview

The **Action Logger** provides comprehensive logging of ALL admin menu interactions, including:
- 🖱️ **Every UI click** (buttons, links, actions)
- 📄 **Page navigation** (dashboard → players → bans, etc.)
- 🎮 **Menu open/close events**
- 👤 **Player selection clicks**
- ⚙️ **Admin actions** (teleport, spectate, kick, ban, etc.)
- 🔧 **Config changes** (live config updates from UI)

## Three-Tier Logging System

### 1️⃣ Console Logging
- **Where**: FiveM Server Console
- **Format**: Timestamp + Admin Name/ID + Action + Details
- **Example**: `[2025-01-15 14:30:45] Admin "John Doe" [license:abc123] clicked "Teleport" on dashboard`
- **Control**: `Config.Discord.consoleLogging.enabled = true`

### 2️⃣ Discord Webhook Logging
- **Where**: Discord channel via webhook
- **Format**: Rich embeds with color-coding
- **Colors**:
  - 🔵 Blue: Menu clicks, page changes
  - 🟢 Green: Menu open/close
  - 🟡 Yellow: Player selection
  - 🔴 Red: Admin actions (teleport, kick, ban)
  - 🟣 Purple: Config changes
- **Control**: `Config.Discord.logMenuClicks = true` (per action type)

### 3️⃣ Database Logging
- **Where**: `ec_admin_action_logs` table in MySQL
- **Retention**: Permanent (for audit trail)
- **Queryable**: Yes (via SQL or future admin analytics)
- **Fields**: admin_identifier, action, category, target, details, metadata, timestamp

---

## Configuration

### Enable/Disable Logging

In `config.lua`:

```lua
Config.Discord = {
    -- Console Logging
    consoleLogging = {
        enabled = true,                 -- Master switch
        logLevel = 'all',               -- 'all', 'actions', 'menu', 'none'
        logMenuClicks = true,           -- Log every button click
        logMenuNavigation = true,       -- Log page changes
        logPlayerActions = true,        -- Log player selection
        logAdminActions = true,         -- Log admin commands
        showTimestamps = true,          -- Include timestamps
        showAdminName = true,           -- Include admin name
        showTargetName = true           -- Include target name
    },
    
    -- Discord Webhook Logging (per action type)
    logMenuClicks = true,               -- Send menu clicks to webhook
    logMenuOpens = true,                -- Send menu open/close events
    logPageChanges = true,              -- Send page navigation
    logPlayerSelection = true,          -- Send player clicks
    logConfigChanges = true,            -- Send config updates
    logTeleports = true,                -- Send teleport actions
    logSpectate = true,                 -- Send spectate actions
    logNoclip = true,                   -- Send noclip toggles
    logGodMode = true,                  -- Send god mode toggles
    logFreeze = true,                   -- Send freeze actions
    logRevive = true,                   -- Send revive actions
    logWeaponGive = true,               -- Send weapon give actions
    logItemGive = true,                 -- Send item give actions
    logMoneyGive = true,                -- Send money give actions
    logJobChange = true,                -- Send job change actions
    logAdminActions = true              -- Send ALL admin actions (master switch)
}
```

---

## Usage Examples

### 🔧 Server-Side (Lua)

```lua
-- Log a menu click
ActionLogger.LogMenuClick(source, 'TeleportButton', 'dashboard', 'PlayerActions')

-- Log an admin action
ActionLogger.LogAdminAction(source, 'Teleport', {
    target = targetId,
    targetName = targetName,
    coordinates = coords
})

-- Log a config change
ActionLogger.LogConfigChange(source, 'Config.Discord.webhookUrl', oldValue, newValue)

-- Log page change
ActionLogger.LogPageChange(source, 'dashboard', 'players')

-- Generic log (custom category)
ActionLogger.Log(source, 'CUSTOM_CATEGORY', 'My Custom Action', {
    field1 = 'value1',
    field2 = 'value2'
})
```

### 💻 Client-Side (Lua)

```lua
-- Trigger from client to server
TriggerServerEvent('ec_admin:log:menuClick', 'TeleportButton', 'dashboard', 'PlayerActions')

-- Via export
exports['EC_Admin_Ultimate']:LogClick('TeleportButton', 'PlayerActions')

-- Via global
ClientLogger.LogClick('TeleportButton', 'PlayerActions')
```

### ⚛️ UI/React (JavaScript)

```javascript
import { logClick, logPageChange, logPlayerSelect, useLoggedClick } from '@/utils/logger';

// Manual click logging
function MyButton() {
    const handleClick = () => {
        logClick('TeleportButton', 'PlayerActions');
        // ... your logic
    };
    
    return <button onClick={handleClick}>Teleport</button>;
}

// Auto-logging with hook
function MyButton() {
    const handleClick = useLoggedClick('TeleportButton', () => {
        // ... your logic
    }, 'PlayerActions');
    
    return <button onClick={handleClick}>Teleport</button>;
}

// Page change logging
useEffect(() => {
    logPageChange('dashboard');
}, []);

// Player selection
const handlePlayerClick = (player) => {
    logPlayerSelect(player.id, player.name);
    // ... your logic
};
```

---

## Action Categories

| Category | Description | Example |
|----------|-------------|---------|
| `MENU_CLICK` | Any UI button/element click | "Teleport", "Kick", "Ban" |
| `MENU_OPEN` | Admin menu opened | Menu opened via command/key |
| `MENU_CLOSE` | Admin menu closed | Menu closed/ESC pressed |
| `PAGE_CHANGE` | Navigation between pages | Dashboard → Players |
| `PLAYER_SELECT` | Clicking on a player | Selecting player in list |
| `ADMIN_ACTION` | Admin command executed | Teleport, kick, ban, etc. |
| `CONFIG_CHANGE` | Config value updated | Webhook URL changed |

---

## Database Schema

```sql
CREATE TABLE IF NOT EXISTS `ec_admin_action_logs` (
  `id` INT(11) AUTO_INCREMENT,
  `admin_identifier` VARCHAR(100) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `action` VARCHAR(100) NOT NULL,
  `category` VARCHAR(50) DEFAULT 'general',
  `target_identifier` VARCHAR(100) DEFAULT NULL,
  `target_name` VARCHAR(100) DEFAULT NULL,
  `details` TEXT DEFAULT NULL,
  `metadata` LONGTEXT DEFAULT NULL,
  `timestamp` BIGINT(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `admin_identifier` (`admin_identifier`),
  KEY `timestamp` (`timestamp`),
  KEY `category` (`category`)
);
```

### Query Examples

```sql
-- Get all actions by admin
SELECT * FROM ec_admin_action_logs WHERE admin_identifier = 'license:abc123' ORDER BY timestamp DESC LIMIT 100;

-- Get all menu clicks in last hour
SELECT * FROM ec_admin_action_logs WHERE category = 'MENU_CLICK' AND timestamp > UNIX_TIMESTAMP() - 3600;

-- Get all admin actions (not menu clicks)
SELECT * FROM ec_admin_action_logs WHERE category = 'ADMIN_ACTION' ORDER BY timestamp DESC;

-- Count actions per admin
SELECT admin_name, COUNT(*) as action_count FROM ec_admin_action_logs GROUP BY admin_identifier ORDER BY action_count DESC;
```

---

## Discord Webhook Example

```json
{
  "embeds": [{
    "title": "🖱️ Menu Click",
    "color": 3447003,
    "fields": [
      {
        "name": "Admin",
        "value": "John Doe [license:abc123]",
        "inline": true
      },
      {
        "name": "Button",
        "value": "Teleport",
        "inline": true
      },
      {
        "name": "Page",
        "value": "dashboard",
        "inline": true
      },
      {
        "name": "Component",
        "value": "PlayerActions",
        "inline": true
      }
    ],
    "timestamp": "2025-01-15T14:30:45.000Z",
    "footer": {
      "text": "EC Admin Ultimate v1.0.0"
    }
  }]
}
```

---

## Integration Checklist

### ✅ Files Created/Modified

- ✅ `server/action-logger.lua` - Server-side logging system
- ✅ `client/action-logger.lua` - Client-side event triggers
- ✅ `ui/src/utils/logger.js` - React/UI logging utilities
- ✅ `config.lua` - Logging configuration options
- ✅ `fxmanifest.lua` - Added to server_scripts and client_scripts
- ✅ `sql/ec_admin_ultimate.sql` - Database table exists

### 🔄 Integration Steps (For UI Developers)

1. **Import logger utility in React components:**
   ```javascript
   import { logClick, logPageChange } from '@/utils/logger';
   ```

2. **Add to button clicks:**
   ```javascript
   <button onClick={() => { logClick('ButtonName'); handleAction(); }}>
   ```

3. **Add to page changes:**
   ```javascript
   useEffect(() => { logPageChange('pageName'); }, []);
   ```

4. **Add to player selection:**
   ```javascript
   onClick={() => logPlayerSelect(player.id, player.name)}
   ```

---

## Performance Considerations

- **Console Logging**: Minimal overhead (~0.1ms per log)
- **Discord Webhooks**: Async, non-blocking (sent in background)
- **Database Writes**: Async, queued (does not block server)
- **Caching**: Admin names cached to avoid repeated database queries
- **Rate Limiting**: Discord webhooks respect rate limits (30 requests per webhook per minute)

---

## Troubleshooting

### Console logs not appearing?
1. Check `Config.Discord.consoleLogging.enabled = true`
2. Verify `logMenuClicks = true` for specific action type
3. Ensure action-logger.lua is loaded in fxmanifest.lua

### Discord webhooks not sending?
1. Check webhook URL is valid in config.lua
2. Verify `Config.Discord.logMenuClicks = true` (per action type)
3. Test webhook with curl: `curl -X POST -H "Content-Type: application/json" -d '{"content":"test"}' YOUR_WEBHOOK_URL`
4. Check for Discord rate limiting (max 30 per minute per webhook)

### Database not logging?
1. Verify `ec_admin_action_logs` table exists
2. Check MySQL connection (`oxmysql` resource running)
3. Check server console for SQL errors
4. Verify database credentials in server.cfg

### UI clicks not logging?
1. Ensure `client/action-logger.lua` is loaded
2. Check browser console for JavaScript errors
3. Verify `window.nuiHandoff` exists in UI code
4. Add `logClick()` calls to React components

---

## Future Enhancements

- [ ] Real-time log viewer in admin UI
- [ ] Analytics dashboard (most clicked buttons, most active admins)
- [ ] Log retention policy (auto-delete old logs)
- [ ] Export logs to CSV/JSON
- [ ] Advanced filtering (date range, admin, action type)
- [ ] Log playback (replay admin session)

---

## Support

For issues or questions about the logging system:
- Check this documentation first
- Review `config.lua` for available options
- Check server console for error messages
- Test with Discord webhook tester tools

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-15  
**Author**: EC Beta Solutions
