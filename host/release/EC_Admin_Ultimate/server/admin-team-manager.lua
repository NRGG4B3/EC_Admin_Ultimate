--[[
    EC Admin Ultimate - Admin Team Manager
    Manages admin team members from config and database
    Supports Discord role-based permissions
]]

local AdminTeam = {
    members = {},
    discordCache = {},
    initialized = false
}

-- Initialize admin team from config
function AdminTeam.Init()
    if AdminTeam.initialized then
        return
    end
    
    Logger.Info('👥 Loading Admin Team Manager...')
    
    -- Load from config
    if Config and Config.AdminTeam and Config.AdminTeam.members then
        for _, member in ipairs(Config.AdminTeam.members) do
            AdminTeam.AddMember(member.identifier, member.name, member.rank, member.permissions)
        end
        Logger.Info(string.format('', #Config.AdminTeam.members))
    end
    
    -- Load from database
    if MySQL and Config.Database and Config.Database.enabled then
        MySQL.query('SELECT * FROM ec_admin_team', {}, function(results)
            if results then
                for _, member in ipairs(results) do
                    local permissions = json.decode(member.permissions) or {}
                    AdminTeam.AddMember(member.identifier, member.name, member.rank, permissions, true)
                end
                Logger.Info(string.format('', #results))
            end
        end)
    end
    
    -- Initialize Discord permissions if enabled
    if Config and Config.Discord and Config.Discord.rolePermissions and Config.Discord.rolePermissions.enabled then
        AdminTeam.InitDiscordPermissions()
    end
    
    AdminTeam.initialized = true
    Logger.Info('✅ Admin Team Manager loaded')
end

-- Add admin team member
function AdminTeam.AddMember(identifier, name, rank, permissions, fromDatabase)
    if not identifier then
        return false, 'Identifier required'
    end
    
    -- Check if member already exists
    if AdminTeam.members[identifier] then
        return false, 'Member already exists'
    end
    
    -- Get rank template permissions
    local rankPermissions = {}
    if rank and Config.AdminTeam and Config.AdminTeam.ranks and Config.AdminTeam.ranks[rank] then
        rankPermissions = Config.AdminTeam.ranks[rank].permissions or {}
    end
    
    -- Merge rank permissions with custom permissions
    local allPermissions = {}
    for _, perm in ipairs(rankPermissions) do
        table.insert(allPermissions, perm)
    end
    if permissions then
        for _, perm in ipairs(permissions) do
            if not table.contains(allPermissions, perm) then
                table.insert(allPermissions, perm)
            end
        end
    end
    
    -- Create member entry
    AdminTeam.members[identifier] = {
        identifier = identifier,
        name = name or 'Unknown',
        rank = rank or 'admin',
        permissions = allPermissions,
        addedAt = os.time()
    }
    
    -- Grant permissions
    for _, permission in ipairs(allPermissions) do
        EC_Perms.Grant(identifier, permission)
    end
    
    -- Save to database if not from database
    if not fromDatabase and MySQL and Config.Database and Config.Database.enabled then
        MySQL.insert('INSERT INTO ec_admin_team (identifier, name, rank, permissions, added_at) VALUES (?, ?, ?, ?, ?)', {
            identifier,
            name or 'Unknown',
            rank or 'admin',
            json.encode(allPermissions),
            os.time()
        })
    end
    
    Logger.Info(string.format('', name or 'Unknown', identifier))
    
    return true, 'Member added successfully'
end

-- Remove admin team member
function AdminTeam.RemoveMember(identifier)
    if not AdminTeam.members[identifier] then
        return false, 'Member not found'
    end
    
    local member = AdminTeam.members[identifier]
    
    -- Revoke permissions
    for _, permission in ipairs(member.permissions) do
        EC_Perms.Revoke(identifier, permission)
    end
    
    -- Remove from memory
    AdminTeam.members[identifier] = nil
    
    -- Remove from database
    if MySQL and Config.Database and Config.Database.enabled then
        MySQL.execute('DELETE FROM ec_admin_team WHERE identifier = ?', {identifier})
    end
    
    Logger.Info(string.format('', member.name, identifier))
    
    return true, 'Member removed successfully'
end

-- Update admin team member
function AdminTeam.UpdateMember(identifier, data)
    if not AdminTeam.members[identifier] then
        return false, 'Member not found'
    end
    
    local member = AdminTeam.members[identifier]
    
    -- Update name
    if data.name then
        member.name = data.name
    end
    
    -- Update rank and permissions
    if data.rank then
        member.rank = data.rank
        
        -- Get new rank permissions
        local rankPermissions = {}
        if Config.AdminTeam and Config.AdminTeam.ranks and Config.AdminTeam.ranks[data.rank] then
            rankPermissions = Config.AdminTeam.ranks[data.rank].permissions or {}
        end
        
        -- Revoke old permissions
        for _, permission in ipairs(member.permissions) do
            EC_Perms.Revoke(identifier, permission)
        end
        
        -- Grant new permissions
        member.permissions = rankPermissions
        for _, permission in ipairs(rankPermissions) do
            EC_Perms.Grant(identifier, permission)
        end
    end
    
    -- Update custom permissions
    if data.permissions then
        -- Revoke old custom permissions
        for _, permission in ipairs(member.permissions) do
            EC_Perms.Revoke(identifier, permission)
        end
        
        -- Grant new permissions
        member.permissions = data.permissions
        for _, permission in ipairs(data.permissions) do
            EC_Perms.Grant(identifier, permission)
        end
    end
    
    -- Update database
    if MySQL and Config.Database and Config.Database.enabled then
        MySQL.execute('UPDATE ec_admin_team SET name = ?, rank = ?, permissions = ? WHERE identifier = ?', {
            member.name,
            member.rank,
            json.encode(member.permissions),
            identifier
        })
    end
    
    Logger.Info(string.format('', member.name, identifier))
    
    return true, 'Member updated successfully'
end

-- Get all admin team members
function AdminTeam.GetAll()
    local members = {}
    for identifier, member in pairs(AdminTeam.members) do
        table.insert(members, member)
    end
    return members
end

-- Get member by identifier
function AdminTeam.GetMember(identifier)
    return AdminTeam.members[identifier]
end

-- Initialize Discord permissions
function AdminTeam.InitDiscordPermissions()
    Logger.Info('🎮 Initializing Discord role-based permissions...')
    
    if not Config.Discord.rolePermissions.guildId or Config.Discord.rolePermissions.guildId == '' then
        Logger.Info('⚠️  Discord Guild ID not configured')
        return
    end
    
    if not Config.Discord.rolePermissions.botToken or Config.Discord.rolePermissions.botToken == '' then
        Logger.Info('⚠️  Discord Bot Token not configured')
        return
    end
    
    Logger.Info('✅ Discord role-based permissions initialized')
    Logger.Info('💡 Players with Discord roles will auto-receive permissions')
end

-- Check player Discord roles and grant permissions
function AdminTeam.CheckDiscordRoles(source)
    if not Config.Discord or not Config.Discord.rolePermissions or not Config.Discord.rolePermissions.enabled then
        return
    end
    
    -- Get player Discord ID
    local discordId = nil
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.match(id, 'discord:') then
            discordId = string.gsub(id, 'discord:', '')
            break
        end
    end
    
    if not discordId then
        return
    end
    
    -- Check cache first
    if AdminTeam.discordCache[discordId] and (os.time() - AdminTeam.discordCache[discordId].timestamp) < 300 then
        return AdminTeam.discordCache[discordId].permissions
    end
    
    -- Fetch Discord roles
    local guildId = Config.Discord.rolePermissions.guildId
    local botToken = Config.Discord.rolePermissions.botToken
    local url = string.format('https://discord.com/api/v10/guilds/%s/members/%s', guildId, discordId)
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data and data.roles then
                local permissions = {}
                
                -- Check full access roles
                for _, roleId in ipairs(data.roles) do
                    if table.contains(Config.Discord.rolePermissions.fullAccessRoles, roleId) then
                        table.insert(permissions, 'ec_admin.all')
                    end
                end
                
                -- Check super admin roles
                for _, roleId in ipairs(data.roles) do
                    if table.contains(Config.Discord.rolePermissions.superAdminRoles, roleId) then
                        table.insert(permissions, 'ec_admin.super')
                    end
                end
                
                -- Check admin roles
                for _, roleId in ipairs(data.roles) do
                    if table.contains(Config.Discord.rolePermissions.adminRoles, roleId) then
                        table.insert(permissions, 'ec_admin.menu')
                    end
                end
                
                -- Grant permissions
                local identifier = GetPlayerIdentifier(source, 0)
                for _, permission in ipairs(permissions) do
                    EC_Perms.Grant(identifier, permission)
                end
                
                -- Cache result
                AdminTeam.discordCache[discordId] = {
                    permissions = permissions,
                    timestamp = os.time()
                }
                
                if #permissions > 0 then
                    Logger.Info(string.format('', GetPlayerName(source), #permissions))
                end
            end
        end
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. botToken,
        ['Content-Type'] = 'application/json'
    })
end

-- Player joined event - check Discord roles
AddEventHandler('playerJoining', function()
    local source = source
    SetTimeout(5000, function()
        AdminTeam.CheckDiscordRoles(source)
    end)
end)

-- Initialize on resource start
CreateThread(function()
    Wait(3000)  -- Wait for config and database
    AdminTeam.Init()
end)

-- Exports
exports('AddAdminMember', AdminTeam.AddMember)
exports('RemoveAdminMember', AdminTeam.RemoveMember)
exports('UpdateAdminMember', AdminTeam.UpdateMember)
exports('GetAdminTeam', AdminTeam.GetAll)
exports('GetAdminMember', AdminTeam.GetMember)

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
