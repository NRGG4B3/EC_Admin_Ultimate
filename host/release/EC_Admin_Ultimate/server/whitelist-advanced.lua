-- EC Admin Ultimate - Advanced Whitelist & Connection Queue System
-- Complete whitelist management with applications, queue, roles, and Discord integration
Logger.Info('🛡️ Loading Advanced Whitelist & Queue System...')

-- Safety check: Ensure Config exists
if not Config then
    Logger.Info('')
    Config = {}
end

local Whitelist = {}
local Queue = {}
local Applications = {}
local Roles = {}

-- Data storage
local whitelistData = {
    whitelist = {},
    applications = {},
    queue = {},
    roles = {},
    settings = Config.Whitelist or {},
    rateLimit = {}
}

-- Initialize default roles
local function InitializeRoles()
    whitelistData.roles = {}
    
    -- Add default roles
    if Config.Whitelist and Config.Whitelist.roles and Config.Whitelist.roles.default then
        for _, role in ipairs(Config.Whitelist.roles.default) do
            table.insert(whitelistData.roles, {
                id = role.name,
                name = role.name,
                priority = role.priority,
                color = role.color,
                permissions = role.permissions or {},
                isDefault = true,
                createdAt = os.time() * 1000
            })
        end
    end
    
    -- Add custom roles
    if Config.Whitelist and Config.Whitelist.roles and Config.Whitelist.roles.custom then
        for _, role in ipairs(Config.Whitelist.roles.custom) do
            table.insert(whitelistData.roles, {
                id = role.name,
                name = role.name,
                priority = role.priority,
                color = role.color,
                permissions = role.permissions or {},
                isDefault = false,
                createdAt = os.time() * 1000
            })
        end
    end
    
    Logger.Info(string.format('', #whitelistData.roles))
end

-- Utility Functions
local function HasPermission(source, permission)
    if _G.ECPermissions then return _G.ECPermissions.HasPermission(source, permission or 'admin') end
    return IsPlayerAceAllowed(source, 'admin') or IsPlayerAceAllowed(source, permission or 'admin')
end

local function GenerateId()
    return os.date('%Y%m%d%H%M%S') .. '_' .. math.random(10000, 99999)
end

local function GetPlayerIdentifiers(source)
    local identifiers = {
        steamId = nil,
        license = nil,
        discordId = nil,
        ip = nil
    }
    
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local identifier = GetPlayerIdentifier(source, i)
        if identifier then
            if string.match(identifier, 'steam:') then
                identifiers.steamId = identifier
            elseif string.match(identifier, 'license:') then
                identifiers.license = identifier
            elseif string.match(identifier, 'discord:') then
                identifiers.discordId = identifier
            elseif string.match(identifier, 'ip:') then
                identifiers.ip = identifier
            end
        end
    end
    
    return identifiers
end

-- Role Management
function Roles.Get(identifier)
    local roles = {}
    
    for _, entry in ipairs(whitelistData.whitelist) do
        if entry.identifier == identifier or 
           entry.steamId == identifier or 
           entry.license == identifier or 
           entry.discordId == identifier then
            if entry.roles then
                for _, roleName in ipairs(entry.roles) do
                    table.insert(roles, roleName)
                end
            end
            break
        end
    end
    
    return roles
end

function Roles.GetPriority(identifier)
    local roles = Roles.Get(identifier)
    local maxPriority = 0
    
    if Config.Whitelist and Config.Whitelist.queue and Config.Whitelist.queue.priorities then
        for _, roleName in ipairs(roles) do
            local priority = Config.Whitelist.queue.priorities[roleName] or 0
            if priority > maxPriority then
                maxPriority = priority
            end
        end
    end
    
    -- Default priority if no roles
    if maxPriority == 0 and Config.Whitelist and Config.Whitelist.queue and Config.Whitelist.queue.priorities then
        maxPriority = Config.Whitelist.queue.priorities.default or 50
    end
    
    return maxPriority
end

function Roles.HasPermission(identifier, permission)
    local roles = Roles.Get(identifier)
    
    for _, roleName in ipairs(roles) do
        for _, role in ipairs(whitelistData.roles) do
            if role.name == roleName then
                for _, perm in ipairs(role.permissions or {}) do
                    if perm == permission or perm == 'admin' then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- Whitelist Functions
function Whitelist.IsWhitelisted(source)
    local settings = Config.Whitelist or whitelistData.settings
    
    if not settings.enabled then
        return true
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    
    for _, entry in ipairs(whitelistData.whitelist) do
        if entry.status == 'active' then
            if entry.identifier == identifiers.steamId or 
               entry.identifier == identifiers.license or 
               entry.identifier == identifiers.discordId or
               entry.steamId == identifiers.steamId or
               entry.license == identifiers.license or
               entry.discordId == identifiers.discordId then
                return true
            end
        end
    end
    
    return false
end

function Whitelist.Add(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end
    
    if not data.identifier or not data.name then
        return { success = false, message = 'Identifier and name required' }
    end
    
    -- Check if already whitelisted
    for _, entry in ipairs(whitelistData.whitelist) do
        if entry.identifier == data.identifier or 
           entry.steamId == data.steamId or 
           entry.license == data.license then
            return { success = false, message = 'Already whitelisted' }
        end
    end
    
    local entry = {
        id = GenerateId(),
        identifier = data.identifier,
        name = data.name,
        steamId = data.steamId,
        license = data.license,
        discordId = data.discordId,
        roles = data.roles or {'whitelist'},
        status = 'active',
        addedBy = GetPlayerName(source) or 'System',
        addedAt = os.time() * 1000,
        priority = data.priority or 'normal',
        notes = data.notes or ''
    }
    
    table.insert(whitelistData.whitelist, entry)
    
    -- Send Discord notification
    if _G.ECWebhooks then
        _G.ECWebhooks.SendLog('whitelist', {
            title = '✅ Whitelist Entry Added',
            description = string.format('**%s** added **%s** to whitelist\n\nRoles: %s', 
                GetPlayerName(source) or 'System', 
                entry.name,
                table.concat(entry.roles, ', ')
            ),
            color = 3066993,
            fields = {
                { name = 'Identifier', value = entry.identifier or 'N/A', inline = true },
                { name = 'Priority', value = entry.priority, inline = true }
            }
        })
    end
    
    Logger.Info(string.format('', 
        entry.name, table.concat(entry.roles, ', ')))
    
    return { success = true, message = 'Added to whitelist successfully', entry = entry }
end

function Whitelist.Remove(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end
    
    for i, entry in ipairs(whitelistData.whitelist) do
        if entry.id == data.id then
            table.remove(whitelistData.whitelist, i)
            
            if _G.ECWebhooks then
                _G.ECWebhooks.SendLog('whitelist', {
                    title = '❌ Whitelist Entry Removed',
                    description = string.format('**%s** removed **%s** from whitelist', 
                        GetPlayerName(source) or 'System', entry.name),
                    color = 15158332
                })
            end
            
            Logger.Info(string.format('', entry.name))
            return { success = true, message = 'Removed from whitelist' }
        end
    end
    
    return { success = false, message = 'Entry not found' }
end

function Whitelist.UpdateRoles(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end
    
    for _, entry in ipairs(whitelistData.whitelist) do
        if entry.id == data.id then
            entry.roles = data.roles
            Logger.Info(string.format('', 
                entry.name, table.concat(entry.roles, ', ')))
            return { success = true, message = 'Roles updated successfully' }
        end
    end
    
    return { success = false, message = 'Entry not found' }
end

-- Application Functions
function Applications.Submit(source, data)
    local settings = Config.Whitelist
    if not settings or not settings.application then
        return { success = false, message = 'Applications are not enabled' }
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    local identifier = identifiers.steamId or identifiers.license or identifiers.discordId
    
    if not identifier then
        return { success = false, message = 'No valid identifier found' }
    end
    
    -- Check if already whitelisted
    if Whitelist.IsWhitelisted(source) then
        return { success = false, message = 'You are already whitelisted' }
    end
    
    -- Rate limiting
    if settings.advanced and settings.advanced.rateLimit and settings.advanced.rateLimit.enabled then
        local rateLimitData = whitelistData.rateLimit[identifier]
        if rateLimitData then
            local now = os.time() * 1000
            local timeWindow = settings.advanced.rateLimit.timeWindow or 86400000
            local maxApplications = settings.advanced.rateLimit.maxApplications or 3
            
            if now - rateLimitData.firstAttempt < timeWindow then
                if rateLimitData.count >= maxApplications then
                    return { success = false, message = 'Too many applications. Please wait 24 hours.' }
                end
                rateLimitData.count = rateLimitData.count + 1
            else
                whitelistData.rateLimit[identifier] = { firstAttempt = now, count = 1 }
            end
        else
            whitelistData.rateLimit[identifier] = { firstAttempt = os.time() * 1000, count = 1 }
        end
    end
    
    -- Check for existing pending application
    for _, app in ipairs(whitelistData.applications) do
        if app.identifier == identifier and app.status == 'pending' then
            return { success = false, message = 'You already have a pending application' }
        end
    end
    
    -- Create application
    local application = {
        id = GenerateId(),
        identifier = identifier,
        steamId = identifiers.steamId,
        license = identifiers.license,
        discordId = identifiers.discordId,
        applicantName = data.name or GetPlayerName(source),
        age = data.age,
        discord = data.discord,
        reason = data.reason,
        experience = data.experience,
        referral = data.referral,
        status = 'pending',
        submittedAt = os.time() * 1000,
        reviewedBy = nil,
        reviewedAt = nil
    }
    
    table.insert(whitelistData.applications, application)
    
    -- Send Discord notification with approval buttons
    if _G.ECWebhooks and settings.application.approvalWebhook and settings.application.approvalWebhook ~= '' then
        _G.ECWebhooks.SendApplicationNotification(application, settings.application.approvalWebhook)
    elseif _G.ECWebhooks and settings.application.discordWebhook and settings.application.discordWebhook ~= '' then
        _G.ECWebhooks.SendLog('whitelist', {
            title = '📝 New Whitelist Application',
            description = string.format('**%s** has submitted a whitelist application', application.applicantName),
            color = 3447003,
            fields = {
                { name = 'Name', value = data.name or 'N/A', inline = true },
                { name = 'Age', value = tostring(data.age or 'N/A'), inline = true },
                { name = 'Discord', value = data.discord or 'N/A', inline = true },
                { name = 'Reason', value = data.reason or 'N/A', inline = false },
                { name = 'Experience', value = data.experience or 'N/A', inline = false },
                { name = 'Application ID', value = application.id, inline = false }
            }
        }, settings.application.discordWebhook)
    end
    
    Logger.Info(string.format('', 
        application.applicantName, application.id))
    
    return { 
        success = true, 
        message = 'Application submitted successfully. Please wait for approval.',
        applicationId = application.id
    }
end

function Applications.Approve(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end
    
    for i, app in ipairs(whitelistData.applications) do
        if app.id == data.id then
            if app.status ~= 'pending' then
                return { success = false, message = 'Application already processed' }
            end
            
            -- Create whitelist entry
            local entry = {
                id = GenerateId(),
                identifier = app.steamId or app.license or app.discordId or app.identifier,
                name = app.applicantName,
                steamId = app.steamId,
                license = app.license,
                discordId = app.discordId,
                roles = data.roles or {'whitelist'},
                status = 'active',
                addedBy = GetPlayerName(source) or 'System',
                addedAt = os.time() * 1000,
                priority = 'normal',
                notes = 'Approved from application #' .. app.id
            }
            
            table.insert(whitelistData.whitelist, entry)
            
            -- Update application
            app.status = 'approved'
            app.reviewedBy = GetPlayerName(source) or 'System'
            app.reviewedAt = os.time() * 1000
            
            -- Send Discord notification
            if _G.ECWebhooks then
                _G.ECWebhooks.SendLog('whitelist', {
                    title = '✅ Application Approved',
                    description = string.format('**%s** approved application for **%s**', 
                        GetPlayerName(source) or 'System', app.applicantName),
                    color = 3066993,
                    fields = {
                        { name = 'Application ID', value = app.id, inline = true },
                        { name = 'Roles', value = table.concat(entry.roles, ', '), inline = true }
                    }
                })
            end
            
            Logger.Info(string.format('', 
                app.applicantName, app.id))
            
            return { success = true, message = 'Application approved and added to whitelist', entry = entry }
        end
    end
    
    return { success = false, message = 'Application not found' }
end

function Applications.Deny(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end
    
    for i, app in ipairs(whitelistData.applications) do
        if app.id == data.id then
            if app.status ~= 'pending' then
                return { success = false, message = 'Application already processed' }
            end
            
            app.status = 'denied'
            app.reviewedBy = GetPlayerName(source) or 'System'
            app.reviewedAt = os.time() * 1000
            app.denyReason = data.reason
            
            if _G.ECWebhooks then
                _G.ECWebhooks.SendLog('whitelist', {
                    title = '❌ Application Denied',
                    description = string.format('**%s** denied application for **%s**', 
                        GetPlayerName(source) or 'System', app.applicantName),
                    color = 15158332,
                    fields = {
                        { name = 'Application ID', value = app.id, inline = true },
                        { name = 'Reason', value = data.reason or 'No reason provided', inline = false }
                    }
                })
            end
            
            Logger.Info(string.format('', 
                app.applicantName, app.id))
            
            return { success = true, message = 'Application denied' }
        end
    end
    
    return { success = false, message = 'Application not found' }
end

-- Connection Queue Functions
function Queue.Add(source, identifiers, deferrals)
    local settings = Config.Whitelist
    if not settings or not settings.queue or not settings.queue.enabled then
        return true
    end
    
    local identifier = identifiers.steamId or identifiers.license or identifiers.discordId
    if not identifier then
        return false
    end
    
    -- Check if already in queue
    for _, player in ipairs(whitelistData.queue) do
        if player.identifier == identifier then
            player.deferrals = deferrals
            player.lastUpdate = os.time() * 1000
            return true
        end
    end
    
    -- Check queue size
    if #whitelistData.queue >= (settings.queue.maxSize or 150) then
        deferrals.done('Queue is full. Please try again later.')
        return false
    end
    
    -- Get priority
    local priority = Roles.GetPriority(identifier)
    
    -- Add to queue
    local queueEntry = {
        source = source,
        identifier = identifier,
        identifiers = identifiers,
        name = GetPlayerName(source) or 'Unknown',
        priority = priority,
        joinedAt = os.time() * 1000,
        lastUpdate = os.time() * 1000,
        deferrals = deferrals
    }
    
    table.insert(whitelistData.queue, queueEntry)
    
    -- Sort by priority (highest first)
    table.sort(whitelistData.queue, function(a, b)
        return a.priority > b.priority
    end)
    
    Logger.Info(string.format('', 
        queueEntry.name, queueEntry.priority, Queue.GetPosition(identifier), #whitelistData.queue))
    
    return true
end

function Queue.Remove(identifier)
    for i, player in ipairs(whitelistData.queue) do
        if player.identifier == identifier then
            table.remove(whitelistData.queue, i)
            Logger.Info(string.format('', player.name))
            return true
        end
    end
    return false
end

function Queue.GetPosition(identifier)
    for i, player in ipairs(whitelistData.queue) do
        if player.identifier == identifier then
            return i
        end
    end
    return -1
end

function Queue.Update()
    local settings = Config.Whitelist
    if not settings or not settings.queue or not settings.queue.enabled then
        return
    end
    
    local maxPlayers = Config.MaxPlayers or 32
    local currentPlayers = #GetPlayers()
    local availableSlots = maxPlayers - currentPlayers
    
    if availableSlots <= 0 then
        return
    end
    
    -- Process queue
    for i = 1, math.min(availableSlots, #whitelistData.queue) do
        local player = whitelistData.queue[1]
        if player and player.deferrals then
            player.deferrals.done()
            table.remove(whitelistData.queue, 1)
            Logger.Info(string.format('', player.name))
        end
    end
    
    -- Update queue positions for remaining players
    for i, player in ipairs(whitelistData.queue) do
        if player.deferrals then
            local estimatedWait = math.ceil((i * 30) / 60) -- Rough estimate in minutes
            local message = string.format(
                'You are in queue\n\nPosition: %d/%d\nPriority: %s\nEstimated wait: %d minutes',
                i, #whitelistData.queue, 
                player.priority >= 500 and 'Staff' or 
                player.priority >= 150 and 'VIP' or 
                player.priority >= 100 and 'Whitelist' or 'Standard',
                estimatedWait
            )
            player.deferrals.update(message)
        end
    end
end

-- Data retrieval
function Whitelist.GetData(source)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end
    
    return {
        success = true,
        whitelist = whitelistData.whitelist,
        applications = whitelistData.applications,
        queue = whitelistData.queue,
        roles = whitelistData.roles,
        settings = Config.Whitelist or whitelistData.settings
    }
end

-- Player connecting event (NON-BLOCKING VERSION)
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    
    -- CRITICAL: Only check settings, don't use deferrals.defer() to prevent server hang
    local settings = Config.Whitelist
    if not settings or not settings.enabled then
        -- Whitelist disabled, allow connection
        return
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    local identifier = identifiers.steamId or identifiers.license or identifiers.discordId
    
    if not identifier then
        -- Can't identify player, deny for security
        setKickReason('[EC Admin] Unable to identify player. Please ensure Steam/License is valid.')
        CancelEvent()
        return
    end
    
    -- Check maintenance mode (instant check - no blocking)
    if settings.advanced and settings.advanced.maintenanceMode then
        if not Roles.HasPermission(identifier, 'admin') then
            local allowedRoles = settings.advanced.maintenanceRoles or {'staff', 'owner'}
            local hasRole = false
            for _, roleName in ipairs(allowedRoles) do
                local roles = Roles.Get(identifier)
                for _, playerRole in ipairs(roles) do
                    if playerRole == roleName then
                        hasRole = true
                        break
                    end
                end
                if hasRole then break end
            end
            
            if not hasRole then
                setKickReason('Server is currently in maintenance mode.')
                CancelEvent()
                return
            end
        end
    end
    
    -- Check whitelist (instant check - no blocking)
    if settings.enabled then
        local isWhitelisted = Whitelist.IsWhitelisted(source)
        
        if not isWhitelisted then
            -- Send kick message without blocking deferrals
            setKickReason(settings.advanced and settings.advanced.whitelistMessage or 
                'This server is whitelisted. Please apply on our Discord server.')
            CancelEvent()
            return
        end
    end
    
    -- Add to queue if enabled
    if settings.advanced and settings.advanced.enableQueue then
        -- Calculate priority
        local priority = 50 -- Default priority
        local roles = Roles.Get(identifier)
        for _, role in ipairs(roles) do
            if role.priority and role.priority > priority then
                priority = role.priority
            end
        end
        
        -- Add to queue (non-blocking)
        Queue.Add(source, name, identifier, priority)
    end
end)

-- Queue update thread
CreateThread(function()
    while true do
        local settings = Config.Whitelist
        if settings and settings.queue and settings.queue.enabled then
            Queue.Update()
            Wait(settings.queue.refreshRate or 5000)
        else
            Wait(10000)
        end
    end
end)

-- Initialize
CreateThread(function()
    Wait(1000)
    InitializeRoles()
end)

-- Event Handlers
RegisterNetEvent('ec-admin:whitelist:getData')
AddEventHandler('ec-admin:whitelist:getData', function(data, cb)
    local source = source
    local result = Whitelist.GetData(source)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:whitelist:add')
AddEventHandler('ec-admin:whitelist:add', function(data, cb)
    local source = source
    local result = Whitelist.Add(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:whitelist:remove')
AddEventHandler('ec-admin:whitelist:remove', function(data, cb)
    local source = source
    local result = Whitelist.Remove(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:whitelist:updateRoles')
AddEventHandler('ec-admin:whitelist:updateRoles', function(data, cb)
    local source = source
    local result = Whitelist.UpdateRoles(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:application:submit')
AddEventHandler('ec-admin:application:submit', function(data, cb)
    local source = source
    local result = Applications.Submit(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:application:approve')
AddEventHandler('ec-admin:application:approve', function(data, cb)
    local source = source
    local result = Applications.Approve(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:application:deny')
AddEventHandler('ec-admin:application:deny', function(data, cb)
    local source = source
    local result = Applications.Deny(source, data)
    if cb then cb(result) end
end)

-- Exports
exports('IsWhitelisted', Whitelist.IsWhitelisted)
exports('GetRoles', Roles.Get)
exports('GetPriority', Roles.GetPriority)
exports('HasPermission', Roles.HasPermission)

_G.Whitelist = Whitelist
_G.WhitelistRoles = Roles
_G.WhitelistQueue = Queue
_G.WhitelistApplications = Applications

Logger.Info('✅ Advanced Whitelist & Queue System loaded successfully')
Logger.Info('🛡️ Roles: ' .. #whitelistData.roles)
Logger.Info('📝 Application system ready')
Logger.Info('🚶 Connection queue enabled')
