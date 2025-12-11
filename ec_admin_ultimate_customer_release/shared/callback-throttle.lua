--[[
    EC Admin Ultimate - Callback Throttling System
    Prevents callback spam and reduces server load
]]

-- Throttle cache: tracks last call time per callback per source
local throttleCache = {}

-- Throttle wrapper for lib.callback.register
-- Usage: throttleCallback('callbackName', minIntervalMs, callbackFunction)
function throttleCallback(name, minInterval, callback)
    return lib.callback.register(name, function(source, ...)
        local cacheKey = name .. ':' .. tostring(source)
        local now = os.clock() * 1000 -- Convert to milliseconds
        local lastCall = throttleCache[cacheKey] or 0
        local timeSinceLastCall = now - lastCall
        
        if timeSinceLastCall < minInterval then
            -- Too soon, return cached result or reject
            return { success = false, error = 'Rate limited. Please wait ' .. math.ceil((minInterval - timeSinceLastCall) / 1000) .. ' seconds.' }
        end
        
        -- Update cache
        throttleCache[cacheKey] = now
        
        -- Execute callback
        return callback(source, ...)
    end)
end

-- Clean old throttle cache entries (prevent memory leak)
CreateThread(function()
    while true do
        Wait(300000) -- Every 5 minutes
        
        local now = os.clock() * 1000
        local maxAge = 600000 -- 10 minutes
        
        for key, lastCall in pairs(throttleCache) do
            if now - lastCall > maxAge then
                throttleCache[key] = nil
            end
        end
    end
end)

print("^2[Callback Throttle]^7 Throttling system loaded^0")
