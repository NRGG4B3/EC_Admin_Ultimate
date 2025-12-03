--[[
    EC Admin Ultimate - Admin Team Management Callbacks
    NUI callbacks for managing admin team from UI
]]

local function ensurePermissions(source)
    return EC_Perms.Has(source, 'ec_admin.super')
end

local function formatError(message)
    return {
        success = false,
        error = message or 'Unknown error'
    }
end

local function validateIdentifierPayload(data)
    if not data or type(data) ~= 'table' then
        return false, 'Invalid payload'
    end

    if not data.identifier or data.identifier == '' then
        return false, 'Identifier required'
    end

    return true
end

lib.callback.register('ec_admin:getAdminTeam', function(source)
    if not ensurePermissions(source) then
        return formatError('No permission')
    end

    local members = exports.EC_admin_ultimate:GetAdminTeam()

    for _, member in ipairs(members) do
        if Config.AdminTeam and Config.AdminTeam.ranks and Config.AdminTeam.ranks[member.rank] then
            member.rankInfo = Config.AdminTeam.ranks[member.rank]
        end
    end

    return {
        success = true,
        members = members,
        ranks = Config.AdminTeam and Config.AdminTeam.ranks or {}
    }
end)

lib.callback.register('ec_admin:getAdminRanks', function(source)
    if not ensurePermissions(source) then
        return formatError('No permission')
    end

    return {
        success = true,
        ranks = Config.AdminTeam and Config.AdminTeam.ranks or {}
    }
end)

local function addAdminMember(source, data)
    if not ensurePermissions(source) then
        return formatError('No permission - Super Admin required')
    end

    local isValid, errorMessage = validateIdentifierPayload(data)
    if not isValid then
        return formatError(errorMessage)
    end

    local success, message = exports.EC_admin_ultimate:AddAdminMember(
        data.identifier,
        data.name,
        data.rank or 'admin',
        data.permissions
    )

    if success and exports.EC_admin_ultimate and exports.EC_admin_ultimate.LogAdminAction then
        exports.EC_admin_ultimate:LogAdminAction(
            source,
            'ADD_ADMIN',
            nil,
            {
                target_identifier = data.identifier,
                target_name = data.name,
                rank = data.rank
            },
            'Added to admin team'
        )
    end

    return {
        success = success,
        message = success and message or nil,
        error = success and nil or message
    }
end

lib.callback.register('ec_admin:addAdminMember', addAdminMember)

local function removeAdminMember(source, data)
    if not ensurePermissions(source) then
        return formatError('No permission - Super Admin required')
    end

    local isValid, errorMessage = validateIdentifierPayload(data)
    if not isValid then
        return formatError(errorMessage)
    end

    local member = exports.EC_admin_ultimate:GetAdminMember(data.identifier)
    local success, message = exports.EC_admin_ultimate:RemoveAdminMember(data.identifier)

    if success and exports.EC_admin_ultimate and exports.EC_admin_ultimate.LogAdminAction then
        exports.EC_admin_ultimate:LogAdminAction(
            source,
            'REMOVE_ADMIN',
            nil,
            {
                target_identifier = data.identifier,
                target_name = member and member.name or 'Unknown',
                rank = member and member.rank or 'Unknown'
            },
            'Removed from admin team'
        )
    end

    return {
        success = success,
        message = success and message or nil,
        error = success and nil or message
    }
end

lib.callback.register('ec_admin:removeAdminMember', removeAdminMember)

local function updateAdminMember(source, data)
    if not ensurePermissions(source) then
        return formatError('No permission - Super Admin required')
    end

    local isValid, errorMessage = validateIdentifierPayload(data)
    if not isValid then
        return formatError(errorMessage)
    end

    local success, message = exports.EC_admin_ultimate:UpdateAdminMember(data.identifier, {
        name = data.name,
        rank = data.rank,
        permissions = data.permissions
    })

    if success and exports.EC_admin_ultimate and exports.EC_admin_ultimate.LogAdminAction then
        exports.EC_admin_ultimate:LogAdminAction(
            source,
            'UPDATE_ADMIN',
            nil,
            {
                target_identifier = data.identifier,
                target_name = data.name,
                rank = data.rank
            },
            'Updated admin team member'
        )
    end

    return {
        success = success,
        message = success and message or nil,
        error = success and nil or message
    }
end

lib.callback.register('ec_admin:updateAdminMember', updateAdminMember)

lib.callback.register('ec_admin:searchPlayers', function(source, query)
    if not ensurePermissions(source) then
        return formatError('No permission')
    end

    local players = {}
    local allPlayers = GetPlayers()
    local normalizedQuery = query and string.lower(query) or nil

    for _, playerId in ipairs(allPlayers) do
        local playerName = GetPlayerName(playerId)
        local identifier = GetPlayerIdentifier(playerId, 0)

        if not normalizedQuery
            or string.find(string.lower(playerName), normalizedQuery, 1, true)
            or string.find(string.lower(identifier), normalizedQuery, 1, true) then
            local isAdmin = exports.EC_admin_ultimate:GetAdminMember(identifier) ~= nil

            table.insert(players, {
                id = playerId,
                name = playerName,
                identifier = identifier,
                isAdmin = isAdmin
            })
        end
    end

    return {
        success = true,
        players = players
    }
end)

RegisterNetEvent('ec_admin:addAdminMember', function(data)
    local source = source
    local result = addAdminMember(source, data)

    if result.success then
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'success',
            message = result.message or 'Admin member added'
        })
    else
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'error',
            message = result.error or 'Failed to add admin member'
        })
    end
end)

RegisterNetEvent('ec_admin:removeAdminMember', function(data)
    local source = source
    local result = removeAdminMember(source, data)

    if result.success then
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'success',
            message = result.message or 'Admin member removed'
        })
    else
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'error',
            message = result.error or 'Failed to remove admin member'
        })
    end
end)

RegisterNetEvent('ec_admin:updateAdminMember', function(data)
    local source = source
    local result = updateAdminMember(source, data)

    if result.success then
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'success',
            message = result.message or 'Admin member updated'
        })
    else
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'error',
            message = result.error or 'Failed to update admin member'
        })
    end
end)
