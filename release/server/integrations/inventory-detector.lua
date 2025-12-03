--[[
    EC Admin Ultimate - Inventory System Detector
    Auto-detects and provides unified API for inventory systems
    
    Supported:
    - qb-inventory
    - ox_inventory
    - ps-inventory
    - core_inventory (qbx)
    - Framework default (fallback)
    
    NOT SUPPORTED:
    - qs-inventory (removed)
]]

Inventory = {
    Type = nil,
    Resource = nil,
    Ready = false
}

-- Detection
local function DetectInventory()
    local inventories = {
        {name = 'ox_inventory', type = 'ox'},
        {name = 'qb-inventory', type = 'qb'},
        {name = 'ps-inventory', type = 'ps'},
        {name = 'core_inventory', type = 'core'},
        {name = 'codem-inventory', type = 'codem'}
    }
    
    for _, inv in ipairs(inventories) do
        if GetResourceState(inv.name) == 'started' then
            Inventory.Type = inv.type
            Inventory.Resource = inv.name
            Inventory.Ready = true
            return true
        end
    end
    
    -- Fallback to framework inventory
    if _G.ECFramework and _G.ECFramework.Ready then
        Inventory.Type = 'framework'
        Inventory.Resource = _G.ECFramework.Resource
        Inventory.Ready = true
        return true
    end
    
    return false
end

CreateThread(function()
    Wait(2000) -- Wait for framework
    
    Logger.Info('Detecting inventory system...')
    
    if DetectInventory() then
        Logger.Info('✅ Inventory detected: ' .. Inventory.Type .. ' (' .. Inventory.Resource .. ')')
    else
        Logger.Info('⚠️  No inventory system detected')
    end
    
    _G.ECInventory = Inventory
end)

-- =====================================================
--  UNIFIED INVENTORY API
-- =====================================================

-- Get player inventory
function Inventory:GetInventory(source)
    if not self.Ready then return {} end
    
    if self.Type == 'ox' then
        local success, inv = pcall(function()
            return exports.ox_inventory:GetInventory(source)
        end)
        return success and inv or {}
        
    elseif self.Type == 'qb' or self.Type == 'framework' then
        local player = _G.ECFramework:GetPlayer(source)
        if not player then return {} end
        return player.PlayerData.items or {}
        
    elseif self.Type == 'ps' then
        local success, inv = pcall(function()
            return exports['ps-inventory']:GetCurrentInventory(source)
        end)
        return success and inv or {}
        
    elseif self.Type == 'core' then
        local success, inv = pcall(function()
            return exports.core_inventory:getInventory(source)
        end)
        return success and inv or {}
    end
    
    return {}
end

-- Get specific item
function Inventory:GetItem(source, itemName)
    if not self.Ready then return nil end
    
    if self.Type == 'ox' then
        local success, item = pcall(function()
            return exports.ox_inventory:GetItem(source, itemName, nil, true)
        end)
        return success and item or nil
        
    elseif self.Type == 'qb' or self.Type == 'framework' then
        local player = _G.ECFramework:GetPlayer(source)
        if not player then return nil end
        
        for _, item in pairs(player.PlayerData.items) do
            if item.name == itemName then
                return item
            end
        end
        return nil
        
    elseif self.Type == 'ps' then
        local success, item = pcall(function()
            return exports['ps-inventory']:GetItemByName(source, itemName)
        end)
        return success and item or nil
    end
    
    return nil
end

-- Add item
function Inventory:AddItem(source, itemName, amount, metadata)
    if not self.Ready then return false end
    
    amount = amount or 1
    metadata = metadata or {}
    
    if self.Type == 'ox' then
        local success = pcall(function()
            exports.ox_inventory:AddItem(source, itemName, amount, metadata)
        end)
        return success
        
    elseif self.Type == 'qb' or self.Type == 'framework' then
        local player = _G.ECFramework:GetPlayer(source)
        if not player then return false end
        return player.Functions.AddItem(itemName, amount, nil, metadata)
        
    elseif self.Type == 'ps' then
        local success = pcall(function()
            exports['ps-inventory']:AddItem(source, itemName, amount, metadata)
        end)
        return success
        
    elseif self.Type == 'core' then
        local success = pcall(function()
            exports.core_inventory:addItem(source, itemName, amount, metadata)
        end)
        return success
    end
    
    return false
end

-- Remove item
function Inventory:RemoveItem(source, itemName, amount)
    if not self.Ready then return false end
    
    amount = amount or 1
    
    if self.Type == 'ox' then
        local success = pcall(function()
            exports.ox_inventory:RemoveItem(source, itemName, amount)
        end)
        return success
        
    elseif self.Type == 'qb' or self.Type == 'framework' then
        local player = _G.ECFramework:GetPlayer(source)
        if not player then return false end
        return player.Functions.RemoveItem(itemName, amount)
        
    elseif self.Type == 'ps' then
        local success = pcall(function()
            exports['ps-inventory']:RemoveItem(source, itemName, amount)
        end)
        return success
        
    elseif self.Type == 'core' then
        local success = pcall(function()
            exports.core_inventory:removeItem(source, itemName, amount)
        end)
        return success
    end
    
    return false
end

-- Clear inventory
function Inventory:ClearInventory(source)
    if not self.Ready then return false end
    
    if self.Type == 'ox' then
        local success = pcall(function()
            exports.ox_inventory:ClearInventory(source)
        end)
        return success
        
    elseif self.Type == 'qb' or self.Type == 'framework' then
        local player = _G.ECFramework:GetPlayer(source)
        if not player then return false end
        player.Functions.ClearInventory()
        return true
        
    elseif self.Type == 'ps' then
        local inv = self:GetInventory(source)
        for _, item in pairs(inv) do
            self:RemoveItem(source, item.name, item.amount)
        end
        return true
    end
    
    return false
end

-- Get item count
function Inventory:GetItemCount(source, itemName)
    if not self.Ready then return 0 end
    
    if self.Type == 'ox' then
        local success, count = pcall(function()
            return exports.ox_inventory:GetItemCount(source, itemName)
        end)
        return success and count or 0
        
    elseif self.Type == 'qb' or self.Type == 'framework' then
        local player = _G.ECFramework:GetPlayer(source)
        if not player then return 0 end
        
        local item = self:GetItem(source, itemName)
        return item and item.amount or 0
        
    elseif self.Type == 'ps' then
        local item = self:GetItem(source, itemName)
        return item and item.amount or 0
    end
    
    return 0
end

-- Can carry item
function Inventory:CanCarryItem(source, itemName, amount)
    if not self.Ready then return false end
    
    amount = amount or 1
    
    if self.Type == 'ox' then
        local success, canCarry = pcall(function()
            return exports.ox_inventory:CanCarryItem(source, itemName, amount)
        end)
        return success and canCarry or false
        
    elseif self.Type == 'qb' or self.Type == 'framework' then
        -- QB doesn't have native can carry, assume yes
        return true
        
    elseif self.Type == 'ps' then
        local success, canCarry = pcall(function()
            return exports['ps-inventory']:CanCarryItem(source, itemName, amount)
        end)
        return success and canCarry or false
    end
    
    return true
end

-- Get item metadata
function Inventory:GetItemMetadata(source, itemName, slot)
    if not self.Ready then return {} end
    
    local item = self:GetItem(source, itemName)
    if not item then return {} end
    
    if self.Type == 'ox' then
        return item.metadata or {}
    elseif self.Type == 'qb' or self.Type == 'framework' then
        return item.info or {}
    elseif self.Type == 'ps' then
        return item.info or item.metadata or {}
    end
    
    return {}
end

-- Set item metadata
function Inventory:SetItemMetadata(source, itemName, slot, metadata)
    if not self.Ready then return false end
    
    if self.Type == 'ox' then
        local success = pcall(function()
            exports.ox_inventory:SetMetadata(source, slot, metadata)
        end)
        return success
        
    elseif self.Type == 'qb' or self.Type == 'framework' then
        local player = _G.ECFramework:GetPlayer(source)
        if not player then return false end
        
        -- QB stores metadata as 'info'
        if player.PlayerData.items[slot] then
            player.PlayerData.items[slot].info = metadata
            return true
        end
        return false
    end
    
    return false
end

-- Exports
exports('GetInventory', function()
    return Inventory
end)

exports('GetInventoryType', function()
    return Inventory.Type
end)

exports('IsInventoryReady', function()
    return Inventory.Ready
end)

Logger.Info('Inventory detector loaded')