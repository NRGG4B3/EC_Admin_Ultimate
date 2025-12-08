--[[
    EC Admin Ultimate - Testing Checklist UI Backend
    Server-side logic for testing checklist tracking
    
    Handles:
    - testing:getChecklist: Get all checklist items with progress
    - testing:updateItem: Update a checklist item (check/uncheck)
    - testing:updateNotes: Update notes for a checklist item
    - testing:getProgress: Get overall progress statistics
    - testing:resetProgress: Reset all progress for an admin
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Testing Checklist] ERROR: oxmysql not found!^0")
    return
end

-- Helper: Get admin identifier
local function getAdminIdentifier(source)
    if not source or source == 0 then return nil end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, 'license:') then
            return identifier
        end
    end
    
    return nil
end

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Callback: Get checklist with progress
lib.callback.register('ec_admin:testing:getChecklist', function(source)
    local adminId = getAdminIdentifier(source)
    if not adminId then
        return { success = false, error = 'Admin identifier not found' }
    end
    
    -- Get all checklist items from the markdown file structure
    local checklist = {
        categories = {
            {
                id = 'pre-testing-setup',
                title = 'Pre-Testing Setup',
                items = {
                    { id = 'framework-qb-core', text = 'Test with QB-Core (qb-core)', category = 'pre-testing-setup' },
                    { id = 'framework-qbx', text = 'Test with QBX (qbx_core)', category = 'pre-testing-setup' },
                    { id = 'framework-esx', text = 'Test with ESX (es_extended)', category = 'pre-testing-setup' },
                    { id = 'framework-ox-core', text = 'Test with ox_core', category = 'pre-testing-setup' },
                    { id = 'framework-standalone', text = 'Test in Standalone mode (no framework)', category = 'pre-testing-setup' },
                    { id = 'deps-oxmysql', text = 'Verify oxmysql is running', category = 'pre-testing-setup' },
                    { id = 'deps-ox-lib', text = 'Verify ox_lib is running', category = 'pre-testing-setup' },
                    { id = 'deps-console', text = 'Check server console for dependency warnings', category = 'pre-testing-setup' },
                    { id = 'config-load', text = 'Verify correct config loads (host.config.lua vs customer.config.lua)', category = 'pre-testing-setup' },
                    { id = 'config-nui-errors', text = 'Check Config.LogNUIErrors = true is set', category = 'pre-testing-setup' },
                    { id = 'config-webhooks', text = 'Verify webhook URLs are configured (if using)', category = 'pre-testing-setup' },
                    { id = 'config-owner', text = 'Check owner identifiers are set correctly', category = 'pre-testing-setup' },
                }
            },
            {
                id = 'resource-startup',
                title = 'Resource Startup & Initialization',
                items = {
                    { id = 'server-start', text = 'Resource starts without errors', category = 'resource-startup' },
                    { id = 'server-logger', text = 'Logger loads first', category = 'resource-startup' },
                    { id = 'server-framework', text = 'Framework detection works', category = 'resource-startup' },
                    { id = 'server-migrations', text = 'Database migrations run successfully', category = 'resource-startup' },
                    { id = 'server-scripts', text = 'All server scripts load in correct order', category = 'resource-startup' },
                    { id = 'server-errors', text = 'No Lua errors in server console', category = 'resource-startup' },
                    { id = 'client-scripts', text = 'Client scripts load without errors', category = 'resource-startup' },
                    { id = 'client-nui-handler', text = 'NUI error handler loads', category = 'resource-startup' },
                    { id = 'client-error-handler', text = 'Error handler loads', category = 'resource-startup' },
                    { id = 'client-errors', text = 'No client-side Lua errors', category = 'resource-startup' },
                    { id = 'ui-loads', text = 'UI loads without errors', category = 'resource-startup' },
                    { id = 'ui-react-errors', text = 'No React errors in browser console', category = 'resource-startup' },
                    { id = 'ui-error-handler', text = 'Global error handler is active', category = 'resource-startup' },
                    { id = 'ui-error-boundary', text = 'Error boundary is working', category = 'resource-startup' },
                }
            },
            {
                id = 'framework-compatibility',
                title = 'Framework Compatibility Testing',
                items = {
                    { id = 'qb-player-data', text = 'QB-Core: Player data loads correctly', category = 'framework-compatibility' },
                    { id = 'qb-actions', text = 'QB-Core: Player actions work', category = 'framework-compatibility' },
                    { id = 'qb-money', text = 'QB-Core: Money operations work', category = 'framework-compatibility' },
                    { id = 'qb-jobs', text = 'QB-Core: Job/Gang operations work', category = 'framework-compatibility' },
                    { id = 'qb-inventory', text = 'QB-Core: Inventory operations work', category = 'framework-compatibility' },
                    { id = 'qb-vehicles', text = 'QB-Core: Vehicle operations work', category = 'framework-compatibility' },
                    { id = 'qbx-data', text = 'QBX: Player data loads correctly', category = 'framework-compatibility' },
                    { id = 'qbx-features', text = 'QBX: All QB-Core features work', category = 'framework-compatibility' },
                    { id = 'esx-data', text = 'ESX: Player data loads correctly', category = 'framework-compatibility' },
                    { id = 'esx-jobs', text = 'ESX: ESX job system works', category = 'framework-compatibility' },
                    { id = 'esx-money', text = 'ESX: ESX money system works', category = 'framework-compatibility' },
                    { id = 'esx-inventory', text = 'ESX: ESX inventory works', category = 'framework-compatibility' },
                    { id = 'esx-vehicles', text = 'ESX: ESX vehicle system works', category = 'framework-compatibility' },
                    { id = 'ox-data', text = 'ox_core: Player data loads correctly', category = 'framework-compatibility' },
                    { id = 'ox-identity', text = 'ox_core: Identity system works', category = 'framework-compatibility' },
                    { id = 'ox-groups', text = 'ox_core: Groups/jobs work', category = 'framework-compatibility' },
                    { id = 'ox-money', text = 'ox_core: Money system works', category = 'framework-compatibility' },
                    { id = 'standalone-works', text = 'Standalone: Resource works without any framework', category = 'framework-compatibility' },
                    { id = 'standalone-basic', text = 'Standalone: Basic player operations work', category = 'framework-compatibility' },
                    { id = 'standalone-fallbacks', text = 'Standalone: Graceful fallbacks work', category = 'framework-compatibility' },
                }
            },
            {
                id = 'ui-pages',
                title = 'UI Pages & Navigation',
                items = {
                    { id = 'dashboard-loads', text = 'Dashboard: Page loads without errors', category = 'ui-pages' },
                    { id = 'dashboard-metrics', text = 'Dashboard: Server metrics display correctly', category = 'ui-pages' },
                    { id = 'dashboard-players', text = 'Dashboard: Player count updates in real-time', category = 'ui-pages' },
                    { id = 'dashboard-resources', text = 'Dashboard: Resource count displays correctly', category = 'ui-pages' },
                    { id = 'dashboard-chart', text = 'Dashboard: Historical metrics chart loads', category = 'ui-pages' },
                    { id = 'dashboard-quick-actions', text = 'Dashboard: Quick Actions Widget displays 16 actions', category = 'ui-pages' },
                    { id = 'dashboard-quick-actions-work', text = 'Dashboard: Quick Actions work from dashboard', category = 'ui-pages' },
                    { id = 'dashboard-view-all', text = 'Dashboard: "View All" button opens Quick Actions Center', category = 'ui-pages' },
                    { id = 'players-list', text = 'Players: Player list loads', category = 'ui-pages' },
                    { id = 'players-data', text = 'Players: Player data displays correctly', category = 'ui-pages' },
                    { id = 'players-search', text = 'Players: Search/filter works', category = 'ui-pages' },
                    { id = 'players-profile', text = 'Players: Clicking player opens profile', category = 'ui-pages' },
                    { id = 'player-profile-loads', text = 'Player Profile: Profile loads for selected player', category = 'ui-pages' },
                    { id = 'player-profile-data', text = 'Player Profile: All player data displays', category = 'ui-pages' },
                    { id = 'player-profile-actions', text = 'Player Profile: Actions work (kick, ban, teleport)', category = 'ui-pages' },
                    { id = 'vehicles-list', text = 'Vehicles: Vehicle list loads', category = 'ui-pages' },
                    { id = 'vehicles-data', text = 'Vehicles: Vehicle data displays', category = 'ui-pages' },
                    { id = 'vehicles-actions', text = 'Vehicles: Vehicle actions work', category = 'ui-pages' },
                    { id = 'moderation-bans', text = 'Moderation: Bans list loads', category = 'ui-pages' },
                    { id = 'moderation-warnings', text = 'Moderation: Warnings list loads', category = 'ui-pages' },
                    { id = 'moderation-actions', text = 'Moderation: Create ban works', category = 'ui-pages' },
                }
            },
            {
                id = 'error-handling',
                title = 'Error Handling & Logging',
                items = {
                    { id = 'nui-react-errors', text = 'NUI: React errors are caught and logged to server', category = 'error-handling' },
                    { id = 'nui-fetch-errors', text = 'NUI: Fetch errors are caught and logged', category = 'error-handling' },
                    { id = 'nui-console-errors', text = 'NUI: Console errors are caught and logged', category = 'error-handling' },
                    { id = 'nui-promise-errors', text = 'NUI: Unhandled promise rejections are caught', category = 'error-handling' },
                    { id = 'nui-server-errors', text = 'NUI: All errors appear in server console', category = 'error-handling' },
                    { id = 'server-error-logging', text = 'Server: Server errors are logged via Logger', category = 'error-handling' },
                    { id = 'server-error-format', text = 'Server: Error format is correct', category = 'error-handling' },
                    { id = 'client-error-logging', text = 'Client: Client errors are caught', category = 'error-handling' },
                }
            },
            {
                id = 'permissions-security',
                title = 'Permissions & Security',
                items = {
                    { id = 'perms-checks', text = 'Permission: Permission checks work', category = 'permissions-security' },
                    { id = 'perms-unauthorized', text = 'Permission: Unauthorized actions are blocked', category = 'permissions-security' },
                    { id = 'perms-levels', text = 'Permission: Permission levels work correctly', category = 'permissions-security' },
                    { id = 'security-sql', text = 'Security: SQL injection protection works', category = 'permissions-security' },
                    { id = 'security-input', text = 'Security: Input validation works', category = 'permissions-security' },
                    { id = 'security-xss', text = 'Security: XSS protection works (NUI)', category = 'permissions-security' },
                }
            },
            {
                id = 'database',
                title = 'Database Operations',
                items = {
                    { id = 'db-connection', text = 'Database: Database connects successfully', category = 'database' },
                    { id = 'db-migrations', text = 'Database: Migrations run on startup', category = 'database' },
                    { id = 'db-saves', text = 'Database: Player data saves correctly', category = 'database' },
                    { id = 'db-loads', text = 'Database: Player data loads correctly', category = 'database' },
                    { id = 'db-tables', text = 'Database: All tables exist and are correct', category = 'database' },
                }
            },
            {
                id = 'quick-actions',
                title = 'Quick Actions Synchronization',
                items = {
                    { id = 'qa-dashboard-widget', text = 'Quick Actions: Widget displays on dashboard', category = 'quick-actions' },
                    { id = 'qa-dashboard-execute', text = 'Quick Actions: Actions execute correctly from dashboard', category = 'quick-actions' },
                    { id = 'qa-center-opens', text = 'Quick Actions: Quick Actions Center opens from dashboard', category = 'quick-actions' },
                    { id = 'qa-all-available', text = 'Quick Actions: All 60+ actions available in center', category = 'quick-actions' },
                    { id = 'qa-kick-sync', text = 'Quick Actions: Kick works from all pages', category = 'quick-actions' },
                    { id = 'qa-teleport-sync', text = 'Quick Actions: Teleport works from all pages', category = 'quick-actions' },
                    { id = 'qa-vehicle-sync', text = 'Quick Actions: Vehicle actions sync', category = 'quick-actions' },
                    { id = 'qa-economy-sync', text = 'Quick Actions: Economy actions sync', category = 'quick-actions' },
                }
            },
        }
    }
    
    -- Get progress from database
    local progressResult = MySQL.query.await([[
        SELECT item_id, checked, checked_at, notes 
        FROM ec_testing_checklist 
        WHERE admin_id = ?
    ]], {adminId})
    
    local progress = {}
    if progressResult then
        for _, row in ipairs(progressResult) do
            progress[row.item_id] = {
                checked = row.checked == 1,
                checkedAt = row.checked_at,
                notes = row.notes
            }
        end
    end
    
    -- Merge progress with checklist items
    for _, category in ipairs(checklist.categories) do
        for _, item in ipairs(category.items) do
            if progress[item.id] then
                item.checked = progress[item.id].checked
                item.checkedAt = progress[item.id].checkedAt
                item.notes = progress[item.id].notes
            else
                item.checked = false
                item.checkedAt = nil
                item.notes = nil
            end
        end
    end
    
    -- Calculate overall progress
    local totalItems = 0
    local checkedItems = 0
    for _, category in ipairs(checklist.categories) do
        for _, item in ipairs(category.items) do
            totalItems = totalItems + 1
            if item.checked then
                checkedItems = checkedItems + 1
            end
        end
    end
    
    return {
        success = true,
        checklist = checklist,
        progress = {
            total = totalItems,
            checked = checkedItems,
            percentage = totalItems > 0 and math.floor((checkedItems / totalItems) * 100) or 0
        }
    }
end)

-- Callback: Update checklist item
lib.callback.register('ec_admin:testing:updateItem', function(source, data)
    local adminId = getAdminIdentifier(source)
    if not adminId then
        return { success = false, error = 'Admin identifier not found' }
    end
    
    local itemId = data.itemId
    local checked = data.checked == true
    local notes = data.notes
    
    if not itemId then
        return { success = false, error = 'Item ID is required' }
    end
    
    local timestamp = getCurrentTimestamp()
    
    -- Insert or update
    MySQL.insert.await([[
        INSERT INTO ec_testing_checklist 
        (admin_id, item_id, category, checked, checked_at, notes, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        checked = VALUES(checked),
        checked_at = VALUES(checked_at),
        notes = VALUES(notes),
        updated_at = VALUES(updated_at)
    ]], {
        adminId,
        itemId,
        data.category or 'general',
        checked and 1 or 0,
        checked and timestamp or nil,
        notes or nil,
        timestamp,
        timestamp
    })
    
    return { success = true }
end)

-- Callback: Get progress statistics
lib.callback.register('ec_admin:testing:getProgress', function(source)
    local adminId = getAdminIdentifier(source)
    if not adminId then
        return { success = false, error = 'Admin identifier not found' }
    end
    
    local result = MySQL.query.await([[
        SELECT 
            COUNT(*) as total,
            SUM(checked) as checked,
            category,
            COUNT(CASE WHEN checked = 1 THEN 1 END) as category_checked
        FROM ec_testing_checklist
        WHERE admin_id = ?
        GROUP BY category
    ]], {adminId})
    
    local totalResult = MySQL.query.await([[
        SELECT 
            COUNT(*) as total,
            SUM(checked) as checked
        FROM ec_testing_checklist
        WHERE admin_id = ?
    ]], {adminId})
    
    local total = totalResult and totalResult[1] and totalResult[1].total or 0
    local checked = totalResult and totalResult[1] and totalResult[1].checked or 0
    
    return {
        success = true,
        total = total,
        checked = checked,
        percentage = total > 0 and math.floor((checked / total) * 100) or 0,
        byCategory = result or {}
    }
end)

-- Callback: Reset progress
lib.callback.register('ec_admin:testing:resetProgress', function(source)
    local adminId = getAdminIdentifier(source)
    if not adminId then
        return { success = false, error = 'Admin identifier not found' }
    end
    
    MySQL.query.await([[
        DELETE FROM ec_testing_checklist WHERE admin_id = ?
    ]], {adminId})
    
    return { success = true }
end)

print("^2[Testing Checklist]^7 Testing checklist backend loaded^0")
