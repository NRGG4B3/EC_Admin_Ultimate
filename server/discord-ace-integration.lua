--[[
    EC Admin Ultimate - Discord ACE Integration
    Auto-grants ACE permissions based on Discord roles
    
    Features:
    - Fetches Discord roles on player join
    - Maps Discord roles to ACE permissions
    - Auto-grants ACE perms dynamically
    - Caches Discord roles for performance
    - Syncs with existing permission system
]]

local DiscordACE = {
    cache = {},  -- Discord role cache
    playerAces = {},  -- Track granted ACEs per player
    initialized = false
}

-- Initialize Discord ACE integration
function DiscordACE.Init()
    if DiscordACE.initialized then
        return
    end
    
    if not Config or not Config.Discord or not Config.Discord.rolePermissions or not Config.Discord.rolePermissions.enabled then
        Logger.Warn('⚠️ Discord role permissions disabled in config')
        return
    end
    
    if not Config.Discord.rolePermissions.guildId or Config.Discord.rolePermissions.guildId == '' then
        Logger.Error('❌ Discord Guild ID not configured')
        Logger.Error('ℹ️ Set Config.Discord.rolePermissions.guildId in config.lua')
        return
    end
    
    if not Config.Discord.rolePermissions.botToken or Config.Discord.rolePermissions.botToken == '' then
        Logger.Error('❌ Discord Bot Token not configured')
        Logger.Error('ℹ️ Set Config.Discord.rolePermissions.botToken in config.lua')
        return
    end
    
    Logger.Success('✅ Discord ACE Integration initialized')
    Logger.Info('🎮 Discord roles will auto-grant ACE permissions')
    
    DiscordACE.initialized = true
end

-- Get player Discord ID
function DiscordACE.GetDiscordId(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then
        return nil
    end
    
    for _, id in ipairs(identifiers) do
        if string.match(id, 'discord:') then
            return string.gsub(id, 'discord:', '')
        end
    end
    
    return nil
end

-- Fetch Discord roles from API
function DiscordACE.FetchRoles(discordId, callback)
    if not discordId then
        callback(nil)
        return
    end
    
    -- Check cache first (5 minute cache)
    if DiscordACE.cache[discordId] and (os.time() - DiscordACE.cache[discordId].timestamp) < 300 then
        callback(DiscordACE.cache[discordId].roles)
        return
    end
    
    local guildId = Config.Discord.rolePermissions.guildId
    local botToken = Config.Discord.rolePermissions.botToken
    local url = string.format('https://discord.com/api/v10/guilds/%s/members/%s', guildId, discordId)
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data and data.roles then
                -- Cache the roles
                DiscordACE.cache[discordId] = {
                    roles = data.roles,
                    timestamp = os.time()
                }
                
                callback(data.roles)
                return
            end
        elseif statusCode == 404 then
            Logger.Warn(string.format('⚠️ Player not found in Discord server (ID: %s)', discordId))
        elseif statusCode == 401 then
            Logger.Error('❌ Invalid bot token')
        elseif statusCode == 403 then
            Logger.Error('❌ Bot does not have access to this server')
        else
            Logger.Error(string.format('⚠️ Discord API error: %d', statusCode))
        end
        
        callback(nil)
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. botToken,
        ['Content-Type'] = 'application/json'
    })
end

-- Map Discord roles to ACE permissions
function DiscordACE.MapRolesToACE(roles)
    local acePermissions = {}
    
    if not roles or not Config.Discord or not Config.Discord.rolePermissions then
        return acePermissions
    end
    
    -- Check full access roles (grant all permissions)
    if Config.Discord.rolePermissions.fullAccessRoles then
        for _, roleId in ipairs(roles) do
            for _, fullAccessRole in ipairs(Config.Discord.rolePermissions.fullAccessRoles) do
                if roleId == fullAccessRole then
                    table.insert(acePermissions, 'ec_admin.all')
                    table.insert(acePermissions, 'ec_admin.super')
                    table.insert(acePermissions, 'ec_admin.menu')
                    Logger.Success('✅ Full Access role detected')
                    return acePermissions  -- Full access, no need to check other roles
                end
            end
        end
    end
    
    -- Check super admin roles
    if Config.Discord.rolePermissions.superAdminRoles then
        for _, roleId in ipairs(roles) do
            for _, superAdminRole in ipairs(Config.Discord.rolePermissions.superAdminRoles) do
                if roleId == superAdminRole then
                    table.insert(acePermissions, 'ec_admin.super')
                    table.insert(acePermissions, 'ec_admin.menu')
                    Logger.Success('✅ Super Admin role detected')
                end
            end
        end
    end
    
    -- Check admin roles
    if Config.Discord.rolePermissions.adminRoles then
        for _, roleId in ipairs(roles) do
            for _, adminRole in ipairs(Config.Discord.rolePermissions.adminRoles) do
                if roleId == adminRole then
                    if not table.contains(acePermissions, 'ec_admin.menu') then
                        table.insert(acePermissions, 'ec_admin.menu')
                        Logger.Success('✅ Admin role detected')
                    end
                end
            end
        end
    end
    
    -- Add custom role mappings if configured
    if Config.Discord.rolePermissions.customRoleMappings then
        for _, mapping in ipairs(Config.Discord.rolePermissions.customRoleMappings) do
            for _, roleId in ipairs(roles) do
                if roleId == mapping.roleId then
                    for _, permission in ipairs(mapping.acePermissions or {}) do
                        if not table.contains(acePermissions, permission) then
                            table.insert(acePermissions, permission)
                        end
                    end
                end
            end
        end
    end
    
    return acePermissions
end

-- Grant ACE permissions to player
function DiscordACE.GrantACE(source, permissions)
    if not source or not permissions or #permissions == 0 then
        return
    end
    
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then
        return
    end
    
    -- Track granted ACEs for this player
    DiscordACE.playerAces[source] = DiscordACE.playerAces[source] or {}
    
    for _, permission in ipairs(permissions) do
        -- Grant ACE permission dynamically
        ExecuteCommand(string.format('add_principal identifier.%s ec_admin.%s allow', identifier, permission:gsub('ec_admin%.', '')))
        
        -- Track it
        table.insert(DiscordACE.playerAces[source], permission)
        
        Logger.Success(string.format('✅ Granted %s to %s (%s)', permission, GetPlayerName(source) or 'Unknown', identifier))
    end
end

-- Revoke ACE permissions from player
function DiscordACE.RevokeACE(source)
    if not DiscordACE.playerAces[source] then
        return
    end
    
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then
        return
    end
    
    for _, permission in ipairs(DiscordACE.playerAces[source]) do
        -- Revoke ACE permission
        ExecuteCommand(string.format('remove_principal identifier.%s ec_admin.%s', identifier, permission:gsub('ec_admin%.', '')))
        
        Logger.Warn(string.format('⚠️ Revoked %s from %s (%s)', permission, GetPlayerName(source) or 'Unknown', identifier))
    end
    
    DiscordACE.playerAces[source] = nil
end

-- Process player Discord roles and grant ACE
function DiscordACE.ProcessPlayer(source)
    if not DiscordACE.initialized then
        return
    end
    
    local discordId = DiscordACE.GetDiscordId(source)
    if not discordId then
        Logger.Warn(string.format('⚠️ Player %s has no Discord linked', GetPlayerName(source) or 'Unknown'))
        return
    end
    
    DiscordACE.FetchRoles(discordId, function(roles)
        if not roles then
            return
        end
        
        -- Map roles to ACE permissions
        local acePermissions = DiscordACE.MapRolesToACE(roles)
        
        if #acePermissions > 0 then
            -- Grant ACE permissions
            DiscordACE.GrantACE(source, acePermissions)
            
            Logger.Success(string.format('✅ Processed player %s: %d Discord roles → %d ACE permissions', 
                GetPlayerName(source) or 'Unknown', 
                #roles, 
                #acePermissions))
        else
            Logger.Info(string.format('ℹ️ Player %s has %d Discord roles but no matching admin roles', 
                GetPlayerName(source) or 'Unknown', 
                #roles))
        end
    end)
end

-- Player joining event
AddEventHandler('playerJoining', function()
    local source = source
    
    -- Wait 5 seconds for player to fully connect
    SetTimeout(5000, function()
        DiscordACE.ProcessPlayer(source)
    end)
end)

-- Player dropping event - revoke ACE permissions
AddEventHandler('playerDropped', function()
    local source = source
    DiscordACE.RevokeACE(source)
    
    -- Clear cache entry if exists
    local discordId = DiscordACE.GetDiscordId(source)
    if discordId and DiscordACE.cache[discordId] then
        DiscordACE.cache[discordId] = nil
    end
end)

-- Manual refresh command (for admins)
RegisterCommand('refreshdiscordace', function(source, args, rawCommand)
    if source == 0 then
        -- Console command - refresh all players
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            DiscordACE.ProcessPlayer(tonumber(playerId))
        end
        Logger.Success('✅ Refreshed all players')
    else
        -- Player command - refresh self
        if EC_Perms and EC_Perms.Has(source, 'ec_admin.super') then
            DiscordACE.ProcessPlayer(source)
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[Discord ACE]', 'Your Discord roles have been refreshed'}
            })
        else
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[Discord ACE]', 'No permission'}
            })
        end
    end
end, false)

-- Initialize on resource start
CreateThread(function()
    Wait(3000)  -- Wait for config and database
    DiscordACE.Init()
    
    -- Process all currently connected players
    if DiscordACE.initialized then
        Wait(5000)
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            DiscordACE.ProcessPlayer(tonumber(playerId))
        end
    end
end)

-- Periodic cache cleanup (every 10 minutes)
CreateThread(function()
    while true do
        Wait(600000)  -- 10 minutes
        
        local now = os.time()
        local cleaned = 0
        
        for discordId, data in pairs(DiscordACE.cache) do
            if (now - data.timestamp) > 600 then  -- Older than 10 minutes
                DiscordACE.cache[discordId] = nil
                cleaned = cleaned + 1
            end
        end
        
        if cleaned > 0 then
            Logger.Info(string.format('🧹 Cleaned %d expired cache entries', cleaned))
        end
    end
end)

-- Helper function for table.contains
if not table.contains then
    function table.contains(table, element)
        for _, value in pairs(table) do
            if value == element then
                return true
            end
        end
        return false
    end
end

-- Exports
exports('RefreshDiscordACE', DiscordACE.ProcessPlayer)
exports('GetDiscordRoles', DiscordACE.FetchRoles)

Logger.Success('[Discord ACE] Module loaded', '🎮')
