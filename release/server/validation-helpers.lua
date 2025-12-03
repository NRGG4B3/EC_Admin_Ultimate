--[[
    EC Admin Ultimate - Validation Helpers
    Centralized input validation functions
]]

Logger.Info('📋 Loading validation helpers...')

-- ============================================================================
-- STRING VALIDATION
-- ============================================================================

function SanitizeReason(reason)
    if not reason or type(reason) ~= 'string' then
        return "No reason provided"
    end
    
    -- Trim whitespace
    reason = reason:match("^%s*(.-)%s*$") or ""
    
    -- Limit to 500 characters
    if #reason > 500 then
        reason = reason:sub(1, 497) .. "..."
    end
    
    return reason ~= "" and reason or "No reason provided"
end

function SanitizeMessage(message, maxLength)
    maxLength = maxLength or 500
    
    if not message or type(message) ~= 'string' then
        return nil
    end
    
    -- Trim whitespace
    message = message:match("^%s*(.-)%s*$") or ""
    
    if #message == 0 then
        return nil
    end
    
    -- Limit length
    if #message > maxLength then
        message = message:sub(1, maxLength)
    end
    
    return message
end

-- ============================================================================
-- PLAYER VALIDATION
-- ============================================================================

function ValidatePlayerId(playerId)
    playerId = tonumber(playerId)
    
    if not playerId then
        return false, nil, "Invalid player ID"
    end
    
    if not GetPlayerName(playerId) then
        return false, nil, "Player not found"
    end
    
    return true, playerId, nil
end

function ValidatePlayerExists(playerId, errorMessage)
    local valid, validId, err = ValidatePlayerId(playerId)
    
    if not valid then
        return false, err or errorMessage or "Player not found"
    end
    
    return true, validId
end

-- ============================================================================
-- AMOUNT VALIDATION
-- ============================================================================

function ValidateAmount(amount, min, max, name)
    amount = tonumber(amount)
    name = name or "Amount"
    min = min or 1
    max = max or 999999999
    
    if not amount then
        return false, nil, string.format("%s must be a number", name)
    end
    
    -- NaN check
    if amount ~= amount then
        return false, nil, string.format("%s is invalid (NaN)", name)
    end
    
    if amount < min or amount > max then
        return false, nil, string.format("%s must be between %d and %d", name, min, max)
    end
    
    return true, amount, nil
end

-- ============================================================================
-- ITEM/JOB VALIDATION
-- ============================================================================

function ValidateItemName(item)
    if not item or type(item) ~= 'string' then
        return false, "Invalid item name"
    end
    
    -- Trim
    item = item:match("^%s*(.-)%s*$") or ""
    
    if #item == 0 or #item > 50 then
        return false, "Item name must be 1-50 characters"
    end
    
    -- Alphanumeric + underscore only
    if not string.match(item, '^[a-zA-Z0-9_]+$') then
        return false, "Item name contains invalid characters"
    end
    
    return true, item
end

function ValidateJobName(job)
    if not job or type(job) ~= 'string' then
        return false, "Invalid job name"
    end
    
    -- Trim
    job = job:match("^%s*(.-)%s*$") or ""
    
    if #job == 0 or #job > 50 then
        return false, "Job name must be 1-50 characters"
    end
    
    -- Alphanumeric + underscore only
    if not string.match(job, '^[a-zA-Z0-9_]+$') then
        return false, "Job name contains invalid characters"
    end
    
    return true, job
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('SanitizeReason', SanitizeReason)
exports('SanitizeMessage', SanitizeMessage)
exports('ValidatePlayerId', ValidatePlayerId)
exports('ValidatePlayerExists', ValidatePlayerExists)
exports('ValidateAmount', ValidateAmount)
exports('ValidateItemName', ValidateItemName)
exports('ValidateJobName', ValidateJobName)

-- Make globally available
_G.SanitizeReason = SanitizeReason
_G.SanitizeMessage = SanitizeMessage
_G.ValidatePlayerId = ValidatePlayerId
_G.ValidatePlayerExists = ValidatePlayerExists
_G.ValidateAmount = ValidateAmount
_G.ValidateItemName = ValidateItemName
_G.ValidateJobName = ValidateJobName

Logger.Info('✅ Validation helpers loaded')
