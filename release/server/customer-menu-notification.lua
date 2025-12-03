--[[
    Customer Menu Notification System
    Sends Discord notification when customers use the admin menu
]]

local MENU_NOTIFIER = {}

-- Track which players have already been notified (session-based)
local notifiedPlayers = {}

-- Check if customer mode
local function IsCustomerMode()
    return GetConvar('ec_mode', 'CUSTOMER') == 'CUSTOMER'
end

-- Send Discord notification
local function SendMenuNotification(source, playerName, identifiers)
    if not Config.Discord or not Config.Discord.enabled then return end
    if not Config.Discord.notifyCustomerMenu then return end
    if not Config.Discord.webhook then return end
    
    -- Get Discord ID if available
    local discordId = nil
    local license = nil
    for _, identifier in ipairs(identifiers) do
        if identifier:match("^discord:") then
            discordId = identifier:gsub("^discord:", "")
        elseif identifier:match("^license:") then
            license = identifier:gsub("^license:", "")
        end
    end
    
    local embed = {
        {
            title = "🟢 Customer Using Admin Menu",
            description = ("%s opened the admin panel"):format(playerName),
            color = 5763719, -- Green
            fields = {
                {
                    name = "Player Name",
                    value = playerName,
                    inline = true
                },
                {
                    name = "Server ID",
                    value = tostring(source),
                    inline = true
                },
                {
                    name = "Discord",
                    value = discordId and ("<@" .. discordId .. ">") or "Not linked",
                    inline = true
                },
                {
                    name = "License",
                    value = license and ("||" .. license:sub(1, 20) .. "...||") or "Unknown",
                    inline = false
                }
            },
            footer = {
                text = "EC Admin Ultimate - Customer Menu Access"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }
    }
    
    PerformHttpRequest(Config.Discord.webhook, function(err, text, headers)
        -- Silent - no logging
    end, 'POST', json.encode({
        username = "Customer Menu Monitor",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Register event for menu open
RegisterNetEvent('ec-admin:server:menuOpened', function()
    local src = source
    
    -- Only notify in customer mode
    if not IsCustomerMode() then return end
    
    -- Check if already notified this session
    if notifiedPlayers[src] then return end
    
    local playerName = GetPlayerName(src)
    local identifiers = GetPlayerIdentifiers(src)
    
    -- Send notification
    SendMenuNotification(src, playerName, identifiers)
    
    -- Mark as notified
    notifiedPlayers[src] = true
end)

-- Clean up on player drop
AddEventHandler('playerDropped', function()
    local src = source
    notifiedPlayers[src] = nil
end)

-- Only load in customer mode
CreateThread(function()
    Wait(5000)
    
    if IsCustomerMode() then
        print('^2[Customer Menu] Notification system loaded^0')
        
        -- Enable notification in config
        Config.Discord = Config.Discord or {}
        Config.Discord.notifyCustomerMenu = true
    end
end)

return MENU_NOTIFIER
