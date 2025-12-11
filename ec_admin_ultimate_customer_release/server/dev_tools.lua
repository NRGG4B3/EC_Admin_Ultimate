--[[
    EC Admin Ultimate - Dev Tools UI Backend
    Server-side logic for developer tools page
    
    Handles:
    - devTools:getData: Get dev tools data
    - devTools:executeScript: Execute a script
    - devTools:runCommand: Run a command
]]

-- Check if player has permission
local function hasDevToolsPermission(source)
    if not source or source == 0 then return false end
    
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.dev_tools')
    end
    
    -- Fallback: Check if player is admin
    local framework = ECFramework and ECFramework.GetFramework() or 'standalone'
    
    if framework == 'qb' or framework == 'qbx' then
        local player = ECFramework.GetPlayerObject(source)
        if player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name == 'admin' or player.PlayerData.job.name == 'dev'
        end
    elseif framework == 'esx' then
        local player = ECFramework.GetPlayerObject(source)
        if player and player.group then
            return player.group == 'admin' or player.group == 'superadmin'
        end
    elseif framework == 'standalone' then
        -- Standalone mode: Check via permissions system or owner identifiers
        if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
            return exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.dev_tools')
        end
        -- Fallback: Check if player is in Config.Owners
        if Config and Config.Owners then
            local identifiers = ECFramework.GetIdentifiers(source)
            for _, ownerId in pairs(Config.Owners) do
                if identifiers.steam == ownerId or identifiers.license == ownerId or 
                   identifiers.discord == ownerId or identifiers.fivem == ownerId then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- ============================================================================
-- LIB.CALLBACK REGISTERS (fetchNui calls from UI)
-- ============================================================================

-- Callback: Get dev tools data
lib.callback.register('ec_admin:devTools:getData', function(source)
    if not hasDevToolsPermission(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Dev tools data collection (returns empty structure - data populated by Node.js backend if available)
    return {
        success = true,
        data = {
            scripts = {},
            console = {
                logs = {}
            },
            resources = {},
            files = {}
        }
    }
end)

-- Callback: Execute script
lib.callback.register('ec_admin:devTools:executeScript', function(source, data)
    if not hasDevToolsPermission(source) then
        return { success = false, error = 'Access denied' }
    end
    
    if not data or not data.script then
        return { success = false, error = 'Script content required' }
    end
    
    local adminInfo = getAdminInfo(source)
    
    -- Script execution disabled for security (intentional - prevents code injection)
    
    print(string.format("^3[Dev Tools]^7 %s (%s) attempted to execute script^0", adminInfo.name, adminInfo.id))
    
    return {
        success = false,
        error = 'Script execution is disabled for security reasons'
    }
end)

-- Callback: Run command
lib.callback.register('ec_admin:devTools:runCommand', function(source, data)
    if not hasDevToolsPermission(source) then
        return { success = false, error = 'Access denied' }
    end
    
    if not data or not data.command then
        return { success = false, error = 'Command required' }
    end
    
    local adminInfo = getAdminInfo(source)
    
    -- Command execution disabled for security (intentional - prevents command injection)
    
    print(string.format("^3[Dev Tools]^7 %s (%s) attempted to run command: %s^0", adminInfo.name, adminInfo.id, data.command))
    
    return {
        success = false,
        error = 'Command execution is disabled for security reasons',
        output = 'This feature is disabled in production mode'
    }
end)

-- RegisterNUICallback: Get dev tools data (direct fetch from UI)
-- Note: RegisterNUICallback doesn't have source, so we use lib.callback.register only
-- The client bridge (nui-dev-tools.lua) handles the NUI callback and forwards to lib.callback

print("^2[Dev Tools]^7 Dev tools backend loaded^0")

