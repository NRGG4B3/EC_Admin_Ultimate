--[[
    EC Admin Ultimate - Host Status Client
    Sends host mode status to NUI
]]

-- Request host status from server
RegisterNetEvent('ec_admin:hostStatus', function(status)
    -- Send host status to NUI
    SendNUIMessage({
        type = 'EC_HOST_STATUS',
        isHost = status.isHost or false,
        isNRGStaff = status.isNRGStaff or false,
        canAccessHostDashboard = status.canAccessHostDashboard or false,
        mode = status.mode or 'customer'
    })
end)

-- Request host status on resource start
CreateThread(function()
    Wait(2000) -- Wait for server to be ready
    TriggerServerEvent('ec_admin:requestHostStatus')
end)

print("^2[Host Status]^7 Client-side host status handler loaded^0")

