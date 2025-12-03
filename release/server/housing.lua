-- EC Admin Ultimate - Housing Management System (PRODUCTION STABLE)
-- Version: 1.0.0 - Complete housing tracking and management

Logger.Info('🏠 Loading housing management system...')

local Housing = {}

-- Framework detection
local Framework = nil
local FrameworkObject = nil

-- Housing cache
local housingCache = {
    properties = {},
    rentals = {},
    transactions = {},
    lastUpdate = 0
}

-- Configuration
local config = {
    updateInterval = 60000,     -- 60 seconds
    cacheEnabled = true
}

-- Safe framework detection
local function DetectFramework()
    -- Detect QBCore (QBX variant)
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('🏠 QBCore (qbx_core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qbx_core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('🏠 QBCore framework successfully connected')
        else
            Logger.Info('⚠️ QBX Core detected but GetCoreObject() not available yet')
            Logger.Info('⚠️ Housing will use basic mode until core loads')
        end
        return true  -- Return true even if core object isn't ready yet
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('🏠 QBCore (qb-core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('🏠 QBCore framework successfully connected')
        else
            Logger.Info('⚠️ QB Core detected but GetCoreObject() not available yet')
        end
        return true  -- Return true even if core object isn't ready yet
    end
    
    -- Detect ESX
    if GetResourceState('es_extended') == 'started' then
        Framework = 'ESX'
        local success, esxObj = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)
        if success and esxObj then
            FrameworkObject = esxObj
            Logger.Info('🏠 ESX framework detected')
        end
        return true  -- Return true even if ESX object isn't ready yet
    end
    
    Logger.Info('⚠️ No supported framework detected for housing')
    return false
end

-- Get player name from citizenid/identifier
local function GetPlayerName(citizenid)
    if not Framework or not FrameworkObject then
        return 'Unknown'
    end
    
    if Framework == 'QBCore' then
        -- Try online first
        for _, playerId in pairs(GetPlayers()) do
            local Player = FrameworkObject.Functions.GetPlayer(tonumber(playerId))
            if Player and Player.PlayerData.citizenid == citizenid then
                return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            end
        end
        
        -- Try database
        if MySQL and MySQL.query then
            local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
            if result and result[1] then
                local charinfo = json.decode(result[1].charinfo or '{}')
                return (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or 'Player')
            end
        end
    elseif Framework == 'ESX' then
        -- ESX implementation
        for _, playerId in pairs(GetPlayers()) do
            local xPlayer = FrameworkObject.GetPlayerFromId(tonumber(playerId))
            if xPlayer and xPlayer.identifier == citizenid then
                return xPlayer.getName()
            end
        end
    end
    
    return 'Unknown'
end

-- Get all properties
function Housing.GetProperties()
    local properties = {}
    
    if not Framework or not FrameworkObject then
        return properties
    end
    
    -- Check for qb-houses or similar housing scripts
    if GetResourceState('qb-houses') == 'started' or GetResourceState('qb-housing') == 'started' then
        -- Try to get from qb-houses database
        if MySQL and MySQL.query then
            local result = MySQL.query.await('SELECT * FROM player_houses')
            if result then
                for _, row in ipairs(result) do
                    local hasKeys = {}
                    if row.keyholders then
                        hasKeys = json.decode(row.keyholders or '[]')
                    end
                    
                    table.insert(properties, {
                        id = row.house or 'house_' .. row.identifier,
                        name = row.house,
                        label = row.label or row.house,
                        type = row.tier or 'apartment',
                        address = row.label or 'Unknown',
                        owner = row.citizenid,
                        ownerName = GetPlayerName(row.citizenid),
                        citizenid = row.citizenid,
                        price = tonumber(row.price) or 0,
                        owned = true,
                        garage = tonumber(row.garage) or 2,
                        locked = row.locked == 1,
                        hasKeys = hasKeys,
                        coords = {
                            x = tonumber(row.x) or 0,
                            y = tonumber(row.y) or 0,
                            z = tonumber(row.z) or 0
                        }
                    })
                end
            end
        end
    end
    
    -- Check for ps-housing
    if GetResourceState('ps-housing') == 'started' then
        if MySQL and MySQL.query then
            local result = MySQL.query.await('SELECT * FROM properties')
            if result then
                for _, row in ipairs(result) do
                    local hasKeys = {}
                    if row.has_access then
                        hasKeys = json.decode(row.has_access or '[]')
                    end
                    
                    table.insert(properties, {
                        id = 'prop_' .. row.property_id,
                        name = row.property_id or 'property',
                        label = row.street or row.property_id,
                        type = row.apartment or 'house',
                        address = row.street or 'Unknown',
                        owner = row.owner_citizenid,
                        ownerName = GetPlayerName(row.owner_citizenid),
                        citizenid = row.owner_citizenid,
                        price = tonumber(row.price) or 0,
                        owned = row.owner_citizenid ~= nil,
                        garage = tonumber(row.garage_size) or 2,
                        locked = row.door_data and json.decode(row.door_data or '{}').locked or false,
                        hasKeys = hasKeys,
                        coords = {
                            x = tonumber(row.coords_x) or 0,
                            y = tonumber(row.coords_y) or 0,
                            z = tonumber(row.coords_z) or 0
                        }
                    })
                end
            end
        end
    end
    
    -- Check for apartments table
    if #properties == 0 and MySQL and MySQL.query then
        local result = MySQL.query.await('SELECT * FROM apartments')
        if result then
            for _, row in ipairs(result) do
                table.insert(properties, {
                    id = 'apt_' .. (row.id or row.name),
                    name = row.name or 'apartment',
                    label = row.label or row.name,
                    type = 'apartment',
                    address = row.label or 'Unknown',
                    owner = row.citizenid,
                    ownerName = row.citizenid and GetPlayerName(row.citizenid) or nil,
                    citizenid = row.citizenid,
                    price = tonumber(row.price) or 0,
                    owned = row.citizenid ~= nil,
                    garage = 1,
                    locked = true,
                    hasKeys = row.citizenid and {row.citizenid} or {},
                    coords = {
                        x = 0,
                        y = 0,
                        z = 0
                    }
                })
            end
        end
    end
    
    return properties
end

-- Get rentals
function Housing.GetRentals()
    local rentals = {}
    
    if not Framework or not FrameworkObject then
        return rentals
    end
    
    -- Check for rental table in database
    if MySQL and MySQL.query then
        local result = MySQL.query.await('SELECT * FROM property_rentals')
        if result then
            for _, row in ipairs(result) do
                table.insert(rentals, {
                    id = 'rental_' .. row.id,
                    property = row.property_id,
                    propertyName = row.property_name or 'Unknown Property',
                    tenant = row.tenant_citizenid,
                    tenantName = GetPlayerName(row.tenant_citizenid),
                    landlord = row.landlord_citizenid,
                    landlordName = GetPlayerName(row.landlord_citizenid),
                    rent = tonumber(row.monthly_rent) or 0,
                    nextPayment = row.next_payment,
                    status = row.status or 'active',
                    dueDate = tonumber(row.due_date) or os.time()
                })
            end
        end
    end
    
    return rentals
end

-- Get transactions
function Housing.GetTransactions()
    local transactions = {}
    
    if not Framework or not FrameworkObject then
        return transactions
    end
    
    -- Check for housing transactions in database
    if MySQL and MySQL.query then
        local result = MySQL.query.await('SELECT * FROM housing_transactions ORDER BY timestamp DESC LIMIT 100')
        if result then
            for _, row in ipairs(result) do
                table.insert(transactions, {
                    id = 'tx_' .. row.id,
                    property = row.property_id,
                    propertyName = row.property_name or 'Unknown Property',
                    buyer = row.buyer_citizenid,
                    buyerName = GetPlayerName(row.buyer_citizenid),
                    seller = row.seller_citizenid or 'SYSTEM',
                    sellerName = row.seller_citizenid and GetPlayerName(row.seller_citizenid) or 'System',
                    price = tonumber(row.price) or 0,
                    date = row.date or os.date('%Y-%m-%d'),
                    timestamp = tonumber(row.timestamp) or os.time(),
                    type = row.transaction_type or 'purchase'
                })
            end
        end
    end
    
    return transactions
end

-- Get comprehensive housing data
function Housing.GetAllData()
    local properties = Housing.GetProperties()
    local rentals = Housing.GetRentals()
    local transactions = Housing.GetTransactions()
    
    local stats = {
        totalProperties = #properties,
        ownedProperties = 0,
        forSale = 0,
        activeRentals = 0,
        totalValue = 0,
        monthlyRentIncome = 0
    }
    
    -- Calculate stats
    for _, property in ipairs(properties) do
        if property.owned then
            stats.ownedProperties = stats.ownedProperties + 1
        else
            stats.forSale = stats.forSale + 1
        end
        stats.totalValue = stats.totalValue + property.price
    end
    
    for _, rental in ipairs(rentals) do
        if rental.status == 'active' then
            stats.activeRentals = stats.activeRentals + 1
            stats.monthlyRentIncome = stats.monthlyRentIncome + rental.rent
        end
    end
    
    return {
        properties = properties,
        rentals = rentals,
        transactions = transactions,
        framework = Framework,
        stats = stats
    }
end

-- Update property
function Housing.UpdateProperty(adminSource, propertyId, price, address)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'manageHousing') then
        return false, 'Insufficient permissions'
    end
    
    if MySQL and MySQL.query then
        -- Try qb-houses
        MySQL.query('UPDATE player_houses SET price = ?, label = ? WHERE house = ?', 
            {price, address, propertyId})
        
        -- Try ps-housing
        MySQL.query('UPDATE properties SET price = ?, street = ? WHERE property_id = ?', 
            {price, address, propertyId})
        
        Logger.Info(string.format('', propertyId, price))
        return true, 'Property updated successfully'
    end
    
    return false, 'Database not available'
end

-- Transfer property
function Housing.TransferProperty(adminSource, propertyId, targetCitizenId)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'manageHousing') then
        return false, 'Insufficient permissions'
    end
    
    if MySQL and MySQL.query then
        -- Try qb-houses
        MySQL.query('UPDATE player_houses SET citizenid = ? WHERE house = ?', 
            {targetCitizenId, propertyId})
        
        -- Try ps-housing
        MySQL.query('UPDATE properties SET owner_citizenid = ? WHERE property_id = ?', 
            {targetCitizenId, propertyId})
        
        -- Log transaction
        MySQL.insert('INSERT INTO housing_transactions (property_id, buyer_citizenid, seller_citizenid, transaction_type, timestamp) VALUES (?, ?, ?, ?, ?)',
            {propertyId, targetCitizenId, 'ADMIN_TRANSFER', 'transfer', os.time()})
        
        Logger.Info(string.format('', propertyId, targetCitizenId))
        return true, 'Property transferred successfully'
    end
    
    return false, 'Database not available'
end

-- Remove ownership
function Housing.RemoveOwnership(adminSource, propertyId, reason)
    if not _G.ECPermissions or not_G.ECPermissions.HasPermission(adminSource, 'wipeHousing') then
        return false, 'Insufficient permissions'
    end
    
    if MySQL and MySQL.query then
        -- Try qb-houses
        MySQL.query('UPDATE player_houses SET citizenid = NULL WHERE house = ?', {propertyId})
        
        -- Try ps-housing
        MySQL.query('UPDATE properties SET owner_citizenid = NULL WHERE property_id = ?', {propertyId})
        
        Logger.Info(string.format('', propertyId, reason))
        return true, 'Ownership removed successfully'
    end
    
    return false, 'Database not available'
end

-- Toggle lock
function Housing.ToggleLock(adminSource, propertyId)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'manageHousing') then
        return false, 'Insufficient permissions'
    end
    
    if MySQL and MySQL.query then
        -- Try qb-houses
        MySQL.query('UPDATE player_houses SET locked = NOT locked WHERE house = ?', {propertyId})
        
        Logger.Info(string.format('', propertyId))
        return true, 'Lock status toggled'
    end
    
    return false, 'Database not available'
end

-- Give key
function Housing.GiveKey(adminSource, propertyId, targetCitizenId)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'manageHousing') then
        return false, 'Insufficient permissions'
    end
    
    if MySQL and MySQL.query then
        -- Get current keyholders
        local result = MySQL.query.await('SELECT keyholders FROM player_houses WHERE house = ?', {propertyId})
        if result and result[1] then
            local keyholders = json.decode(result[1].keyholders or '[]')
            
            -- Check if already has key
            for _, holder in ipairs(keyholders) do
                if holder == targetCitizenId then
                    return false, 'Player already has a key'
                end
            end
            
            -- Add new keyholder
            table.insert(keyholders, targetCitizenId)
            
            MySQL.query('UPDATE player_houses SET keyholders = ? WHERE house = ?', 
                {json.encode(keyholders), propertyId})
            
            Logger.Info(string.format('', propertyId, targetCitizenId))
            return true, 'Key given successfully'
        end
    end
    
    return false, 'Failed to give key'
end

-- Add property
function Housing.AddProperty(adminSource, name, propertyType, price, address, garage)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'manageHousing') then
        return false, 'Insufficient permissions'
    end
    
    if MySQL and MySQL.query then
        -- Try qb-houses
        MySQL.insert('INSERT INTO player_houses (house, label, price, tier, garage) VALUES (?, ?, ?, ?, ?)',
            {name, address, price, propertyType, garage})
        
        Logger.Info(string.format('', name, price))
        return true, 'Property added successfully'
    end
    
    return false, 'Database not available'
end

-- Initialize
function Housing.Initialize()
    Logger.Info('🏠 Initializing housing system...')
    
    local frameworkDetected = DetectFramework()
    if not frameworkDetected then
        Logger.Info('⚠️ Housing system disabled - no supported framework')
        return false
    end
    
    -- Create tables if they don't exist
    if MySQL and MySQL.query then
        -- Housing transactions table
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `housing_transactions` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `property_id` varchar(50) NOT NULL,
                `property_name` varchar(100) DEFAULT NULL,
                `buyer_citizenid` varchar(50) NOT NULL,
                `seller_citizenid` varchar(50) DEFAULT NULL,
                `price` int(11) DEFAULT 0,
                `transaction_type` varchar(20) DEFAULT 'purchase',
                `date` date DEFAULT NULL,
                `timestamp` bigint(20) DEFAULT NULL,
                PRIMARY KEY (`id`),
                KEY `property_id` (`property_id`),
                KEY `buyer_citizenid` (`buyer_citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        
        -- Property rentals table
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `property_rentals` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `property_id` varchar(50) NOT NULL,
                `property_name` varchar(100) DEFAULT NULL,
                `tenant_citizenid` varchar(50) NOT NULL,
                `landlord_citizenid` varchar(50) NOT NULL,
                `monthly_rent` int(11) DEFAULT 0,
                `next_payment` date DEFAULT NULL,
                `status` varchar(20) DEFAULT 'active',
                `due_date` bigint(20) DEFAULT NULL,
                PRIMARY KEY (`id`),
                KEY `property_id` (`property_id`),
                KEY `tenant_citizenid` (`tenant_citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        
        Logger.Info('🏠 Housing database tables initialized')
    end
    
    -- Update cache periodically
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(config.updateInterval)
            
            housingCache.properties = Housing.GetProperties()
            housingCache.rentals = Housing.GetRentals()
            housingCache.transactions = Housing.GetTransactions()
            housingCache.lastUpdate = os.time()
        end
    end)
    
    Logger.Info('✅ Housing system initialized with ' .. Framework .. ' framework')
    return true
end

-- Server events
RegisterNetEvent('ec-admin:getHousingData')
AddEventHandler('ec-admin:getHousingData', function()
    local source = source
    local data = Housing.GetAllData()
    TriggerClientEvent('ec-admin:receiveHousingData', source, data)
end)

-- Admin action events
RegisterNetEvent('ec-admin:housing:updateProperty')
AddEventHandler('ec-admin:housing:updateProperty', function(data, cb)
    local source = source
    local success, message = Housing.UpdateProperty(source, data.propertyId, data.price, data.address)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:housing:transferProperty')
AddEventHandler('ec-admin:housing:transferProperty', function(data, cb)
    local source = source
    local success, message = Housing.TransferProperty(source, data.propertyId, data.targetCitizenId)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:housing:removeOwnership')
AddEventHandler('ec-admin:housing:removeOwnership', function(data, cb)
    local source = source
    local success, message = Housing.RemoveOwnership(source, data.propertyId, data.reason)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:housing:toggleLock')
AddEventHandler('ec-admin:housing:toggleLock', function(data, cb)
    local source = source
    local success, message = Housing.ToggleLock(source, data.propertyId)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:housing:giveKey')
AddEventHandler('ec-admin:housing:giveKey', function(data, cb)
    local source = source
    local success, message = Housing.GiveKey(source, data.propertyId, data.targetCitizenId)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:housing:addProperty')
AddEventHandler('ec-admin:housing:addProperty', function(data, cb)
    local source = source
    local success, message = Housing.AddProperty(source, data.name, data.type, data.price, data.address, data.garage)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

-- Exports
exports('GetProperties', function()
    return Housing.GetProperties()
end)

exports('GetRentals', function()
    return Housing.GetRentals()
end)

exports('GetTransactions', function()
    return Housing.GetTransactions()
end)

exports('GetAllHousingData', function()
    return Housing.GetAllData()
end)

-- Initialize
Housing.Initialize()

-- Make available globally
_G.ECHousing = Housing

Logger.Info('✅ Housing system loaded successfully')