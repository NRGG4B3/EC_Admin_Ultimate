--[[
    EC Admin Ultimate - Notification System
    Works with ALL frameworks including standalone
    Fallback chain: lib.notify → QBCore → ESX → Chat
]]

-- Show notification with automatic framework detection
local function ShowNotification(data)
    local title = data.title or 'EC Admin'
    local description = data.description or data.message or ''
    local type = data.type or 'info'
    
    -- Method 1: ox_lib (most common)
    if lib and lib.notify then
        lib.notify({
            title = title,
            description = description,
            type = type,
            duration = data.duration or 5000
        })
        return
    end
    
    -- Method 2: QBCore notify (check if qb-core exists)
    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore and QBCore.Functions and QBCore.Functions.Notify then
            QBCore.Functions.Notify(description, type, data.duration or 5000)
            return
        end
    end
    
    -- Method 3: QBX notify
    if GetResourceState('qbx_core') == 'started' then
        local QBX = exports.qbx_core
        if QBX and QBX.Notify then
            QBX.Notify(description, type, data.duration or 5000)
            return
        end
    end
    
    -- Method 4: ESX notification
    if GetResourceState('es_extended') == 'started' then
        local ESX = exports.es_extended:getSharedObject()
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(description, type, data.duration or 5000)
            return
        end
    end
    
    -- Method 4: Chat fallback (works everywhere)
    local color = {255, 255, 255}
    if type == 'error' then
        color = {255, 0, 0}
    elseif type == 'success' then
        color = {0, 255, 0}
    elseif type == 'warning' then
        color = {255, 165, 0}
    end
    
    TriggerEvent('chat:addMessage', {
        color = color,
        multiline = true,
        args = {title, description}
    })
end

-- Listen for notification events
RegisterNetEvent('ec_admin:notification')
AddEventHandler('ec_admin:notification', function(message, type)
    ShowNotification({
        title = 'EC Admin',
        description = message,
        type = type or 'info'
    })
end)

-- Export for use in other scripts
exports('ShowNotification', ShowNotification)

Logger.Info('')
