--[[
    EC Admin Ultimate - Community Management Callbacks
    Complete community system: groups, events, leaderboards, achievements, social features
]]

local QBCore = nil
local ESX = nil
local Framework = 'unknown'

-- Initialize framework
CreateThread(function()
    Wait(1000)
    
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core -- QBX uses direct export
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    else
        Framework = 'standalone'
    end
    
    Logger.Info('Community Management Initialized: ' .. Framework)
end)

-- Create community tables
CreateThread(function()
    Wait(2000)
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_groups (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            description TEXT NULL,
            group_type ENUM('crew', 'clan', 'organization', 'faction', 'custom') DEFAULT 'custom',
            leader_id VARCHAR(50) NOT NULL,
            leader_name VARCHAR(100) NOT NULL,
            member_count INT DEFAULT 0,
            max_members INT DEFAULT 50,
            is_public BOOLEAN DEFAULT 1,
            discord_webhook VARCHAR(255) NULL,
            color VARCHAR(7) DEFAULT '#3b82f6',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_leader (leader_id),
            INDEX idx_type (group_type)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_members (
            id INT AUTO_INCREMENT PRIMARY KEY,
            group_id INT NOT NULL,
            player_id VARCHAR(50) NOT NULL,
            player_name VARCHAR(100) NOT NULL,
            role ENUM('leader', 'officer', 'member') DEFAULT 'member',
            joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (group_id) REFERENCES ec_community_groups(id) ON DELETE CASCADE,
            UNIQUE KEY unique_member (group_id, player_id),
            INDEX idx_player (player_id)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_events (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(200) NOT NULL,
            description TEXT NULL,
            event_type ENUM('race', 'tournament', 'meetup', 'heist', 'custom') DEFAULT 'custom',
            organizer_id VARCHAR(50) NOT NULL,
            organizer_name VARCHAR(100) NOT NULL,
            start_time TIMESTAMP NOT NULL,
            duration INT DEFAULT 60,
            location VARCHAR(255) NULL,
            max_participants INT DEFAULT 50,
            participant_count INT DEFAULT 0,
            prize_pool INT DEFAULT 0,
            status ENUM('scheduled', 'ongoing', 'completed', 'cancelled') DEFAULT 'scheduled',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_organizer (organizer_id),
            INDEX idx_status (status),
            INDEX idx_start (start_time)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_event_participants (
            id INT AUTO_INCREMENT PRIMARY KEY,
            event_id INT NOT NULL,
            player_id VARCHAR(50) NOT NULL,
            player_name VARCHAR(100) NOT NULL,
            registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (event_id) REFERENCES ec_community_events(id) ON DELETE CASCADE,
            UNIQUE KEY unique_participant (event_id, player_id)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_achievements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            description TEXT NULL,
            category VARCHAR(50) DEFAULT 'general',
            icon VARCHAR(50) DEFAULT 'trophy',
            points INT DEFAULT 10,
            requirement_type VARCHAR(50) NOT NULL,
            requirement_value INT DEFAULT 1,
            is_secret BOOLEAN DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_category (category)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_player_achievements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_id VARCHAR(50) NOT NULL,
            player_name VARCHAR(100) NOT NULL,
            achievement_id INT NOT NULL,
            unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (achievement_id) REFERENCES ec_community_achievements(id) ON DELETE CASCADE,
            UNIQUE KEY unique_unlock (player_id, achievement_id),
            INDEX idx_player (player_id)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_leaderboards (
            player_id VARCHAR(50) PRIMARY KEY,
            player_name VARCHAR(100) NOT NULL,
            total_playtime INT DEFAULT 0,
            total_money INT DEFAULT 0,
            total_arrests INT DEFAULT 0,
            total_deaths INT DEFAULT 0,
            total_kills INT DEFAULT 0,
            achievement_points INT DEFAULT 0,
            reputation_score INT DEFAULT 0,
            rank_position INT DEFAULT 0,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_playtime (total_playtime),
            INDEX idx_money (total_money),
            INDEX idx_achievements (achievement_points),
            INDEX idx_rank (rank_position)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_announcements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(200) NOT NULL,
            message TEXT NOT NULL,
            announcement_type ENUM('info', 'warning', 'success', 'event', 'update') DEFAULT 'info',
            posted_by VARCHAR(100) NOT NULL,
            priority INT DEFAULT 1,
            is_pinned BOOLEAN DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_priority (priority),
            INDEX idx_pinned (is_pinned),
            INDEX idx_created (created_at)
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_community_social (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_id VARCHAR(50) NOT NULL,
            player_name VARCHAR(100) NOT NULL,
            action_type ENUM('status', 'achievement', 'event', 'group') NOT NULL,
            message TEXT NOT NULL,
            metadata TEXT NULL,
            likes INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_player (player_id),
            INDEX idx_created (created_at)
        )
    ]], {})
    
    Logger.Info('Community tables initialized')
end)

-- Helper: Get player identifier
local function GetPlayerIdentifier(src)
    if Framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'qb-core' then
        local Player = QBCore.Functions.GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier or nil
    else
        return GetPlayerIdentifiers(src)[1] or nil
    end
end

-- Get all community data
RegisterNetEvent('ec_admin_ultimate:server:getCommunityData', function()
    local src = source
    
    -- Get groups
    local groups = MySQL.Sync.fetchAll([[
        SELECT g.*, COUNT(m.id) as actual_members
        FROM ec_community_groups g
        LEFT JOIN ec_community_members m ON g.id = m.group_id
        GROUP BY g.id
        ORDER BY g.created_at DESC
    ]], {})
    
    -- Get events
    local events = MySQL.Sync.fetchAll([[
        SELECT e.*, COUNT(p.id) as actual_participants
        FROM ec_community_events e
        LEFT JOIN ec_community_event_participants p ON e.id = p.event_id
        GROUP BY e.id
        ORDER BY e.start_time DESC
    ]], {})
    
    local function buildCommunityData()
        -- Build community payload (groups, events, achievements, announcements)
        local groups = {}
        local events = {}
        local achievements = {}
        local announcements = {}

        if MySQL then
            groups = MySQL.Sync.fetchAll('SELECT * FROM ec_community_groups ORDER BY created_at DESC', {}) or {}
            events = MySQL.Sync.fetchAll('SELECT * FROM ec_community_events ORDER BY date DESC', {}) or {}
            achievements = MySQL.Sync.fetchAll('SELECT * FROM ec_community_achievements ORDER BY created_at DESC', {}) or {}
            announcements = MySQL.Sync.fetchAll('SELECT * FROM ec_announcements ORDER BY created_at DESC', {}) or {}
        end

        return {
            success = true,
            data = {
                groups = groups,
                events = events,
                achievements = achievements,
                announcements = announcements
            }
        }
    end

    lib.callback.register('ec_admin:getCommunityData', function(source, _)
        return buildCommunityData()
    end)

    RegisterNetEvent('ec_admin_ultimate:server:getCommunityData', function()
        local src = source
        local payload = buildCommunityData()
        TriggerClientEvent('ec_admin_ultimate:client:receiveCommunityData', src, payload)
    end)
    
    -- Get leaderboards
    local leaderboards = {
        playtime = MySQL.Sync.fetchAll('SELECT * FROM ec_community_leaderboards ORDER BY total_playtime DESC LIMIT 50', {}),
        money = MySQL.Sync.fetchAll('SELECT * FROM ec_community_leaderboards ORDER BY total_money DESC LIMIT 50', {}),
        achievements = MySQL.Sync.fetchAll('SELECT * FROM ec_community_leaderboards ORDER BY achievement_points DESC LIMIT 50', {}),
        reputation = MySQL.Sync.fetchAll('SELECT * FROM ec_community_leaderboards ORDER BY reputation_score DESC LIMIT 50', {})
    }
    
    -- Get announcements
    local announcements = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_community_announcements 
        ORDER BY is_pinned DESC, priority DESC, created_at DESC 
        LIMIT 50
    ]], {})
    
    -- Get social feed
    local socialFeed = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_community_social 
        ORDER BY created_at DESC 
        LIMIT 100
    ]], {})
    
    -- Calculate stats
    local stats = {
        totalGroups = #groups,
        totalMembers = 0,
        totalEvents = #events,
        upcomingEvents = 0,
        totalAchievements = #achievements,
        totalUnlocks = 0,
        totalPlayers = 0,
        announcements = #announcements,
        activeGroups = 0
    }
    
    for _, group in ipairs(groups) do
        stats.totalMembers = stats.totalMembers + (group.actual_members or 0)
        if (group.actual_members or 0) > 0 then
            stats.activeGroups = stats.activeGroups + 1
        end
    end
    
    for _, event in ipairs(events) do
        if event.status == 'scheduled' then
            stats.upcomingEvents = stats.upcomingEvents + 1
        end
    end
    
    for _, achievement in ipairs(achievements) do
        stats.totalUnlocks = stats.totalUnlocks + (achievement.unlocked_count or 0)
    end
    
    local playerCount = MySQL.Sync.fetchScalar('SELECT COUNT(DISTINCT player_id) FROM ec_community_leaderboards', {})
    stats.totalPlayers = playerCount or 0
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveCommunityData', src, {
        success = true,
        data = {
            groups = groups,
            events = events,
            achievements = achievements,
            leaderboards = leaderboards,
            announcements = announcements,
            socialFeed = socialFeed,
            stats = stats,
            framework = Framework
        }
    })
end)

-- Create group
RegisterNetEvent('ec_admin_ultimate:server:createGroup', function(data)
    local src = source
    local name = data.name
    local description = data.description or ''
    local groupType = data.groupType or 'custom'
    local maxMembers = tonumber(data.maxMembers) or 50
    local isPublic = data.isPublic == true
    local color = data.color or '#3b82f6'
    
    if not name then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Group name is required'
        })
        return
    end
    
    local playerId = GetPlayerIdentifier(src)
    local playerName = GetPlayerName(src)
    
    -- Create group
    MySQL.Async.execute([[
        INSERT INTO ec_community_groups (name, description, group_type, leader_id, leader_name, max_members, is_public, color)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {name, description, groupType, playerId, playerName, maxMembers, isPublic, color}, function(insertId)
        -- Add creator as member
        MySQL.Async.execute([[
            INSERT INTO ec_community_members (group_id, player_id, player_name, role)
            VALUES (?, ?, ?, 'leader')
        ]], {insertId, playerId, playerName})
        
        MySQL.Async.execute('UPDATE ec_community_groups SET member_count = 1 WHERE id = ?', {insertId})
        
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = true,
            message = 'Group created successfully'
        })
    end)
end)

-- Delete group
RegisterNetEvent('ec_admin_ultimate:server:deleteGroup', function(data)
    local src = source
    local groupId = tonumber(data.groupId)
    
    if not groupId then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Invalid group ID'
        })
        return
    end
    
    MySQL.Async.execute('DELETE FROM ec_community_groups WHERE id = ?', {groupId})
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Group deleted successfully'
    })
end)

-- Create event
RegisterNetEvent('ec_admin_ultimate:server:createEvent', function(data)
    local src = source
    local title = data.title
    local description = data.description or ''
    local eventType = data.eventType or 'custom'
    local startTime = data.startTime
    local duration = tonumber(data.duration) or 60
    local location = data.location or ''
    local maxParticipants = tonumber(data.maxParticipants) or 50
    local prizePool = tonumber(data.prizePool) or 0
    
    if not title or not startTime then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Title and start time are required'
        })
        return
    end
    
    local playerId = GetPlayerIdentifier(src)
    local playerName = GetPlayerName(src)
    
    MySQL.Async.execute([[
        INSERT INTO ec_community_events 
        (title, description, event_type, organizer_id, organizer_name, start_time, duration, location, max_participants, prize_pool)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {title, description, eventType, playerId, playerName, startTime, duration, location, maxParticipants, prizePool})
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Event created successfully'
    })
end)

-- Delete event
RegisterNetEvent('ec_admin_ultimate:server:deleteEvent', function(data)
    local src = source
    local eventId = tonumber(data.eventId)
    
    if not eventId then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Invalid event ID'
        })
        return
    end
    
    MySQL.Async.execute('DELETE FROM ec_community_events WHERE id = ?', {eventId})
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Event deleted successfully'
    })
end)

-- Update event status
RegisterNetEvent('ec_admin_ultimate:server:updateEventStatus', function(data)
    local src = source
    local eventId = tonumber(data.eventId)
    local status = data.status
    
    if not eventId or not status then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Invalid data'
        })
        return
    end
    
    MySQL.Async.execute('UPDATE ec_community_events SET status = ? WHERE id = ?', {status, eventId})
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Event status updated'
    })
end)

-- Create achievement
RegisterNetEvent('ec_admin_ultimate:server:createAchievement', function(data)
    local src = source
    local name = data.name
    local description = data.description or ''
    local category = data.category or 'general'
    local icon = data.icon or 'trophy'
    local points = tonumber(data.points) or 10
    local requirementType = data.requirementType or 'manual'
    local requirementValue = tonumber(data.requirementValue) or 1
    local isSecret = data.isSecret == true
    
    if not name then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Achievement name is required'
        })
        return
    end
    
    MySQL.Async.execute([[
        INSERT INTO ec_community_achievements 
        (name, description, category, icon, points, requirement_type, requirement_value, is_secret)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {name, description, category, icon, points, requirementType, requirementValue, isSecret})
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Achievement created successfully'
    })
end)

-- Delete achievement
RegisterNetEvent('ec_admin_ultimate:server:deleteAchievement', function(data)
    local src = source
    local achievementId = tonumber(data.achievementId)
    
    if not achievementId then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Invalid achievement ID'
        })
        return
    end
    
    MySQL.Async.execute('DELETE FROM ec_community_achievements WHERE id = ?', {achievementId})
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Achievement deleted successfully'
    })
end)

-- Grant achievement to player
RegisterNetEvent('ec_admin_ultimate:server:grantAchievement', function(data)
    local src = source
    local playerId = data.playerId
    local playerName = data.playerName
    local achievementId = tonumber(data.achievementId)
    
    if not playerId or not achievementId then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Invalid data'
        })
        return
    end
    
    -- Get achievement points
    local achievement = MySQL.Sync.fetchAll('SELECT points FROM ec_community_achievements WHERE id = ? LIMIT 1', {achievementId})
    
    if not achievement or #achievement == 0 then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Achievement not found'
        })
        return
    end
    
    local points = achievement[1].points
    
    -- Grant achievement
    MySQL.Async.execute([[
        INSERT IGNORE INTO ec_community_player_achievements (player_id, player_name, achievement_id)
        VALUES (?, ?, ?)
    ]], {playerId, playerName, achievementId})
    
    -- Update leaderboard
    MySQL.Async.execute([[
        INSERT INTO ec_community_leaderboards (player_id, player_name, achievement_points)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE achievement_points = achievement_points + ?
    ]], {playerId, playerName, points, points})
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Achievement granted successfully'
    })
end)

-- Create announcement
RegisterNetEvent('ec_admin_ultimate:server:createAnnouncement', function(data)
    local src = source
    local title = data.title
    local message = data.message
    local announcementType = data.announcementType or 'info'
    local priority = tonumber(data.priority) or 1
    local isPinned = data.isPinned == true
    
    if not title or not message then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Title and message are required'
        })
        return
    end
    
    local postedBy = GetPlayerName(src)
    
    MySQL.Async.execute([[
        INSERT INTO ec_community_announcements (title, message, announcement_type, posted_by, priority, is_pinned)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {title, message, announcementType, postedBy, priority, isPinned})
    
    -- Broadcast to all players
    TriggerClientEvent('ec_admin_ultimate:client:newAnnouncement', -1, {
        title = title,
        message = message,
        type = announcementType
    })
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Announcement created successfully'
    })
end)

-- Delete announcement
RegisterNetEvent('ec_admin_ultimate:server:deleteAnnouncement', function(data)
    local src = source
    local announcementId = tonumber(data.announcementId)
    
    if not announcementId then
        TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
            success = false,
            message = 'Invalid announcement ID'
        })
        return
    end
    
    MySQL.Async.execute('DELETE FROM ec_community_announcements WHERE id = ?', {announcementId})
    
    TriggerClientEvent('ec_admin_ultimate:client:communityResponse', src, {
        success = true,
        message = 'Announcement deleted successfully'
    })
end)

-- Update leaderboard (called by other systems)
local function UpdateLeaderboard(playerId, playerName, field, value)
    local fields = {
        playtime = 'total_playtime',
        money = 'total_money',
        arrests = 'total_arrests',
        deaths = 'total_deaths',
        kills = 'total_kills',
        reputation = 'reputation_score'
    }
    
    local dbField = fields[field]
    if not dbField then return end
    
    MySQL.Async.execute([[
        INSERT INTO ec_community_leaderboards (player_id, player_name, ]] .. dbField .. [[)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE ]] .. dbField .. [[ = ]] .. dbField .. [[ + ?
    ]], {playerId, playerName, value, value})
end

-- Export function
exports('UpdateLeaderboard', UpdateLeaderboard)

-- =============================================================================
-- ADVANCED ENGAGEMENT TRACKING (ENHANCED)
-- =============================================================================

local EngagementEngine = {
    members = {},
    leaderboards = {}
}

-- Track member engagement
local function TrackMemberEngagement(playerId, action, points)
    if not EngagementEngine.members[playerId] then
        EngagementEngine.members[playerId] = {
            totalEngagement = 0,
            joinDate = os.time(),
            lastActive = os.time()
        }
    end
    
    local member = EngagementEngine.members[playerId]
    member.totalEngagement = member.totalEngagement + (points or 10)
    member.lastActive = os.time()
    
    MySQL.Async.execute([[
        INSERT INTO ec_community_engagement (player_id, action, points)
        VALUES (?, ?, ?)
    ]], {tonumber(playerId), action, points or 10})
end

-- Calculate engagement score
local function CalculateEngagementScore(playerId)
    local member = EngagementEngine.members[playerId]
    if not member then return 0 end
    
    local daysSinceJoin = (os.time() - member.joinDate) / 86400
    local engagementRate = member.totalEngagement / math.max(1, daysSinceJoin)
    return math.floor(engagementRate * 10)
end

-- Update community leaderboards
local function UpdateCommunityLeaderboards()
    EngagementEngine.leaderboards.engagement = {}
    
    local scores = {}
    for playerId, member in pairs(EngagementEngine.members) do
        local score = CalculateEngagementScore(tonumber(playerId))
        table.insert(scores, {
            playerId = tonumber(playerId),
            score = score
        })
    end
    
    table.sort(scores, function(a, b) return a.score > b.score end)
    
    for rank, entry in ipairs(scores) do
        if rank <= 100 then
            table.insert(EngagementEngine.leaderboards.engagement, {
                rank = rank,
                playerId = entry.playerId,
                score = entry.score
            })
        end
    end
end

-- Get member engagement profile
lib.callback.register('ec_admin:getMemberEngagementProfile', function(source, playerId)
    local member = EngagementEngine.members[tonumber(playerId)]
    if not member then
        return { success = false }
    end
    
    local score = CalculateEngagementScore(tonumber(playerId))
    return {
        success = true,
        playerId = tonumber(playerId),
        totalEngagement = member.totalEngagement,
        engagementScore = score,
        joinedDaysAgo = math.floor((os.time() - member.joinDate) / 86400),
        lastActive = member.lastActive
    }
end)

-- Get community leaderboard
lib.callback.register('ec_admin:getCommunityLeaderboard', function(source, limit)
    limit = limit or 50
    local result = {}
    for i = 1, math.min(limit, #EngagementEngine.leaderboards.engagement) do
        table.insert(result, EngagementEngine.leaderboards.engagement[i])
    end
    return result
end)

-- Track event participation
lib.callback.register('ec_admin:trackEventParticipation', function(source, eventId, playerId, points)
    TrackMemberEngagement(tonumber(playerId), 'event_participation', points or 100)
    return { success = true }
end)

-- Update leaderboards every 30 minutes
CreateThread(function()
    while true do
        Wait(30 * 60 * 1000)
        UpdateCommunityLeaderboards()
    end
end)

Logger.Info('Community callbacks loaded + Advanced Engagement Tracking')