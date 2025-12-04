# EC Admin Ultimate - Master API Documentation

**Complete API Reference for All Systems**  
*Generated: December 4, 2025*  
*Total Events: 50+ | Total Callbacks: 40+*

---

## Table of Contents

1. [AI Analytics System](#ai-analytics-system)
2. [Anticheat Detection System](#anticheat-detection-system)
3. [Dev Tools System](#dev-tools-system)
4. [Performance Monitoring](#performance-monitoring)
5. [AI Detection System](#ai-detection-system)
6. [Housing Market System](#housing-market-system)
7. [Livemap Tracking System](#livemap-tracking-system)
8. [Dashboard System](#dashboard-system)
9. [Reports Analytics](#reports-analytics)
10. [Community Features](#community-features)
11. [Host Management Billing](#host-management-billing)

---

## AI Analytics System

### Events

#### `ec_admin_ultimate:server:getAIAnalytics`
**Purpose:** Retrieve comprehensive AI analytics data  
**Trigger:** Client side  
**Parameters:**
```lua
{
    timeframe = '24h'  -- '24h', '7d', '30d'
}
```
**Response Event:** `ec_admin_ultimate:client:aiAnalyticsUpdate`  
**Response Data:**
```lua
{
    totalDetections = number,
    avgRiskScore = number,
    topThreats = table,
    timeframeDetections = table,
    predictions = table
}
```
**Example:**
```lua
TriggerServerEvent('ec_admin_ultimate:server:getAIAnalytics', {
    timeframe = '24h'
})
```

#### `ec_admin_ultimate:server:getPlayerAnalysis`
**Purpose:** Get detailed analysis for specific player  
**Trigger:** Client side  
**Parameters:**
```lua
{
    playerId = number,
    analysisType = 'full'  -- 'full', 'summary', 'risk'
}
```
**Response Event:** `ec_admin_ultimate:client:playerAnalysisUpdate`  
**Response Data:**
```lua
{
    playerId = number,
    riskScore = number,
    flags = table,
    detectionHistory = table,
    predictions = table
}
```

#### `ec_admin_ultimate:server:getTrendPredictions`
**Purpose:** Get trend predictions across all players  
**Trigger:** Client side  
**Parameters:** None  
**Response Event:** `ec_admin_ultimate:client:trendPredictionsUpdate`  
**Response Data:**
```lua
{
    predictions = {
        {
            metric = 'detection_count',
            predicted = number,
            confidence = number
        }
    }
}
```

---

## Anticheat Detection System

### Events

#### `ec_admin_ultimate:server:startAntiCheatMonitoring`
**Purpose:** Start anticheat monitoring for server  
**Trigger:** Client side  
**Parameters:** None  
**Response Event:** `ec_admin_ultimate:client:antiCheatStatus`  
**Response Data:**
```lua
{
    success = boolean,
    message = string,
    monitoringActive = boolean
}
```

#### `ec_admin_ultimate:server:getDetectedThreat`
**Purpose:** Retrieve information about detected threat  
**Trigger:** Client side  
**Parameters:**
```lua
{
    threatId = string
}
```
**Response Event:** `ec_admin_ultimate:client:threatDetailsResponse`  
**Response Data:**
```lua
{
    id = string,
    type = string,  -- 'aim_bot', 'wall_hack', 'godmode', 'speed_hack'
    severity = string,  -- 'low', 'medium', 'high', 'critical'
    detectedAt = number,
    playerName = string,
    evidence = table
}
```

#### `ec_admin_ultimate:server:banThreatActor`
**Purpose:** Ban player detected as threat  
**Trigger:** Client side  
**Parameters:**
```lua
{
    playerId = number,
    reason = string,
    duration = number  -- 0 for permanent
}
```
**Response Event:** `ec_admin_ultimate:client:actionResponse`  
**Response Data:**
```lua
{
    success = boolean,
    message = string,
    banId = string
}
```

---

## Dev Tools System

### Callbacks

#### `ec_admin:getServerLogs`
**Purpose:** Fetch server logs with filters  
**Parameters:**
```lua
{
    source,
    filter = 'all',  -- 'errors', 'warnings', 'info', 'all'
    limit = 100,
    offset = 0
}
```
**Response:**
```lua
{
    success = boolean,
    logs = table,
    total = number
}
```

#### `ec_admin:executeDebugCommand`
**Purpose:** Execute debug command on server  
**Parameters:**
```lua
{
    source,
    command = string,
    args = table
}
```
**Response:**
```lua
{
    success = boolean,
    output = string
}
```

### Events

#### `ec_admin_ultimate:server:streamPerformanceData`
**Purpose:** Start streaming performance data  
**Trigger:** Client side  
**Parameters:**
```lua
{
    interval = 1000  -- milliseconds
}
```
**Response Event:** `ec_admin_ultimate:client:performanceStreamUpdate`

---

## Performance Monitoring

### Callbacks

#### `ec_admin:getPerformanceMetrics`
**Purpose:** Get current performance metrics  
**Parameters:**
```lua
{
    source
}
```
**Response:**
```lua
{
    success = boolean,
    tps = number,
    cpuUsage = number,
    memoryUsage = number,
    networkLatency = number,
    activeScripts = number
}
```

#### `ec_admin:getAnomalies`
**Purpose:** Get detected anomalies  
**Parameters:**
```lua
{
    source,
    timeframe = '24h'
}
```
**Response:**
```lua
{
    success = boolean,
    anomalies = {
        {
            type = string,
            severity = string,
            detectedAt = number,
            value = number
        }
    }
}
```

---

## AI Detection System

### Events

#### `ec_admin_ultimate:server:getAdvancedAnalysis`
**Purpose:** Get advanced AI bot analysis with predictions  
**Trigger:** Client side  
**Parameters:**
```lua
{
    playerId = number
}
```
**Response Event:** `ec_admin_ultimate:client:advancedAnalysisUpdate`  
**Response Data:**
```lua
{
    playerId = number,
    baseScore = number,
    predictedScore = number,
    anomalyScore = number,
    confidenceScore = number,
    recommendation = string,  -- 'Monitor', 'Investigate', 'Ban'
    patterns = table
}
```

#### `ec_admin_ultimate:server:getAnomalyDetections`
**Purpose:** Get detected anomalies for all players  
**Trigger:** Client side  
**Parameters:** None  
**Response Event:** `ec_admin_ultimate:client:anomalyDetectionsUpdate`

---

## Housing Market System

### Events

#### `ec_admin_ultimate:server:getHousingMarketStatus`
**Purpose:** Get current housing market status  
**Trigger:** Client side  
**Parameters:** None  
**Response Event:** `ec_admin_ultimate:client:housingMarketUpdate`  
**Response Data:**
```lua
{
    demandFactor = number,  -- 0.7 to 1.3
    supplyLevel = number,
    avgPropertyPrice = number,
    trendDirection = string,  -- 'up', 'down', 'stable'
    volatility = number
}
```

#### `ec_admin_ultimate:server:purchaseProperty`
**Purpose:** Purchase a property  
**Trigger:** Client side  
**Parameters:**
```lua
{
    propertyId = number,
    price = number
}
```
**Response Event:** `ec_admin_ultimate:client:purchaseResponse`  
**Response Data:**
```lua
{
    success = boolean,
    message = string,
    propertyData = table
}
```

#### `ec_admin_ultimate:server:rentProperty`
**Purpose:** Create rental agreement  
**Trigger:** Client side  
**Parameters:**
```lua
{
    propertyId = number,
    tenantId = number,
    monthlyRent = number
}
```
**Response Event:** `ec_admin_ultimate:client:rentalResponse`

---

## Livemap Tracking System

### Events

#### `ec_admin_ultimate:server:startPlayerTracking`
**Purpose:** Start tracking specific player  
**Trigger:** Client side  
**Parameters:**
```lua
{
    targetPlayerId = number
}
```
**Response Event:** `ec_admin_ultimate:client:trackingResponse`

#### `ec_admin_ultimate:server:getHeatmapData`
**Purpose:** Get heatmap intensity data  
**Trigger:** Client side  
**Parameters:** None  
**Response Event:** `ec_admin_ultimate:client:heatmapUpdate`  
**Response Data:**
```lua
{
    {
        x = number,
        y = number,
        intensity = number,  -- 0-255
        playerCount = number,
        color = {r = number, g = number, b = number, a = number}
    }
}
```

#### `ec_admin_ultimate:server:getActivityZones`
**Purpose:** Get detected activity zones  
**Trigger:** Client side  
**Parameters:** None  
**Response Event:** `ec_admin_ultimate:client:activityZonesUpdate`  
**Response Data:**
```lua
{
    {
        id = number,
        x = number,
        y = number,
        intensity = number,
        playerCount = number,
        radius = number
    }
}
```

---

## Dashboard System

### Callbacks

#### `ec_admin:getServerMetrics`
**Purpose:** Get main server metrics  
**Parameters:**
```lua
{
    source
}
```
**Response:**
```lua
{
    success = boolean,
    playersOnline = number,
    activeVehicles = number,
    serverHealth = number,
    cpuUsage = number,
    memoryUsage = number
}
```

#### `ec_admin:getPerformanceMetrics`
**Purpose:** Get performance overview  
**Parameters:**
```lua
{
    source
}
```
**Response:**
```lua
{
    success = boolean,
    tps = number,
    avgLatency = number,
    scriptCount = number
}
```

---

## Reports Analytics

### Callbacks

#### `ec_admin:generatePerformanceReport`
**Purpose:** Generate detailed performance report  
**Parameters:**
```lua
{
    source,
    period = '24h'  -- '24h', '7d', '30d'
}
```
**Response:**
```lua
{
    success = boolean,
    period = string,
    generatedAt = number,
    data = {
        tps = {
            average = number,
            median = number,
            stdDev = number,
            p95 = number,
            p99 = number,
            trend = number
        },
        cpu = { ... },
        memory = { ... }
    }
}
```

#### `ec_admin:generatePlayerActivityReport`
**Purpose:** Generate player activity report  
**Parameters:**
```lua
{
    source,
    playerId = number,
    period = '24h'
}
```
**Response:**
```lua
{
    success = boolean,
    data = {
        login_count = number,
        logout_count = number,
        vehicles_spawned = number,
        total_actions = number
    }
}
```

#### `ec_admin:generateModerationReport`
**Purpose:** Generate moderation statistics  
**Parameters:**
```lua
{
    source,
    period = '24h'
}
```
**Response:**
```lua
{
    success = boolean,
    data = {
        byType = table
    }
}
```

---

## Community Features

### Events

#### `ec_admin_ultimate:server:createCommunityEvent`
**Purpose:** Create new community event  
**Trigger:** Client side  
**Parameters:**
```lua
{
    name = string,
    description = string,
    type = string,  -- 'race', 'meetup', 'competition'
    scheduledTime = number,
    maxPlayers = number
}
```
**Response Event:** `ec_admin_ultimate:client:eventCreated`

#### `ec_admin_ultimate:server:registerForEvent`
**Purpose:** Register player for event  
**Trigger:** Client side  
**Parameters:**
```lua
{
    eventId = string
}
```
**Response Event:** `ec_admin_ultimate:client:eventRegistered`

#### `ec_admin_ultimate:server:getLeaderboard`
**Purpose:** Get community leaderboard  
**Trigger:** Client side  
**Parameters:**
```lua
{
    type = string,  -- 'engagement', 'events', 'reputation'
    limit = number
}
```
**Response Event:** `ec_admin_ultimate:client:leaderboardResponse`  
**Response Data:**
```lua
{
    {
        rank = number,
        playerId = number,
        name = string,
        score = number
    }
}
```

### Callbacks

#### `ec_admin:getMemberEngagementProfile`
**Purpose:** Get member engagement data  
**Parameters:**
```lua
{
    source,
    playerId = number
}
```
**Response:**
```lua
{
    success = boolean,
    totalEngagement = number,
    engagementScore = number,
    joinedDaysAgo = number
}
```

---

## Host Management Billing

### Callbacks

#### `ec_admin:generateBillingReport`
**Purpose:** Generate billing and revenue report  
**Parameters:**
```lua
{
    source,
    period = '30d'  -- '30d', '90d', '1y'
}
```
**Response:**
```lua
{
    success = boolean,
    revenue = {
        total_revenue = number,
        payment_count = number
    },
    mrr = number,  -- Monthly Recurring Revenue
    arr = number,  -- Annual Recurring Revenue
    activeSubscriptions = number,
    churnRate = string
}
```

#### `ec_admin:getInvoiceDetails`
**Purpose:** Get specific invoice details  
**Parameters:**
```lua
{
    source,
    invoiceId = string
}
```
**Response:**
```lua
{
    id = string,
    customerId = string,
    amount = number,
    status = string,
    createdAt = number,
    dueDate = number
}
```

#### `ec_admin:trackEventParticipation`
**Purpose:** Track community event participation for billing  
**Parameters:**
```lua
{
    source,
    eventId = string,
    playerId = number,
    points = number
}
```
**Response:**
```lua
{
    success = boolean
}
```

---

## Best Practices

### Event Handling
- Always wrap network events in error handlers
- Use appropriate timeout values for async operations
- Validate all input parameters before processing
- Log important operations for audit trails

### Callback Responses
- Always include a `success` boolean in responses
- Provide clear error messages when operations fail
- Return consistent data structures
- Include timestamps for all database operations

### Performance Optimization
- Batch database queries when possible
- Use caching for frequently accessed data
- Implement rate limiting on sensitive callbacks
- Monitor callback execution times

### Security Considerations
- Validate player IDs and identifiers
- Check admin permissions before sensitive operations
- Sanitize all user input
- Log all administrative actions
- Implement audit trails for financial transactions

---

## Database Tables Reference

**AI Analytics:**
- `ec_ai_analytics_data` - Raw metrics collection
- `ec_ai_detections` - Detection records
- `ec_ai_player_patterns` - Player behavior patterns

**Anticheat:**
- `ec_anticheat_detections` - Threat detections
- `ec_anticheat_events` - Cheat events
- `ec_anticheat_bans` - Ban records
- `ec_anticheat_signatures` - Cheat signatures

**Performance:**
- `ec_performance_metrics` - Time-series metrics
- `ec_performance_anomalies` - Detected anomalies

**Housing:**
- `ec_housing_properties` - Property data
- `ec_housing_rentals` - Rental agreements
- `ec_housing_market_trends` - Market data

**Livemap:**
- `ec_livemap_history` - Location history
- `ec_livemap_tracking` - Active tracking sessions

**Community:**
- `ec_community_events` - Community events
- `ec_community_engagement` - Member engagement
- `ec_community_leaderboards` - Leaderboard data

**Billing:**
- `ec_billing_invoices` - Invoice records
- `ec_billing_payments` - Payment records
- `ec_billing_subscriptions` - Subscription data

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-04 | Initial release - All 11 systems documented |

**Last Updated:** December 4, 2025  
**Total Pages:** 15  
**Total Events:** 50+  
**Total Callbacks:** 40+