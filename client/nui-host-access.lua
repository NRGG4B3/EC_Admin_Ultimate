--[[
    EC Admin Ultimate - Host Access NUI Bridge
    Handles host access checks from UI
]]

-- NUI Callback: Check host access
RegisterNUICallback('checkHostAccess', function(data, cb)
    -- Get host status from server
    lib.callback('ec_admin:getHostStatus', false, function(response)
        if response then
            cb({
                hostMode = response.isHost or false,
                isNRGStaff = response.isNRGStaff or false,
                canAccessHostDashboard = response.canAccessHostDashboard or false,
                mode = response.mode or 'customer'
            })
        else
            cb({
                hostMode = false,
                isNRGStaff = false,
                canAccessHostDashboard = false,
                mode = 'customer'
            })
        end
    end, {})
end)

print("^2[NUI Host Access]^7 Host access bridge loaded^0")

