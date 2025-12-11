--[[
    EC Admin Ultimate - Housing UI Backend
    Server-side logic for housing management
    
    Handles:
    - housing:getData: Get all housing data (properties, rentals, transactions, stats)
    - housing:transferProperty: Transfer property to new owner
    - housing:evictProperty: Evict property owner
    - housing:deleteProperty: Delete property
    - housing:setPropertyPrice: Set property price
    
    Framework Support: QB-Core, QBX, ESX
    Housing System Support: qb-houses, qb-apartments, esx_property, custom
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Housing] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Housing] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local dataCache = {}
local CACHE_TTL = 15 -- Cache for 15 seconds

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get player object
local function getPlayerObject(source)
    return ECFramework.GetPlayerObject(source)
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Detect housing system
local function detectHousingSystem()
    -- Check for qb-houses
    if GetResourceState('qb-houses') == 'started' then
        return 'qb-houses'
    end
    
    -- Check for qb-apartments
    if GetResourceState('qb-apartments') == 'started' then
        return 'qb-apartments'
    end
    
    -- Check for esx_property
    if GetResourceState('esx_property') == 'started' then
        return 'esx_property'
    end
    
    -- Check for custom housing systems
    if GetResourceState('ps-housing') == 'started' then
        return 'ps-housing'
    end
    
    -- Default to framework housing
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        return 'qb-houses'
    elseif framework == 'esx' then
        return 'esx_property'
    end
    
    return 'unknown'
end

-- Helper: Get player identifier from source
local function getPlayerIdentifierFromSource(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    -- Try license first
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    return identifiers[1]
end

-- Helper: Get player source from identifier
local function getPlayerSourceByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local ids = GetPlayerIdentifiers(source)
            if ids then
                for _, id in ipairs(ids) do
                    if id == identifier then
                        return source
                    end
                end
            end
        end
    end
    return nil
end

-- Helper: Get player name from identifier
local function getPlayerNameByIdentifier(identifier)
    -- Try online first
    local source = getPlayerSourceByIdentifier(identifier)
    if source then
        return GetPlayerName(source) or 'Unknown'
    end
    
    -- Try database
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        local success, result = pcall(function()
            return MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1', {identifier})
        end)
        if success and result and result[1] then
            local charinfo = json.decode(result[1].charinfo or '{}')
            if charinfo then
                return (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            end
        end
    elseif framework == 'esx' then
        local result = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1', {identifier})
        if result and result[1] then
            return (result[1].firstname or '') .. ' ' .. (result[1].lastname or '')
        end
    end
    
    return 'Unknown'
end

-- Helper: Log housing action
local function logHousingAction(actionType, propertyId, propertyName, oldOwner, oldOwnerName, newOwner, newOwnerName, adminId, adminName, oldPrice, newPrice, actionData, reason, success, errorMsg)
    MySQL.insert.await([[
        INSERT INTO ec_housing_actions_log 
        (action_type, property_id, property_name, old_owner, old_owner_name, new_owner, new_owner_name, admin_id, admin_name, old_price, new_price, action_data, reason, timestamp, success, error_message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        actionType, propertyId, propertyName, oldOwner, oldOwnerName, newOwner, newOwnerName,
        adminId, adminName, oldPrice, newPrice,
        actionData and json.encode(actionData) or nil, reason,
        getCurrentTimestamp(), success and 1 or 0, errorMsg
    })
end

-- Helper: Get all properties
local function getAllProperties()
    local properties = {}
    local framework = getFramework()
    local housingSystem = detectHousingSystem()
    
    if housingSystem == 'qb-houses' or housingSystem == 'qb-apartments' then
        -- QB housing: Query houses/apartments table
        local tableName = housingSystem == 'qb-houses' and 'player_houses' or 'apartments'
        local result = MySQL.query.await(string.format('SELECT * FROM %s', tableName), {})
        
        if result then
            for _, row in ipairs(result) do
                local owner = row.citizenid or row.owner or ''
                local ownerName = 'Unknown'
                if owner ~= '' then
                    ownerName = getPlayerNameByIdentifier(owner)
                end
                
                local keys = {}
                if row.keyholders then
                    keys = json.decode(row.keyholders or '[]') or {}
                end
                
                table.insert(properties, {
                    id = row.house or row.id or tostring(row),
                    name = row.house or row.label or 'Unknown',
                    label = row.label or row.house or 'Unknown',
                    type = housingSystem == 'qb-houses' and 'house' or 'apartment',
                    address = row.adress or row.address or row.label or 'Unknown',
                    owner = owner,
                    ownerName = ownerName,
                    citizenid = owner,
                    price = tonumber(row.price) or 0,
                    owned = (owner ~= ''),
                    garage = tonumber(row.garage) or 0,
                    locked = (row.locked == 1 or row.locked == true),
                    hasKeys = keys,
                    coords = {
                        x = tonumber(row.coords?.x or row.coords_x or row.x) or 0.0,
                        y = tonumber(row.coords?.y or row.coords_y or row.y) or 0.0,
                        z = tonumber(row.coords?.z or row.coords_z or row.z) or 0.0
                    },
                    tier = tonumber(row.tier) or 1,
                    metadata = row.metadata or {}
                })
            end
        end
    elseif housingSystem == 'esx_property' then
        -- ESX property: Query properties table
        local result = MySQL.query.await('SELECT * FROM properties', {})
        
        if result then
            for _, row in ipairs(result) do
                local owner = row.owner or ''
                local ownerName = 'Unknown'
                if owner ~= '' then
                    ownerName = getPlayerNameByIdentifier(owner)
                end
                
                local keys = {}
                if row.keys then
                    keys = json.decode(row.keys or '[]') or {}
                end
                
                table.insert(properties, {
                    id = row.id,
                    name = row.name or 'Unknown',
                    label = row.label or row.name or 'Unknown',
                    type = row.type or 'house',
                    address = row.address or row.label or 'Unknown',
                    owner = owner,
                    ownerName = ownerName,
                    citizenid = owner,
                    price = tonumber(row.price) or 0,
                    owned = (owner ~= ''),
                    garage = tonumber(row.garage) or 0,
                    locked = (row.locked == 1 or row.locked == true),
                    hasKeys = keys,
                    coords = {
                        x = tonumber(row.coords_x or row.x) or 0.0,
                        y = tonumber(row.coords_y or row.y) or 0.0,
                        z = tonumber(row.coords_z or row.z) or 0.0
                    },
                    tier = tonumber(row.tier) or 1,
                    metadata = {}
                })
            end
        end
    end
    
    return properties
end

-- Helper: Get all rentals
local function getAllRentals()
    local rentals = {}
    local framework = getFramework()
    
    -- Check if rentals table exists
    local result = MySQL.query.await('SHOW TABLES LIKE "rentals"', {})
    if result and result[1] then
        local rentalResult = MySQL.query.await('SELECT * FROM rentals WHERE status = ?', {'active'})
        if rentalResult then
            for _, row in ipairs(rentalResult) do
                local tenantName = getPlayerNameByIdentifier(row.tenant or '')
                local landlordName = getPlayerNameByIdentifier(row.landlord or '')
                
                table.insert(rentals, {
                    id = row.id,
                    property = row.property_id or row.property,
                    propertyName = row.property_name or 'Unknown',
                    tenant = row.tenant or '',
                    tenantName = tenantName,
                    landlord = row.landlord or '',
                    landlordName = landlordName,
                    rent = tonumber(row.rent) or 0,
                    nextPayment = row.next_payment or '',
                    status = row.status or 'active',
                    dueDate = tonumber(row.due_date) or 0
                })
            end
        end
    end
    
    return rentals
end

-- Helper: Get all transactions
local function getAllTransactions()
    local transactions = {}
    
    -- Check if property_transactions table exists
    local result = MySQL.query.await('SHOW TABLES LIKE "property_transactions"', {})
    if result and result[1] then
        local transResult = MySQL.query.await('SELECT * FROM property_transactions ORDER BY timestamp DESC LIMIT 100', {})
        if transResult then
            for _, row in ipairs(transResult) do
                local buyerName = getPlayerNameByIdentifier(row.buyer or '')
                local sellerName = getPlayerNameByIdentifier(row.seller or '')
                
                table.insert(transactions, {
                    id = row.id,
                    property = row.property_id or row.property,
                    propertyName = row.property_name or 'Unknown',
                    buyer = row.buyer or '',
                    buyerName = buyerName,
                    seller = row.seller or '',
                    sellerName = sellerName,
                    price = tonumber(row.price) or 0,
                    date = os.date('%Y-%m-%d', row.timestamp),
                    timestamp = row.timestamp,
                    type = row.type or 'sale'
                })
            end
        end
    end
    
    return transactions
end

-- Helper: Get housing data (shared logic)
local function getHousingData()
    -- Check cache
    if dataCache.data and (getCurrentTimestamp() - dataCache.timestamp) < CACHE_TTL then
        return dataCache.data
    end
    
    local properties = getAllProperties()
    local rentals = getAllRentals()
    local transactions = getAllTransactions()
    
    -- Calculate statistics
    local stats = {
        totalProperties = #properties,
        ownedProperties = 0,
        vacantProperties = 0,
        totalValue = 0,
        activeRentals = #rentals,
        monthlyRentIncome = 0
    }
    
    for _, property in ipairs(properties) do
        if property.owned then
            stats.ownedProperties = stats.ownedProperties + 1
        else
            stats.vacantProperties = stats.vacantProperties + 1
        end
        stats.totalValue = stats.totalValue + property.price
    end
    
    for _, rental in ipairs(rentals) do
        stats.monthlyRentIncome = stats.monthlyRentIncome + rental.rent
    end
    
    local data = {
        properties = properties,
        rentals = rentals,
        transactions = transactions,
        stats = stats,
        framework = getFramework(),
        housingSystem = detectHousingSystem()
    }
    
    -- Cache data
    dataCache = {
        data = data,
        timestamp = getCurrentTimestamp()
    }
    
    return data
end

-- ============================================================================
-- REGISTERNUICALLBACK HANDLERS (Direct fetch from UI)
-- ============================================================================

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('housing:getData', function(data, cb)
--     local response = getHousingData()
--     cb({ success = true, data = response })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('housing:transferProperty', function(data, cb)
--     local propertyId = data.propertyId
--     local newOwnerId = data.newOwnerId
--     
--     if not propertyId or not newOwnerId then
--         cb({ success = false, message = 'Property ID and new owner ID required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Property transferred successfully'
--     
--     local framework = getFramework()
--     local housingSystem = detectHousingSystem()
--     
--     -- Get property info
--     local properties = getAllProperties()
--     local property = nil
--     for _, prop in ipairs(properties) do
--         if tostring(prop.id) == tostring(propertyId) then
--             property = prop
--             break
--         end
--     end
--     
--     if not property then
--         cb({ success = false, message = 'Property not found' })
--         return
--     end
--     
--     local oldOwner = property.owner or ''
--     local oldOwnerName = property.ownerName or 'Unknown'
--     local newOwnerName = 'Unknown'
--     
--     -- Get new owner identifier
--     local newOwnerIdentifier = nil
--     if tonumber(newOwnerId) then
--         local source = tonumber(newOwnerId)
--         newOwnerIdentifier = getPlayerIdentifierFromSource(source)
--         newOwnerName = GetPlayerName(source) or 'Unknown'
--     else
--         newOwnerIdentifier = newOwnerId
--         newOwnerName = getPlayerNameByIdentifier(newOwnerId)
--     end
--     
--     if housingSystem == 'qb-houses' or housingSystem == 'qb-apartments' then
--         local tableName = housingSystem == 'qb-houses' and 'player_houses' or 'apartments'
--         local idField = housingSystem == 'qb-houses' and 'house' or 'id'
--         
--         -- Update owner
--         MySQL.update.await(string.format('UPDATE %s SET citizenid = ?, owner = ? WHERE %s = ?', tableName, idField), {
--             newOwnerIdentifier, newOwnerIdentifier, propertyId
--         })
--         success = true
--     elseif housingSystem == 'esx_property' then
--         -- Update owner
--         MySQL.update.await('UPDATE properties SET owner = ? WHERE id = ?', {
--             newOwnerIdentifier, propertyId
--         })
--         success = true
--     end
--     
--     -- Log action
--     logHousingAction('transfer', tostring(propertyId), property.name, oldOwner, oldOwnerName, newOwnerIdentifier, newOwnerName, adminInfo.id, adminInfo.name, nil, nil, data, nil, success, nil)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to transfer property' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('housing:evictProperty', function(data, cb)
--     local propertyId = data.propertyId
--     
--     if not propertyId then
--         cb({ success = false, message = 'Property ID required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Property evicted successfully'
--     
--     local housingSystem = detectHousingSystem()
--     
--     -- Get property info
--     local properties = getAllProperties()
--     local property = nil
--     for _, prop in ipairs(properties) do
--         if tostring(prop.id) == tostring(propertyId) then
--             property = prop
--             break
--         end
--     end
--     
--     if not property then
--         cb({ success = false, message = 'Property not found' })
--         return
--     end
--     
--     local oldOwner = property.owner or ''
--     local oldOwnerName = property.ownerName or 'Unknown'
--     
--     if housingSystem == 'qb-houses' or housingSystem == 'qb-apartments' then
--         local tableName = housingSystem == 'qb-houses' and 'player_houses' or 'apartments'
--         local idField = housingSystem == 'qb-houses' and 'house' or 'id'
--         
--         -- Clear owner
--         MySQL.update.await(string.format('UPDATE %s SET citizenid = ?, owner = ? WHERE %s = ?', tableName, idField), {
--             '', '', propertyId
--         })
--         success = true
--     elseif housingSystem == 'esx_property' then
--         -- Clear owner
--         MySQL.update.await('UPDATE properties SET owner = ? WHERE id = ?', {
--             '', propertyId
--         })
--         success = true
--     end
--     
--     -- Log action
--     logHousingAction('evict', tostring(propertyId), property.name, oldOwner, oldOwnerName, '', 'System', adminInfo.id, adminInfo.name, nil, nil, data, nil, success, nil)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to evict property' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('housing:deleteProperty', function(data, cb)
--     local propertyId = data.propertyId
--     
--     if not propertyId then
--         cb({ success = false, message = 'Property ID required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Property deleted successfully'
--     
--     local housingSystem = detectHousingSystem()
--     
--     -- Get property info
--     local properties = getAllProperties()
--     local property = nil
--     for _, prop in ipairs(properties) do
--         if tostring(prop.id) == tostring(propertyId) then
--             property = prop
--             break
--         end
--     end
--     
--     if not property then
--         cb({ success = false, message = 'Property not found' })
--         return
--     end
--     
--     local oldOwner = property.owner or ''
--     local oldOwnerName = property.ownerName or 'Unknown'
--     
--     if housingSystem == 'qb-houses' or housingSystem == 'qb-apartments' then
--         local tableName = housingSystem == 'qb-houses' and 'player_houses' or 'apartments'
--         local idField = housingSystem == 'qb-houses' and 'house' or 'id'
--         
--         -- Delete property
--         MySQL.query.await(string.format('DELETE FROM %s WHERE %s = ?', tableName, idField), {propertyId})
--         success = true
--     elseif housingSystem == 'esx_property' then
--         -- Delete property
--         MySQL.query.await('DELETE FROM properties WHERE id = ?', {propertyId})
--         success = true
--     end
--     
--     -- Log action
--     logHousingAction('delete', tostring(propertyId), property.name, oldOwner, oldOwnerName, '', 'System', adminInfo.id, adminInfo.name, nil, nil, data, nil, success, nil)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to delete property' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('housing:setPropertyPrice', function(data, cb)
--     local propertyId = data.propertyId
--     local price = tonumber(data.price)
--     
--     if not propertyId or not price then
--         cb({ success = false, message = 'Property ID and price required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Property price updated successfully'
--     
--     local housingSystem = detectHousingSystem()
--     
--     -- Get property info
--     local properties = getAllProperties()
--     local property = nil
--     for _, prop in ipairs(properties) do
--         if tostring(prop.id) == tostring(propertyId) then
--             property = prop
--             break
--         end
--     end
--     
--     if not property then
--         cb({ success = false, message = 'Property not found' })
--         return
--     end
--     
--     local oldPrice = property.price or 0
--     
--     if housingSystem == 'qb-houses' or housingSystem == 'qb-apartments' then
--         local tableName = housingSystem == 'qb-houses' and 'player_houses' or 'apartments'
--         local idField = housingSystem == 'qb-houses' and 'house' or 'id'
--         
--         -- Update price
--         MySQL.update.await(string.format('UPDATE %s SET price = ? WHERE %s = ?', tableName, idField), {
--             price, propertyId
--         })
--         success = true
--     elseif housingSystem == 'esx_property' then
--         -- Update price
--         MySQL.update.await('UPDATE properties SET price = ? WHERE id = ?', {
--             price, propertyId
--         })
--         success = true
--     end
--     
--     -- Log action
--     logHousingAction('set_price', tostring(propertyId), property.name, property.owner, property.ownerName, property.owner, property.ownerName, adminInfo.id, adminInfo.name, oldPrice, price, data, nil, success, nil)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to set property price' })
-- end)

print("^2[Housing]^7 UI Backend loaded - Housing System: " .. detectHousingSystem() .. "^0")

