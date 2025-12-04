# Automatic Database System

## 🎯 Overview

**FULLY AUTOMATIC** - No manual configuration needed by host or customers.

The database system automatically:
- ✅ Detects if MySQL/MariaDB is available
- ✅ Creates database if needed
- ✅ Creates all required tables
- ✅ Falls back to file storage if DB unavailable
- ✅ Works for both HOST and CUSTOMER modes

---

## 🚀 How It Works

### On Server Startup:

1. **Auto-Detection** (2 seconds after start)
   ```
   [EC Admin] 🔍 Auto-detecting database configuration...
   ```

2. **If oxmysql is available:**
   ```
   [EC Admin] ✅ oxmysql detected and loaded
   [EC Admin] ✅ Database connection successful
   [EC Admin] ✅ Database created/verified: ec_admin_ultimate
   [EC Admin] 📋 Creating database tables...
   [EC Admin]    ✓ Table created: ec_config
   [EC Admin]    ✓ Table created: ec_admins
   [EC Admin]    ✓ Table created: ec_bans
   ... (and so on)
   [EC Admin] ✅ All tables created successfully (11/11)
   [EC Admin] ✅ MySQL database initialized and ready
   ```

3. **If oxmysql is NOT available:**
   ```
   [EC Admin] ℹ️ oxmysql not found - will use file storage
   [EC Admin] 📁 Initializing file-based storage...
   [EC Admin] ✅ File storage initialized and ready
   [EC Admin] ℹ️ All data will be stored in resource files
   ```

---

## 📋 Database Tables

### Core Tables (All Modes):
- `ec_config` - Configuration storage
- `ec_admins` - Admin users
- `ec_bans` - Player bans
- `ec_players` - Player database
- `ec_actions` - Admin actions log
- `ec_warnings` - Player warnings
- `ec_sessions` - Session management
- `ec_logs` - System logs

### Host-Only Tables (Host Mode):
- `ec_licenses` - License management
- `ec_servers` - Server registry
- `ec_audit` - Audit trail

---

## 🔧 Using MySQL (Optional)

If you want to use MySQL instead of file storage:

### Step 1: Install oxmysql

```bash
ensure oxmysql
```

### Step 2: Configure oxmysql

In your `server.cfg` (before EC Admin):

```bash
# MySQL Configuration (example)
set mysql_connection_string "mysql://root@localhost/fivem?charset=utf8mb4"

# Start oxmysql BEFORE EC Admin
ensure oxmysql
ensure EC_admin_ultimate
```

### Step 3: Restart

```bash
restart EC_admin_ultimate
```

That's it! EC Admin will automatically:
- Detect oxmysql
- Create database `ec_admin_ultimate`
- Create all tables
- Start using MySQL

---

## 📁 File Storage (Default)

If oxmysql is not available, EC Admin uses file storage:

**Storage Location:**
```
/resources/EC_admin_ultimate/data/
├── admins.json
├── bans.json
├── players.json
├── actions.json
└── ... (other data files)
```

**Features:**
- ✅ Zero configuration
- ✅ Works out of the box
- ✅ No database required
- ⚠️ Limited to single server (no cross-server sync)

---

## 🔄 Migration

### From File Storage to MySQL:

1. Install oxmysql
2. Configure MySQL connection
3. Restart EC Admin
4. Data will automatically migrate

### From MySQL to File Storage:

1. Stop oxmysql
2. Restart EC Admin
3. Will automatically fall back to file storage
4. Data in MySQL is preserved (can switch back anytime)

---

## 🛠️ Unified API

All database operations use the same API regardless of backend:

```lua
-- Insert record (works with both MySQL and file storage)
InsertRecord('ec_bans', {
    identifier = 'steam:110000XXXXX',
    reason = 'Hacking',
    banned_by = 'Admin'
}, function(result)
    print('Ban added: ' .. result)
end)

-- Query records
QueryRecords('ec_players', 'identifier = "steam:110000XXXXX"', function(results)
    print('Found ' .. #results .. ' players')
end)

-- Update record
UpdateRecord('ec_admins', {
    rank = 'superadmin'
}, 'id = 1', function(success)
    print('Updated: ' .. tostring(success))
end)

-- Delete record
DeleteRecord('ec_bans', 'id = 123', function(success)
    print('Deleted: ' .. tostring(success))
end)
```

---

## 📊 Check Current Storage

### In Server Console:

```lua
# Check if using MySQL
ExecuteCommand('lua print(exports["EC_admin_ultimate"]:IsUsingDatabase())')

# Check if using file storage
ExecuteCommand('lua print(exports["EC_admin_ultimate"]:IsUsingFileStorage())')

# Get database state
ExecuteCommand('lua print(json.encode(exports["EC_admin_ultimate"]:GetDatabaseState()))')
```

### Expected Output:

**With MySQL:**
```
Database State: {
    available: true,
    connected: true,
    tablesCreated: true,
    usingFileStorage: false
}
```

**With File Storage:**
```
Database State: {
    available: true,
    connected: false,
    tablesCreated: false,
    usingFileStorage: true
}
```

---

## ⚙️ Advanced Configuration

### Custom Database Name

If you want to use a different database name:

```lua
-- server/database/auto-setup.lua (line 26)
databaseName = 'your_custom_db_name',
```

### Disable File Storage Fallback

If you want to REQUIRE MySQL:

```lua
-- server/database/auto-setup.lua (line 34)
fallbackToFiles = false,
```

**Warning:** With this disabled, EC Admin won't start if MySQL is unavailable.

---

## 🐛 Troubleshooting

### Issue: "oxmysql not available"

**Solution:**
- Ensure oxmysql is installed
- Check `ensure oxmysql` is BEFORE EC Admin
- Verify MySQL server is running
- Test oxmysql with: `refresh; ensure oxmysql`

### Issue: "Database query failed"

**Solution:**
- Check MySQL credentials in oxmysql config
- Verify MySQL user has CREATE DATABASE permission
- Test connection manually: `mysql -u root -p`

### Issue: "Failed to create database"

**Solution:**
- Grant permissions to MySQL user:
  ```sql
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
  FLUSH PRIVILEGES;
  ```

### Issue: File storage data not persisting

**Solution:**
- Check resource has write permissions
- Verify `/data/` folder exists in resource
- Check server console for file write errors

---

## ✅ Benefits

**For Customers:**
- ✅ Zero configuration - works immediately
- ✅ No database setup required
- ✅ Optional MySQL upgrade path
- ✅ Data automatically managed

**For Host:**
- ✅ Database auto-created
- ✅ All tables auto-created
- ✅ Cross-server features work with MySQL
- ✅ No manual SQL scripts to run

---

## 📞 Support

**If you have database issues:**
1. Check server console for error messages
2. Verify oxmysql status: `ensure oxmysql`
3. Test MySQL connection manually
4. Contact support with console logs

**File storage is always available as fallback!**
