// @ts-nocheck - Complex template system with dynamic types
import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { Separator } from '../ui/separator';
import { ScrollArea } from '../ui/scroll-area';
import { 
  Code, Terminal, Database, Bug, Zap, Settings, Monitor, Activity,
  Play, Save, Download, Upload, Copy, Trash2, Plus, FileCode,
  FolderOpen, File, Search, RefreshCw, AlertCircle, CheckCircle,
  Loader2, Eye, EyeOff, Maximize2, Minimize2, GitBranch, Package, XCircle,
  Wand2, BookOpen, Layers, FileJson, FilePlus, Library, Sparkles, Info
} from 'lucide-react';
import { isEnvBrowser, fetchNui } from '../nui-bridge';
import { toastSuccess, toastError } from '../../lib/toast';

interface DevToolsPageProps {
  liveData: any;
}

interface Script {
  id: string;
  name: string;
  type: 'client' | 'server' | 'shared';
  language: 'lua' | 'javascript';
  content: string;
  lastModified: number;
  author: string;
  running: boolean;
  category?: string;
}

interface ConsoleLog {
  timestamp: number;
  type: 'info' | 'warn' | 'error' | 'success';
  message: string;
  source?: string;
}

interface ResourceFile {
  name: string;
  type: 'client' | 'server' | 'shared' | 'config' | 'manifest';
  content: string;
}

interface CodeSnippet {
  id: string;
  title: string;
  description: string;
  category: string;
  code: string;
  language: 'lua' | 'javascript';
}

export function DevToolsPage({ liveData }: DevToolsPageProps) {
  const [activeTab, setActiveTab] = useState('editor');
  const [isLoading, setIsLoading] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);

  // Script Editor State
  const [scripts, setScripts] = useState<Script[]>([]);
  const [selectedScript, setSelectedScript] = useState<Script | null>(null);
  const [editorContent, setEditorContent] = useState('');
  const [scriptName, setScriptName] = useState('');
  const [scriptType, setScriptType] = useState<'client' | 'server' | 'shared'>('client');
  const [scriptLanguage, setScriptLanguage] = useState<'lua' | 'javascript'>('lua');
  const [scriptCategory, setScriptCategory] = useState('general');

  // Resource Builder State
  const [resourceName, setResourceName] = useState('');
  const [resourceDescription, setResourceDescription] = useState('');
  const [resourceAuthor, setResourceAuthor] = useState('Admin');
  const [resourceVersion, setResourceVersion] = useState('1.0.0');
  const [resourceFiles, setResourceFiles] = useState<ResourceFile[]>([]);

  // Script Wizard State
  const [wizardStep, setWizardStep] = useState(0);
  const [wizardType, setWizardType] = useState('vehicle');
  const [wizardOptions, setWizardOptions] = useState<Record<string, any>>({});

  // Console State
  const [consoleLogs, setConsoleLogs] = useState<ConsoleLog[]>([
    { timestamp: Date.now(), type: 'success', message: '[EC Admin] Dev Tools initialized', source: 'system' },
    { timestamp: Date.now(), type: 'info', message: '[EC Admin] Script editor ready', source: 'system' }
  ]);
  const [consoleFilter, setConsoleFilter] = useState<'all' | 'info' | 'warn' | 'error' | 'success'>('all');

  // Debug State
  const [debugMode, setDebugMode] = useState(false);
  const [liveReload, setLiveReload] = useState(false);
  const [autoSave, setAutoSave] = useState(true);
  const [showSnippets, setShowSnippets] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Code Snippets Library
  const codeSnippets: CodeSnippet[] = [
    {
      id: 'vehicle-spawn',
      title: 'Vehicle Spawner',
      description: 'Spawn vehicles at player position',
      category: 'vehicles',
      language: 'lua',
      code: `local function SpawnVehicle(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetVehicleEngineOn(vehicle, true, true, false)
    
    return vehicle
end

RegisterCommand('spawncar', function(source, args)
    if args[1] then
        SpawnVehicle(GetHashKey(args[1]))
    end
end)`
    },
    {
      id: 'teleport',
      title: 'Teleport System',
      description: 'Teleport player to coordinates',
      category: 'player',
      language: 'lua',
      code: `RegisterCommand('tp', function(source, args)
    local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if x and y and z then
        local ped = PlayerPedId()
        SetEntityCoords(ped, x, y, z, false, false, false, true)
    end
end)`
    },
    {
      id: 'give-weapon',
      title: 'Give Weapon',
      description: 'Give weapon to player',
      category: 'player',
      language: 'lua',
      code: `RegisterCommand('giveweapon', function(source, args)
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(args[1] or 'WEAPON_PISTOL')
    local ammo = tonumber(args[2]) or 250
    
    GiveWeaponToPed(ped, weaponHash, ammo, false, true)
    SetPedAmmo(ped, weaponHash, ammo)
end)`
    },
    {
      id: 'server-broadcast',
      title: 'Server Broadcast',
      description: 'Broadcast message to all players',
      category: 'server',
      language: 'lua',
      code: `RegisterCommand('broadcast', function(source, args)
    local message = table.concat(args, ' ')
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 0, 0},
        multiline = true,
        args = {"[SERVER]", message}
    })
end, true)`
    },
    {
      id: 'economy-money',
      title: 'Money Transfer',
      description: 'Transfer money between players',
      category: 'economy',
      language: 'lua',
      code: `-- QB-Core Example
RegisterCommand('givemoney', function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if targetId and amount then
        local Player = QBCore.Functions.GetPlayer(source)
        local Target = QBCore.Functions.GetPlayer(targetId)
        
        if Player and Target then
            if Player.PlayerData.money.cash >= amount then
                Player.Functions.RemoveMoney('cash', amount)
                Target.Functions.AddMoney('cash', amount)
                TriggerClientEvent('QBCore:Notify', source, 'Money sent!', 'success')
            end
        end
    end
end)`
    },
    {
      id: 'door-lock',
      title: 'Door Lock System',
      description: 'Lock/unlock doors',
      category: 'housing',
      language: 'lua',
      code: `local doorLocked = false

RegisterCommand('lockdoor', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local door = GetClosestObjectOfType(coords, 2.0, GetHashKey('prop_door'), false)
    
    if door ~= 0 then
        doorLocked = not doorLocked
        FreezeEntityPosition(door, doorLocked)
        TriggerEvent('chat:addMessage', {
            args = {"Door " .. (doorLocked and "locked" or "unlocked")}
        })
    end
end)`
    },
    {
      id: 'blip-creator',
      title: 'Create Map Blip',
      description: 'Add blip to map',
      category: 'map',
      language: 'lua',
      code: `function CreateBlipAtCoords(coords, sprite, color, text, scale)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite or 1)
    SetBlipColour(blip, color or 1)
    SetBlipScale(blip, scale or 0.8)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text or "Location")
    EndTextCommandSetBlipName(blip)
    
    return blip
end`
    },
    {
      id: 'database-query',
      title: 'Database Query',
      description: 'Execute MySQL query',
      category: 'database',
      language: 'lua',
      code: `MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
    ['@identifier'] = identifier
}, function(result)
    if result[1] then
        print('User found:', json.encode(result[1]))
    else
        print('User not found')
    end
end)`
    },
    {
      id: 'nui-callback',
      title: 'NUI Callback',
      description: 'Handle UI callback',
      category: 'ui',
      language: 'lua',
      code: `RegisterNUICallback('myCallback', function(data, cb)
    print('Received from UI:', json.encode(data))
    
    -- Process data
    local result = {
        success = true,
        message = 'Data processed'
    }
    
    cb(result)
end)`
    },
    {
      id: 'event-handler',
      title: 'Event Handler',
      description: 'Register event handler',
      category: 'events',
      language: 'lua',
      code: `RegisterNetEvent('myResource:eventName')
AddEventHandler('myResource:eventName', function(param1, param2)
    print('Event triggered:', param1, param2)
    -- Handle event
end)`
    },
    {
      id: 'job-duty',
      title: 'Job Duty Toggle',
      description: 'Toggle player job duty',
      category: 'jobs',
      language: 'lua',
      code: `-- QB-Core Example
RegisterCommand('toggleduty', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local onDuty = not Player.PlayerData.job.onduty
        Player.Functions.SetJobDuty(onDuty)
        TriggerClientEvent('QBCore:Notify', source, 
            'You are now ' .. (onDuty and 'on' or 'off') .. ' duty', 
            'primary'
        )
    end
end)`
    },
    {
      id: 'inventory-item',
      title: 'Give Item',
      description: 'Give item to player',
      category: 'inventory',
      language: 'lua',
      code: `-- QB-Core Example
RegisterCommand('giveitem', function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    local itemName = args[1]
    local amount = tonumber(args[2]) or 1
    
    if Player and itemName then
        Player.Functions.AddItem(itemName, amount)
        TriggerClientEvent('inventory:client:ItemBox', source, 
            QBCore.Shared.Items[itemName], 'add', amount
        )
    end
end)`
    }
  ];

  // Comprehensive script templates
  const scriptTemplates = {
    lua: {
      client: {
        basic: `-- Client Script
-- Author: ${resourceAuthor}
-- Description: Basic client script

RegisterCommand('mycommand', function(source, args)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    print('Player coords:', coords)
end, false)

print('[Script] Loaded successfully')`,
        
        vehicle_system: `-- Advanced Vehicle System
-- Features: Spawn, modify, tune vehicles

local VehicleSystem = {}

-- Spawn vehicle
function VehicleSystem.SpawnVehicle(model, coords, heading)
    local hash = GetHashKey(model)
    
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return false, "Invalid vehicle model"
    end
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetModelAsNoLongerNeeded(hash)
    
    return true, vehicle
end

-- Modify vehicle
function VehicleSystem.ModifyVehicle(vehicle, mods)
    SetVehicleModKit(vehicle, 0)
    
    for modType, modIndex in pairs(mods) do
        SetVehicleMod(vehicle, modType, modIndex, false)
    end
    
    ToggleVehicleMod(vehicle, 18, true) -- Turbo
    SetVehicleEnveffScale(vehicle, 0.0) -- Reduce dirt
end

-- Commands
RegisterCommand('spawnveh', function(source, args)
    local model = args[1] or 'adder'
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    local success, result = VehicleSystem.SpawnVehicle(model, coords, heading)
    if success then
        print('[Vehicle System] Vehicle spawned:', result)
    else
        print('[Vehicle System] Error:', result)
    end
end)

RegisterCommand('maxveh', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        local mods = {}
        for i = 0, 49 do
            local maxMod = GetNumVehicleMods(vehicle, i) - 1
            if maxMod > 0 then
                mods[i] = maxMod
            end
        end
        VehicleSystem.ModifyVehicle(vehicle, mods)
        print('[Vehicle System] Vehicle maxed out')
    end
end)

print('[Vehicle System] Initialized')`,

        player_manager: `-- Player Management System
-- Features: Health, armor, weapons, stats

local PlayerManager = {}
PlayerManager.Data = {
    health = 200,
    armor = 100,
    weapons = {}
}

-- Health functions
function PlayerManager.SetHealth(health)
    local ped = PlayerPedId()
    SetEntityHealth(ped, health)
    PlayerManager.Data.health = health
end

function PlayerManager.HealPlayer()
    PlayerManager.SetHealth(200)
    SetPedArmour(PlayerPedId(), 100)
    print('[Player] Healed')
end

-- Weapon functions
function PlayerManager.GiveWeapon(weaponHash, ammo)
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, GetHashKey(weaponHash), ammo or 250, false, true)
    SetPedAmmo(ped, GetHashKey(weaponHash), ammo or 250)
    
    table.insert(PlayerManager.Data.weapons, weaponHash)
end

function PlayerManager.RemoveAllWeapons()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    PlayerManager.Data.weapons = {}
    print('[Player] All weapons removed')
end

-- Stats functions
function PlayerManager.SetStat(statName, value)
    StatSetInt(GetHashKey("MP0_" .. statName), value, true)
end

-- Commands
RegisterCommand('heal', function()
    PlayerManager.HealPlayer()
end)

RegisterCommand('god', function()
    SetEntityInvincible(PlayerPedId(), true)
    print('[Player] God mode enabled')
end)

RegisterCommand('ungod', function()
    SetEntityInvincible(PlayerPedId(), false)
    print('[Player] God mode disabled')
end)

RegisterCommand('givegun', function(source, args)
    local weapon = args[1] or 'WEAPON_PISTOL'
    local ammo = tonumber(args[2]) or 250
    PlayerManager.GiveWeapon(weapon, ammo)
end)

print('[Player Manager] Initialized')`,

        ui_system: `-- UI System
-- NUI Integration and UI Management

local UISystem = {
    isOpen = false,
    data = {}
}

-- Open UI
function UISystem.Open(data)
    UISystem.isOpen = true
    UISystem.data = data or {}
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        data = UISystem.data
    })
end

-- Close UI
function UISystem.Close()
    UISystem.isOpen = false
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })
end

-- Update UI
function UISystem.Update(data)
    UISystem.data = data
    SendNUIMessage({
        action = 'updateUI',
        data = data
    })
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    UISystem.Close()
    cb('ok')
end)

RegisterNUICallback('actionPerformed', function(data, cb)
    print('[UI] Action:', data.action)
    
    -- Handle actions
    if data.action == 'spawn' then
        TriggerEvent('myResource:spawnVehicle', data.vehicle)
    end
    
    cb({success = true})
end)

-- Commands
RegisterCommand('openui', function()
    UISystem.Open({
        title = 'My UI',
        items = {'Item 1', 'Item 2', 'Item 3'}
    })
end)

-- Close UI on ESC
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if UISystem.isOpen and IsControlJustReleased(0, 322) then -- ESC
            UISystem.Close()
        end
    end
end)

print('[UI System] Initialized')`
      },
      
      server: {
        basic: `-- Server Script
-- Author: ${resourceAuthor}

RegisterCommand('servercommand', function(source, args)
    local playerName = GetPlayerName(source)
    print('Command by:', playerName)
end, true)

print('[Script] Server loaded')`,

        economy_system: `-- Economy System
-- Money management, transactions, shops

local EconomySystem = {}
EconomySystem.Accounts = {}

-- Initialize player account
function EconomySystem.CreateAccount(source, identifier)
    EconomySystem.Accounts[identifier] = {
        cash = 5000,
        bank = 10000,
        transactions = {}
    }
    
    print('[Economy] Account created:', identifier)
end

-- Get account
function EconomySystem.GetAccount(identifier)
    return EconomySystem.Accounts[identifier]
end

-- Add money
function EconomySystem.AddMoney(identifier, account, amount)
    if not EconomySystem.Accounts[identifier] then return false end
    
    EconomySystem.Accounts[identifier][account] = 
        EconomySystem.Accounts[identifier][account] + amount
    
    table.insert(EconomySystem.Accounts[identifier].transactions, {
        type = 'add',
        account = account,
        amount = amount,
        timestamp = os.time()
    })
    
    return true
end

-- Remove money
function EconomySystem.RemoveMoney(identifier, account, amount)
    if not EconomySystem.Accounts[identifier] then return false end
    
    if EconomySystem.Accounts[identifier][account] < amount then
        return false
    end
    
    EconomySystem.Accounts[identifier][account] = 
        EconomySystem.Accounts[identifier][account] - amount
    
    table.insert(EconomySystem.Accounts[identifier].transactions, {
        type = 'remove',
        account = account,
        amount = amount,
        timestamp = os.time()
    })
    
    return true
end

-- Transfer money
RegisterCommand('transfer', function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then return end
    
    local sourceIdentifier = GetPlayerIdentifier(source)
    local targetIdentifier = GetPlayerIdentifier(targetId)
    
    if EconomySystem.RemoveMoney(sourceIdentifier, 'cash', amount) then
        EconomySystem.AddMoney(targetIdentifier, 'cash', amount)
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[Economy]', 'Transfer successful'}
        })
    end
end)

print('[Economy System] Initialized')`,

        database_manager: `-- Database Manager
-- MySQL operations and data persistence

local DatabaseManager = {}

-- Execute query
function DatabaseManager.Execute(query, params, cb)
    MySQL.Async.execute(query, params, function(rowsChanged)
        if cb then cb(rowsChanged) end
    end)
end

-- Fetch single row
function DatabaseManager.FetchOne(query, params, cb)
    MySQL.Async.fetchAll(query, params, function(result)
        if cb then cb(result[1]) end
    end)
end

-- Fetch all rows
function DatabaseManager.FetchAll(query, params, cb)
    MySQL.Async.fetchAll(query, params, function(result)
        if cb then cb(result) end
    end)
end

-- Player data functions
function DatabaseManager.LoadPlayerData(identifier, cb)
    DatabaseManager.FetchOne(
        'SELECT * FROM players WHERE identifier = @identifier',
        {['@identifier'] = identifier},
        function(player)
            if player then
                cb(player)
            else
                -- Create new player
                DatabaseManager.Execute(
                    'INSERT INTO players (identifier, money, bank) VALUES (@identifier, @money, @bank)',
                    {
                        ['@identifier'] = identifier,
                        ['@money'] = 5000,
                        ['@bank'] = 10000
                    },
                    function()
                        DatabaseManager.LoadPlayerData(identifier, cb)
                    end
                )
            end
        end
    )
end

function DatabaseManager.SavePlayerData(identifier, data, cb)
    DatabaseManager.Execute(
        'UPDATE players SET money = @money, bank = @bank WHERE identifier = @identifier',
        {
            ['@identifier'] = identifier,
            ['@money'] = data.money,
            ['@bank'] = data.bank
        },
        cb
    )
end

-- Example usage
AddEventHandler('playerJoining', function()
    local source = source
    local identifier = GetPlayerIdentifier(source)
    
    DatabaseManager.LoadPlayerData(identifier, function(playerData)
        print('[Database] Player loaded:', identifier)
        -- Use player data
    end)
end)

print('[Database Manager] Initialized')`,

        job_system: `-- Job System
-- Job management, duty, salary

local JobSystem = {}
JobSystem.Jobs = {
    police = {
        name = 'Police',
        grades = {
            {name = 'Cadet', salary = 1000},
            {name = 'Officer', salary = 2000},
            {name = 'Sergeant', salary = 3000},
            {name = 'Lieutenant', salary = 4000},
            {name = 'Captain', salary = 5000}
        }
    },
    ems = {
        name = 'EMS',
        grades = {
            {name = 'Trainee', salary = 1000},
            {name = 'Paramedic', salary = 2000},
            {name = 'Doctor', salary = 3000},
            {name = 'Chief', salary = 4000}
        }
    }
}

JobSystem.PlayerJobs = {}

-- Set player job
function JobSystem.SetJob(source, jobName, grade)
    if not JobSystem.Jobs[jobName] then return false end
    
    local identifier = GetPlayerIdentifier(source)
    JobSystem.PlayerJobs[identifier] = {
        name = jobName,
        grade = grade or 0,
        onDuty = false
    }
    
    TriggerClientEvent('jobSystem:setJob', source, JobSystem.PlayerJobs[identifier])
    return true
end

-- Toggle duty
function JobSystem.ToggleDuty(source)
    local identifier = GetPlayerIdentifier(source)
    if not JobSystem.PlayerJobs[identifier] then return false end
    
    JobSystem.PlayerJobs[identifier].onDuty = not JobSystem.PlayerJobs[identifier].onDuty
    
    TriggerClientEvent('jobSystem:dutyChanged', source, JobSystem.PlayerJobs[identifier].onDuty)
    return JobSystem.PlayerJobs[identifier].onDuty
end

-- Salary system
Citizen.CreateThread(function()
    while true do
        Wait(600000) -- 10 minutes
        
        for identifier, jobData in pairs(JobSystem.PlayerJobs) do
            if jobData.onDuty then
                local job = JobSystem.Jobs[jobData.name]
                if job then
                    local salary = job.grades[jobData.grade + 1].salary
                    -- Add salary to player account
                    print('[Job System] Salary paid:', identifier, salary)
                end
            end
        end
    end
end)

-- Commands
RegisterCommand('setjob', function(source, args)
    local targetId = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0
    
    if JobSystem.SetJob(targetId, jobName, grade) then
        print('[Job System] Job set:', jobName)
    end
end, true)

RegisterCommand('duty', function(source)
    local onDuty = JobSystem.ToggleDuty(source)
    TriggerClientEvent('chat:addMessage', source, {
        args = {'[Job]', 'You are now ' .. (onDuty and 'on' or 'off') .. ' duty'}
    })
end)

print('[Job System] Initialized')`
      },
      
      shared: {
        basic: `-- Shared Configuration
-- Author: ${resourceAuthor}

Config = {}
Config.Version = '1.0.0'
Config.Debug = false

print('[Config] Loaded')`,

        framework_config: `-- Framework Configuration
-- Settings and configurations

Config = {}

-- General Settings
Config.Framework = 'qbcore' -- 'qbcore', 'esx', or 'standalone'
Config.Debug = false
Config.Locale = 'en'

-- Economy Settings
Config.Economy = {
    startingCash = 5000,
    startingBank = 10000,
    maxCash = 50000,
    enableATM = true,
    enableShops = true
}

-- Job Settings
Config.Jobs = {
    police = {
        name = 'Police Department',
        maxSlots = 20,
        vehicles = {'police', 'police2', 'police3'},
        weapons = {'WEAPON_PISTOL', 'WEAPON_STUNGUN', 'WEAPON_NIGHTSTICK'}
    },
    ems = {
        name = 'Emergency Medical Services',
        maxSlots = 15,
        vehicles = {'ambulance'},
        weapons = {}
    }
}

-- Vehicle Settings
Config.Vehicles = {
    fuelEnabled = true,
    damageMultiplier = 1.0,
    enableKeys = true,
    garages = {
        {coords = vector3(215.9, -805.8, 31.0), name = 'Central Garage'},
        {coords = vector3(-340.7, -874.3, 31.3), name = 'South Garage'}
    }
}

-- Map Settings
Config.Map = {
    blips = {
        {coords = vector3(215.9, -805.8, 31.0), sprite = 357, color = 3, name = 'Garage'},
        {coords = vector3(295.8, -584.6, 43.3), sprite = 61, color = 2, name = 'Hospital'}
    },
    markers = {
        {coords = vector3(215.9, -805.8, 31.0), type = 1, color = {r = 0, g = 255, b = 0}}
    }
}

-- Notification Settings
Config.Notifications = {
    position = 'top-right', -- 'top-right', 'top-left', 'bottom-right', 'bottom-left'
    duration = 5000
}

print('[Config] Framework configuration loaded')`
      }
    },
    
    javascript: {
      client: `// Client Script (JavaScript)
// Author: ${resourceAuthor}

RegisterCommand('mycommand', (source, args) => {
    const ped = PlayerPedId();
    const coords = GetEntityCoords(ped, true);
    console.log('Player coords:', coords);
}, false);

console.log('[Script] Loaded successfully');`,
      
      server: `// Server Script (JavaScript)
// Author: ${resourceAuthor}

RegisterCommand('servercommand', (source, args) => {
    const playerName = GetPlayerName(source);
    console.log(\`Command by: \${playerName}\`);
}, true);

console.log('[Script] Server loaded');`,
      
      shared: `// Shared Configuration (JavaScript)
// Author: ${resourceAuthor}

const Config = {
    version: '1.0.0',
    debug: false
};

console.log('[Config] Loaded');`
    }
  };

  // Load scripts with auto-refresh and NUI listeners
  useEffect(() => {
    let isMounted = true;

    // Initial load
    loadScripts();

    // Auto-refresh every 30 seconds
    const interval = setInterval(() => {
      if (isMounted) {
        loadScripts();
      }
    }, 30000);

    // Listen for NUI messages
    const handleMessage = (event: MessageEvent) => {
      if (event.data.action === 'devToolsData') {
        const result = event.data.data;
        if (result && result.success && result.data && isMounted) {
          setScripts(result.data.scripts || []);
        }
      } else if (event.data.action === 'devToolsResponse') {
        const result = event.data.data;
        if (result) {
          if (result.success) {
            showToast(result.message || 'Action completed successfully', 'success');
            addConsoleLog('success', result.message || 'Action completed');
            // Refresh scripts after action
            loadScripts();
          } else {
            showToast(result.message || 'Action failed', 'error');
            addConsoleLog('error', result.message || 'Action failed');
          }
        }
      }
    };

    window.addEventListener('message', handleMessage);

    return () => {
      isMounted = false;
      clearInterval(interval);
      window.removeEventListener('message', handleMessage);
    };
  }, []);

  const loadScripts = async () => {
    if (isEnvBrowser()) {
      // Mock scripts with more examples
      setScripts([
        {
          id: '1',
          name: 'vehicle_spawner',
          type: 'client',
          language: 'lua',
          content: scriptTemplates.lua.client.vehicle_system,
          lastModified: Date.now() - 3600000,
          author: 'Admin',
          running: false,
          category: 'vehicles'
        },
        {
          id: '2',
          name: 'player_manager',
          type: 'client',
          language: 'lua',
          content: scriptTemplates.lua.client.player_manager,
          lastModified: Date.now() - 7200000,
          author: 'Admin',
          running: false,
          category: 'player'
        },
        {
          id: '3',
          name: 'economy_system',
          type: 'server',
          language: 'lua',
          content: scriptTemplates.lua.server.economy_system,
          lastModified: Date.now() - 10800000,
          author: 'Admin',
          running: false,
          category: 'economy'
        }
      ]);
      return;
    }

    try {
      const response = await fetchNui<any>('devTools:getData', {}, null);
      if (response && response.success && response.data) {
        setScripts(response.data.scripts || []);
      }
    } catch (error) {
      console.error('Failed to load scripts:', error);
    }
  };

  // Save script
  const handleSaveScript = async () => {
    if (!scriptName.trim()) {
      showToast('Please enter a script name', 'error');
      return;
    }

    if (!editorContent.trim()) {
      showToast('Script content cannot be empty', 'error');
      return;
    }

    setIsLoading(true);

    const newScript: Script = {
      id: selectedScript?.id || Date.now().toString(),
      name: scriptName,
      type: scriptType,
      language: scriptLanguage,
      content: editorContent,
      lastModified: Date.now(),
      author: resourceAuthor,
      running: false,
      category: scriptCategory
    };

    try {
      if (isEnvBrowser()) {
        await new Promise(resolve => setTimeout(resolve, 500));
        setScripts(prev => {
          const existing = prev.findIndex(s => s.id === newScript.id);
          if (existing >= 0) {
            const updated = [...prev];
            updated[existing] = newScript;
            return updated;
          }
          return [...prev, newScript];
        });
        addConsoleLog('success', `Script "${scriptName}" saved successfully`);
        showToast('Script saved successfully', 'success');
      } else {
        const response = await fetchNui<{ success: boolean; message: string }>(
          'devTools:saveScript',
          newScript,
          null
        );

        if (response.success) {
          showToast(response.message, 'success');
          addConsoleLog('success', response.message);
          loadScripts();
        } else {
          showToast(response.message, 'error');
          addConsoleLog('error', response.message);
        }
      }
    } catch (error) {
      showToast('Failed to save script', 'error');
      addConsoleLog('error', 'Failed to save script');
    } finally {
      setIsLoading(false);
    }
  };

  // Execute script
  const handleExecuteScript = async () => {
    if (!selectedScript && !editorContent.trim()) {
      showToast('No script to execute', 'error');
      return;
    }

    setIsLoading(true);
    addConsoleLog('info', `Executing script: ${scriptName || selectedScript?.name || 'Untitled'}`);

    try {
      if (isEnvBrowser()) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        addConsoleLog('success', 'Script executed successfully');
        addConsoleLog('info', `Output: ${scriptType} script running on ${scriptLanguage}`);
        showToast('Script executed successfully', 'success');
      } else {
        const response = await fetchNui<{ success: boolean; message: string; output?: string }>(
          'devTools:executeScript',
          { 
            id: selectedScript?.id,
            content: editorContent,
            type: scriptType,
            language: scriptLanguage
          },
          null
        );

        if (response.success) {
          showToast(response.message, 'success');
          addConsoleLog('success', response.message);
          if (response.output) {
            addConsoleLog('info', `Output: ${response.output}`);
          }
        } else {
          showToast(response.message, 'error');
          addConsoleLog('error', response.message);
        }
      }
    } catch (error) {
      showToast('Failed to execute script', 'error');
      addConsoleLog('error', 'Script execution failed');
    } finally {
      setIsLoading(false);
    }
  };

  // Load script to editor
  const handleLoadScript = (script: Script) => {
    setSelectedScript(script);
    setEditorContent(script.content);
    setScriptName(script.name);
    setScriptType(script.type);
    setScriptLanguage(script.language);
    setScriptCategory(script.category || 'general');
    addConsoleLog('info', `Loaded script: ${script.name}`);
  };

  // Delete script
  const handleDeleteScript = async (id: string) => {
    if (!confirm('Are you sure you want to delete this script?')) return;

    setIsLoading(true);

    try {
      if (isEnvBrowser()) {
        await new Promise(resolve => setTimeout(resolve, 300));
        setScripts(prev => prev.filter(s => s.id !== id));
        addConsoleLog('info', 'Script deleted');
        showToast('Script deleted', 'success');
      } else {
        const response = await fetchNui<{ success: boolean; message: string }>(
          'devTools:deleteScript',
          { id },
          null
        );

        if (response.success) {
          showToast(response.message, 'success');
          addConsoleLog('info', response.message);
          loadScripts();
        } else {
          showToast(response.message, 'error');
        }
      }
    } catch (error) {
      showToast('Failed to delete script', 'error');
    } finally {
      setIsLoading(false);
    }
  };

  // New script
  const handleNewScript = () => {
    setSelectedScript(null);
    setEditorContent(scriptTemplates[scriptLanguage][scriptType].basic || '-- New Script\n-- Write your code here\n\n');
    setScriptName('');
    setScriptType('client');
    setScriptLanguage('lua');
    setScriptCategory('general');
    addConsoleLog('info', 'New script created');
  };

  // Load template
  const handleLoadTemplate = (templateKey: string) => {
    const template = scriptTemplates[scriptLanguage][scriptType][templateKey] || scriptTemplates[scriptLanguage][scriptType].basic;
    setEditorContent(template);
    addConsoleLog('info', `Template loaded: ${templateKey}`);
  };

  // Insert snippet
  const handleInsertSnippet = (snippet: CodeSnippet) => {
    setEditorContent(prev => prev + '\n\n' + snippet.code + '\n');
    addConsoleLog('info', `Snippet inserted: ${snippet.title}`);
    setShowSnippets(false);
  };

  // Add console log
  const addConsoleLog = (type: ConsoleLog['type'], message: string, source?: string) => {
    const log: ConsoleLog = {
      timestamp: Date.now(),
      type,
      message,
      source: source || 'editor'
    };
    setConsoleLogs(prev => [...prev, log]);
  };

  // Export script
  const handleExportScript = () => {
    const blob = new Blob([editorContent], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = (scriptName || 'script') + '.' + scriptLanguage;
    a.click();
    URL.revokeObjectURL(url);
    addConsoleLog('success', 'Script exported');
  };

  // Generate full resource
  const handleGenerateResource = async () => {
    if (!resourceName.trim()) {
      showToast('Please enter a resource name', 'error');
      return;
    }

    const manifest = `fx_version 'cerulean'
game 'gta5'

author '${resourceAuthor}'
description '${resourceDescription}'
version '${resourceVersion}'

${resourceFiles.filter(f => f.type === 'client').length > 0 ? `client_scripts {
${resourceFiles.filter(f => f.type === 'client').map(f => `    '${f.name}',`).join('\n')}
}` : ''}

${resourceFiles.filter(f => f.type === 'server').length > 0 ? `server_scripts {
${resourceFiles.filter(f => f.type === 'server').map(f => `    '${f.name}',`).join('\n')}
}` : ''}

${resourceFiles.filter(f => f.type === 'shared').length > 0 ? `shared_scripts {
${resourceFiles.filter(f => f.type === 'shared').map(f => `    '${f.name}',`).join('\n')}
}` : ''}`;

    addConsoleLog('success', 'Resource manifest generated');
    
    // In production, this would create actual files
    if (isEnvBrowser()) {
      showToast('Resource generated (preview mode)', 'success');
      console.log('Generated manifest:', manifest);
    } else {
      try {
        const response = await fetchNui<{ success: boolean; message: string }>(
          'devTools:saveResource',
          {
            name: resourceName,
            manifest: manifest,
            files: resourceFiles
          },
          null
        );

        if (response.success) {
          showToast(response.message, 'success');
          addConsoleLog('success', response.message);
        }
      } catch (error) {
        showToast('Failed to generate resource', 'error');
      }
    }
  };

  // Add file to resource
  const handleAddResourceFile = () => {
    const newFile: ResourceFile = {
      name: scriptType + '_script.lua',
      type: scriptType,
      content: editorContent
    };
    setResourceFiles(prev => [...prev, newFile]);
    addConsoleLog('info', `File added to resource: ${newFile.name}`);
  };

  // Get console type badge
  const getConsoleTypeBadge = (type: ConsoleLog['type']) => {
    const variants = {
      info: { variant: 'default' as const, icon: Activity, color: 'text-blue-500' },
      warn: { variant: 'secondary' as const, icon: AlertCircle, color: 'text-orange-500' },
      error: { variant: 'destructive' as const, icon: XCircle, color: 'text-red-500' },
      success: { variant: 'default' as const, icon: CheckCircle, color: 'text-green-500' }
    };

    const badge = variants[type];
    const Icon = badge.icon;

    return (
      <Badge variant={badge.variant} className="flex items-center gap-1 shrink-0">
        <Icon className="size-3" />
        {type}
      </Badge>
    );
  };

  const filteredLogs = consoleFilter === 'all' 
    ? consoleLogs 
    : consoleLogs.filter(log => log.type === consoleFilter);

  const filteredSnippets = searchQuery 
    ? codeSnippets.filter(s => 
        s.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        s.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
        s.category.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : codeSnippets;

  return (
    <div className={`space-y-6 ${isFullscreen ? 'fixed inset-0 z-50 p-6 overflow-auto' : ''}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1>Advanced Development Tools</h1>
          <p className="text-muted-foreground">Full script editor, code generation & resource builder</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => setIsFullscreen(!isFullscreen)}>
            {isFullscreen ? <Minimize2 className="size-4" /> : <Maximize2 className="size-4" />}
          </Button>
          <Badge variant={debugMode ? 'default' : 'outline'}>
            <Bug className="size-3 mr-1" />
            Debug {debugMode ? 'ON' : 'OFF'}
          </Badge>
        </div>
      </div>

      {/* Main Content */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="editor">
            <Code className="size-4 mr-2" />
            Editor
          </TabsTrigger>
          <TabsTrigger value="templates">
            <FileCode className="size-4 mr-2" />
            Templates
          </TabsTrigger>
          <TabsTrigger value="snippets">
            <Library className="size-4 mr-2" />
            Snippets
          </TabsTrigger>
          <TabsTrigger value="resource">
            <Package className="size-4 mr-2" />
            Resource Builder
          </TabsTrigger>
          <TabsTrigger value="scripts">
            <FolderOpen className="size-4 mr-2" />
            Scripts ({scripts.length})
          </TabsTrigger>
          <TabsTrigger value="console">
            <Terminal className="size-4 mr-2" />
            Console
          </TabsTrigger>
        </TabsList>

        {/* Script Editor Tab */}
        <TabsContent value="editor" className="space-y-4">
          <div className="grid grid-cols-12 gap-4">
            {/* Editor Sidebar */}
            <Card className="col-span-3">
              <CardHeader>
                <CardTitle className="text-base">Script Configuration</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label>Script Name</Label>
                  <Input 
                    placeholder="my_awesome_script" 
                    value={scriptName}
                    onChange={(e) => setScriptName(e.target.value)}
                  />
                </div>

                <div className="space-y-2">
                  <Label>Type</Label>
                  <Select value={scriptType} onValueChange={(value: any) => setScriptType(value)}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="client">Client (runs on player)</SelectItem>
                      <SelectItem value="server">Server (runs on server)</SelectItem>
                      <SelectItem value="shared">Shared (both sides)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Language</Label>
                  <Select value={scriptLanguage} onValueChange={(value: any) => setScriptLanguage(value)}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="lua">Lua</SelectItem>
                      <SelectItem value="javascript">JavaScript</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Category</Label>
                  <Select value={scriptCategory} onValueChange={setScriptCategory}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="general">General</SelectItem>
                      <SelectItem value="vehicles">Vehicles</SelectItem>
                      <SelectItem value="player">Player</SelectItem>
                      <SelectItem value="economy">Economy</SelectItem>
                      <SelectItem value="jobs">Jobs</SelectItem>
                      <SelectItem value="housing">Housing</SelectItem>
                      <SelectItem value="inventory">Inventory</SelectItem>
                      <SelectItem value="ui">UI/NUI</SelectItem>
                      <SelectItem value="database">Database</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <Separator />

                <div className="space-y-2">
                  <Button className="w-full" variant="outline" onClick={handleNewScript}>
                    <Plus className="size-4 mr-2" />
                    New Script
                  </Button>
                  <Button className="w-full" variant="outline" onClick={() => setShowSnippets(!showSnippets)}>
                    <Sparkles className="size-4 mr-2" />
                    {showSnippets ? 'Hide' : 'Show'} Snippets
                  </Button>
                </div>

                <Separator />

                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <Label className="text-sm">Auto-Save</Label>
                    <Switch checked={autoSave} onCheckedChange={setAutoSave} />
                  </div>

                  <div className="flex items-center justify-between">
                    <Label className="text-sm">Live Reload</Label>
                    <Switch checked={liveReload} onCheckedChange={setLiveReload} />
                  </div>

                  <div className="flex items-center justify-between">
                    <Label className="text-sm">Debug Mode</Label>
                    <Switch checked={debugMode} onCheckedChange={setDebugMode} />
                  </div>
                </div>

                <Separator />

                <div className="p-3 bg-muted rounded-lg space-y-1">
                  <p className="text-xs font-medium">Quick Info</p>
                  <div className="text-xs text-muted-foreground space-y-0.5">
                    <div>Lines: {editorContent.split('\n').length}</div>
                    <div>Chars: {editorContent.length}</div>
                    <div>Words: {editorContent.split(/\s+/).filter(Boolean).length}</div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Code Editor */}
            <Card className={showSnippets ? "col-span-6" : "col-span-9"}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>Code Editor</CardTitle>
                  <div className="flex gap-2">
                    <Badge variant="outline" className="capitalize">{scriptType}</Badge>
                    <Badge variant="outline" className="uppercase">{scriptLanguage}</Badge>
                    <Badge variant="secondary" className="capitalize">{scriptCategory}</Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <Textarea
                  value={editorContent}
                  onChange={(e) => setEditorContent(e.target.value)}
                  className="font-mono text-sm min-h-[500px] bg-muted/50 resize-none"
                  placeholder="-- Write your FiveM script here...
-- Use Ctrl+S to save
-- Tab to indent

-- Example:
RegisterCommand('hello', function(source, args)
    print('Hello from script editor!')
end)"
                  spellCheck={false}
                />

                <div className="flex flex-wrap gap-2">
                  <Button onClick={handleSaveScript} disabled={isLoading}>
                    {isLoading && <Loader2 className="size-4 mr-2 animate-spin" />}
                    <Save className="size-4 mr-2" />
                    Save Script
                  </Button>
                  <Button onClick={handleExecuteScript} disabled={isLoading}>
                    <Play className="size-4 mr-2" />
                    Execute
                  </Button>
                  <Button variant="outline" onClick={() => navigator.clipboard.writeText(editorContent)}>
                    <Copy className="size-4 mr-2" />
                    Copy
                  </Button>
                  <Button variant="outline" onClick={handleExportScript}>
                    <Download className="size-4 mr-2" />
                    Export
                  </Button>
                  <Button variant="outline" onClick={handleAddResourceFile}>
                    <FilePlus className="size-4 mr-2" />
                    Add to Resource
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Code Snippets Sidebar */}
            {showSnippets && (
              <Card className="col-span-3">
                <CardHeader>
                  <CardTitle className="text-base">Code Snippets</CardTitle>
                  <Input
                    placeholder="Search snippets..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="mt-2"
                  />
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-[500px]">
                    <div className="space-y-2">
                      {filteredSnippets.map((snippet) => (
                        <div
                          key={snippet.id}
                          className="p-3 border rounded-lg hover:bg-muted/50 cursor-pointer transition-colors"
                          onClick={() => handleInsertSnippet(snippet)}
                        >
                          <div className="flex items-start gap-2">
                            <Code className="size-4 text-primary shrink-0 mt-0.5" />
                            <div className="flex-1 min-w-0">
                              <p className="font-medium text-sm truncate">{snippet.title}</p>
                              <p className="text-xs text-muted-foreground line-clamp-2">{snippet.description}</p>
                              <Badge variant="outline" className="mt-1 text-xs">{snippet.category}</Badge>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>

        {/* Templates Tab */}
        <TabsContent value="templates" className="space-y-4">
          <div className="grid grid-cols-3 gap-4">
            {/* Basic Templates */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Basic Templates</CardTitle>
                <CardDescription>Simple starting templates</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button 
                  variant="outline" 
                  className="w-full justify-start" 
                  onClick={() => handleLoadTemplate('basic')}
                >
                  <FileCode className="size-4 mr-2" />
                  Basic {scriptType.charAt(0).toUpperCase() + scriptType.slice(1)} Script
                </Button>
              </CardContent>
            </Card>

            {/* Client Templates */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Client Scripts</CardTitle>
                <CardDescription>Client-side templates</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button 
                  variant="outline" 
                  className="w-full justify-start text-left" 
                  onClick={() => {
                    setScriptType('client');
                    handleLoadTemplate('vehicle_system');
                  }}
                >
                  <FileCode className="size-4 mr-2 shrink-0" />
                  <span className="truncate">Vehicle System</span>
                </Button>
                <Button 
                  variant="outline" 
                  className="w-full justify-start text-left" 
                  onClick={() => {
                    setScriptType('client');
                    handleLoadTemplate('player_manager');
                  }}
                >
                  <FileCode className="size-4 mr-2 shrink-0" />
                  <span className="truncate">Player Manager</span>
                </Button>
                <Button 
                  variant="outline" 
                  className="w-full justify-start text-left" 
                  onClick={() => {
                    setScriptType('client');
                    handleLoadTemplate('ui_system');
                  }}
                >
                  <FileCode className="size-4 mr-2 shrink-0" />
                  <span className="truncate">UI/NUI System</span>
                </Button>
              </CardContent>
            </Card>

            {/* Server Templates */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Server Scripts</CardTitle>
                <CardDescription>Server-side templates</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button 
                  variant="outline" 
                  className="w-full justify-start text-left" 
                  onClick={() => {
                    setScriptType('server');
                    handleLoadTemplate('economy_system');
                  }}
                >
                  <FileCode className="size-4 mr-2 shrink-0" />
                  <span className="truncate">Economy System</span>
                </Button>
                <Button 
                  variant="outline" 
                  className="w-full justify-start text-left" 
                  onClick={() => {
                    setScriptType('server');
                    handleLoadTemplate('database_manager');
                  }}
                >
                  <FileCode className="size-4 mr-2 shrink-0" />
                  <span className="truncate">Database Manager</span>
                </Button>
                <Button 
                  variant="outline" 
                  className="w-full justify-start text-left" 
                  onClick={() => {
                    setScriptType('server');
                    handleLoadTemplate('job_system');
                  }}
                >
                  <FileCode className="size-4 mr-2 shrink-0" />
                  <span className="truncate">Job System</span>
                </Button>
              </CardContent>
            </Card>

            {/* Shared Templates */}
            <Card className="col-span-3">
              <CardHeader>
                <CardTitle className="text-base">Shared/Config Templates</CardTitle>
                <CardDescription>Configuration and shared scripts</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="grid grid-cols-3 gap-2">
                  <Button 
                    variant="outline" 
                    onClick={() => {
                      setScriptType('shared');
                      handleLoadTemplate('basic');
                    }}
                  >
                    <FileCode className="size-4 mr-2" />
                    Basic Config
                  </Button>
                  <Button 
                    variant="outline" 
                    onClick={() => {
                      setScriptType('shared');
                      handleLoadTemplate('framework_config');
                    }}
                  >
                    <FileCode className="size-4 mr-2" />
                    Framework Config
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Template Preview */}
            <Card className="col-span-3">
              <CardHeader>
                <CardTitle className="text-base">Template Preview</CardTitle>
                <CardDescription>Click a template to load it into the editor</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="p-4 bg-muted rounded-lg">
                  <p className="text-sm text-muted-foreground">
                    Templates are pre-built scripts with common patterns and best practices.
                    Select a template above to load it into the editor and customize it for your needs.
                  </p>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Code Snippets Tab */}
        <TabsContent value="snippets" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Code Snippets Library</CardTitle>
                  <CardDescription>Ready-to-use code snippets for common tasks</CardDescription>
                </div>
                <Input
                  placeholder="Search snippets..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-64"
                />
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4">
                {filteredSnippets.map((snippet) => (
                  <Card key={snippet.id} className="hover:bg-muted/50 transition-colors">
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <CardTitle className="text-base">{snippet.title}</CardTitle>
                          <CardDescription className="text-xs mt-1">{snippet.description}</CardDescription>
                        </div>
                        <Badge variant="outline" className="capitalize">{snippet.category}</Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <pre className="p-3 bg-black/90 rounded text-xs font-mono overflow-auto max-h-32">
                        <code className="text-green-400">{snippet.code}</code>
                      </pre>
                      <div className="flex gap-2">
                        <Button 
                          size="sm" 
                          className="flex-1"
                          onClick={() => handleInsertSnippet(snippet)}
                        >
                          <Plus className="size-3 mr-1" />
                          Insert
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline"
                          onClick={() => navigator.clipboard.writeText(snippet.code)}
                        >
                          <Copy className="size-3 mr-1" />
                          Copy
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Resource Builder Tab */}
        <TabsContent value="resource" className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            {/* Resource Configuration */}
            <Card>
              <CardHeader>
                <CardTitle>Resource Configuration</CardTitle>
                <CardDescription>Configure your FiveM resource</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label>Resource Name</Label>
                  <Input 
                    placeholder="my_awesome_resource" 
                    value={resourceName}
                    onChange={(e) => setResourceName(e.target.value)}
                  />
                </div>

                <div className="space-y-2">
                  <Label>Description</Label>
                  <Textarea 
                    placeholder="What does this resource do?" 
                    value={resourceDescription}
                    onChange={(e) => setResourceDescription(e.target.value)}
                    rows={3}
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Author</Label>
                    <Input 
                      placeholder="Your name" 
                      value={resourceAuthor}
                      onChange={(e) => setResourceAuthor(e.target.value)}
                    />
                  </div>

                  <div className="space-y-2">
                    <Label>Version</Label>
                    <Input 
                      placeholder="1.0.0" 
                      value={resourceVersion}
                      onChange={(e) => setResourceVersion(e.target.value)}
                    />
                  </div>
                </div>

                <Separator />

                <Button 
                  className="w-full" 
                  onClick={handleGenerateResource}
                  disabled={!resourceName.trim() || resourceFiles.length === 0}
                >
                  <Package className="size-4 mr-2" />
                  Generate Resource Package
                </Button>
              </CardContent>
            </Card>

            {/* Resource Files */}
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>Resource Files</CardTitle>
                  <Badge>{resourceFiles.length} files</Badge>
                </div>
              </CardHeader>
              <CardContent>
                <ScrollArea className="h-[400px]">
                  <div className="space-y-2">
                    {resourceFiles.length === 0 ? (
                      <div className="text-center py-8 text-muted-foreground">
                        <FileCode className="size-8 mx-auto mb-2 opacity-50" />
                        <p className="text-sm">No files added yet</p>
                        <p className="text-xs">Add files from the editor tab</p>
                      </div>
                    ) : (
                      resourceFiles.map((file, index) => (
                        <div key={index} className="p-3 border rounded-lg">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              <File className="size-4 text-blue-500" />
                              <div>
                                <p className="font-medium text-sm">{file.name}</p>
                                <p className="text-xs text-muted-foreground capitalize">{file.type} script</p>
                              </div>
                            </div>
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => setResourceFiles(prev => prev.filter((_, i) => i !== index))}
                            >
                              <Trash2 className="size-4" />
                            </Button>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>

            {/* fxmanifest Preview */}
            <Card className="col-span-2">
              <CardHeader>
                <CardTitle>fxmanifest.lua Preview</CardTitle>
                <CardDescription>This will be generated for your resource</CardDescription>
              </CardHeader>
              <CardContent>
                <pre className="p-4 bg-black/90 rounded text-sm font-mono overflow-auto max-h-64">
                  <code className="text-green-400">
{`fx_version 'cerulean'
game 'gta5'

author '${resourceAuthor}'
description '${resourceDescription}'
version '${resourceVersion}'

${resourceFiles.filter(f => f.type === 'client').length > 0 ? `client_scripts {
${resourceFiles.filter(f => f.type === 'client').map(f => `    '${f.name}',`).join('\n')}
}

` : ''}${resourceFiles.filter(f => f.type === 'server').length > 0 ? `server_scripts {
${resourceFiles.filter(f => f.type === 'server').map(f => `    '${f.name}',`).join('\n')}
}

` : ''}${resourceFiles.filter(f => f.type === 'shared').length > 0 ? `shared_scripts {
${resourceFiles.filter(f => f.type === 'shared').map(f => `    '${f.name}',`).join('\n')}
}` : ''}`}
                  </code>
                </pre>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Saved Scripts Tab */}
        <TabsContent value="scripts" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Saved Scripts</CardTitle>
                <Button onClick={handleNewScript}>
                  <Plus className="size-4 mr-2" />
                  New Script
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid gap-3">
                {scripts.map((script) => (
                  <div key={script.id} className="p-4 border rounded-lg hover:bg-muted/50 transition-colors">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <FileCode className="size-4 text-blue-500" />
                          <p className="font-medium">{script.name}</p>
                          <Badge variant="outline" className="capitalize">{script.type}</Badge>
                          <Badge variant="secondary" className="uppercase">{script.language}</Badge>
                          {script.category && (
                            <Badge variant="outline" className="capitalize">{script.category}</Badge>
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground">
                          Modified: {new Date(script.lastModified).toLocaleString()}
                        </p>
                        <p className="text-xs text-muted-foreground mt-1">
                          {script.content.split('\n').length} lines • By {script.author}
                        </p>
                      </div>
                      <div className="flex gap-2">
                        <Button size="sm" onClick={() => {
                          handleLoadScript(script);
                          setActiveTab('editor');
                        }}>
                          <Eye className="size-4 mr-1" />
                          Load
                        </Button>
                        <Button size="sm" variant="ghost" onClick={() => handleDeleteScript(script.id)}>
                          <Trash2 className="size-4" />
                        </Button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Console Tab */}
        <TabsContent value="console" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Console Output</CardTitle>
                <div className="flex gap-2">
                  <Select value={consoleFilter} onValueChange={(value: any) => setConsoleFilter(value)}>
                    <SelectTrigger className="w-32">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All ({consoleLogs.length})</SelectItem>
                      <SelectItem value="info">Info</SelectItem>
                      <SelectItem value="warn">Warnings</SelectItem>
                      <SelectItem value="error">Errors</SelectItem>
                      <SelectItem value="success">Success</SelectItem>
                    </SelectContent>
                  </Select>
                  <Button size="sm" variant="outline" onClick={() => setConsoleLogs([])}>
                    <Trash2 className="size-4 mr-1" />
                    Clear
                  </Button>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-96 w-full bg-black/90 p-4 rounded-lg">
                <div className="space-y-2 font-mono text-sm">
                  {filteredLogs.length === 0 ? (
                    <div className="text-center py-8 text-gray-500">
                      <Terminal className="size-8 mx-auto mb-2 opacity-50" />
                      <p className="text-sm">No console logs</p>
                    </div>
                  ) : (
                    filteredLogs.map((log, index) => (
                      <div key={index} className="flex items-start gap-2">
                        <span className="text-gray-500 text-xs shrink-0 w-20">
                          {new Date(log.timestamp).toLocaleTimeString()}
                        </span>
                        {getConsoleTypeBadge(log.type)}
                        <span className="flex-1 text-green-400 break-all">{log.message}</span>
                        {log.source && (
                          <span className="text-gray-600 text-xs shrink-0">({log.source})</span>
                        )}
                      </div>
                    ))
                  )}
                </div>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
