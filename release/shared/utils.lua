-- EC Admin Ultimate - Shared Utilities
-- Functions available on both client and server

Utils = {}

-- Format time from timestamp
function Utils.FormatTime(timestamp)
    local time = os.date("*t", timestamp)
    return string.format("%02d/%02d/%04d %02d:%02d", 
        time.day, time.month, time.year, time.hour, time.min)
end

-- Format duration from seconds
function Utils.FormatDuration(seconds)
    if seconds < 60 then
        return seconds .. "s"
    elseif seconds < 3600 then
        return math.floor(seconds / 60) .. "m"
    elseif seconds < 86400 then
        return math.floor(seconds / 3600) .. "h"
    else
        return math.floor(seconds / 86400) .. "d"
    end
end

-- Get identifier from player
function Utils.GetIdentifier(source, idType)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in pairs(identifiers) do
        if string.find(id, idType) then
            return id
        end
    end
    return nil
end

-- Get all identifiers from player
function Utils.GetAllIdentifiers(source)
    local identifiers = {
        steam = Utils.GetIdentifier(source, "steam"),
        license = Utils.GetIdentifier(source, "license"),
        discord = Utils.GetIdentifier(source, "discord"),
        fivem = Utils.GetIdentifier(source, "fivem"),
        ip = Utils.GetIdentifier(source, "ip")
    }
    return identifiers
end

-- Check if player is owner
function Utils.IsOwner(source)
    local identifiers = Utils.GetAllIdentifiers(source)
    
    if identifiers.steam == Config.Owners.steam or
       identifiers.license == Config.Owners.license or
       identifiers.discord == Config.Owners.discord or
       identifiers.fivem == Config.Owners.fivem then
        return true
    end
    
    return false
end

-- Deep copy table
function Utils.DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in next, original, nil do
            copy[Utils.DeepCopy(key)] = Utils.DeepCopy(value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Check if table contains value
function Utils.TableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Round number to decimal places
function Utils.Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Generate random string
function Utils.GenerateId(length)
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = ''
    for i = 1, length do
        local rand = math.random(1, #chars)
        id = id .. chars:sub(rand, rand)
    end
    return id
end

-- Sanitize string for SQL
function Utils.SanitizeString(str)
    if not str then return "" end
    str = string.gsub(str, "'", "''")
    str = string.gsub(str, '"', '""')
    return str
end

-- Format money
function Utils.FormatMoney(amount)
    local formatted = amount
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return "$" .. formatted
end

return Utils
