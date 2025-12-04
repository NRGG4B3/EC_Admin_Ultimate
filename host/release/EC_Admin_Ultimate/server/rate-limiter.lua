--[[
    EC Admin Ultimate - Rate Limiter
    Prevents admin event spam and exploits
]]

Logger.Info('🛡️  Loading rate limiter...')

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local RATE_LIMIT_WINDOW = 1000 -- 1 second window (milliseconds)

local MAX_REQUESTS = {
    -- Economy (strict limits)
    ['ec_admin:giveMoney'] = 5,
    ['ec_admin:removeMoney'] = 5,
    ['ec_admin:setMoney'] = 5,
    ['ec_admin:giveItem'] = 5,
    ['ec_admin:removeItem'] = 5,
    
    -- Vehicles (strict limits)
    ['ec_admin:spawnVehicle'] = 3,
    ['ec_admin:addVehicle'] = 3,
    ['ec_admin:deleteVehicle'] = 10,
    
    -- Moderation (moderate limits)
    ['ec_admin:kickPlayer'] = 3,
    ['ec_admin:banPlayer'] = 2,
    ['ec_admin:warnPlayer'] = 5,
    
    -- Teleportation (higher limits for legitimate use)
    ['ec_admin:teleportToPlayer'] = 10,
    ['ec_admin:bringPlayer'] = 10,
    ['ec_admin:teleportToCoords'] = 15,

    -- Player actions (higher limits)
    ['ec_admin:revivePlayer'] = 10,
    ['ec_admin:healPlayer'] = 10,
    ['ec_admin:freezePlayer'] = 10,
    ['ec_admin:spectatePlayer'] = 5,
    
    -- Jobs/Management (moderate)
    ['ec_admin:setJob'] = 5,
    ['ec_admin:setGang'] = 5,
    
    -- Server control (very strict)
    ['ec_admin:setWeather'] = 2,
    ['ec_admin:setTime'] = 2,
    ['ec_admin:toggleMaintenance'] = 1,
    ['ec_admin:toggleWhitelist'] = 1,
    
    -- Default for any other event
    ['default'] = 20
}

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

local rateLimiters = {}
local violationCounts = {}

-- ============================================================================
-- RATE LIMIT CHECK FUNCTION
-- ============================================================================

function CheckRateLimit(source, eventName)
    local now = GetGameTimer()
    
    -- Initialize player limiter
    if not rateLimiters[source] then
        rateLimiters[source] = {}
    end
    
    -- Initialize event limiter
    if not rateLimiters[source][eventName] then
        rateLimiters[source][eventName] = {
            count = 0,
            windowStart = now
        }
    end
    
    local limiter = rateLimiters[source][eventName]
    local maxRequests = MAX_REQUESTS[eventName] or MAX_REQUESTS['default']
    
    -- Reset window if expired
    if now - limiter.windowStart > RATE_LIMIT_WINDOW then
        limiter.count = 0
        limiter.windowStart = now
    end
    
    -- Check if exceeded
    if limiter.count >= maxRequests then
        -- Track violations
        violationCounts[source] = (violationCounts[source] or 0) + 1
        
        -- Log violation
        Logger.Info(string.format('', 
            source, GetPlayerName(source), eventName, limiter.count, maxRequests))
        
        -- Notify player
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'error',
            message = 'You are doing that too fast! Please wait a moment.'
        })
        
        -- If too many violations, warn admin
        if violationCounts[source] >= 10 then
            Logger.Info(string.format('',
                source, GetPlayerName(source)))
            
            -- Optionally notify other admins
            local players = GetPlayers()
            for _, playerId in ipairs(players) do
                local pid = tonumber(playerId)
                if pid and pid ~= source and HasPermission and HasPermission(pid) then
                    TriggerClientEvent('ec_admin:notify', pid, {
                        type = 'warning',
                        message = string.format('Player %s is triggering rate limits excessively', GetPlayerName(source))
                    })
                end
            end
            
            -- Reset violation count
            violationCounts[source] = 0
        end
        
        return false
    end
    
    -- Increment counter
    limiter.count = limiter.count + 1
    return true
end

-- ============================================================================
-- CLEANUP ON DISCONNECT
-- ============================================================================

AddEventHandler('playerDropped', function()
    local source = source
    
    -- Clean up rate limiter data
    rateLimiters[source] = nil
    violationCounts[source] = nil
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('CheckRateLimit', CheckRateLimit)

-- Make it globally available
_G.CheckRateLimit = CheckRateLimit

Logger.Info('✅ Rate limiter loaded')
