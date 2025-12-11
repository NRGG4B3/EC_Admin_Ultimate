--[[
    EC Admin Ultimate - Community UI Backend
    Server-side logic for community management
    
    Handles:
    - community:getData: Get all community data (groups, events, achievements, leaderboards, announcements)
    - community:createGroup: Create a group
    - community:createEvent: Create an event
    - community:createAchievement: Create an achievement
    - community:createAnnouncement: Create an announcement
    - deleteItem: Delete items (groups, events, achievements, announcements)
    - community:updateEventStatus: Update event status
    - community:grantAchievement: Grant achievement to player
    
    Framework Support: QB-Core, QBX, ESX
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Community] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Community] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
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

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Get player name from identifier
local function getPlayerNameByIdentifier(identifier)
    -- Try online first
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local ids = GetPlayerIdentifiers(source)
            if ids then
                for _, id in ipairs(ids) do
                    if id == identifier then
                        return GetPlayerName(source) or 'Unknown'
                    end
                end
            end
        end
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

-- Helper: Log community action
local function logCommunityAction(adminId, adminName, actionType, targetType, targetId, targetName, details)
    MySQL.insert.await([[
        INSERT INTO ec_community_actions_log 
        (admin_id, admin_name, action_type, target_type, target_id, target_name, details, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        adminId, adminName, actionType, targetType, targetId, targetName,
        details and json.encode(details) or nil, getCurrentTimestamp()
    })
end

-- Helper: Get all groups
local function getAllGroups()
    local groups = {}
    local result = MySQL.query.await([[
        SELECT g.*, COUNT(gm.id) as actual_members
        FROM ec_community_groups g
        LEFT JOIN ec_community_group_members gm ON g.id = gm.group_id
        GROUP BY g.id
        ORDER BY g.created_at DESC
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(groups, {
                id = row.id,
                name = row.name,
                description = row.description or '',
                group_type = row.group_type or 'custom',
                leader_id = row.leader_id,
                leader_name = row.leader_name,
                member_count = tonumber(row.member_count) or 0,
                max_members = tonumber(row.max_members) or 50,
                is_public = (row.is_public == 1 or row.is_public == true),
                color = row.color or '#3b82f6',
                actual_members = tonumber(row.actual_members) or 0,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return groups
end

-- Helper: Get all events
local function getAllEvents()
    local events = {}
    local result = MySQL.query.await([[
        SELECT e.*, COUNT(ep.id) as actual_participants
        FROM ec_community_events e
        LEFT JOIN ec_community_event_participants ep ON e.id = ep.event_id
        GROUP BY e.id
        ORDER BY e.start_time DESC
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(events, {
                id = row.id,
                title = row.title,
                description = row.description or '',
                event_type = row.event_type or 'custom',
                organizer_id = row.organizer_id,
                organizer_name = row.organizer_name,
                start_time = os.date('%Y-%m-%dT%H:%M:%SZ', row.start_time),
                duration = tonumber(row.duration) or 60,
                location = row.location or '',
                max_participants = tonumber(row.max_participants) or 50,
                participant_count = tonumber(row.participant_count) or 0,
                prize_pool = tonumber(row.prize_pool) or 0,
                status = row.status or 'scheduled',
                actual_participants = tonumber(row.actual_participants) or 0,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return events
end

-- Helper: Get all achievements
local function getAllAchievements()
    local achievements = {}
    local result = MySQL.query.await([[
        SELECT a.*, COUNT(pa.id) as unlocked_count
        FROM ec_community_achievements a
        LEFT JOIN ec_community_player_achievements pa ON a.id = pa.achievement_id
        GROUP BY a.id
        ORDER BY a.created_at DESC
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(achievements, {
                id = row.id,
                name = row.name,
                description = row.description or '',
                category = row.category or 'general',
                icon = row.icon or 'trophy',
                points = tonumber(row.points) or 10,
                requirement_type = row.requirement_type or 'manual',
                requirement_value = tonumber(row.requirement_value) or 1,
                is_secret = (row.is_secret == 1 or row.is_secret == true),
                unlocked_count = tonumber(row.unlocked_count) or 0,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return achievements
end

-- Helper: Get leaderboards
local function getLeaderboards()
    local leaderboards = {
        playtime = {},
        money = {},
        achievements = {},
        reputation = {}
    }
    
    local framework = getFramework()
    
    if framework == 'qb' or framework == 'qbx' then
        -- Playtime leaderboard
        local success1, playtimeResult = pcall(function()
            return MySQL.query.await([[
                SELECT citizenid, charinfo, playtime
                FROM players
                ORDER BY playtime DESC
                LIMIT 10
            ]], {})
        end)
        
        if success1 and playtimeResult then
            for i, row in ipairs(playtimeResult) do
                local charinfo = json.decode(row.charinfo or '{}')
                table.insert(leaderboards.playtime, {
                    player_id = row.citizenid,
                    player_name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
                    total_playtime = tonumber(row.playtime) or 0,
                    rank_position = i
                })
            end
        end
        
        -- Money leaderboard
        local success2, moneyResult = pcall(function()
            return MySQL.query.await([[
                SELECT citizenid, charinfo, money
                FROM players
                ORDER BY JSON_EXTRACT(money, '$.cash') + JSON_EXTRACT(money, '$.bank') DESC
                LIMIT 10
            ]], {})
        end)
        
        if success2 and moneyResult then
            for i, row in ipairs(moneyResult) do
                local charinfo = json.decode(row.charinfo or '{}')
                local money = json.decode(row.money or '{}')
                local totalMoney = (tonumber(money.cash) or 0) + (tonumber(money.bank) or 0)
                table.insert(leaderboards.money, {
                    player_id = row.citizenid,
                    player_name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
                    total_money = totalMoney,
                    rank_position = i
                })
            end
        end
    elseif framework == 'esx' then
        -- Playtime leaderboard (if playtime column exists)
        local playtimeResult = MySQL.query.await([[
            SELECT identifier, firstname, lastname
            FROM users
            ORDER BY playtime DESC
            LIMIT 10
        ]], {})
        
        if playtimeResult then
            for i, row in ipairs(playtimeResult) do
                table.insert(leaderboards.playtime, {
                    player_id = row.identifier,
                    player_name = (row.firstname or '') .. ' ' .. (row.lastname or ''),
                    total_playtime = tonumber(row.playtime) or 0,
                    rank_position = i
                })
            end
        end
        
        -- Money leaderboard
        local moneyResult = MySQL.query.await([[
            SELECT identifier, firstname, lastname, accounts
            FROM users
            ORDER BY JSON_EXTRACT(accounts, '$.bank') DESC
            LIMIT 10
        ]], {})
        
        if moneyResult then
            for i, row in ipairs(moneyResult) do
                local accounts = json.decode(row.accounts or '{}')
                table.insert(leaderboards.money, {
                    player_id = row.identifier,
                    player_name = (row.firstname or '') .. ' ' .. (row.lastname or ''),
                    total_money = tonumber(accounts.bank) or 0,
                    rank_position = i
                })
            end
        end
    end
    
    -- Achievements leaderboard
    local achievementResult = MySQL.query.await([[
        SELECT pa.player_id, COUNT(pa.id) as achievement_count, SUM(a.points) as total_points
        FROM ec_community_player_achievements pa
        JOIN ec_community_achievements a ON pa.achievement_id = a.id
        GROUP BY pa.player_id
        ORDER BY total_points DESC
        LIMIT 10
    ]], {})
    
    if achievementResult then
        for i, row in ipairs(achievementResult) do
            local playerName = getPlayerNameByIdentifier(row.player_id)
            table.insert(leaderboards.achievements, {
                player_id = row.player_id,
                player_name = playerName,
                achievement_points = tonumber(row.total_points) or 0,
                rank_position = i
            })
        end
    end
    
    return leaderboards
end

-- Helper: Get all announcements
local function getAllAnnouncements()
    local announcements = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_community_announcements
        ORDER BY is_pinned DESC, created_at DESC
        LIMIT 100
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(announcements, {
                id = row.id,
                title = row.title,
                message = row.message,
                announcement_type = row.announcement_type or 'info',
                posted_by = row.posted_by,
                priority = tonumber(row.priority) or 1,
                is_pinned = (row.is_pinned == 1 or row.is_pinned == true),
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return announcements
end

-- Helper: Get community data (shared logic)
local function getCommunityData()
    -- Check cache
    if dataCache.data and (getCurrentTimestamp() - dataCache.timestamp) < CACHE_TTL then
        return dataCache.data
    end
    
    local groups = getAllGroups()
    local events = getAllEvents()
    local achievements = getAllAchievements()
    local leaderboards = getLeaderboards()
    local announcements = getAllAnnouncements()
    
    -- Calculate statistics
    local stats = {
        totalGroups = #groups,
        totalMembers = 0,
        totalEvents = #events,
        upcomingEvents = 0,
        totalAchievements = #achievements,
        totalUnlocks = 0,
        totalPlayers = GetNumPlayerIndices() or 0,
        announcements = #announcements,
        activeGroups = 0
    }
    
    for _, group in ipairs(groups) do
        stats.totalMembers = stats.totalMembers + group.actual_members
        if group.actual_members > 0 then
            stats.activeGroups = stats.activeGroups + 1
        end
    end
    
    for _, event in ipairs(events) do
        if event.status == 'scheduled' or event.status == 'active' then
            stats.upcomingEvents = stats.upcomingEvents + 1
        end
    end
    
    for _, achievement in ipairs(achievements) do
        stats.totalUnlocks = stats.totalUnlocks + achievement.unlocked_count
    end
    
    local data = {
        groups = groups,
        events = events,
        achievements = achievements,
        leaderboards = leaderboards,
        announcements = announcements,
        socialFeed = {}, -- Placeholder for social feed
        stats = stats,
        framework = getFramework()
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
-- RegisterNUICallback('community:getData', function(data, cb)
--     local response = getCommunityData()
--     cb({ success = true, data = response })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('community:createGroup', function(data, cb)
--     local name = data.name
--     local description = data.description or ''
--     local groupType = data.groupType or 'custom'
--     local maxMembers = tonumber(data.maxMembers) or 50
--     local isPublic = data.isPublic ~= false
--     local color = data.color or '#3b82f6'
--     
--     if not name then
--         cb({ success = false, message = 'Group name required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Group created successfully'
--     
--     -- Insert group
--     local result = MySQL.insert.await([[
--         INSERT INTO ec_community_groups 
--         (name, description, group_type, leader_id, leader_name, max_members, is_public, color, created_at)
--         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
--     ]], {
--         name, description, groupType, adminInfo.id, adminInfo.name, maxMembers,
--         isPublic and 1 or 0, color, getCurrentTimestamp()
--     })
--     
--     if result then
--         success = true
--         local groupId = result.insertId
--         
--         -- Add leader as member
--         MySQL.insert.await([[
--             INSERT INTO ec_community_group_members 
--             (group_id, player_id, player_name, role, joined_at)
--             VALUES (?, ?, ?, 'leader', ?)
--         ]], {groupId, adminInfo.id, adminInfo.name, getCurrentTimestamp()})
--         
--         -- Log action
--         logCommunityAction(adminInfo.id, adminInfo.name, 'create_group', 'group', groupId, name, {
--             group_type = groupType,
--             max_members = maxMembers,
--             is_public = isPublic
--         })
--     end
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to create group' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('community:createEvent', function(data, cb)
--     local title = data.title
--     local description = data.description or ''
--     local eventType = data.eventType or 'custom'
--     local startTime = data.startTime
--     local duration = tonumber(data.duration) or 60
--     local location = data.location or ''
--     local maxParticipants = tonumber(data.maxParticipants) or 50
--     local prizePool = tonumber(data.prizePool) or 0
--     
--     if not title or not startTime then
--         cb({ success = false, message = 'Title and start time required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Event created successfully'
--     
--     -- Parse start time
--     local startTimestamp = nil
--     if type(startTime) == 'string' then
--         -- Parse ISO date string
--         local year, month, day, hour, min, sec = string.match(startTime, '(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)')
--         if year and month and day and hour and min then
--             startTimestamp = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec) or 0})
--         end
--     else
--         startTimestamp = tonumber(startTime) or getCurrentTimestamp()
--     end
--     
--     -- Insert event
--     local result = MySQL.insert.await([[
--         INSERT INTO ec_community_events 
--         (title, description, event_type, organizer_id, organizer_name, start_time, duration, location, max_participants, prize_pool, status, created_at)
--         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'scheduled', ?)
--     ]], {
--         title, description, eventType, adminInfo.id, adminInfo.name,
--         startTimestamp, duration, location, maxParticipants, prizePool, getCurrentTimestamp()
--     })
--     
--     if result then
--         success = true
--         local eventId = result.insertId
--         
--         -- Log action
--         logCommunityAction(adminInfo.id, adminInfo.name, 'create_event', 'event', eventId, title, {
--             event_type = eventType,
--             start_time = startTimestamp,
--             duration = duration
--         })
--     end
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to create event' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Create achievement
-- RegisterNUICallback('community:createAchievement', function(data, cb)
--     local name = data.name
--     local description = data.description or ''
--     local category = data.category or 'general'
--     local icon = data.icon or 'trophy'
--     local points = tonumber(data.points) or 10
--     local requirementType = data.requirementType or 'manual'
--     local requirementValue = tonumber(data.requirementValue) or 1
--     local isSecret = data.isSecret == true
--     
--     if not name then
--         cb({ success = false, message = 'Achievement name required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Achievement created successfully'
--     
--     -- Insert achievement
--     local result = MySQL.insert.await([[
--         INSERT INTO ec_community_achievements 
--         (name, description, category, icon, points, requirement_type, requirement_value, is_secret, created_at)
--         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
--     ]], {
--         name, description, category, icon, points, requirementType, requirementValue,
--         isSecret and 1 or 0, getCurrentTimestamp()
--     })
--     
--     if result then
--         success = true
--         local achievementId = result.insertId
--         
--         -- Log action
--         logCommunityAction(adminInfo.id, adminInfo.name, 'create_achievement', 'achievement', achievementId, name, {
--             category = category,
--             points = points,
--             requirement_type = requirementType
--         })
--     end
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to create achievement' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Create announcement
-- RegisterNUICallback('community:createAnnouncement', function(data, cb)
--     local title = data.title
--     local message = data.message
--     local announcementType = data.announcementType or 'info'
--     local priority = tonumber(data.priority) or 1
--     local isPinned = data.isPinned == true
--     
--     if not title or not message then
--         cb({ success = false, message = 'Title and message required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message_text = 'Announcement created successfully'
--     
--     -- Insert announcement
--     local result = MySQL.insert.await([[
--         INSERT INTO ec_community_announcements 
--         (title, message, announcement_type, posted_by, posted_by_name, priority, is_pinned, created_at)
--         VALUES (?, ?, ?, ?, ?, ?, ?, ?)
--     ]], {
--         title, message, announcementType, adminInfo.id, adminInfo.name,
--         priority, isPinned and 1 or 0, getCurrentTimestamp()
--     })
--     
--     if result then
--         success = true
--         local announcementId = result.insertId
--         
--         -- Send announcement to all players
--         TriggerClientEvent('chat:addMessage', -1, {
--             color = {255, 255, 0},
--             multiline = true,
--             args = {'[ANNOUNCEMENT]', title .. ': ' .. message}
--         })
--         
--         -- Log action
--         logCommunityAction(adminInfo.id, adminInfo.name, 'create_announcement', 'announcement', announcementId, title, {
--             announcement_type = announcementType,
--             priority = priority,
--             is_pinned = isPinned
--         })
--     end
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message_text or 'Failed to create announcement' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Delete item
-- RegisterNUICallback('deleteItem', function(data, cb)
--     local groupId = data.groupId
--     local eventId = data.eventId
--     local achievementId = data.achievementId
--     local announcementId = data.announcementId
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Item deleted successfully'
--     local targetType = nil
--     local targetId = nil
--     local targetName = nil
--     
--     if groupId then
--         targetType = 'group'
--         targetId = groupId
--         local result = MySQL.query.await('SELECT name FROM ec_community_groups WHERE id = ? LIMIT 1', {groupId})
--         if result and result[1] then
--             targetName = result[1].name
--             MySQL.query.await('DELETE FROM ec_community_groups WHERE id = ?', {groupId})
--             success = true
--         end
--     elseif eventId then
--         targetType = 'event'
--         targetId = eventId
--         local result = MySQL.query.await('SELECT title FROM ec_community_events WHERE id = ? LIMIT 1', {eventId})
--         if result and result[1] then
--             targetName = result[1].title
--             MySQL.query.await('DELETE FROM ec_community_events WHERE id = ?', {eventId})
--             success = true
--         end
--     elseif achievementId then
--         targetType = 'achievement'
--         targetId = achievementId
--         local result = MySQL.query.await('SELECT name FROM ec_community_achievements WHERE id = ? LIMIT 1', {achievementId})
--         if result and result[1] then
--             targetName = result[1].name
--             MySQL.query.await('DELETE FROM ec_community_achievements WHERE id = ?', {achievementId})
--             success = true
--         end
--     elseif announcementId then
--         targetType = 'announcement'
--         targetId = announcementId
--         local result = MySQL.query.await('SELECT title FROM ec_community_announcements WHERE id = ? LIMIT 1', {announcementId})
--         if result and result[1] then
--             targetName = result[1].title
--             MySQL.query.await('DELETE FROM ec_community_announcements WHERE id = ?', {announcementId})
--             success = true
--         end
--     else
--         cb({ success = false, message = 'Item ID required' })
--         return
--     end
--     
--     if success then
--         -- Log action
--         logCommunityAction(adminInfo.id, adminInfo.name, 'delete_' .. targetType, targetType, targetId, targetName, nil)
--     end
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to delete item' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Update event status
-- RegisterNUICallback('community:updateEventStatus', function(data, cb)
--     local eventId = tonumber(data.eventId)
--     local status = data.status
--     
--     if not eventId or not status then
--         cb({ success = false, message = 'Event ID and status required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Event status updated successfully'
--     
--     -- Update event status
--     MySQL.update.await([[
--         UPDATE ec_community_events 
--         SET status = ?
--         WHERE id = ?
--     ]], {status, eventId})
--     
--     success = true
--     
--     -- Get event name
--     local result = MySQL.query.await('SELECT title FROM ec_community_events WHERE id = ? LIMIT 1', {eventId})
--     local eventName = result and result[1] and result[1].title or 'Unknown'
--     
--     -- Log action
--     logCommunityAction(adminInfo.id, adminInfo.name, 'update_event_status', 'event', eventId, eventName, {
--         new_status = status
--     })
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to update event status' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Grant achievement
-- RegisterNUICallback('community:grantAchievement', function(data, cb)
--     local playerId = data.playerId
--     local playerName = data.playerName or 'Unknown'
--     local achievementId = tonumber(data.achievementId)
--     
--     if not playerId or not achievementId then
--         cb({ success = false, message = 'Player ID and achievement ID required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Achievement granted successfully'
--     
--     -- Check if already unlocked
--     local checkResult = MySQL.query.await([[
--         SELECT id FROM ec_community_player_achievements 
--         WHERE player_id = ? AND achievement_id = ?
--         LIMIT 1
--     ]], {playerId, achievementId})
--     
--     if checkResult and checkResult[1] then
--         cb({ success = false, message = 'Player already has this achievement' })
--         return
--     end
--     
--     -- Grant achievement
--     MySQL.insert.await([[
--         INSERT INTO ec_community_player_achievements 
--         (player_id, achievement_id, unlocked_at, unlocked_by)
--         VALUES (?, ?, ?, ?)
--     ]], {playerId, achievementId, getCurrentTimestamp(), adminInfo.id})
--     
--     success = true
--     
--     -- Get achievement name
--     local achievementResult = MySQL.query.await('SELECT name FROM ec_community_achievements WHERE id = ? LIMIT 1', {achievementId})
--     local achievementName = achievementResult and achievementResult[1] and achievementResult[1].name or 'Unknown'
--     
--     -- Log action
--     logCommunityAction(adminInfo.id, adminInfo.name, 'grant_achievement', 'achievement', achievementId, achievementName, {
--         player_id = playerId,
--         player_name = playerName
--     })
--     
--     -- Notify player if online
--     for _, playerIdStr in ipairs(GetPlayers()) do
--         local source = tonumber(playerIdStr)
--         if source then
--             local ids = GetPlayerIdentifiers(source)
--             if ids then
--                 for _, id in ipairs(ids) do
--                     if id == playerId then
--                         TriggerClientEvent('chat:addMessage', source, {
--                             color = {255, 215, 0},
--                             multiline = true,
--                             args = {'[ACHIEVEMENT]', 'You unlocked: ' .. achievementName}
--                         })
--                         break
--                     end
--                 end
--             end
--         end
--     end
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to grant achievement' })
-- end)

print("^2[Community]^7 UI Backend loaded^0")

