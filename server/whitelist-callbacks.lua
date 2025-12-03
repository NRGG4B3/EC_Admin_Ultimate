--[[
    EC Admin Ultimate - Whitelist Management NUI Callbacks
    Complete whitelist UI integration with database persistence
]]

local QBCore = nil
local ESX = nil
local Framework = 'unknown'

-- Initialize framework
CreateThread(function()
    Wait(1000)
    
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core -- QBX uses direct export
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    else
        Framework = 'standalone'
    end
    
    Logger.Info('Whitelist NUI Callbacks Initialized: ' .. Framework)
end)

-- Create whitelist database tables
CreateThread(function()
    Wait(2000)
    
    -- Initialize whitelist-related database tables safely
    local ok, err = pcall(function()
        -- Main whitelist table
        MySQL.query.await([[ 
            CREATE TABLE IF NOT EXISTS ec_whitelist (
                id INT AUTO_INCREMENT PRIMARY KEY,
                identifier VARCHAR(100) NOT NULL,
                name VARCHAR(100) NOT NULL,
                steam_id VARCHAR(100) NULL,
                license VARCHAR(100) NULL,
                discord_id VARCHAR(100) NULL,
                ip_address VARCHAR(100) NULL,
                roles TEXT NULL,
                status VARCHAR(20) NOT NULL DEFAULT 'active',
                added_by VARCHAR(100) NULL,
                priority VARCHAR(20) NULL DEFAULT 'normal',
                notes TEXT NULL,
                expires_at TIMESTAMP NULL,
                added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_identifier (identifier),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], {})

        -- Whitelist roles
        MySQL.query.await([[ 
            CREATE TABLE IF NOT EXISTS ec_whitelist_roles (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(64) NOT NULL UNIQUE,
                display_name VARCHAR(100) NOT NULL,
                priority INT NOT NULL DEFAULT 50,
                color VARCHAR(16) NOT NULL DEFAULT '#3b82f6',
                permissions TEXT NULL,
                is_default TINYINT(1) NOT NULL DEFAULT 0
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], {})

        -- Whitelist applications
        MySQL.query.await([[ 
            CREATE TABLE IF NOT EXISTS ec_whitelist_applications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                identifier VARCHAR(100) NOT NULL,
                applicant_name VARCHAR(100) NOT NULL,
                steam_id VARCHAR(100) NULL,
                license VARCHAR(100) NULL,
                discord_id VARCHAR(100) NULL,
                status VARCHAR(20) NOT NULL DEFAULT 'pending',
                deny_reason TEXT NULL,
                submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                reviewed_by VARCHAR(100) NULL,
                reviewed_at TIMESTAMP NULL,
                INDEX idx_identifier (identifier),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], {})
    end)

    if not ok then
        Logger.Error('Whitelist DB init failed: ' .. tostring(err))
    else
        Logger.Info('✅ Whitelist database tables initialized')
    end
end)

-- Shared builder: collect Whitelist payload
local function buildWhitelistData()
    -- Get whitelist entries (async)
    local whitelist = MySQL.query.await([[ 
        SELECT * FROM ec_whitelist 
        ORDER BY added_at DESC
    ]], {}) or {}

    -- Parse roles JSON
    for _, entry in ipairs(whitelist) do
        if entry.roles then
            entry.roles = json.decode(entry.roles) or {}
        else
            entry.roles = {}
        end
    end

    -- Get applications (async)
    local applications = MySQL.query.await([[ 
        SELECT * FROM ec_whitelist_applications 
        ORDER BY submitted_at DESC
    ]], {}) or {}

    -- Get roles (async)
    local roles = MySQL.query.await([[ 
        SELECT * FROM ec_whitelist_roles 
        ORDER BY priority DESC
    ]], {}) or {}

    -- Parse permissions JSON
    for _, role in ipairs(roles) do
        if role.permissions then
            role.permissions = json.decode(role.permissions) or {}
        else
            role.permissions = {}
        end
    end

    -- Calculate stats
    local stats = {
        totalWhitelisted = #whitelist,
        activeWhitelisted = 0,
        inactiveWhitelisted = 0,
        totalApplications = #applications,
        pendingApplications = 0,
        approvedApplications = 0,
        deniedApplications = 0,
        totalRoles = #roles
    }

    for _, entry in ipairs(whitelist) do
        if entry.status == 'active' then
            stats.activeWhitelisted = stats.activeWhitelisted + 1
        else
            stats.inactiveWhitelisted = stats.inactiveWhitelisted + 1
        end
    end

    for _, app in ipairs(applications) do
        if app.status == 'pending' then
            stats.pendingApplications = stats.pendingApplications + 1
        elseif app.status == 'approved' then
            stats.approvedApplications = stats.approvedApplications + 1
        elseif app.status == 'denied' then
            stats.deniedApplications = stats.deniedApplications + 1
        end
    end

    return {
        success = true,
        data = {
            whitelist = whitelist,
            applications = applications,
            roles = roles,
            stats = stats,
            framework = Framework
        }
    }
end

-- New: ox_lib callback for NUI request/response flow
lib.callback.register('ec_admin:getWhitelistData', function(source, _)
    return buildWhitelistData()
end)

-- Helper: Get player identifier
local function GetPlayerIdentifier(src)
    if Framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'qb-core' then
        local Player = QBCore.Functions.GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier or nil
    else
        return GetPlayerIdentifiers(src)[1] or nil
    end
end

-- Get all whitelist data
RegisterNetEvent('ec_admin_ultimate:server:getWhitelistData', function()
    local src = source
    CreateThread(function()
        local payload = buildWhitelistData()
        TriggerClientEvent('ec_admin_ultimate:client:receiveWhitelistData', src, payload)
    end)
end)

-- Add whitelist entry
RegisterNetEvent('ec_admin_ultimate:server:addWhitelist', function(data)
    local src = source
    
    if not data.identifier or not data.name then
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = false,
            message = 'Identifier and name are required'
        })
        return
    end
    
    CreateThread(function()
        local adminName = GetPlayerName(src)
        local roles = json.encode(data.roles or {'whitelist'})
        
        -- Check if already exists (async)
        local existing = MySQL.scalar.await('SELECT id FROM ec_whitelist WHERE identifier = ? LIMIT 1', {data.identifier})
        
        if existing then
            TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
                success = false,
                message = 'This identifier is already whitelisted'
            })
            return
        end
        
        MySQL.query.await([[
            INSERT INTO ec_whitelist 
            (identifier, name, steam_id, license, discord_id, ip_address, roles, status, added_by, priority, notes, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            data.identifier,
            data.name,
            data.steamId or nil,
            data.license or nil,
            data.discordId or nil,
            data.ipAddress or nil,
            roles,
            data.status or 'active',
            adminName,
            data.priority or 'normal',
            data.notes or nil,
            data.expiresAt or nil
        })
        
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = true,
            message = 'Player added to whitelist'
        })
    end)
    
    -- Log action
    Logger.Info(string.format('[Whitelist] %s added %s to whitelist', adminName, data.name))
end)

-- Update whitelist entry
RegisterNetEvent('ec_admin_ultimate:server:updateWhitelist', function(data)
    local src = source
    
    if not data.id then
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = false,
            message = 'Entry ID is required'
        })
        return
    end
    
    CreateThread(function()
        local roles = json.encode(data.roles or {})
        
        MySQL.query.await([[
            UPDATE ec_whitelist 
            SET name = ?, steam_id = ?, license = ?, discord_id = ?, roles = ?, 
                status = ?, priority = ?, notes = ?, expires_at = ?
            WHERE id = ?
        ]], {
            data.name,
            data.steamId or nil,
            data.license or nil,
            data.discordId or nil,
            roles,
            data.status or 'active',
            data.priority or 'normal',
            data.notes or nil,
            data.expiresAt or nil,
            data.id
        })
        
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = true,
            message = 'Whitelist entry updated'
        })
        
    Logger.Info(string.format('[Whitelist] %s updated entry ID %s', GetPlayerName(src), tostring(data.id)))
    end)
end)

-- Remove whitelist entry
RegisterNetEvent('ec_admin_ultimate:server:removeWhitelist', function(data)
    local src = source
    
    if not data.id then
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = false,
            message = 'Entry ID is required'
        })
        return
    end
    
    CreateThread(function()
        -- Get entry name before deleting
        local entry = MySQL.query.await('SELECT name FROM ec_whitelist WHERE id = ? LIMIT 1', {data.id})
        
        MySQL.query.await('DELETE FROM ec_whitelist WHERE id = ?', {data.id})
        
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = true,
            message = 'Player removed from whitelist'
        })
        
        if entry and #entry > 0 then
            Logger.Info(string.format('[Whitelist] %s removed %s from whitelist', GetPlayerName(src), entry[1].name))
        end
    end)
end)

-- Approve application
RegisterNetEvent('ec_admin_ultimate:server:approveApplication', function(data)
    local src = source
    
    if not data.id then
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = false,
            message = 'Application ID is required'
        })
        return
    end
    
    CreateThread(function()
        -- Get application
        local app = MySQL.query.await('SELECT * FROM ec_whitelist_applications WHERE id = ? LIMIT 1', {data.id})
        
        if not app or #app == 0 then
            TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
                success = false,
                message = 'Application not found'
            })
            return
        end
        
        local application = app[1]
        
        -- Update application status
        MySQL.query.await([[
            UPDATE ec_whitelist_applications 
            SET status = 'approved', reviewed_by = ?, reviewed_at = NOW()
            WHERE id = ?
        ]], {GetPlayerName(src), data.id})
        
        -- Add to whitelist
        local roles = json.encode(data.roles or {'whitelist'})
        
        MySQL.query.await([[
            INSERT INTO ec_whitelist 
            (identifier, name, steam_id, license, discord_id, roles, status, added_by, priority, notes)
            VALUES (?, ?, ?, ?, ?, ?, 'active', ?, 'normal', ?)
        ]], {
            application.identifier,
            application.applicant_name,
            application.steam_id,
            application.license,
            application.discord_id,
            roles,
            GetPlayerName(src),
            'Approved from application #' .. data.id
        })
        
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = true,
            message = 'Application approved and player whitelisted'
        })

    Logger.Info(string.format('[Whitelist] %s approved application for %s', GetPlayerName(src), application.applicant_name))
    end)
end)

-- Deny application
RegisterNetEvent('ec_admin_ultimate:server:denyApplication', function(data)
    local src = source

    if not data.id then
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = false,
            message = 'Application ID is required'
        })
        return
    end

    CreateThread(function()
        MySQL.query.await([[
            UPDATE ec_whitelist_applications
            SET status = 'denied', reviewed_by = ?, reviewed_at = NOW(), deny_reason = ?
            WHERE id = ?
        ]], {GetPlayerName(src), data.reason or 'No reason provided', data.id})

        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = true,
            message = 'Application denied'
        })

    Logger.Info(string.format('[Whitelist] %s denied application ID %s', GetPlayerName(src), tostring(data.id)))
    end)
end)

-- Create role
RegisterNetEvent('ec_admin_ultimate:server:createRole', function(data)
    local src = source
    
    if not data.name or not data.displayName then
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = false,
            message = 'Role name and display name are required'
        })
        return
    end
    
    local permissions = json.encode(data.permissions or {})
    
    MySQL.Async.execute([[
        INSERT INTO ec_whitelist_roles (name, display_name, priority, color, permissions, is_default)
        VALUES (?, ?, ?, ?, ?, 0)
    ]], {
        data.name,
        data.displayName,
        data.priority or 50,
        data.color or '#3b82f6',
        permissions
    })
    
    TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
        success = true,
        message = 'Role created successfully'
    })
    
    Logger.Info(string.format('[Whitelist] %s created role %s', GetPlayerName(src), data.displayName))
end)

-- Update role
RegisterNetEvent('ec_admin_ultimate:server:updateRole', function(data)
    local src = source
    
    if not data.id then
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = false,
            message = 'Role ID is required'
        })
        return
    end
    
    local permissions = json.encode(data.permissions or {})
    
    MySQL.Async.execute([[
        UPDATE ec_whitelist_roles 
        SET display_name = ?, priority = ?, color = ?, permissions = ?
        WHERE id = ?
    ]], {
        data.displayName,
        data.priority or 50,
        data.color or '#3b82f6',
        permissions,
        data.id
    })
    
    TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
        success = true,
        message = 'Role updated successfully'
    })
    
    Logger.Info(string.format('[Whitelist] %s updated role ID %s', GetPlayerName(src), tostring(data.id)))
end)

-- Delete role
RegisterNetEvent('ec_admin_ultimate:server:deleteRole', function(data)
    local src = source
    
    if not data.id then
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = false,
            message = 'Role ID is required'
        })
        return
    end
    
    CreateThread(function()
        -- Check if it's a default role
        local role = MySQL.query.await('SELECT is_default, display_name FROM ec_whitelist_roles WHERE id = ? LIMIT 1', {data.id})
        
        if role and #role > 0 and role[1].is_default == 1 then
            TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
                success = false,
                message = 'Cannot delete default roles'
            })
            return
        end
        
        MySQL.query.await('DELETE FROM ec_whitelist_roles WHERE id = ? AND is_default = 0', {data.id})
        
        TriggerClientEvent('ec_admin_ultimate:client:whitelistResponse', src, {
            success = true,
            message = 'Role deleted successfully'
        })
        
        if role and #role > 0 then
            Logger.Info(string.format('[Whitelist] %s deleted role %s', GetPlayerName(src), role[1].display_name))
        end
    end)
end)

-- Check if player is whitelisted (export - async version)
exports('IsWhitelisted', function(identifier, callback)
    CreateThread(function()
        local result = MySQL.scalar.await([[
            SELECT COUNT(*) FROM ec_whitelist
            WHERE (identifier = ? OR steam_id = ? OR license = ?)
            AND status = 'active'
        ]], {identifier, identifier, identifier})
        
        local isWhitelisted = result and result > 0
        
        if callback then
            callback(isWhitelisted)
        end
        
        return isWhitelisted
    end)
end)

Logger.Info('Whitelist NUI callbacks loaded')