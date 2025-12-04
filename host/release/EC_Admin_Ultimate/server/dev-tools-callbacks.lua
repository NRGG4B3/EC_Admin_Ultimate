--[[
    EC Admin Ultimate - Dev Tools Server Callbacks
    Script editor, resource builder, and development utilities
]]

Logger.Info('Loading Dev Tools callbacks...')

-- Create dev tools tables
CreateThread(function()
    Wait(3000)
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_dev_scripts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            type ENUM('client', 'server', 'shared') NOT NULL,
            language ENUM('lua', 'javascript') NOT NULL,
            content LONGTEXT NOT NULL,
            category VARCHAR(50) DEFAULT 'general',
            author VARCHAR(100) NOT NULL,
            running TINYINT(1) DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_type (type),
            INDEX idx_author (author)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_dev_console_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            type ENUM('info', 'warn', 'error', 'success') NOT NULL,
            message TEXT NOT NULL,
            source VARCHAR(100) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_created (created_at)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_dev_resources (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            description TEXT NULL,
            author VARCHAR(100) NOT NULL,
            version VARCHAR(20) NOT NULL,
            files LONGTEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_name (name)
        )
    ]], {})
    
    Logger.Info('Dev Tools tables initialized')
end)

-- Modern callback for dev tools data
lib.callback.register('ec_admin:getDevToolsData', function(source, data)
    -- Get scripts
    local scripts = MySQL.Sync.fetchAll('SELECT * FROM ec_dev_scripts ORDER BY updated_at DESC', {})
    
    -- Get console logs
    local consoleLogs = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_dev_console_logs 
        ORDER BY created_at DESC 
        LIMIT 100
    ]], {})
    
    -- Get saved resources
    local savedResources = MySQL.Sync.fetchAll('SELECT * FROM ec_dev_resources ORDER BY updated_at DESC', {})
    
    -- Get server resources
    local serverResources = {}
    local numResources = GetNumResources()
    
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName and resourceName ~= '_cfx_internal' then
            local state = GetResourceState(resourceName)
            table.insert(serverResources, {
                name = resourceName,
                state = state,
                author = GetResourceMetadata(resourceName, 'author', 0) or 'Unknown',
                version = GetResourceMetadata(resourceName, 'version', 0) or '1.0.0',
                description = GetResourceMetadata(resourceName, 'description', 0) or ''
            })
        end
    end
    
    return {
        success = true,
        scripts = scripts or {},
        consoleLogs = consoleLogs or {},
        savedResources = savedResources or {},
        serverResources = serverResources
    }
end)

-- Legacy event for backward compatibility
RegisterNetEvent('ec_admin_ultimate:server:getDevToolsData', function()
    local src = source
    
    -- Get scripts
    local scripts = MySQL.Sync.fetchAll('SELECT * FROM ec_dev_scripts ORDER BY updated_at DESC', {})
    
    -- Get console logs
    local consoleLogs = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_dev_console_logs 
        ORDER BY created_at DESC 
        LIMIT 100
    ]], {})
    
    -- Get saved resources
    local savedResources = MySQL.Sync.fetchAll('SELECT * FROM ec_dev_resources ORDER BY updated_at DESC', {})
    
    -- Get server resources
    local serverResources = {}
    local numResources = GetNumResources()
    
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName and resourceName ~= '_cfx_internal' then
            local state = GetResourceState(resourceName)
            local author = GetResourceMetadata(resourceName, 'author', 0) or 'Unknown'
            local version = GetResourceMetadata(resourceName, 'version', 0) or '1.0.0'
            local description = GetResourceMetadata(resourceName, 'description', 0) or ''
            
            table.insert(serverResources, {
                name = resourceName,
                state = state,
                author = author,
                version = version,
                description = description
            })
        end
    end
    
    -- Code snippets library
    local snippets = {
        {
            id = 'teleport_player',
            title = 'Teleport Player',
            description = 'Teleport a player to coordinates',
            category = 'player',
            language = 'lua',
            code = [[-- Server-side
RegisterCommand('tp', function(source, args)
    local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if x and y and z then
        SetEntityCoords(GetPlayerPed(source), x, y, z)
    end
end, false)]]
        },
        {
            id = 'give_weapon',
            title = 'Give Weapon',
            description = 'Give weapon to player',
            category = 'weapons',
            language = 'lua',
            code = [[-- Client-side
local ped = PlayerPedId()
GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 250, false, true)]]
        },
        {
            id = 'spawn_vehicle',
            title = 'Spawn Vehicle',
            description = 'Spawn vehicle near player',
            category = 'vehicles',
            language = 'lua',
            code = [[-- Client-side
local ped = PlayerPedId()
local coords = GetEntityCoords(ped)
local heading = GetEntityHeading(ped)
local model = GetHashKey('adder')

RequestModel(model)
while not HasModelLoaded(model) do
    Wait(10)
end

local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
SetPedIntoVehicle(ped, vehicle, -1)]]
        },
        {
            id = 'database_query',
            title = 'Database Query',
            description = 'Query MySQL database',
            category = 'database',
            language = 'lua',
            code = [[-- Server-side
MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = ?', {
    identifier
}, function(result)
    if result[1] then
        Logger.Info('User found:', json.encode(result[1]))
    end
end)]]
        },
        {
            id = 'event_trigger',
            title = 'Trigger Event',
            description = 'Client to Server event',
            category = 'events',
            language = 'lua',
            code = [[-- Client-side
TriggerServerEvent('myResource:serverEvent', data)

-- Server-side
RegisterNetEvent('myResource:serverEvent')
AddEventHandler('myResource:serverEvent', function(data)
    local source = source
    Logger.Info('Received from client:', data)
end)]]
        }
    }
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveDevToolsData', src, {
        success = true,
        data = {
            scripts = scripts,
            consoleLogs = consoleLogs,
            savedResources = savedResources,
            serverResources = serverResources,
            snippets = snippets
        }
    })
end)

-- Save script
RegisterNetEvent('ec_admin_ultimate:server:saveScript', function(data)
    local src = source
    local scriptId = data.scriptId
    local name = data.name
    local type = data.type
    local language = data.language
    local content = data.content
    local category = data.category or 'general'
    
    if scriptId then
        -- Update existing
        MySQL.Async.execute([[
            UPDATE ec_dev_scripts 
            SET name = ?, type = ?, language = ?, content = ?, category = ?, updated_at = NOW()
            WHERE id = ?
        ]], {name, type, language, content, category, scriptId}, function(affectedRows)
            TriggerClientEvent('ec_admin_ultimate:client:devToolsResponse', src, {
                success = true,
                message = 'Script updated successfully'
            })
        end)
    else
        -- Insert new
        MySQL.Async.execute([[
            INSERT INTO ec_dev_scripts (name, type, language, content, category, author)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {name, type, language, content, category, GetPlayerName(src)}, function(insertId)
            TriggerClientEvent('ec_admin_ultimate:client:devToolsResponse', src, {
                success = true,
                message = 'Script created successfully',
                scriptId = insertId
            })
        end)
    end
end)

-- Delete script
RegisterNetEvent('ec_admin_ultimate:server:deleteScript', function(data)
    local src = source
    local scriptId = tonumber(data.scriptId)
    
    MySQL.Async.execute('DELETE FROM ec_dev_scripts WHERE id = ?', {scriptId}, function(affectedRows)
        TriggerClientEvent('ec_admin_ultimate:client:devToolsResponse', src, {
            success = true,
            message = 'Script deleted successfully'
        })
    end)
end)

-- Execute script
RegisterNetEvent('ec_admin_ultimate:server:executeScript', function(data)
    local src = source
    local scriptType = data.scriptType
    local scriptContent = data.scriptContent
    
    if scriptType == 'server' then
        -- Execute server-side script
        local success, err = pcall(function()
            load(scriptContent)()
        end)
        
        if success then
            TriggerClientEvent('ec_admin_ultimate:client:devToolsResponse', src, {
                success = true,
                message = 'Server script executed successfully'
            })
            
            -- Log to console
            MySQL.Async.execute([[
                INSERT INTO ec_dev_console_logs (type, message, source)
                VALUES (?, ?, ?)
            ]], {'success', 'Server script executed', GetPlayerName(src)})
        else
            TriggerClientEvent('ec_admin_ultimate:client:devToolsResponse', src, {
                success = false,
                message = 'Script execution failed: ' .. tostring(err)
            })
            
            -- Log error
            MySQL.Async.execute([[
                INSERT INTO ec_dev_console_logs (type, message, source)
                VALUES (?, ?, ?)
            ]], {'error', 'Script execution failed: ' .. tostring(err), GetPlayerName(src)})
        end
    elseif scriptType == 'client' then
        -- Send to client for execution
        TriggerClientEvent('ec_admin_ultimate:client:executeClientScript', src, {
            script = scriptContent
        })
    end
end)

-- Save resource
RegisterNetEvent('ec_admin_ultimate:server:saveResource', function(data)
    local src = source
    local name = data.name
    local description = data.description or ''
    local author = data.author or GetPlayerName(src)
    local version = data.version or '1.0.0'
    local files = json.encode(data.files or {})
    
    MySQL.Async.execute([[
        INSERT INTO ec_dev_resources (name, description, author, version, files)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            description = VALUES(description),
            version = VALUES(version),
            files = VALUES(files),
            updated_at = NOW()
    ]], {name, description, author, version, files}, function(affectedRows)
        TriggerClientEvent('ec_admin_ultimate:client:devToolsResponse', src, {
            success = true,
            message = 'Resource saved successfully'
        })
    end)
end)

-- Log console message
RegisterNetEvent('ec_admin_ultimate:server:logConsole', function(data)
    local src = source
    local type = data.type or 'info'
    local message = data.message
    local source = data.source or GetPlayerName(src)
    
    MySQL.Async.execute([[
        INSERT INTO ec_dev_console_logs (type, message, source)
        VALUES (?, ?, ?)
    ]], {type, message, source})
end)

-- Clear console logs
RegisterNetEvent('ec_admin_ultimate:server:clearConsoleLogs', function()
    local src = source
    
    MySQL.Async.execute('DELETE FROM ec_dev_console_logs', {}, function(affectedRows)
        TriggerClientEvent('ec_admin_ultimate:client:devToolsResponse', src, {
            success = true,
            message = 'Console logs cleared'
        })
    end)
end)

Logger.Info('Dev Tools callbacks loaded')
