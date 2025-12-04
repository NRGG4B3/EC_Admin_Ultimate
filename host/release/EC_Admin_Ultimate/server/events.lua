-- EC Admin Ultimate - Events System
-- Complete event management system

local Events = {}
local eventsData = {
    events = {},
    activeEvents = {},
    eventHistory = {}
}

local function hasPermission(source, permission)
    if _G.ECPermissions then
        return _G.ECPermissions.HasPermission(source, permission or 'admin')
    end

    return true
end

local function generateId()
    return os.date('%Y%m%d%H%M%S') .. '_' .. math.random(1000, 9999)
end

local function sanitizeEventPayload(data)
    if not data or type(data) ~= 'table' then
        return false, 'Invalid event payload'
    end

    if not data.name or data.name == '' then
        return false, 'Event name required'
    end

    return true
end

local function normalizeEventFields(data)
    local durationMinutes = tonumber(data.duration) or 60
    local maxParticipants = tonumber(data.maxParticipants) or 32
    local cashReward = tonumber(data.cashReward) or 0

    return {
        id = generateId(),
        name = data.name,
        description = data.description or '',
        type = data.type or 'custom',
        status = 'scheduled',
        startTime = os.time() * 1000,
        duration = durationMinutes * 60,
        rewards = { cash = cashReward },
        participants = 0,
        maxParticipants = maxParticipants,
        location = data.location or '',
        recurring = data.recurring or false
    }
end

function Events.GetData(source)
    if not hasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    return {
        success = true,
        events = eventsData.events,
        activeEvents = eventsData.activeEvents,
        eventHistory = eventsData.eventHistory
    }
end

function Events.Create(source, data)
    if not hasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    local isValid, errorMessage = sanitizeEventPayload(data)
    if not isValid then
        return { success = false, message = errorMessage }
    end

    local event = normalizeEventFields(data)
    table.insert(eventsData.events, event)

    return {
        success = true,
        message = 'Event created successfully',
        event = event
    }
end

function Events.Start(source, data)
    if not hasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    for _, event in ipairs(eventsData.events) do
        if event.id == data.id then
            event.status = 'active'
            event.startTime = os.time() * 1000
            table.insert(eventsData.activeEvents, event)
            TriggerClientEvent('ec_admin:events:started', -1, event)

            return {
                success = true,
                message = 'Event started',
                event = event
            }
        end
    end

    return { success = false, message = 'Event not found' }
end

function Events.Stop(source, data)
    if not hasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    for index, event in ipairs(eventsData.activeEvents) do
        if event.id == data.id then
            event.status = 'completed'
            event.endTime = os.time() * 1000
            table.remove(eventsData.activeEvents, index)
            table.insert(eventsData.eventHistory, event)
            TriggerClientEvent('ec_admin:events:stopped', -1, event)

            return {
                success = true,
                message = 'Event stopped',
                event = event
            }
        end
    end

    return { success = false, message = 'Event not found' }
end

function Events.Delete(source, data)
    if not hasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    for index, event in ipairs(eventsData.events) do
        if event.id == data.id then
            table.remove(eventsData.events, index)

            return {
                success = true,
                message = 'Event deleted'
            }
        end
    end

    return { success = false, message = 'Event not found' }
end

RegisterNetEvent('ec_admin:events:getData')
AddEventHandler('ec_admin:events:getData', function(data, cb)
    local source = source
    local result = Events.GetData(source)

    if cb then
        cb(result)
    end
end)

RegisterNetEvent('ec_admin:events:create')
AddEventHandler('ec_admin:events:create', function(data, cb)
    local source = source
    local result = Events.Create(source, data)

    if cb then
        cb(result)
    end
end)

RegisterNetEvent('ec_admin:events:start')
AddEventHandler('ec_admin:events:start', function(data, cb)
    local source = source
    local result = Events.Start(source, data)

    if cb then
        cb(result)
    end
end)

RegisterNetEvent('ec_admin:events:stop')
AddEventHandler('ec_admin:events:stop', function(data, cb)
    local source = source
    local result = Events.Stop(source, data)

    if cb then
        cb(result)
    end
end)

RegisterNetEvent('ec_admin:events:delete')
AddEventHandler('ec_admin:events:delete', function(data, cb)
    local source = source
    local result = Events.Delete(source, data)

    if cb then
        cb(result)
    end
end)

_G.Events = Events
