--[[
    EC Admin Ultimate - Whitelist Actions
    Event handlers for whitelist management
]]

RegisterNetEvent('ec_admin:approveWhitelist', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    if data and data.identifier and Whitelist then
        local success = Whitelist.Approve(data.identifier, GetPlayerName(src))
        
        if success then
            TriggerClientEvent('ec_admin:notify', src, {
                type = 'success',
                message = 'Whitelist application approved'
            })
            
            TriggerEvent('ec_admin:logActivity', {
                type = 'whitelist_approve',
                admin = GetPlayerName(src),
                target = data.identifier,
                description = 'Approved whitelist application'
            })
        end
    end
end)

RegisterNetEvent('ec_admin:denyWhitelist', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    if data and data.identifier and Whitelist then
        local success = Whitelist.Deny(data.identifier, GetPlayerName(src), data.reason)
        
        if success then
            TriggerClientEvent('ec_admin:notify', src, {
                type = 'success',
                message = 'Whitelist application denied'
            })
            
            TriggerEvent('ec_admin:logActivity', {
                type = 'whitelist_deny',
                admin = GetPlayerName(src),
                target = data.identifier,
                description = 'Denied whitelist application'
            })
        end
    end
end)

RegisterNetEvent('ec_admin:removeWhitelist', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    if data and data.identifier and Whitelist then
        local success = Whitelist.Remove(data.identifier)
        
        if success then
            TriggerClientEvent('ec_admin:notify', src, {
                type = 'success',
                message = 'Removed from whitelist'
            })
            
            TriggerEvent('ec_admin:logActivity', {
                type = 'whitelist_remove',
                admin = GetPlayerName(src),
                target = data.identifier,
                description = 'Removed from whitelist'
            })
        end
    end
end)

Logger.Info("^7 Whitelist actions loaded")
