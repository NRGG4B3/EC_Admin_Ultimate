-- EC Admin Ultimate - Communications System
-- Version: 1.0.0 - Complete communications management
-- PRODUCTION READY

Logger.Info('📢 Loading Communications System...')

local Communications = {}

-- Storage
local communicationsData = {
    announcements = {},
    broadcasts = {},
    messages = {},
    settings = {
        broadcastCooldown = 30000, -- 30 seconds
        maxAnnouncementsActive = 10
    }
}

-- Framework detection
local Framework = nil
local FrameworkObject = nil

local function DetectFramework()
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'QBCore'
        -- qbx_core doesn't have GetCoreObject export - using direct exports
        FrameworkObject = exports.qbx_core
        return true
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'QBCore'
        local success, result = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if success then
            FrameworkObject = result
        end
        return true
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'ESX'
        local success, result = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if success then
            FrameworkObject = result
        end
        return true
    end
    return false
end

-- Permission check
local function HasPermission(source, permission)
    if _G.ECPermissions then
        return _G.ECPermissions.HasPermission(source, permission or 'admin')
    end
    return true
end

-- Generate ID
local function GenerateId()
    return os.date('%Y%m%d%H%M%S') .. '_' .. math.random(1000, 9999)
end

-- GET DATA
function Communications.GetData(source)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    -- Clean expired announcements
    local now = os.time() * 1000
    for i = #communicationsData.announcements, 1, -1 do
        local announcement = communicationsData.announcements[i]
        if announcement.expiresAt and announcement.expiresAt < now then
            announcement.status = 'expired'
        end
    end

    return {
        success = true,
        announcements = communicationsData.announcements,
        broadcasts = communicationsData.broadcasts,
        messages = communicationsData.messages
    }
end

-- CREATE ANNOUNCEMENT
function Communications.CreateAnnouncement(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    if not data.title or data.title == '' then
        return { success = false, message = 'Title is required' }
    end

    if not data.message or data.message == '' then
        return { success = false, message = 'Message is required' }
    end

    -- Check active announcements limit
    local activeCount = 0
    for _, announcement in ipairs(communicationsData.announcements) do
        if announcement.status == 'active' then
            activeCount = activeCount + 1
        end
    end

    if activeCount >= communicationsData.settings.maxAnnouncementsActive then
        return { success = false, message = 'Maximum active announcements reached' }
    end

    local announcement = {
        id = GenerateId(),
        title = data.title,
        message = data.message,
        type = data.type or 'info',
        priority = data.priority or 'medium',
        target = data.target or 'all',
        targetPlayers = data.targetPlayers or {},
        author = GetPlayerName(source),
        timestamp = os.time() * 1000,
        expiresAt = data.expiresIn and (os.time() * 1000 + (tonumber(data.expiresIn) * 3600000)) or nil,
        persistent = data.persistent or false,
        sound = data.sound or true,
        status = 'active'
    }

    table.insert(communicationsData.announcements, announcement)

    -- Send to players
    if announcement.target == 'all' or announcement.target == 'online' then
        TriggerClientEvent('ec-admin:communications:announcement', -1, announcement)
    elseif announcement.target == 'specific' and announcement.targetPlayers then
        for _, playerId in ipairs(announcement.targetPlayers) do
            TriggerClientEvent('ec-admin:communications:announcement', playerId, announcement)
        end
    end

    -- Webhook
    if _G.ECWebhooks then
        _G.ECWebhooks.SendLog('communications', {
            title = 'Announcement Created',
            description = string.format('**%s** created announcement: %s', GetPlayerName(source), announcement.title),
            color = 3447003
        })
    end

    Logger.Info(string.format('', GetPlayerName(source), announcement.title))

    return { success = true, message = 'Announcement created successfully' }
end

-- DELETE ANNOUNCEMENT
function Communications.DeleteAnnouncement(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    local announcementId = data.id
    if not announcementId then
        return { success = false, message = 'Announcement ID required' }
    end

    for i, announcement in ipairs(communicationsData.announcements) do
        if announcement.id == announcementId then
            table.remove(communicationsData.announcements, i)
            
            Logger.Info(string.format('', GetPlayerName(source), announcement.title))
            
            return { success = true, message = 'Announcement deleted successfully' }
        end
    end

    return { success = false, message = 'Announcement not found' }
end

-- SEND BROADCAST
function Communications.SendBroadcast(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    if not data.message or data.message == '' then
        return { success = false, message = 'Message is required' }
    end

    local broadcast = {
        id = GenerateId(),
        message = data.message,
        type = data.type or 'info',
        timestamp = os.time() * 1000,
        recipients = #GetPlayers(),
        author = GetPlayerName(source)
    }

    table.insert(communicationsData.broadcasts, broadcast)

    -- Send to all players
    TriggerClientEvent('ec-admin:communications:broadcast', -1, broadcast)

    -- Webhook
    if _G.ECWebhooks then
        _G.ECWebhooks.SendLog('communications', {
            title = 'Broadcast Sent',
            description = string.format('**%s** sent broadcast to %d players', GetPlayerName(source), broadcast.recipients),
            color = 3447003
        })
    end

    Logger.Info(string.format('', GetPlayerName(source), broadcast.recipients))

    return { success = true, message = string.format('Broadcast sent to %d players', broadcast.recipients) }
end

-- SEND MESSAGE
function Communications.SendMessage(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    if not data.to or not data.subject or not data.content then
        return { success = false, message = 'Missing required fields' }
    end

    local message = {
        id = GenerateId(),
        from = GetPlayerName(source),
        to = data.to,
        subject = data.subject,
        content = data.content,
        timestamp = os.time() * 1000,
        read = false,
        important = data.important or false
    }

    table.insert(communicationsData.messages, message)

    -- Send to target player if online
    local targetPlayer = nil
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerName(playerId) == data.to then
            targetPlayer = playerId
            break
        end
    end

    if targetPlayer then
        TriggerClientEvent('ec-admin:communications:message', targetPlayer, message)
    end

    Logger.Info(string.format('', GetPlayerName(source), data.to))

    return { success = true, message = 'Message sent successfully' }
end

-- MARK MESSAGE READ
function Communications.MarkMessageRead(source, data)
    local messageId = data.id
    if not messageId then
        return { success = false, message = 'Message ID required' }
    end

    for _, message in ipairs(communicationsData.messages) do
        if message.id == messageId then
            message.read = true
            return { success = true, message = 'Message marked as read' }
        end
    end

    return { success = false, message = 'Message not found' }
end

-- Cleanup old broadcasts (keep last 50)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 minutes

        if #communicationsData.broadcasts > 50 then
            local toRemove = #communicationsData.broadcasts - 50
            for i = 1, toRemove do
                table.remove(communicationsData.broadcasts, 1)
            end
            Logger.Info('📢 Cleaned up old broadcasts')
        end
    end
end)

-- Initialize
function Communications.Initialize()
    Logger.Info('📢 Initializing Communications System...')
    
    DetectFramework()
    
    Logger.Info('✅ Communications System initialized')
    return true
end

-- Server events
RegisterNetEvent('ec-admin:communications:getData')
AddEventHandler('ec-admin:communications:getData', function(data, cb)
    local source = source
    local result = Communications.GetData(source)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:communications:createAnnouncement')
AddEventHandler('ec-admin:communications:createAnnouncement', function(data, cb)
    local source = source
    local result = Communications.CreateAnnouncement(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:communications:deleteAnnouncement')
AddEventHandler('ec-admin:communications:deleteAnnouncement', function(data, cb)
    local source = source
    local result = Communications.DeleteAnnouncement(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:communications:sendBroadcast')
AddEventHandler('ec-admin:communications:sendBroadcast', function(data, cb)
    local source = source
    local result = Communications.SendBroadcast(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:communications:sendMessage')
AddEventHandler('ec-admin:communications:sendMessage', function(data, cb)
    local source = source
    local result = Communications.SendMessage(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:communications:markMessageRead')
AddEventHandler('ec-admin:communications:markMessageRead', function(data, cb)
    local source = source
    local result = Communications.MarkMessageRead(source, data)
    if cb then cb(result) end
end)

-- Export functions
exports('GetAnnouncements', function()
    return communicationsData.announcements
end)

exports('CreateAnnouncement', function(data)
    return Communications.CreateAnnouncement(0, data)
end)

exports('SendBroadcast', function(message, type)
    return Communications.SendBroadcast(0, { message = message, type = type })
end)

-- Initialize
Communications.Initialize()

-- Make available globally
_G.Communications = Communications

Logger.Info('✅ Communications System loaded successfully')
