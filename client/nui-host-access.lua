--[[
    EC Admin Ultimate - Host Access NUI Bridge
    Handles host access checks from UI
]]

-- NUI Callback: Check host access with error handling
RegisterNUICallback('checkHostAccess', function(data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:getHostStatus', false, {})
        else
            return nil
        end
    end)
    
    if not success then
        print("^1[NUI Host Access]^7 Error in checkHostAccess: " .. tostring(response) .. "^0")
        cb({
            hostMode = false,
            isNRGStaff = false,
            canAccessHostDashboard = false,
            mode = 'customer'
        })
    elseif response then
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
end)

print("^2[NUI Host Access]^7 Host access bridge loaded^0")

