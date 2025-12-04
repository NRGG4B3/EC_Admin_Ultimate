--[[
    EC Admin Ultimate - Host Revenue Calculation Callbacks
    Detects subscription vs lifetime customers and calculates proper revenue metrics
]]

-- Calculate MRR (Monthly Recurring Revenue)
local function calculateMRR()
    local mrr = 0
    local subscriptionCustomers = MySQL.query.await([[
        SELECT SUM(mrr) as total_mrr
        FROM nrg_host_customers
        WHERE license_type = 'subscription'
        AND status = 'active'
        AND subscription_status = 'active'
    ]])
    
    if subscriptionCustomers and subscriptionCustomers[1] then
        mrr = subscriptionCustomers[1].total_mrr or 0
    end
    
    return mrr
end

-- Calculate ARR (Annual Recurring Revenue)
local function calculateARR(mrr)
    return mrr * 12
end

-- Calculate lifetime revenue (one-time purchases)
local function calculateLifetimeRevenue()
    local lifetimeRevenue = MySQL.query.await([[
        SELECT SUM(total_spent) as total_lifetime
        FROM nrg_host_customers
        WHERE license_type IN ('lifetime', 'one-time')
    ]])
    
    if lifetimeRevenue and lifetimeRevenue[1] then
        return lifetimeRevenue[1].total_lifetime or 0
    end
    
    return 0
end

-- Calculate this month's subscription revenue
local function calculateMonthSubscriptionRevenue()
    local monthStart = os.time() - (os.date('*t').day - 1) * 86400
    
    local result = MySQL.query.await([[
        SELECT SUM(amount) as subscription_revenue
        FROM nrg_host_purchases
        WHERE product_type = 'subscription'
        AND purchased_at >= ?
        AND status = 'completed'
    ]], {monthStart})
    
    if result and result[1] then
        return result[1].subscription_revenue or 0
    end
    
    return 0
end

-- Get customer counts by type
local function getCustomerCounts()
    local counts = MySQL.query.await([[
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active,
            SUM(CASE WHEN license_type = 'subscription' AND status = 'active' THEN 1 ELSE 0 END) as subscription,
            SUM(CASE WHEN license_type = 'lifetime' THEN 1 ELSE 0 END) as lifetime,
            SUM(CASE WHEN status = 'trial' THEN 1 ELSE 0 END) as trial
        FROM nrg_host_customers
    ]])
    
    if counts and counts[1] then
        return counts[1]
    end
    
    return {
        total = 0,
        active = 0,
        subscription = 0,
        lifetime = 0,
        trial = 0
    }
end

-- Get revenue totals
local function getRevenueTotals()
    local today = os.time() - (os.time() % 86400)
    local monthStart = os.time() - (os.date('*t').day - 1) * 86400
    
    local revenue = MySQL.query.await([[
        SELECT 
            SUM(CASE WHEN purchased_at >= ? THEN amount ELSE 0 END) as today,
            SUM(CASE WHEN purchased_at >= ? THEN amount ELSE 0 END) as month,
            SUM(amount) as total
        FROM nrg_host_purchases
        WHERE status = 'completed'
    ]], {today, monthStart})
    
    if revenue and revenue[1] then
        return revenue[1]
    end
    
    return {
        today = 0,
        month = 0,
        total = 0
    }
end

-- Main stats callback
lib.callback.register('getHostDashboardStats', function(source)
    -- Check NRG staff permission
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local isNRGStaff = MySQL.query.await([[
        SELECT 1 FROM nrg_host_staff 
        WHERE identifier = ? AND active = 1
    ]], {Player.PlayerData.license})
    
    if not isNRGStaff or #isNRGStaff == 0 then
        return nil
    end
    
    -- Calculate revenue metrics
    local mrr = calculateMRR()
    local arr = calculateARR(mrr)
    local lifetimeRevenue = calculateLifetimeRevenue()
    local subscriptionRevenueMonth = calculateMonthSubscriptionRevenue()
    
    -- Get customer counts
    local customerCounts = getCustomerCounts()
    
    -- Get revenue totals
    local revenueTotals = getRevenueTotals()
    
    -- Get server counts
    local serverCounts = MySQL.query.await([[
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'online' THEN 1 ELSE 0 END) as online
        FROM nrg_host_customer_servers
    ]])
    
    local servers = {total = 0, online = 0}
    if serverCounts and serverCounts[1] then
        servers = serverCounts[1]
    end
    
    -- Get host management stats
    local banStats = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_bans,
            SUM(CASE WHEN is_permanent = 1 THEN 1 ELSE 0 END) as permanent_bans
        FROM nrg_global_bans
        WHERE active = 1
    ]])
    
    local appealStats = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_appeals,
            SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_appeals
        FROM nrg_ban_appeals
    ]])
    
    local warningStats = MySQL.query.await([[
        SELECT COUNT(*) as total_warnings
        FROM nrg_global_warnings
        WHERE active = 1
    ]])
    
    local webhookStats = MySQL.query.await([[
        SELECT COUNT(*) as total_webhooks
        FROM nrg_host_webhooks
        WHERE enabled = 1
    ]])
    
    local ticketStats = MySQL.query.await([[
        SELECT 
            COUNT(*) as pending_tickets
        FROM nrg_support_tickets
        WHERE status IN ('open', 'in_progress')
    ]])
    
    local apiRequestStats = MySQL.query.await([[
        SELECT SUM(requests_today) as today_requests
        FROM nrg_api_status
    ]])
    
    local cityStats = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_cities,
            SUM(CASE WHEN status = 'online' THEN 1 ELSE 0 END) as online_cities
        FROM nrg_connected_cities
    ]])
    
    local actionStats = MySQL.query.await([[
        SELECT COUNT(*) as today_actions
        FROM nrg_host_action_logs
        WHERE timestamp >= ?
    ]], {os.time() - 86400})
    
    return {
        -- Customer stats
        total_customers = customerCounts.total or 0,
        active_customers = customerCounts.active or 0,
        subscription_customers = customerCounts.subscription or 0,
        lifetime_customers = customerCounts.lifetime or 0,
        trial_customers = customerCounts.trial or 0,
        
        -- Server stats
        total_servers = servers.total or 0,
        online_servers = servers.online or 0,
        
        -- Revenue stats
        revenue_today = revenueTotals.today or 0,
        revenue_month = revenueTotals.month or 0,
        revenue_total = revenueTotals.total or 0,
        mrr = mrr,
        arr = arr,
        lifetime_revenue = lifetimeRevenue,
        subscription_revenue_month = subscriptionRevenueMonth,
        
        -- Support stats
        pending_tickets = (ticketStats and ticketStats[1] and ticketStats[1].pending_tickets) or 0,
        api_requests_today = (apiRequestStats and apiRequestStats[1] and apiRequestStats[1].today_requests) or 0,
        
        -- Host management stats
        totalBans = (banStats and banStats[1] and banStats[1].total_bans) or 0,
        totalBansPermanent = (banStats and banStats[1] and banStats[1].permanent_bans) or 0,
        pendingAppeals = (appealStats and appealStats[1] and appealStats[1].pending_appeals) or 0,
        totalAppeals = (appealStats and appealStats[1] and appealStats[1].total_appeals) or 0,
        totalWarnings = (warningStats and warningStats[1] and warningStats[1].total_warnings) or 0,
        totalWebhooks = (webhookStats and webhookStats[1] and webhookStats[1].total_webhooks) or 0,
        webhookExecutions24h = 0, -- TODO: Track this in webhook logs
        actionsToday = (actionStats and actionStats[1] and actionStats[1].today_actions) or 0,
        totalCities = (cityStats and cityStats[1] and cityStats[1].total_cities) or 0,
        onlineCities = (cityStats and cityStats[1] and cityStats[1].online_cities) or 0,
        
        -- ✅ PRODUCTION READY: Get webhook execution stats from database
        webhookExecutions24h = _G.MetricsDB and _G.MetricsDB.GetWebhookStats(24).executions24h or 0,
    }
end)

-- Get all customers with revenue details
lib.callback.register('getHostCustomers', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local isNRGStaff = MySQL.query.await([[
        SELECT 1 FROM nrg_host_staff 
        WHERE identifier = ? AND active = 1
    ]], {Player.PlayerData.license})
    
    if not isNRGStaff or #isNRGStaff == 0 then
        return {}
    end
    
    local customers = MySQL.query.await([[
        SELECT 
            c.*,
            COUNT(DISTINCT s.id) as total_servers,
            SUM(CASE WHEN s.status = 'online' THEN 1 ELSE 0 END) as active_servers
        FROM nrg_host_customers c
        LEFT JOIN nrg_host_customer_servers s ON s.customer_id = c.id
        GROUP BY c.id
        ORDER BY c.created_at DESC
    ]])
    
    return customers or {}
end)

-- Update customer subscription status (manual override)
RegisterNetEvent('host:updateCustomerSubscription', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local isNRGStaff = MySQL.query.await([[
        SELECT 1 FROM nrg_host_staff 
        WHERE identifier = ? AND active = 1
    ]], {Player.PlayerData.license})
    
    if not isNRGStaff or #isNRGStaff == 0 then
        return
    end
    
    MySQL.update([[
        UPDATE nrg_host_customers
        SET 
            license_type = ?,
            subscription_plan = ?,
            subscription_status = ?,
            mrr = ?,
            next_billing = ?
        WHERE id = ?
    ]], {
        data.licenseType,
        data.subscriptionPlan,
        data.subscriptionStatus,
        data.mrr,
        data.nextBilling,
        data.customerId
    })
    
    TriggerClientEvent('QBCore:Notify', src, 'Customer subscription updated', 'success')
end)

-- Automatically detect license type from purchase
RegisterNetEvent('host:processPurchase', function(data)
    local src = source
    
    -- Record purchase
    local purchaseId = MySQL.insert.await([[
        INSERT INTO nrg_host_purchases 
        (customer_id, product_name, product_type, amount, currency, status, purchased_at, transaction_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.customerId,
        data.productName,
        data.productType,
        data.amount,
        data.currency or 'USD',
        'completed',
        os.time(),
        data.transactionId
    })
    
    -- Update customer based on product type
    if data.productType == 'subscription' then
        -- Calculate MRR based on plan
        local mrr = data.amount
        if data.subscriptionPlan == 'yearly' then
            mrr = data.amount / 12
        end
        
        MySQL.update([[
            UPDATE nrg_host_customers
            SET 
                license_type = 'subscription',
                subscription_plan = ?,
                subscription_status = 'active',
                mrr = ?,
                subscription_started = ?,
                next_billing = ?,
                total_spent = total_spent + ?,
                last_payment = ?,
                status = 'active'
            WHERE id = ?
        ]], {
            data.subscriptionPlan or 'monthly',
            mrr,
            os.time(),
            os.time() + (data.subscriptionPlan == 'yearly' and 31536000 or 2592000), -- 1 year or 30 days
            data.amount,
            os.time(),
            data.customerId
        })
    elseif data.productType == 'license' then
        -- Lifetime/one-time purchase
        MySQL.update([[
            UPDATE nrg_host_customers
            SET 
                license_type = 'lifetime',
                total_spent = total_spent + ?,
                lifetime_value = total_spent + ?,
                last_payment = ?,
                status = 'active'
            WHERE id = ?
        ]], {
            data.amount,
            data.amount,
            os.time(),
            data.customerId
        })
    end
    
    -- Log action
    MySQL.insert([[
        INSERT INTO nrg_host_action_logs 
        (action_type, admin_id, admin_name, details, timestamp)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        'purchase_processed',
        'system',
        'Automatic',
        json.encode({
            customer_id = data.customerId,
            product_name = data.productName,
            amount = data.amount,
            product_type = data.productType
        }),
        os.time()
    })
    
    if src then
        TriggerClientEvent('QBCore:Notify', src, 'Purchase processed successfully', 'success')
    end
end)

    
    -- Log action
    MySQL.insert([[
        INSERT INTO nrg_host_action_logs 
        (action_type, admin_id, admin_name, details, timestamp)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        'purchase_processed',
        'system',
        'Automatic',
        json.encode({
            customer_id = data.customerId,
            product_name = data.productName,
            amount = data.amount,
            product_type = data.productType
        }),
        os.time()
    })
    
    if src then
        TriggerClientEvent('QBCore:Notify', src, 'Purchase processed successfully', 'success')
    end
end)

-- =============================================================================
-- ADVANCED HOST MANAGEMENT BILLING (ENHANCED)
-- =============================================================================

local BillingEngine = {
    invoices = {},
    subscriptions = {},
    paymentMethods = {},
    stats = {
        totalRevenue = 0,
        totalCustomers = 0,
        activeSubscriptions = 0
    }
}

-- Create invoice
local function CreateInvoice(customerId, amount, items, dueDate)
    local invoiceId = 'INV_' .. os.time() .. '_' .. math.random(10000, 99999)
    
    local invoice = {
        id = invoiceId,
        customerId = customerId,
        amount = amount,
        items = items,
        createdAt = os.time(),
        dueDate = dueDate,
        status = 'pending',  -- 'pending', 'paid', 'overdue', 'cancelled'
        paidAt = nil,
        amountPaid = 0
    }
    
    BillingEngine.invoices[invoiceId] = invoice
    
    MySQL.Async.execute([[
        INSERT INTO ec_billing_invoices 
        (invoice_id, customer_id, amount, status, due_date, created_at)
        VALUES (?, ?, ?, ?, FROM_UNIXTIME(?), FROM_UNIXTIME(?))
    ]], {invoiceId, customerId, amount, 'pending', dueDate, os.time()})
    
    return invoice
end

-- Process payment
local function ProcessPayment(invoiceId, amount, paymentMethod)
    local invoice = BillingEngine.invoices[invoiceId]
    if not invoice then return false end
    
    invoice.amountPaid = invoice.amountPaid + amount
    
    if invoice.amountPaid >= invoice.amount then
        invoice.status = 'paid'
        invoice.paidAt = os.time()
    end
    
    MySQL.Async.execute([[
        INSERT INTO ec_billing_payments 
        (invoice_id, amount, payment_method, paid_at)
        VALUES (?, ?, ?, FROM_UNIXTIME(?))
    ]], {invoiceId, amount, paymentMethod, os.time()})
    
    return true
end

-- Create subscription plan
local function CreateSubscriptionPlan(customerId, planName, monthlyAmount, billingCycle)
    local subscriptionId = 'SUB_' .. os.time() .. '_' .. math.random(10000, 99999)
    
    local subscription = {
        id = subscriptionId,
        customerId = customerId,
        planName = planName,
        monthlyAmount = monthlyAmount,
        billingCycle = billingCycle,  -- 'monthly', 'annual', 'quarterly'
        status = 'active',
        startDate = os.time(),
        renewalDate = os.time() + (30 * 24 * 3600),
        nextBillingDate = os.time() + (30 * 24 * 3600)
    }
    
    BillingEngine.subscriptions[subscriptionId] = subscription
    
    MySQL.Async.execute([[
        INSERT INTO ec_billing_subscriptions 
        (subscription_id, customer_id, plan_name, monthly_amount, billing_cycle, status, start_date)
        VALUES (?, ?, ?, ?, ?, 'active', FROM_UNIXTIME(?))
    ]], {subscriptionId, customerId, planName, monthlyAmount, billingCycle, os.time()})
    
    return subscription
end

-- Calculate MRR with advanced metrics
local function GetAdvancedMRR()
    local result = MySQL.query.await([[
        SELECT 
            SUM(monthly_amount) as mrr,
            COUNT(*) as subscription_count
        FROM ec_billing_subscriptions
        WHERE status = 'active'
    ]])
    
    if result and result[1] then
        BillingEngine.stats.activeSubscriptions = result[1].subscription_count or 0
        return result[1].mrr or 0
    end
    return 0
end

-- Calculate churn rate
local function CalculateChurnRate()
    local thirtyDaysAgo = os.time() - (30 * 24 * 3600)
    
    local result = MySQL.query.await([[
        SELECT COUNT(*) as cancelled_count
        FROM ec_billing_subscriptions
        WHERE status = 'cancelled'
        AND DATE(updated_at) > DATE(FROM_UNIXTIME(?))
    ]], {thirtyDaysAgo})
    
    if not result or not result[1] then return 0 end
    
    local cancelledCount = result[1].cancelled_count or 0
    local activeCount = BillingEngine.stats.activeSubscriptions
    
    if activeCount == 0 then return 0 end
    return (cancelledCount / activeCount) * 100
end

-- Generate billing report
lib.callback.register('ec_admin:generateBillingReport', function(source, period)
    local startTime = os.time()
    if period == '30d' then startTime = startTime - (30 * 24 * 3600)
    elseif period == '90d' then startTime = startTime - (90 * 24 * 3600)
    elseif period == '1y' then startTime = startTime - (365 * 24 * 3600)
    end
    
    local revenue = MySQL.query.await([[
        SELECT SUM(amount) as total_revenue, COUNT(*) as payment_count
        FROM ec_billing_payments
        WHERE paid_at > FROM_UNIXTIME(?)
    ]], {startTime})
    
    local mrr = GetAdvancedMRR()
    local churnRate = CalculateChurnRate()
    
    return {
        success = true,
        period = period,
        revenue = revenue[1] or { total_revenue = 0, payment_count = 0 },
        mrr = mrr,
        arr = mrr * 12,
        activeSubscriptions = BillingEngine.stats.activeSubscriptions,
        churnRate = string.format("%.2f", churnRate) .. '%'
    }
end)

-- Get invoice details
lib.callback.register('ec_admin:getInvoiceDetails', function(source, invoiceId)
    local invoice = BillingEngine.invoices[invoiceId]
    if invoice then
        return invoice
    end
    
    local result = MySQL.query.await([[
        SELECT * FROM ec_billing_invoices WHERE invoice_id = ?
    ]], {invoiceId})
    
    return result[1] or nil
end)

-- Process subscription renewal
CreateThread(function()
    while true do
        Wait(24 * 60 * 60 * 1000)  -- Run daily
        
        for subscriptionId, subscription in pairs(BillingEngine.subscriptions) do
            if subscription.status == 'active' and os.time() >= subscription.nextBillingDate then
                -- Create renewal invoice
                local renewalAmount = subscription.monthlyAmount
                local invoiceId = CreateInvoice(
                    subscription.customerId,
                    renewalAmount,
                    {{name = subscription.planName, amount = renewalAmount}},
                    os.time() + (30 * 24 * 3600)
                )
                
                -- Update subscription next billing date
                subscription.nextBillingDate = os.time() + (30 * 24 * 3600)
                
                MySQL.Async.execute([[
                    UPDATE ec_billing_subscriptions 
                    SET next_billing_date = FROM_UNIXTIME(?)
                    WHERE subscription_id = ?
                ]], {subscription.nextBillingDate, subscriptionId})
            end
        end
    end
end)

Logger.Success('[NRG Host Revenue] Revenue calculation system loaded + Advanced Billing Engine', '💰')
