--[[
    EC Admin Ultimate - Housing Management Callbacks
    Complete housing system with multi-framework support
    Supports: QB-Core, QBX, qb-houses, qbx_properties, ps-housing, ESX housing
]]

local QBCore = nil
local ESX = nil
local Framework = 'unknown'
local HousingSystem = 'unknown'

-- Initialize framework
CreateThread(function()
    Wait(1000)
    
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core -- QBX uses direct export
        Framework = 'qbx'
        
        if GetResourceState('qbx_properties') == 'started' then
            HousingSystem = 'qbx_properties'
        elseif GetResourceState('ps-housing') == 'started' then
            HousingSystem = 'ps-housing'
        elseif GetResourceState('qb-houses') == 'started' then
            HousingSystem = 'qb-houses'
        else
            HousingSystem = 'standalone'
        end
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
        
        if GetResourceState('ps-housing') == 'started' then
            HousingSystem = 'ps-housing'
        elseif GetResourceState('qb-houses') == 'started' then
            HousingSystem = 'qb-houses'
        elseif GetResourceState('qb-apartments') == 'started' then
            HousingSystem = 'qb-apartments'
        else
            HousingSystem = 'standalone'
        end
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
        HousingSystem = 'esx_property'
    end
    
    Logger.Debug('Housing System: ' .. HousingSystem .. ' (' .. Framework .. ')')
end)

-- Get player name from citizenid/identifier
local function GetPlayerName(identifier)
    if not identifier then return 'Unknown' end
    
    if Framework == 'qb-core' or Framework == 'qbx' then
        local result = MySQL.Sync.fetchAll('SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1', {identifier})
        if result and result[1] then
            local charinfo = json.decode(result[1].charinfo)
            if charinfo then
                return (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            end
        end
    elseif Framework == 'esx' then
        local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1', {identifier})
        if result and result[1] then
            return (result[1].firstname or '') .. ' ' .. (result[1].lastname or '')
        end
    end
    
    return 'Unknown'
end

-- Get all properties
local function GetAllProperties()
    local properties = {}
    local stats = {
        totalProperties = 0,
        ownedProperties = 0,
        vacantProperties = 0,
        totalValue = 0,
        activeRentals = 0,
        monthlyRentIncome = 0
    }
    
    if HousingSystem == 'qb-houses' or HousingSystem == 'qb-apartments' then
        -- QB Housing
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_houses', {})
        if result then
            for _, house in ipairs(result) do
                local coords = type(house.coords) == 'string' and json.decode(house.coords) or house.coords or { x = 0, y = 0, z = 0 }
                
                table.insert(properties, {
                    id = house.id or house.house,
                    name = house.house or house.label or 'Property ' .. (house.id or 'Unknown'),
                    label = house.label or house.house or 'Unknown',
                    address = house.street or house.label or 'Unknown Street',
                    type = house.type or 'house',
                    owner = house.citizenid,
                    ownerName = house.citizenid and GetPlayerName(house.citizenid) or 'Vacant',
                    citizenid = house.citizenid,
                    price = house.price or 0,
                    owned = house.citizenid ~= nil,
                    garage = house.garage or 0,
                    locked = house.locked == 1,
                    hasKeys = type(house.keyholders) == 'string' and json.decode(house.keyholders) or (house.keyholders or {}),
                    coords = coords,
                    tier = house.tier or 1,
                    metadata = house.metadata and (type(house.metadata) == 'string' and json.decode(house.metadata) or house.metadata) or {}
                })
                
                stats.totalProperties = stats.totalProperties + 1
                if house.citizenid then
                    stats.ownedProperties = stats.ownedProperties + 1
                else
                    stats.vacantProperties = stats.vacantProperties + 1
                end
                stats.totalValue = stats.totalValue + (house.price or 0)
            end
        end
    elseif HousingSystem == 'qbx_properties' then
        -- QBX Properties
        local result = MySQL.Sync.fetchAll('SELECT * FROM properties', {})
        if result then
            for _, property in ipairs(result) do
                local coords = type(property.coords) == 'string' and json.decode(property.coords) or property.coords or { x = 0, y = 0, z = 0 }
                
                table.insert(properties, {
                    id = property.id or property.property_id,
                    name = property.property_name or 'Property ' .. (property.id or 'Unknown'),
                    label = property.property_name or 'Unknown',
                    address = property.street or property.property_name or 'Unknown Street',
                    type = property.property_type or 'house',
                    owner = property.owner,
                    ownerName = property.owner and GetPlayerName(property.owner) or 'Vacant',
                    citizenid = property.owner,
                    price = property.price or 0,
                    owned = property.owner ~= nil,
                    garage = property.has_garage == 1 and 1 or 0,
                    locked = property.locked == 1,
                    hasKeys = {},
                    coords = coords,
                    tier = property.tier or 1,
                    metadata = {}
                })
                
                stats.totalProperties = stats.totalProperties + 1
                if property.owner then
                    stats.ownedProperties = stats.ownedProperties + 1
                else
                    stats.vacantProperties = stats.vacantProperties + 1
                end
                stats.totalValue = stats.totalValue + (property.price or 0)
            end
        end
    elseif HousingSystem == 'ps-housing' then
        -- PS Housing
        local result = MySQL.Sync.fetchAll('SELECT * FROM properties', {})
        if result then
            for _, property in ipairs(result) do
                local coords = type(property.door_data) == 'string' and json.decode(property.door_data) or property.door_data or { x = 0, y = 0, z = 0 }
                if coords.x == nil then coords = { x = 0, y = 0, z = 0 } end
                
                table.insert(properties, {
                    id = property.property_id or property.id,
                    name = property.property_id or 'Property ' .. (property.id or 'Unknown'),
                    label = property.property_id or 'Unknown',
                    address = property.street or property.property_id or 'Unknown Street',
                    type = 'house',
                    owner = property.owner_citizenid,
                    ownerName = property.owner_citizenid and GetPlayerName(property.owner_citizenid) or 'Vacant',
                    citizenid = property.owner_citizenid,
                    price = property.apartment and property.apartment.price or 0,
                    owned = property.owner_citizenid ~= nil,
                    garage = property.has_garage == 1 and 1 or 0,
                    locked = property.locked == 1,
                    hasKeys = {},
                    coords = coords,
                    tier = property.tier or 1,
                    metadata = {}
                })
                
                stats.totalProperties = stats.totalProperties + 1
                if property.owner_citizenid then
                    stats.ownedProperties = stats.ownedProperties + 1
                else
                    stats.vacantProperties = stats.vacantProperties + 1
                end
                stats.totalValue = stats.totalValue + (property.apartment and property.apartment.price or 0)
            end
        end
    elseif Framework == 'esx' then
        -- ESX Housing
        local result = MySQL.Sync.fetchAll('SELECT * FROM owned_properties', {})
        if result then
            for _, property in ipairs(result) do
                table.insert(properties, {
                    id = property.id,
                    name = property.name or 'Property ' .. property.id,
                    label = property.name or 'Unknown',
                    address = property.name or 'Unknown',
                    type = 'property',
                    owner = property.owner,
                    ownerName = property.owner and GetPlayerName(property.owner) or 'Vacant',
                    citizenid = property.owner,
                    price = property.price or 0,
                    owned = property.owner ~= nil,
                    garage = 0,
                    locked = false,
                    hasKeys = {},
                    coords = { x = 0, y = 0, z = 0 },
                    tier = 1,
                    metadata = {}
                })
                
                stats.totalProperties = stats.totalProperties + 1
                if property.owner then
                    stats.ownedProperties = stats.ownedProperties + 1
                else
                    stats.vacantProperties = stats.vacantProperties + 1
                end
                stats.totalValue = stats.totalValue + (property.price or 0)
            end
        end
    end
    
    return properties, stats
end

-- Get rentals (if supported)
local function GetRentals()
    local rentals = {}
    
    -- Check if rentals table exists
    local tableExists = MySQL.Sync.fetchAll("SHOW TABLES LIKE 'property_rentals'", {})
    if not tableExists or #tableExists == 0 then
        return rentals
    end
    
    local result = MySQL.Sync.fetchAll('SELECT * FROM property_rentals', {})
    if result then
        for _, rental in ipairs(result) do
            table.insert(rentals, {
                id = rental.id,
                property = rental.property_id,
                propertyName = rental.property_name or 'Unknown',
                tenant = rental.tenant_citizenid,
                tenantName = GetPlayerName(rental.tenant_citizenid),
                landlord = rental.landlord_citizenid,
                landlordName = GetPlayerName(rental.landlord_citizenid),
                rent = rental.rent_amount or 0,
                nextPayment = rental.next_payment or 'Unknown',
                status = rental.status or 'active',
                dueDate = rental.due_date or 0
            })
        end
    end
    
    return rentals
end

-- Get transactions (if supported)
local function GetTransactions()
    local transactions = {}
    
    -- Check if transactions table exists
    local tableExists = MySQL.Sync.fetchAll("SHOW TABLES LIKE 'property_transactions'", {})
    if not tableExists or #tableExists == 0 then
        return transactions
    end
    
    local result = MySQL.Sync.fetchAll('SELECT * FROM property_transactions ORDER BY timestamp DESC LIMIT 100', {})
    if result then
        for _, trans in ipairs(result) do
            table.insert(transactions, {
                id = trans.id,
                property = trans.property_id,
                propertyName = trans.property_name or 'Unknown',
                buyer = trans.buyer_citizenid,
                buyerName = GetPlayerName(trans.buyer_citizenid),
                seller = trans.seller_citizenid,
                sellerName = trans.seller_citizenid and GetPlayerName(trans.seller_citizenid) or 'Bank',
                price = trans.price or 0,
                date = trans.date or 'Unknown',
                timestamp = trans.timestamp or 0,
                type = trans.transaction_type or 'purchase'
            })
        end
    end
    
    return transactions
end

-- ==========================================
-- CALLBACK: Get All Housing Data (ox_lib callback for NUI)
-- ==========================================
-- ✅ CANONICAL VERSION - This is the primary implementation

lib.callback.register('ec_admin:getHousing', function(source, data)
    local properties, stats = GetAllProperties()
    local rentals = GetRentals()
    local transactions = GetTransactions()
    
    -- Calculate rental stats
    for _, rental in ipairs(rentals) do
        if rental.status == 'active' then
            stats.activeRentals = stats.activeRentals + 1
            stats.monthlyRentIncome = stats.monthlyRentIncome + rental.rent
        end
    end
    
    return {
        success = true,
        data = {
            properties = properties,
            rentals = rentals,
            transactions = transactions,
            stats = stats,
            framework = Framework,
            housingSystem = HousingSystem
        }
    }
end)

-- LEGACY: Main callback - Get all housing data (RegisterNetEvent version for backwards compatibility)
lib.callback.register('ec_admin:getHousingData', function(source, _)
    local src = source
    local properties, stats = GetAllProperties()
    local rentals = GetRentals()
    local transactions = GetTransactions()
    for _, rental in ipairs(rentals) do
        if rental.status == 'active' then
            stats.activeRentals = stats.activeRentals + 1
            stats.monthlyRentIncome = stats.monthlyRentIncome + rental.rent
        end
    end
    return { success = true, data = { properties = properties, rentals = rentals, transactions = transactions, stats = stats, framework = Framework, housingSystem = HousingSystem } }
end)

RegisterNetEvent('ec_admin_ultimate:server:getHousingData', function()
    local src = source
    
    local properties, stats = GetAllProperties()
    local rentals = GetRentals()
    local transactions = GetTransactions()
    
    -- Calculate rental stats
    for _, rental in ipairs(rentals) do
        if rental.status == 'active' then
            stats.activeRentals = stats.activeRentals + 1
            stats.monthlyRentIncome = stats.monthlyRentIncome + rental.rent
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveHousingData', src, {
        success = true,
        data = {
            properties = properties,
            rentals = rentals,
            transactions = transactions,
            stats = stats,
            framework = Framework,
            housingSystem = HousingSystem
        }
    })
end)

-- Transfer property
RegisterNetEvent('ec_admin_ultimate:server:transferProperty', function(data)
    local src = source
    local propertyId = data.propertyId
    local newOwner = data.newOwnerId
    
    if not propertyId or not newOwner then
        TriggerClientEvent('ec_admin_ultimate:client:housingResponse', src, {
            success = false,
            message = 'Invalid data'
        })
        return
    end
    
    local success = false
    local message = 'Failed to transfer property'
    
    if HousingSystem == 'qb-houses' or HousingSystem == 'qb-apartments' then
        local result = MySQL.Sync.execute('UPDATE player_houses SET citizenid = ? WHERE house = ?', {newOwner, propertyId})
        success = result > 0
        message = success and 'Property transferred successfully' or 'Property not found'
    elseif HousingSystem == 'qbx_properties' then
        local result = MySQL.Sync.execute('UPDATE properties SET owner = ? WHERE property_id = ?', {newOwner, propertyId})
        success = result > 0
        message = success and 'Property transferred successfully' or 'Property not found'
    elseif HousingSystem == 'ps-housing' then
        local result = MySQL.Sync.execute('UPDATE properties SET owner_citizenid = ? WHERE property_id = ?', {newOwner, propertyId})
        success = result > 0
        message = success and 'Property transferred successfully' or 'Property not found'
    elseif Framework == 'esx' then
        local result = MySQL.Sync.execute('UPDATE owned_properties SET owner = ? WHERE id = ?', {newOwner, propertyId})
        success = result > 0
        message = success and 'Property transferred successfully' or 'Property not found'
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:housingResponse', src, {
        success = success,
        message = message
    })
    
    if success then
        Logger.Debug(string.format('%s transferred property %s to %s', GetPlayerName(src), propertyId, newOwner), '🏠')
    end
end)

-- Evict property (remove owner)
RegisterNetEvent('ec_admin_ultimate:server:evictProperty', function(data)
    local src = source
    local propertyId = data.propertyId
    
    if not propertyId then
        TriggerClientEvent('ec_admin_ultimate:client:housingResponse', src, {
            success = false,
            message = 'Invalid property ID'
        })
        return
    end
    
    local success = false
    local message = 'Failed to evict property'
    
    if HousingSystem == 'qb-houses' or HousingSystem == 'qb-apartments' then
        local result = MySQL.Sync.execute('UPDATE player_houses SET citizenid = NULL WHERE house = ?', {propertyId})
        success = result > 0
        message = success and 'Property evicted successfully' or 'Property not found'
    elseif HousingSystem == 'qbx_properties' then
        local result = MySQL.Sync.execute('UPDATE properties SET owner = NULL WHERE property_id = ?', {propertyId})
        success = result > 0
        message = success and 'Property evicted successfully' or 'Property not found'
    elseif HousingSystem == 'ps-housing' then
        local result = MySQL.Sync.execute('UPDATE properties SET owner_citizenid = NULL WHERE property_id = ?', {propertyId})
        success = result > 0
        message = success and 'Property evicted successfully' or 'Property not found'
    elseif Framework == 'esx' then
        local result = MySQL.Sync.execute('UPDATE owned_properties SET owner = NULL WHERE id = ?', {propertyId})
        success = result > 0
        message = success and 'Property evicted successfully' or 'Property not found'
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:housingResponse', src, {
        success = success,
        message = message
    })
    
    if success then
        Logger.Debug(string.format('%s evicted property %s', GetPlayerName(src), propertyId), '🏠')
    end
end)

-- Delete property
RegisterNetEvent('ec_admin_ultimate:server:deleteProperty', function(data)
    local src = source
    local propertyId = data.propertyId
    
    if not propertyId then
        TriggerClientEvent('ec_admin_ultimate:client:housingResponse', src, {
            success = false,
            message = 'Invalid property ID'
        })
        return
    end
    
    local success = false
    local message = 'Failed to delete property'
    
    if HousingSystem == 'qb-houses' or HousingSystem == 'qb-apartments' then
        local result = MySQL.Sync.execute('DELETE FROM player_houses WHERE house = ?', {propertyId})
        success = result > 0
        message = success and 'Property deleted successfully' or 'Property not found'
    elseif HousingSystem == 'qbx_properties' then
        local result = MySQL.Sync.execute('DELETE FROM properties WHERE property_id = ?', {propertyId})
        success = result > 0
        message = success and 'Property deleted successfully' or 'Property not found'
    elseif HousingSystem == 'ps-housing' then
        local result = MySQL.Sync.execute('DELETE FROM properties WHERE property_id = ?', {propertyId})
        success = result > 0
        message = success and 'Property deleted successfully' or 'Property not found'
    elseif Framework == 'esx' then
        local result = MySQL.Sync.execute('DELETE FROM owned_properties WHERE id = ?', {propertyId})
        success = result > 0
        message = success and 'Property deleted successfully' or 'Property not found'
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:housingResponse', src, {
        success = success,
        message = message
    })
    
    if success then
        Logger.Info(string.format('', GetPlayerName(src), propertyId))
    end
end)

-- Set property price
RegisterNetEvent('ec_admin_ultimate:server:setPropertyPrice', function(data)
    local src = source
    local propertyId = data.propertyId
    local price = tonumber(data.price)
    
    if not propertyId or not price then
        TriggerClientEvent('ec_admin_ultimate:client:housingResponse', src, {
            success = false,
            message = 'Invalid data'
        })
        return
    end
    
    local success = false
    local message = 'Failed to set price'
    
    if HousingSystem == 'qb-houses' or HousingSystem == 'qb-apartments' then
        local result = MySQL.Sync.execute('UPDATE player_houses SET price = ? WHERE house = ?', {price, propertyId})
        success = result > 0
        message = success and 'Price updated successfully' or 'Property not found'
    elseif HousingSystem == 'qbx_properties' then
        local result = MySQL.Sync.execute('UPDATE properties SET price = ? WHERE property_id = ?', {price, propertyId})
        success = result > 0
        message = success and 'Price updated successfully' or 'Property not found'
    elseif Framework == 'esx' then
        local result = MySQL.Sync.execute('UPDATE owned_properties SET price = ? WHERE id = ?', {price, propertyId})
        success = result > 0
        message = success and 'Price updated successfully' or 'Property not found'
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:housingResponse', src, {
        success = success,
        message = message
    })
end)

Logger.Info('Housing callbacks loaded')