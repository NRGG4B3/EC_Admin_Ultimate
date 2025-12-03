--[[
    EC Admin Ultimate - Global Ban System Integration
    Full integration with NRG Global Ban API
    - Check global bans on player join
    - Sync local bans to global API
    - Sync global bans to local database
    - Admin UI for managing global bans
]]--

Logger.Info('🌐 Loading Global Ban Integration...')

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local GLOBAL_BAN_ENABLED = Config and Config.APIs and Config.APIs.GlobalBans and Config.APIs.GlobalBans.enabled or false
local BYPASS_OWNERS = Config and Config.APIs and Config.APIs.GlobalBans and Config.APIs.GlobalBans.bypassOwners or true
local BYPASS_NRG_STAFF = Config and Config.APIs and Config.APIs.GlobalBans and Config.APIs.GlobalBans.bypassNRGStaff or true

-- Get API URL based on mode
local function GetGlobalBanAPIURL()
    local hostFolderExists = LoadResourceFile(GetCurrentResourceName(), 'host/README.md') ~= nil
    
    if hostFolderExists then
        -- HOST MODE: Use local multi-port server (Port 3001)
        return 'http://127.0.0.1:3001/api/global-bans'
    else
        -- CUSTOMER MODE: Use production API
        return 'https://api.ecbetasolutions.com/global-bans'
    end
end

local GLOBAL_BAN_API = GetGlobalBanAPIURL()

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get API key from registration
local function GetAPIKey()
    local isRegistered, regData = IsGlobalBanRegistered()
    if isRegistered and regData then
        return regData.apiKey
    end
    return nil
end

-- Get server ID from registration
local function GetServerId()
    local isRegistered, regData = IsGlobalBanRegistered()
    if isRegistered and regData then
        return regData.serverId
    end
    return nil
end

-- Check if player is owner
local function IsPlayerOwner(source)
    if not BYPASS_OWNERS then return false end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return false end
    
    -- Check against owner identifiers in config
    local ownerSteam = GetConvar('ec_owner_steam', '')
    local ownerLicense = GetConvar('ec_owner_license', '')
    local ownerFivem = GetConvar('ec_owner_fivem', '')
    local ownerDiscord = GetConvar('ec_owner_discord', '')
    
    for _, id in pairs(identifiers) do
        if ownerSteam ~= '' and id == ownerSteam then return true end
        if ownerLicense ~= '' and id == ownerLicense then return true end
        if ownerFivem ~= '' and id == ownerFivem then return true end
        if ownerDiscord ~= '' and id == ownerDiscord then return true end
    end
    
    return false
end

-- Check if player is NRG staff
local function IsPlayerNRGStaff(source)
    if not BYPASS_NRG_STAFF then return false end
    
    -- Use NRG staff auto-access system
    if _G.IsNRGStaff then
        local isStaff, staffData = _G.IsNRGStaff(source)
        return isStaff
    end
    
    return false
end

-- Get all player identifiers
local function GetAllIdentifiers(source)
    local identifiers = GetPlayerIdentifiers(source)
    local ids = {
        license = nil,
        steam = nil,
        fivem = nil,
        discord = nil,
        ip = nil
    }
    
    if not identifiers then return ids end
    
    for _, id in pairs(identifiers) do
        if string.find(id, 'license:') then
            ids.license = id
        elseif string.find(id, 'steam:') then
            ids.steam = id
        elseif string.find(id, 'fivem:') then
            ids.fivem = id
        elseif string.find(id, 'discord:') then
            ids.discord = id
        elseif string.find(id, 'ip:') then
            ids.ip = id
        end
    end
    
    return ids
end

-- ============================================================================
-- GLOBAL BAN CHECKING (ON PLAYER JOIN)
-- ============================================================================

-- Check if player is globally banned
function CheckGlobalBan(source, callback)
    if not GLOBAL_BAN_ENABLED then
        callback(false, nil)
        return
    end
    
    -- Bypass for owners
    if IsPlayerOwner(source) then
        Logger.Warn(string.format('⚠️ Skipping ban check for server owner (Source: %s)', source))
        callback(false, nil)
        return
    end
    
    -- Bypass for NRG staff
    if IsPlayerNRGStaff(source) then
        Logger.Warn(string.format('⚠️ Skipping ban check for NRG staff (Source: %s)', source))
        callback(false, nil)
        return
    end
    
    local apiKey = GetAPIKey()
    if not apiKey then
        Logger.Warn('⚠️ No API key found, skipping global ban check')
        callback(false, nil)
        return
    end
    
    local ids = GetAllIdentifiers(source)
    if not ids.license then
        Logger.Warn('⚠️ No license found for player, skipping check')
        callback(false, nil)
        return
    end
    
    local playerName = GetPlayerName(source)
    
    -- Query global ban API
    local url = GLOBAL_BAN_API .. '/check'
    local payload = {
        license = ids.license,
        steam = ids.steam,
        fivem = ids.fivem,
        discord = ids.discord,
        ip = ids.ip
    }
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data then
                if data.banned then
                    Logger.Error(string.format('🚫 Player %s is GLOBALLY BANNED', playerName))
                    callback(true, data)
                else
                    Logger.Info(string.format('✅ Player %s is not globally banned', playerName))
                    callback(false, nil)
                end
            else
                Logger.Warn('⚠️ Invalid response from API')
                callback(false, nil)
            end
        elseif statusCode == 404 then
            -- API endpoint not found - silently allow connection (API might not be set up yet)
            -- Logger.Debug('ℹ️ API endpoint not found (404) - allowing connection')
            callback(false, nil)
        elseif statusCode == 0 then
            -- Connection failed - silently allow connection (offline server, etc)
            -- Logger.Debug('ℹ️ Could not connect to Global Ban API - allowing connection')
            callback(false, nil)
        else
            -- Only log on non-404/0 errors to reduce spam
            Logger.Warn(string.format('⚠️ API request failed (Status: %s) - allowing connection', statusCode))
            callback(false, nil)
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
        ['X-API-Key'] = apiKey
    })
end

-- ============================================================================
-- PLAYER CONNECTION EVENT - CHECK GLOBAL BANS
-- ============================================================================

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    if not GLOBAL_BAN_ENABLED then return end
    
    local source = source
    
    -- Use deferrals for async check
    deferrals.defer()
    
    -- Wait a bit to ensure identifiers are available
    Wait(100)
    
    deferrals.update('Checking global ban status...')
    
    CheckGlobalBan(source, function(isBanned, banData)
        if isBanned and banData then
            -- Player is globally banned
            local reason = banData.reason or 'Banned from NRG network'
            local bannedBy = banData.bannedBy or 'System'
            local date = banData.date or 'Unknown'
            
            local kickMessage = string.format([[
🚫 GLOBAL BAN - NRG Network

You are banned from this server.

Reason: %s
Banned By: %s
Date: %s

This ban is synchronized across all NRG servers.
To appeal, visit: https://discord.gg/nrg
            ]], reason, bannedBy, date)
            
            deferrals.done(kickMessage)
            
            Logger.Error(string.format('🚫 Blocked connection: %s (License: %s)', playerName, banData.license or 'Unknown'))
        else
            -- Player is not banned, allow connection
            deferrals.done()
        end
    end)
end)

-- ============================================================================
-- SYNC LOCAL BAN TO GLOBAL API
-- ============================================================================

function SyncBanToGlobalAPI(banData, callback)
    if not GLOBAL_BAN_ENABLED then
        if callback then callback(false, 'Global bans disabled') end
        return
    end
    
    local apiKey = GetAPIKey()
    local serverId = GetServerId()
    
    if not apiKey or not serverId then
        Logger.Warn('⚠️ Not registered with Global Ban API')
        if callback then callback(false, 'Not registered') end
        return
    end
    
    local url = GLOBAL_BAN_API .. '/add'
    local payload = {
        serverId = serverId,
        license = banData.license,
        steam = banData.steam,
        fivem = banData.fivem,
        discord = banData.discord,
        ip = banData.ip,
        playerName = banData.playerName,
        reason = banData.reason,
        bannedBy = banData.bannedBy,
        duration = banData.duration or 0, -- 0 = permanent
        evidence = banData.evidence or {},
        metadata = banData.metadata or {}
    }
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 or statusCode == 201 then
            Logger.Success(string.format('✅ Ban synced to global API: %s', banData.playerName))
            if callback then callback(true, 'Ban synced') end
        else
            Logger.Error(string.format('❌ Failed to sync ban (Status: %s)', statusCode))
            if callback then callback(false, 'API error') end
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
        ['X-API-Key'] = apiKey
    })
end

-- ============================================================================
-- SYNC GLOBAL BAN TO LOCAL DATABASE
-- ============================================================================

function SyncGlobalBanToLocal(globalBanData)
    if not globalBanData or not globalBanData.license then return end
    
    -- Insert into local bans table
    if MySQL and MySQL.Async then
        MySQL.Async.execute([[
            INSERT INTO bans (license, name, reason, bannedby, expire, timestamp)
            VALUES (@license, @name, @reason, @bannedby, @expire, @timestamp)
            ON DUPLICATE KEY UPDATE
                name = @name,
                reason = @reason,
                bannedby = @bannedby,
                expire = @expire
        ]], {
            ['@license'] = globalBanData.license,
            ['@name'] = globalBanData.playerName or 'Unknown',
            ['@reason'] = '[GLOBAL BAN] ' .. (globalBanData.reason or 'No reason'),
            ['@bannedby'] = globalBanData.bannedBy or 'Global Ban System',
            ['@expire'] = globalBanData.duration == 0 and 0 or (os.time() + globalBanData.duration),
            ['@timestamp'] = os.time()
        end, function(rowsChanged)
            if rowsChanged > 0 then
                Logger.Success(string.format('✅ Synced global ban to local: %s', globalBanData.playerName))
            end
        end)
    end
end

-- ============================================================================
-- REMOVE GLOBAL BAN
-- ============================================================================

function RemoveGlobalBan(license, callback)
    if not GLOBAL_BAN_ENABLED then
        if callback then callback(false, 'Global bans disabled') end
        return
    end
    
    local apiKey = GetAPIKey()
    local serverId = GetServerId()
    
    if not apiKey or not serverId then
        if callback then callback(false, 'Not registered') end
        return
    end
    
    local url = GLOBAL_BAN_API .. '/remove'
    local payload = {
        serverId = serverId,
        license = license
    }
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            Logger.Success(string.format('✅ Removed global ban: %s', license))
            if callback then callback(true, 'Ban removed') end
        else
            Logger.Error(string.format('❌ Failed to remove ban (Status: %s)', statusCode))
            if callback then callback(false, 'API error') end
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
        ['X-API-Key'] = apiKey
    })
end

-- ============================================================================
-- GET ALL GLOBAL BANS (FOR UI)
-- ============================================================================

function GetAllGlobalBans(callback)
    if not GLOBAL_BAN_ENABLED then
        if callback then callback(false, {}) end
        return
    end
    
    local apiKey = GetAPIKey()
    local serverId = GetServerId()
    
    if not apiKey or not serverId then
        if callback then callback(false, {}) end
        return
    end
    
    local url = GLOBAL_BAN_API .. '/list?serverId=' .. serverId
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data and data.bans then
                if callback then callback(true, data.bans) end
            else
                if callback then callback(false, {}) end
            end
        else
            if callback then callback(false, {}) end
        end
    end, 'GET', '', {
        ['X-API-Key'] = apiKey
    })
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

-- Ban player globally
RegisterNetEvent('ec_admin:globalBanPlayer', function(data)
    local src = source
    
    -- Permission check
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(src, 'moderation.ban') then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'No permission'
        })
        return
    end
    
    local targetId = data.playerId
    local reason = data.reason or 'No reason provided'
    local duration = data.duration or 0 -- 0 = permanent
    
    if not targetId then return end
    
    -- Check if target is owner or NRG staff
    if IsPlayerOwner(targetId) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Cannot ban server owner'
        })
        return
    end
    
    if IsPlayerNRGStaff(targetId) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Cannot ban NRG staff'
        })
        return
    end
    
    local ids = GetAllIdentifiers(targetId)
    local playerName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)
    
    local banData = {
        license = ids.license,
        steam = ids.steam,
        fivem = ids.fivem,
        discord = ids.discord,
        ip = ids.ip,
        playerName = playerName,
        reason = reason,
        bannedBy = adminName,
        duration = duration
    }
    
    -- Sync to global API
    SyncBanToGlobalAPI(banData, function(success, message)
        if success then
            -- Also ban locally
            SyncGlobalBanToLocal(banData)
            
            -- Kick player
            DropPlayer(targetId, string.format('🚫 GLOBAL BAN\n\nReason: %s\nBanned By: %s\n\nThis ban is synchronized across all NRG servers.', reason, adminName))
            
            TriggerClientEvent('ec_admin:notify', src, {
                type = 'success',
                message = 'Player globally banned'
            })
            
            Logger.Success(string.format('🚫 %s globally banned %s (Reason: %s)', adminName, playerName, reason))
        else
            TriggerClientEvent('ec_admin:notify', src, {
                type = 'error',
                message = 'Failed to sync global ban'
            })
        end
    end)
end)

-- Unban player globally
RegisterNetEvent('ec_admin:globalUnbanPlayer', function(data)
    local src = source
    
    -- Permission check
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(src, 'moderation.unban') then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'No permission'
        })
        return
    end
    
    local license = data.license
    if not license then return end
    
    RemoveGlobalBan(license, function(success, message)
        if success then
            -- Also remove from local database
            if MySQL and MySQL.Async then
                MySQL.Async.execute('DELETE FROM ec_admin_bans WHERE license = @license', {
                    ['@license'] = license
                })
            end
            
            TriggerClientEvent('ec_admin:notify', src, {
                type = 'success',
                message = 'Player globally unbanned'
            })
            
            Logger.Success(string.format('✅ %s removed global ban: %s', GetPlayerName(src), license))
        else
            TriggerClientEvent('ec_admin:notify', src, {
                type = 'error',
                message = 'Failed to remove global ban'
            })
        end
    end)
end)

-- Get global bans for UI
lib.callback.register('ec_admin:getGlobalBans', function(source)
    local result = {}
    local success = false
    
    GetAllGlobalBans(function(ok, bans)
        success = ok
        result = bans
    end)
    
    -- Wait for async callback
    Wait(1000)
    
    return {
        success = success,
        bans = result
    }
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('CheckGlobalBan', CheckGlobalBan)
exports('SyncBanToGlobalAPI', SyncBanToGlobalAPI)
exports('RemoveGlobalBan', RemoveGlobalBan)
exports('GetAllGlobalBans', GetAllGlobalBans)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

if GLOBAL_BAN_ENABLED then
    Logger.Info('✅ Global Ban Integration loaded')
    Logger.Info('🌐 Checking global bans on player join')
    Logger.Info('🔄 Syncing local bans to global API')
    
    if BYPASS_OWNERS then
        Logger.Info('⚠️  Server owners bypass global bans')
    end
    
    if BYPASS_NRG_STAFF then
        Logger.Info('⚠️  NRG staff bypass global bans')
    end
else
    Logger.Info('⚠️  Global Ban Integration disabled in config')
end

return {
    CheckGlobalBan = CheckGlobalBan,
    SyncBanToGlobalAPI = SyncBanToGlobalAPI,
    RemoveGlobalBan = RemoveGlobalBan,
    GetAllGlobalBans = GetAllGlobalBans
}