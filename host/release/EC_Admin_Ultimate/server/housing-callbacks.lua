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

-- =============================================================================
-- HOUSING MARKET SYSTEM - ENHANCED
-- =============================================================================

Logger.Info('🏠 Initializing Housing Market Engine')

local HousingMarket = {
    properties = {},
    prices = {},
    marketTrends = {},
    rentalData = {},
    config = {
        basePrice = 50000,
        priceMultiplier = 1.0,
        rentPercentage = 0.02,
        demandFactor = 1.0,
        supplyFactor = 1.0,
        volatility = 0.05
    }
}

-- Calculate property value
local function CalculatePropertyValue(property)
    local baseValue = property.basePrice or HousingMarket.config.basePrice
    local locationMultiplier = 1.0
    
    if property.location == 'downtown' then locationMultiplier = 1.5
    elseif property.location == 'suburbs' then locationMultiplier = 1.0
    elseif property.location == 'rural' then locationMultiplier = 0.7
    elseif property.location == 'beachfront' then locationMultiplier = 2.0 end
    
    local conditionMultiplier = 1.0
    if property.condition == 'excellent' then conditionMultiplier = 1.3
    elseif property.condition == 'good' then conditionMultiplier = 1.1
    elseif property.condition == 'fair' then conditionMultiplier = 0.9
    elseif property.condition == 'poor' then conditionMultiplier = 0.7 end
    
    local marketFactor = HousingMarket.config.demandFactor / HousingMarket.config.supplyFactor
    
    local ageDepreciation = 1.0
    if property.age and property.age > 0 then
        ageDepreciation = math.max(0.5, 1.0 - (property.age * 0.005))
    end
    
    local finalValue = baseValue * locationMultiplier * conditionMultiplier * marketFactor * ageDepreciation
    local volatility = math.random(-HousingMarket.config.volatility * 100, HousingMarket.config.volatility * 100) / 100
    finalValue = finalValue * (1.0 + volatility)
    
    return math.floor(finalValue)
end

-- Calculate monthly rent
local function CalculateMonthlyRent(propertyValue)
    return math.floor(propertyValue * HousingMarket.config.rentPercentage)
end

-- Update market trends
local function UpdateMarketTrends()
    local allProperties = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_housing_properties
    ]], {})
    
    if allProperties and #allProperties > 0 then
        local totalPrice = 0
        local availableCount = 0
        
        for _, prop in ipairs(allProperties) do
            totalPrice = totalPrice + (prop.current_price or 0)
            if prop.is_available == 1 then availableCount = availableCount + 1 end
        end
        
        local occupancyRate = 1.0 - (availableCount / #allProperties)
        
        if occupancyRate > 0.9 then
            HousingMarket.config.demandFactor = 1.3
        elseif occupancyRate > 0.75 then
            HousingMarket.config.demandFactor = 1.15
        elseif occupancyRate > 0.5 then
            HousingMarket.config.demandFactor = 1.0
        elseif occupancyRate > 0.25 then
            HousingMarket.config.demandFactor = 0.85
        else
            HousingMarket.config.demandFactor = 0.7
        end
    end
end

-- Get market status
RegisterNetEvent('ec_admin_ultimate:server:getHousingMarketStatus', function()
    local src = source
    UpdateMarketTrends()
    
    local stats = MySQL.Sync.fetchAll([[
        SELECT 
            COUNT(*) as total_properties,
            SUM(CASE WHEN is_available = 1 THEN 1 ELSE 0 END) as available,
            AVG(current_price) as avg_price,
            MIN(current_price) as min_price,
            MAX(current_price) as max_price
        FROM ec_housing_properties
    ]], {})[1] or {}
    
    TriggerClientEvent('ec_admin_ultimate:client:housingMarketStatus', src, {
        trends = HousingMarket.marketTrends,
        statistics = stats,
        demandFactor = HousingMarket.config.demandFactor
    })
end)

-- Get property list
RegisterNetEvent('ec_admin_ultimate:server:getPropertyList', function(filters)
    local src = source
    
    local query = 'SELECT * FROM ec_housing_properties WHERE 1=1'
    local params = {}
    
    if filters.location then
        query = query .. ' AND location = ?'
        table.insert(params, filters.location)
    end
    
    if filters.priceMin then
        query = query .. ' AND current_price >= ?'
        table.insert(params, filters.priceMin)
    end
    
    if filters.priceMax then
        query = query .. ' AND current_price <= ?'
        table.insert(params, filters.priceMax)
    end
    
    if filters.availableOnly then
        query = query .. ' AND is_available = 1'
    end
    
    query = query .. ' ORDER BY current_price ASC LIMIT 50'
    
    local properties = MySQL.Sync.fetchAll(query, params)
    TriggerClientEvent('ec_admin_ultimate:client:propertyListUpdate', src, properties or {})
end)

-- Purchase property
RegisterNetEvent('ec_admin_ultimate:server:purchaseProperty', function(propertyId)
    local src = source
    
    local property = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_housing_properties WHERE id = ?
    ]], { propertyId })[1]
    
    if not property or property.is_available == 0 then
        TriggerClientEvent('ec_admin_ultimate:client:purchaseResponse', src, {
            success = false,
            message = 'Property not available'
        })
        return
    end
    
    MySQL.Async.execute([[
        UPDATE ec_housing_properties SET 
        owner_id = ?, is_available = 0, owner_name = ?, purchase_date = NOW()
        WHERE id = ?
    ]], { src, GetPlayerName(src), propertyId })
    
    TriggerClientEvent('ec_admin_ultimate:client:purchaseResponse', src, {
        success = true,
        message = 'Property purchased!',
        property = property
    })
end)

-- Rent property
RegisterNetEvent('ec_admin_ultimate:server:rentProperty', function(propertyId, months)
    local src = source
    
    local property = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_housing_properties WHERE id = ?
    ]], { propertyId })[1]
    
    if not property then
        TriggerClientEvent('ec_admin_ultimate:client:rentalResponse', src, {
            success = false,
            message = 'Property not found'
        })
        return
    end
    
    local monthlyRent = CalculateMonthlyRent(property.current_price)
    local totalRent = monthlyRent * months
    
    MySQL.Async.execute([[
        INSERT INTO ec_housing_rentals 
        (player_id, property_id, monthly_rent, total_rent, start_date, months, status)
        VALUES (?, ?, ?, ?, NOW(), ?, 'active')
    ]], { src, propertyId, monthlyRent, totalRent, months })
    
    TriggerClientEvent('ec_admin_ultimate:client:rentalResponse', src, {
        success = true,
        message = 'Rental agreement created',
        monthlyRent = monthlyRent,
        totalRent = totalRent
    })
end)

-- Update property condition (admin)
RegisterNetEvent('ec_admin_ultimate:server:updatePropertyCondition', function(propertyId, newCondition)
    local src = source
    
    MySQL.Async.execute([[
        UPDATE ec_housing_properties SET condition = ? WHERE id = ?
    ]], { newCondition, propertyId })
    
    local property = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_housing_properties WHERE id = ?
    ]], { propertyId })[1]
    
    if property then
        local newPrice = CalculatePropertyValue(property)
        MySQL.Async.execute([[
            UPDATE ec_housing_properties SET current_price = ? WHERE id = ?
        ]], { newPrice, propertyId })
    end
end)

-- Update market every hour
CreateThread(function()
    while true do
        Wait(60 * 60 * 1000)
        UpdateMarketTrends()
        
        local properties = MySQL.Sync.fetchAll([[
            SELECT * FROM ec_housing_properties
        ]], {})
        
        if properties then
            for _, property in ipairs(properties) do
                local newPrice = CalculatePropertyValue(property)
                MySQL.Async.execute([[
                    UPDATE ec_housing_properties SET current_price = ? WHERE id = ?
                ]], { newPrice, property.id })
            end
        end
    end
end)

Logger.Success('✅ Housing Market System Enhanced')
Logger.Info('Features: Dynamic pricing | Rental system | Market simulation')
Logger.Info('Housing callbacks loaded')