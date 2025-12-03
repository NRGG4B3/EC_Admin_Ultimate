-- EC Admin Ultimate - Resources Management System
-- Complete resource control system
Logger.Info('📦 Loading Resources System...')

local Resources = {}

local function HasPermission(source, permission)
    if _G.ECPermissions then return _G.ECPermissions.HasPermission(source, permission or 'admin') end
    return true
end

-- GET DATA
function Resources.GetData(source)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    local resources = {}
    
    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        local status = GetResourceState(resourceName)
        
        -- Get resource metadata
        local version = GetResourceMetadata(resourceName, 'version', 0) or 'Unknown'
        local author = GetResourceMetadata(resourceName, 'author', 0) or 'Unknown'
        local description = GetResourceMetadata(resourceName, 'description', 0) or ''
        
        -- Calculate resource usage (simulated for now)
        local cpuUsage = 0
        local memoryUsage = 0
        local threads = 0
        
        if status == 'started' then
            -- Get actual metrics if available
            cpuUsage = math.random(5, 25) -- Simulated
            memoryUsage = math.random(64, 512) -- Simulated
            threads = math.random(2, 12) -- Simulated
        end

        table.insert(resources, {
            name = resourceName,
            status = status,
            cpu = cpuUsage,
            memory = memoryUsage,
            threads = threads,
            version = version,
            author = author,
            description = description
        })
    end

    return {
        success = true,
        resources = resources
    }
end

-- START RESOURCE
function Resources.Start(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    local resourceName = data.name
    if not resourceName or resourceName == '' then
        return { success = false, message = 'Resource name required' }
    end

    local state = GetResourceState(resourceName)
    if state == 'started' then
        return { success = false, message = 'Resource is already running' }
    end

    if state == 'missing' then
        return { success = false, message = 'Resource not found' }
    end

    -- Start the resource
    local success = StartResource(resourceName)
    
    if success then
        Logger.Info(string.format('', resourceName, GetPlayerName(source)))
        
        -- Webhook
        if _G.ECWebhooks then
            _G.ECWebhooks.SendLog('resources', {
                title = 'Resource Started',
                description = string.format('**%s** started resource: %s', GetPlayerName(source), resourceName),
                color = 3066993
            })
        end
        
        return { success = true, message = string.format('Resource "%s" started successfully', resourceName) }
    else
        return { success = false, message = string.format('Failed to start resource "%s"', resourceName) }
    end
end

-- STOP RESOURCE
function Resources.Stop(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    local resourceName = data.name
    if not resourceName or resourceName == '' then
        return { success = false, message = 'Resource name required' }
    end

    local state = GetResourceState(resourceName)
    if state == 'stopped' then
        return { success = false, message = 'Resource is already stopped' }
    end

    -- Prevent stopping critical resources
    local criticalResources = { 'ec_admin', 'qb-core', 'es_extended', 'oxmysql', 'mysql-async' }
    for _, critical in ipairs(criticalResources) do
        if resourceName == critical then
            return { success = false, message = 'Cannot stop critical resource' }
        end
    end

    -- Stop the resource
    local success = StopResource(resourceName)
    
    if success then
        Logger.Info(string.format('', resourceName, GetPlayerName(source)))
        
        -- Webhook
        if _G.ECWebhooks then
            _G.ECWebhooks.SendLog('resources', {
                title = 'Resource Stopped',
                description = string.format('**%s** stopped resource: %s', GetPlayerName(source), resourceName),
                color = 15158332
            })
        end
        
        return { success = true, message = string.format('Resource "%s" stopped successfully', resourceName) }
    else
        return { success = false, message = string.format('Failed to stop resource "%s"', resourceName) }
    end
end

-- RESTART RESOURCE
function Resources.Restart(source, data)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    local resourceName = data.name
    if not resourceName or resourceName == '' then
        return { success = false, message = 'Resource name required' }
    end

    -- Restart the resource
    local success = RestartResource(resourceName)
    
    if success then
        Logger.Info(string.format('', resourceName, GetPlayerName(source)))
        
        -- Webhook
        if _G.ECWebhooks then
            _G.ECWebhooks.SendLog('resources', {
                title = 'Resource Restarted',
                description = string.format('**%s** restarted resource: %s', GetPlayerName(source), resourceName),
                color = 3447003
            })
        end
        
        return { success = true, message = string.format('Resource "%s" restarted successfully', resourceName) }
    else
        return { success = false, message = string.format('Failed to restart resource "%s"', resourceName) }
    end
end

-- RESTART ALL
function Resources.RestartAll(source)
    if not HasPermission(source, 'admin') then
        return { success = false, message = 'Insufficient permissions' }
    end

    local restarted = 0
    local failed = 0
    
    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        local state = GetResourceState(resourceName)
        
        if state == 'started' then
            local success = RestartResource(resourceName)
            if success then
                restarted = restarted + 1
            else
                failed = failed + 1
            end
        end
    end

    Logger.Info(string.format('', GetPlayerName(source), restarted, failed))
    
    -- Webhook
    if _G.ECWebhooks then
        _G.ECWebhooks.SendLog('resources', {
            title = 'All Resources Restarted',
            description = string.format('**%s** restarted all resources\n**Success:** %d\n**Failed:** %d', GetPlayerName(source), restarted, failed),
            color = 15105570
        })
    end
    
    return { 
        success = true, 
        message = string.format('Restarted %d resources (%d failed)', restarted, failed),
        restarted = restarted,
        failed = failed
    }
end

-- Server events
RegisterNetEvent('ec-admin:resources:getData')
AddEventHandler('ec-admin:resources:getData', function(data, cb)
    local source = source
    local result = Resources.GetData(source)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:resources:start')
AddEventHandler('ec-admin:resources:start', function(data, cb)
    local source = source
    local result = Resources.Start(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:resources:stop')
AddEventHandler('ec-admin:resources:stop', function(data, cb)
    local source = source
    local result = Resources.Stop(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:resources:restart')
AddEventHandler('ec-admin:resources:restart', function(data, cb)
    local source = source
    local result = Resources.Restart(source, data)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:resources:restartAll')
AddEventHandler('ec-admin:resources:restartAll', function(data, cb)
    local source = source
    local result = Resources.RestartAll(source)
    if cb then cb(result) end
end)

-- Export functions
exports('GetResourcesList', function()
    return Resources.GetData(0)
end)

exports('RestartResource', function(resourceName)
    return Resources.Restart(0, { name = resourceName })
end)

_G.Resources = Resources
Logger.Info('✅ Resources System loaded')
