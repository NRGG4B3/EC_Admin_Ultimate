--[[
    EC Admin Ultimate - Whitelist UI Backend
    Server-side logic for whitelist management
    
    Handles:
    - whitelist:getData: Get all whitelist data (entries, applications, roles, stats)
    - whitelist:add: Add whitelist entry
    - whitelist:update: Update whitelist entry
    - whitelist:remove: Remove whitelist entry
    - whitelist:approveApplication: Approve application
    - whitelist:denyApplication: Deny application
    - whitelist:createRole: Create whitelist role
    - whitelist:submitApplication: Submit whitelist application (for players)
    
    Also handles:
    - playerConnecting: Check if player is whitelisted when joining
    - Webhook integration for whitelist events
    
    Framework Support: QB-Core, QBX, ESX
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Whitelist] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Whitelist] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Configuration
local WHITELIST_ENABLED = GetConvar('ec_admin_whitelist_enabled', 'true') == 'true'
local WHITELIST_REQUIRE_APPROVAL = GetConvar('ec_admin_whitelist_require_approval', 'false') == 'true'

-- Local variables
local dataCache = {}
local CACHE_TTL = 10 -- Cache for 10 seconds

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Get player identifier from source
local function getPlayerIdentifierFromSource(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    -- Try license first
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    return identifiers[1]
end

-- Helper: Get player name from identifier
local function getPlayerNameByIdentifier(identifier)
    -- Try online first
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local ids = GetPlayerIdentifiers(source)
            if ids then
                for _, id in ipairs(ids) do
                    if id == identifier then
                        return GetPlayerName(source) or 'Unknown'
                    end
                end
            end
        end
    end
    
    -- Try database
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1', {identifier})
        if result and result[1] then
            local charinfo = json.decode(result[1].charinfo or '{}')
            if charinfo then
                return (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            end
        end
    elseif framework == 'esx' then
        local result = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1', {identifier})
        if result and result[1] then
            return (result[1].firstname or '') .. ' ' .. (result[1].lastname or '')
        end
    end
    
    return 'Unknown'
end

-- Helper: Trigger webhook
local function triggerWebhook(eventType, data)
    -- Check if webhook system exists
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].TriggerWebhook then
        exports['ec_admin_ultimate']:TriggerWebhook(eventType, data)
    else
        -- Fallback: Log webhook event (can be integrated with external webhook system)
        print(string.format("^3[Whitelist Webhook]^7 Event: %s | Data: %s^0", eventType, json.encode(data)))
    end
end

-- Helper: Log whitelist action
local function logWhitelistAction(adminId, adminName, actionType, targetType, targetId, targetIdentifier, targetName, details)
    MySQL.insert.await([[
        INSERT INTO ec_whitelist_actions_log 
        (admin_id, admin_name, action_type, target_type, target_id, target_identifier, target_name, details, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        adminId, adminName, actionType, targetType, targetId, targetIdentifier, targetName,
        details and json.encode(details) or nil, getCurrentTimestamp()
    })
end

-- Helper: Check if player is whitelisted
local function isPlayerWhitelisted(identifier, steamId, license, discordId, ipAddress)
    if not WHITELIST_ENABLED then
        return true -- Whitelist disabled, allow all
    end
    
    -- Check by identifier
    local result = MySQL.query.await([[
        SELECT * FROM ec_whitelist_entries 
        WHERE identifier = ? AND status = 'active'
        AND (expires_at IS NULL OR expires_at > ?)
        LIMIT 1
    ]], {identifier, getCurrentTimestamp()})
    
    if result and result[1] then
        return true, result[1]
    end
    
    -- Check by steam_id
    if steamId then
        result = MySQL.query.await([[
            SELECT * FROM ec_whitelist_entries 
            WHERE steam_id = ? AND status = 'active'
            AND (expires_at IS NULL OR expires_at > ?)
            LIMIT 1
        ]], {steamId, getCurrentTimestamp()})
        
        if result and result[1] then
            return true, result[1]
        end
    end
    
    -- Check by license
    if license then
        result = MySQL.query.await([[
            SELECT * FROM ec_whitelist_entries 
            WHERE license = ? AND status = 'active'
            AND (expires_at IS NULL OR expires_at > ?)
            LIMIT 1
        ]], {license, getCurrentTimestamp()})
        
        if result and result[1] then
            return true, result[1]
        end
    end
    
    -- Check by discord_id
    if discordId then
        result = MySQL.query.await([[
            SELECT * FROM ec_whitelist_entries 
            WHERE discord_id = ? AND status = 'active'
            AND (expires_at IS NULL OR expires_at > ?)
            LIMIT 1
        ]], {discordId, getCurrentTimestamp()})
        
        if result and result[1] then
            return true, result[1]
        end
    end
    
    return false, nil
end

-- Helper: Get all whitelist entries
local function getAllWhitelistEntries()
    local entries = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_whitelist_entries
        ORDER BY added_at DESC
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            local roles = {}
            if row.roles then
                roles = json.decode(row.roles) or {}
            end
            
            table.insert(entries, {
                id = row.id,
                identifier = row.identifier,
                name = row.name,
                steam_id = row.steam_id,
                license = row.license,
                discord_id = row.discord_id,
                ip_address = row.ip_address,
                roles = roles,
                status = row.status or 'active',
                added_by = row.added_by,
                added_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.added_at),
                priority = row.priority or 'normal',
                notes = row.notes,
                expires_at = row.expires_at and os.date('%Y-%m-%dT%H:%M:%SZ', row.expires_at) or nil
            })
        end
    end
    
    return entries
end

-- Helper: Get all applications
local function getAllApplications()
    local applications = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_whitelist_applications
        ORDER BY submitted_at DESC
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            local applicationData = {}
            if row.application_data then
                applicationData = json.decode(row.application_data) or {}
            end
            
            table.insert(applications, {
                id = row.id,
                identifier = row.identifier,
                applicant_name = row.applicant_name,
                steam_id = row.steam_id,
                license = row.license,
                discord_id = row.discord_id,
                discord_tag = row.discord_tag,
                age = tonumber(row.age),
                reason = row.reason,
                experience = row.experience,
                referral = row.referral,
                status = row.status or 'pending',
                submitted_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.submitted_at),
                reviewed_by = row.reviewed_by,
                reviewed_at = row.reviewed_at and os.date('%Y-%m-%dT%H:%M:%SZ', row.reviewed_at) or nil,
                deny_reason = row.deny_reason,
                application_data = applicationData
            })
        end
    end
    
    return applications
end

-- Helper: Get all roles
local function getAllRoles()
    local roles = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_whitelist_roles
        ORDER BY priority DESC, created_at ASC
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            local permissions = {}
            if row.permissions then
                permissions = json.decode(row.permissions) or {}
            end
            
            table.insert(roles, {
                id = row.id,
                name = row.name,
                display_name = row.display_name,
                priority = tonumber(row.priority) or 50,
                color = row.color or '#3b82f6',
                permissions = permissions,
                is_default = (row.is_default == 1 or row.is_default == true),
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return roles
end

-- Helper: Get whitelist data (shared logic)
local function getWhitelistData()
    -- Check cache
    if dataCache.data and (getCurrentTimestamp() - dataCache.timestamp) < CACHE_TTL then
        return dataCache.data
    end
    
    local whitelist = getAllWhitelistEntries()
    local applications = getAllApplications()
    local roles = getAllRoles()
    
    -- Calculate statistics
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
    
    for _, application in ipairs(applications) do
        if application.status == 'pending' then
            stats.pendingApplications = stats.pendingApplications + 1
        elseif application.status == 'approved' then
            stats.approvedApplications = stats.approvedApplications + 1
        elseif application.status == 'denied' then
            stats.deniedApplications = stats.deniedApplications + 1
        end
    end
    
    local data = {
        whitelist = whitelist,
        applications = applications,
        roles = roles,
        stats = stats,
        framework = getFramework()
    }
    
    -- Cache data
    dataCache = {
        data = data,
        timestamp = getCurrentTimestamp()
    }
    
    return data
end

-- ============================================================================
-- PLAYER CONNECTING CHECK
-- ============================================================================

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local identifiers = GetPlayerIdentifiers(source)
    
    if not identifiers or #identifiers == 0 then
        deferrals.done('Unable to retrieve player identifiers')
        return
    end
    
    -- Extract identifiers
    local identifier = nil
    local steamId = nil
    local license = nil
    local discordId = nil
    local ipAddress = GetPlayerEndpoint(source)
    
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            license = id
            identifier = id
        elseif string.find(id, 'steam:') then
            steamId = id
        elseif string.find(id, 'discord:') then
            discordId = id
        end
    end
    
    if not identifier then
        identifier = identifiers[1]
    end
    
    -- Check whitelist
    if WHITELIST_ENABLED then
        local isWhitelisted, whitelistEntry = isPlayerWhitelisted(identifier, steamId, license, discordId, ipAddress)
        
        if not isWhitelisted then
            -- Check if they have a pending application
            local applicationResult = MySQL.query.await([[
                SELECT * FROM ec_whitelist_applications 
                WHERE identifier = ? OR steam_id = ? OR license = ? OR discord_id = ?
                ORDER BY submitted_at DESC
                LIMIT 1
            ]], {identifier, steamId or '', license or '', discordId or ''})
            
            if applicationResult and applicationResult[1] then
                local application = applicationResult[1]
                if application.status == 'pending' then
                    -- Log join attempt
                    MySQL.insert.await([[
                        INSERT INTO ec_whitelist_join_attempts 
                        (identifier, name, steam_id, license, discord_id, ip_address, result, reason, attempted_at)
                        VALUES (?, ?, ?, ?, ?, ?, 'denied_whitelist', ?, ?)
                    ]], {identifier, name, steamId, license, discordId, ipAddress, 'Application pending review', getCurrentTimestamp()})
                    
                    -- Trigger webhook
                    triggerWebhook('whitelist_join_denied', {
                        identifier = identifier,
                        name = name,
                        reason = 'Application pending review',
                        application_id = application.id
                    })
                    
                    deferrals.done('Your whitelist application is pending review. Please wait for admin approval.')
                    return
                elseif application.status == 'denied' then
                    -- Log join attempt
                    MySQL.insert.await([[
                        INSERT INTO ec_whitelist_join_attempts 
                        (identifier, name, steam_id, license, discord_id, ip_address, result, reason, attempted_at)
                        VALUES (?, ?, ?, ?, ?, ?, 'denied_whitelist', ?, ?)
                    ]], {identifier, name, steamId, license, discordId, ipAddress, 'Application denied', getCurrentTimestamp()})
                    
                    deferrals.done('Your whitelist application was denied. Reason: ' .. (application.deny_reason or 'No reason provided'))
                    return
                end
            end
            
            -- Not whitelisted and no application
            -- Log join attempt
            MySQL.insert.await([[
                INSERT INTO ec_whitelist_join_attempts 
                (identifier, name, steam_id, license, discord_id, ip_address, result, reason, attempted_at)
                VALUES (?, ?, ?, ?, ?, ?, 'denied_whitelist', ?, ?)
            ]], {identifier, name, steamId, license, discordId, ipAddress, 'Not whitelisted', getCurrentTimestamp()})
            
            -- Trigger webhook
            triggerWebhook('whitelist_join_denied', {
                identifier = identifier,
                name = name,
                reason = 'Not whitelisted'
            })
            
            deferrals.done('You are not whitelisted on this server. Please submit a whitelist application.')
            return
        end
        
        -- Player is whitelisted, log successful join
        MySQL.insert.await([[
            INSERT INTO ec_whitelist_join_attempts 
            (identifier, name, steam_id, license, discord_id, ip_address, result, reason, attempted_at)
            VALUES (?, ?, ?, ?, ?, ?, 'allowed', 'Whitelisted', ?)
        ]], {identifier, name, steamId, license, discordId, ipAddress, getCurrentTimestamp()})
        
        -- Trigger webhook
        triggerWebhook('whitelist_join_allowed', {
            identifier = identifier,
            name = name,
            whitelist_entry = whitelistEntry
        })
    end
end)

-- ============================================================================
-- REGISTERNUICALLBACK HANDLERS (Direct fetch from UI)
-- ============================================================================

-- Callback: Get whitelist data
RegisterNUICallback('whitelist:getData', function(data, cb)
    local response = getWhitelistData()
    cb({ success = true, data = response })
end)

-- Callback: Add whitelist entry
RegisterNUICallback('whitelist:add', function(data, cb)
    local identifier = data.identifier
    local name = data.name
    local steamId = data.steamId
    local license = data.license
    local discordId = data.discordId
    local ipAddress = data.ipAddress
    local roles = data.roles or {'whitelist'}
    local status = data.status or 'active'
    local priority = data.priority or 'normal'
    local notes = data.notes
    local expiresAt = data.expiresAt
    
    if not identifier or not name then
        cb({ success = false, message = 'Identifier and name required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Whitelist entry added successfully'
    
    -- Parse expires_at
    local expiresTimestamp = nil
    if expiresAt then
        if type(expiresAt) == 'string' then
            local year, month, day, hour, min, sec = string.match(expiresAt, '(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)')
            if year and month and day and hour and min then
                expiresTimestamp = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec) or 0})
            end
        else
            expiresTimestamp = tonumber(expiresAt)
        end
    end
    
    -- Insert whitelist entry
    local result = MySQL.insert.await([[
        INSERT INTO ec_whitelist_entries 
        (identifier, name, steam_id, license, discord_id, ip_address, roles, status, added_by, added_at, priority, notes, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        steam_id = VALUES(steam_id),
        license = VALUES(license),
        discord_id = VALUES(discord_id),
        ip_address = VALUES(ip_address),
        roles = VALUES(roles),
        status = VALUES(status),
        priority = VALUES(priority),
        notes = VALUES(notes),
        expires_at = VALUES(expires_at)
    ]], {
        identifier, name, steamId, license, discordId, ipAddress,
        json.encode(roles), status, adminInfo.id, getCurrentTimestamp(),
        priority, notes, expiresTimestamp
    })
    
    if result then
        success = true
        local entryId = result.insertId or 0
        
        -- Log action
        logWhitelistAction(adminInfo.id, adminInfo.name, 'add', 'entry', entryId, identifier, name, {
            roles = roles,
            status = status,
            priority = priority
        })
        
        -- Trigger webhook
        triggerWebhook('whitelist_entry_added', {
            identifier = identifier,
            name = name,
            added_by = adminInfo.name,
            roles = roles
        })
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to add whitelist entry' })
end)

-- Callback: Update whitelist entry
RegisterNUICallback('whitelist:update', function(data, cb)
    local id = tonumber(data.id)
    local name = data.name
    local steamId = data.steamId
    local license = data.license
    local discordId = data.discordId
    local roles = data.roles
    local status = data.status
    local priority = data.priority
    local notes = data.notes
    local expiresAt = data.expiresAt
    
    if not id then
        cb({ success = false, message = 'Entry ID required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Whitelist entry updated successfully'
    
    -- Get existing entry
    local existingResult = MySQL.query.await('SELECT * FROM ec_whitelist_entries WHERE id = ? LIMIT 1', {id})
    if not existingResult or not existingResult[1] then
        cb({ success = false, message = 'Entry not found' })
        return
    end
    
    local existing = existingResult[1]
    
    -- Parse expires_at
    local expiresTimestamp = nil
    if expiresAt ~= nil then
        if expiresAt == '' or expiresAt == false then
            expiresTimestamp = nil
        elseif type(expiresAt) == 'string' then
            local year, month, day, hour, min, sec = string.match(expiresAt, '(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)')
            if year and month and day and hour and min then
                expiresTimestamp = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec) or 0})
            end
        else
            expiresTimestamp = tonumber(expiresAt)
        end
    else
        expiresTimestamp = existing.expires_at
    end
    
    -- Update entry
    MySQL.update.await([[
        UPDATE ec_whitelist_entries 
        SET name = COALESCE(?, name),
            steam_id = COALESCE(?, steam_id),
            license = COALESCE(?, license),
            discord_id = COALESCE(?, discord_id),
            roles = COALESCE(?, roles),
            status = COALESCE(?, status),
            priority = COALESCE(?, priority),
            notes = COALESCE(?, notes),
            expires_at = ?
        WHERE id = ?
    ]], {
        name, steamId, license, discordId,
        roles and json.encode(roles) or nil,
        status, priority, notes, expiresTimestamp, id
    })
    
    success = true
    
    -- Log action
    logWhitelistAction(adminInfo.id, adminInfo.name, 'update', 'entry', id, existing.identifier, existing.name, {
        old_status = existing.status,
        new_status = status or existing.status,
        roles = roles or json.decode(existing.roles or '[]')
    })
    
    -- Trigger webhook
    triggerWebhook('whitelist_entry_updated', {
        identifier = existing.identifier,
        name = name or existing.name,
        updated_by = adminInfo.name,
        changes = {
            status = status,
            roles = roles
        }
    })
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to update whitelist entry' })
end)

-- Callback: Remove whitelist entry
RegisterNUICallback('whitelist:remove', function(data, cb)
    local id = tonumber(data.id)
    
    if not id then
        cb({ success = false, message = 'Entry ID required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Whitelist entry removed successfully'
    
    -- Get entry info
    local result = MySQL.query.await('SELECT * FROM ec_whitelist_entries WHERE id = ? LIMIT 1', {id})
    if not result or not result[1] then
        cb({ success = false, message = 'Entry not found' })
        return
    end
    
    local entry = result[1]
    
    -- Delete entry
    MySQL.query.await('DELETE FROM ec_whitelist_entries WHERE id = ?', {id})
    success = true
    
    -- Log action
    logWhitelistAction(adminInfo.id, adminInfo.name, 'remove', 'entry', id, entry.identifier, entry.name, nil)
    
    -- Trigger webhook
    triggerWebhook('whitelist_entry_removed', {
        identifier = entry.identifier,
        name = entry.name,
        removed_by = adminInfo.name
    })
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to remove whitelist entry' })
end)

-- Callback: Approve application
RegisterNUICallback('whitelist:approveApplication', function(data, cb)
    local id = tonumber(data.id)
    local roles = data.roles or {'whitelist'}
    
    if not id then
        cb({ success = false, message = 'Application ID required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Application approved successfully'
    
    -- Get application
    local result = MySQL.query.await('SELECT * FROM ec_whitelist_applications WHERE id = ? LIMIT 1', {id})
    if not result or not result[1] then
        cb({ success = false, message = 'Application not found' })
        return
    end
    
    local application = result[1]
    
    -- Update application status
    MySQL.update.await([[
        UPDATE ec_whitelist_applications 
        SET status = 'approved',
            reviewed_by = ?,
            reviewed_by_name = ?,
            reviewed_at = ?
        WHERE id = ?
    ]], {adminInfo.id, adminInfo.name, getCurrentTimestamp(), id})
    
    -- Add to whitelist
    MySQL.insert.await([[
        INSERT INTO ec_whitelist_entries 
        (identifier, name, steam_id, license, discord_id, roles, status, added_by, added_at, priority)
        VALUES (?, ?, ?, ?, ?, ?, 'active', ?, ?, 'normal')
        ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        status = 'active',
        roles = VALUES(roles)
    ]], {
        application.identifier, application.applicant_name,
        application.steam_id, application.license, application.discord_id,
        json.encode(roles), adminInfo.id, getCurrentTimestamp()
    })
    
    success = true
    
    -- Log action
    logWhitelistAction(adminInfo.id, adminInfo.name, 'approve', 'application', id, application.identifier, application.applicant_name, {
        roles = roles
    })
    
    -- Trigger webhook
    triggerWebhook('whitelist_application_approved', {
        application_id = id,
        identifier = application.identifier,
        applicant_name = application.applicant_name,
        approved_by = adminInfo.name,
        roles = roles
    })
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to approve application' })
end)

-- Callback: Deny application
RegisterNUICallback('whitelist:denyApplication', function(data, cb)
    local id = tonumber(data.id)
    local reason = data.reason or 'No reason provided'
    
    if not id then
        cb({ success = false, message = 'Application ID required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Application denied successfully'
    
    -- Get application
    local result = MySQL.query.await('SELECT * FROM ec_whitelist_applications WHERE id = ? LIMIT 1', {id})
    if not result or not result[1] then
        cb({ success = false, message = 'Application not found' })
        return
    end
    
    local application = result[1]
    
    -- Update application status
    MySQL.update.await([[
        UPDATE ec_whitelist_applications 
        SET status = 'denied',
            reviewed_by = ?,
            reviewed_by_name = ?,
            reviewed_at = ?,
            deny_reason = ?
        WHERE id = ?
    ]], {adminInfo.id, adminInfo.name, getCurrentTimestamp(), reason, id})
    
    success = true
    
    -- Log action
    logWhitelistAction(adminInfo.id, adminInfo.name, 'deny', 'application', id, application.identifier, application.applicant_name, {
        reason = reason
    })
    
    -- Trigger webhook
    triggerWebhook('whitelist_application_denied', {
        application_id = id,
        identifier = application.identifier,
        applicant_name = application.applicant_name,
        denied_by = adminInfo.name,
        reason = reason
    })
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to deny application' })
end)

-- Callback: Create role
RegisterNUICallback('whitelist:createRole', function(data, cb)
    local name = data.name
    local displayName = data.displayName
    local priority = tonumber(data.priority) or 50
    local color = data.color or '#3b82f6'
    local permissions = data.permissions or {}
    
    if not name or not displayName then
        cb({ success = false, message = 'Name and display name required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Role created successfully'
    
    -- Insert role
    local result = MySQL.insert.await([[
        INSERT INTO ec_whitelist_roles 
        (name, display_name, priority, color, permissions, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        name, displayName, priority, color, json.encode(permissions), getCurrentTimestamp()
    })
    
    if result then
        success = true
        local roleId = result.insertId
        
        -- Log action
        logWhitelistAction(adminInfo.id, adminInfo.name, 'create_role', 'role', roleId, nil, name, {
            display_name = displayName,
            priority = priority
        })
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to create role' })
end)

-- Callback: Submit application (for players)
RegisterNUICallback('whitelist:submitApplication', function(data, cb)
    local identifier = data.identifier
    local applicantName = data.applicantName
    local steamId = data.steamId
    local license = data.license
    local discordId = data.discordId
    local discordTag = data.discordTag
    local age = tonumber(data.age)
    local reason = data.reason
    local experience = data.experience
    local referral = data.referral
    local applicationData = data.applicationData or {}
    
    if not identifier or not applicantName then
        cb({ success = false, message = 'Identifier and name required' })
        return
    end
    
    local success = false
    local message = 'Application submitted successfully'
    
    -- Check if application already exists
    local existingResult = MySQL.query.await([[
        SELECT * FROM ec_whitelist_applications 
        WHERE identifier = ? AND status = 'pending'
        LIMIT 1
    ]], {identifier})
    
    if existingResult and existingResult[1] then
        cb({ success = false, message = 'You already have a pending application' })
        return
    end
    
    -- Insert application
    local result = MySQL.insert.await([[
        INSERT INTO ec_whitelist_applications 
        (identifier, applicant_name, steam_id, license, discord_id, discord_tag, age, reason, experience, referral, status, submitted_at, application_data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)
    ]], {
        identifier, applicantName, steamId, license, discordId, discordTag, age,
        reason, experience, referral, getCurrentTimestamp(), json.encode(applicationData)
    })
    
    if result then
        success = true
        local applicationId = result.insertId
        
        -- Trigger webhook
        triggerWebhook('whitelist_application_submitted', {
            application_id = applicationId,
            identifier = identifier,
            applicant_name = applicantName,
            discord_tag = discordTag
        })
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to submit application' })
end)

print("^2[Whitelist]^7 UI Backend loaded - Whitelist " .. (WHITELIST_ENABLED and "enabled" or "disabled") .. "^0")

