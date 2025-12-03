--[[
    EC Admin Ultimate - Post-Setup Cleanup
    Removes setup files after customer installation
    Host installations keep setup files for re-configuration
]]--

-- Safety check: Ensure Config exists
if not Config then
    Logger.Info('')
    return
end

-- Path validator is now a global module, not require
local PathValidator = _G.PathValidator or {
    isValidPath = function(path)
        if not path or type(path) ~= 'string' then return false end
        local invalidChars = {'..', '~', '$', '|', '>', '<'}
        for _, char in ipairs(invalidChars) do
            if string.find(path, char, 1, true) then return false end
        end
        return true
    end
}

-- Files to remove for customer installations
local CUSTOMER_CLEANUP_FILES = {
    'ui/components/setup/',
    'ui/components/setup-or-admin.tsx',
    'ui/lib/setup-validation.ts',
    'ui/lib/setup-cleanup.ts',
    'setup.bat'
}

-- Create Open_Web_Admin.bat file
RegisterNetEvent('ec:createBatFile', function(data)
    local src = source
    local filename = data.filename or 'Open_Web_Admin.bat'
    local content = data.content or ''
    
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local filePath = resourcePath .. '/../' .. filename
    
    local file = io.open(filePath, 'w')
    if file then
        file:write(content)
        file:close()
        
        Logger.Info('' .. filename .. '^7')
        TriggerClientEvent('ec:createBatFileResponse', src, { success = true })
    else
        Logger.Info('' .. filename .. '^7')
        TriggerClientEvent('ec:createBatFileResponse', src, { success = false })
    end
end)

-- Write setup_complete.json flag
RegisterNetEvent('ec:writeSetupFlag', function(data)
    local src = source
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local flagPath = resourcePath .. '/setup_complete.json'
    
    local file = io.open(flagPath, 'w')
    if file then
        local json = require('json') or json
        file:write(json.encode(data))
        file:close()
        
        Logger.Info('')
        TriggerClientEvent('ec:writeSetupFlagResponse', src, { success = true })
    else
        Logger.Info('')
        TriggerClientEvent('ec:writeSetupFlagResponse', src, { success = false })
    end
end)

-- Check if setup is complete
RegisterNetEvent('ec:checkSetupFlag', function()
    local src = source
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local flagPath = resourcePath .. '/setup_complete.json'
    
    local file = io.open(flagPath, 'r')
    if file then
        local content = file:read('*all')
        file:close()
        
        local json = require('json') or json
        local flag = json.decode(content)
        TriggerClientEvent('ec:checkSetupFlagResponse', src, flag)
    else
        TriggerClientEvent('ec:checkSetupFlagResponse', src, { completed = false })
    end
end)

-- Delete setup flag (for re-running setup)
RegisterNetEvent('ec:deleteSetupFlag', function()
    local src = source
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local flagPath = resourcePath .. '/setup_complete.json'
    
    local success = os.remove(flagPath)
    if success then
        Logger.Info('')
        TriggerClientEvent('ec:deleteSetupFlagResponse', src, { success = true })
    else
        Logger.Info('')
        TriggerClientEvent('ec:deleteSetupFlagResponse', src, { success = false })
    end
end)

-- Perform cleanup of setup files
RegisterNetEvent('ec:cleanup', function(data)
    local src = source
    local isHostMode = data.isHostMode or false
    local action = data.action or 'cleanup_setup_files'
    
    local result = {
        success = true,
        filesRemoved = {},
        errors = {}
    }
    
    -- Only cleanup for customer installations
    if not isHostMode and action == 'cleanup_setup_files' then
        Logger.Info('')
        
        local resourcePath = GetResourcePath(GetCurrentResourceName())
        
        for _, file in ipairs(CUSTOMER_CLEANUP_FILES) do
            local fullPath = resourcePath .. '/' .. file
            
            -- SECURITY: Validate path is safe before executing shell commands
            local safe, err = PathValidator.isValidPath(fullPath)
            if not safe then
                table.insert(result.errors, 'Security: ' .. err .. ' (' .. PathValidator.SanitizeForLog(fullPath) .. ')')
                Logger.Info('' .. err .. '^7')
                goto continue
            end
            
            -- Additional validation for directory deletion
            if string.sub(file, -1) == '/' then
                local canModify, modErr = PathValidator.CanModifyDirectory(fullPath)
                if not canModify then
                    table.insert(result.errors, 'Protected: ' .. modErr)
                    Logger.Info('' .. file .. '^7')
                    goto continue
                end
            end
            
            -- Check if it's a directory
            if string.sub(file, -1) == '/' then
                -- HARDENED: Use validated path with no user input in command
                -- Only execute if path validation passed
                local success = os.execute('rd /s /q "' .. fullPath .. '" 2>nul')
                if success == 0 or success == true then
                    table.insert(result.filesRemoved, file)
                    Logger.Info('' .. file .. '^7')
                else
                    table.insert(result.errors, 'Failed to remove: ' .. file)
                end
            else
                -- Remove file (os.remove is safe, no shell involved)
                local success = os.remove(fullPath)
                if success then
                    table.insert(result.filesRemoved, file)
                    Logger.Info('' .. file .. '^7')
                else
                    table.insert(result.errors, 'Failed to remove: ' .. file)
                end
            end
            
            ::continue::
        end
        
        Logger.Info('' .. #result.filesRemoved .. ' items.^7')
        
        if #result.errors > 0 then
            Logger.Info('' .. #result.errors .. ' errors.^7')
            result.success = false
        end
    else
        Logger.Info('')
    end
    
    TriggerClientEvent('ec:cleanupResponse', src, result)
end)

-- Check if fxmanifest.lua needs updating
function CheckAndFixManifest()
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local manifestPath = resourcePath .. '/fxmanifest.lua'
    
    local file = io.open(manifestPath, 'r')
    if not file then
        Logger.Info('')
        return false
    end
    
    local content = file:read('*all')
    file:close()
    
    local needsFix = false
    local fixes = {}
    
    -- Check for correct ui_page
    if not string.find(content, "ui_page 'ui/dist/index.html'") then
        needsFix = true
        table.insert(fixes, "ui_page needs to be 'ui/dist/index.html'")
    end
    
    -- Check for dist files
    if not string.find(content, "'ui/dist/%*%*'") then
        needsFix = true
        table.insert(fixes, "files need to include 'ui/dist/**'")
    end
    
    if needsFix then
        -- Suppress warning if verbose logging disabled
        if Config.Logging and Config.Logging.verboseStartup then
            Logger.Info('')
            for _, fix in ipairs(fixes) do
                Logger.Warn('⚠️ ' .. fix)
            end
            Logger.Info('')
        end
    end
    
    Logger.Info('')
    return true
end

-- Run manifest check on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Wait a bit for everything to load
    Wait(1000)
    CheckAndFixManifest()
end)