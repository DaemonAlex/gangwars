local Ox = exports.ox_lib

-- Notify Players Near Gang Areas of Gang Activity
RegisterNetEvent('gangWars:notifyGangActivity')
AddEventHandler('gangWars:notifyGangActivity', function(message, gangTerritory)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(gangTerritory.x, gangTerritory.y, gangTerritory.z))
    
    if distance < 500.0 then -- Only notify players within 500 meters of the gang territory
        Ox.ShowNotification({
            title = 'Gang Activity',
            description = message,
            type = 'error',
            duration = 5000
        })
    end

    -- Notify police if gangs are shooting
    local playerJob = exports['qb-core']:GetPlayerData().job.name
    if playerJob == 'police' then
        Ox.ShowNotification({
            title = 'Police Alert',
            description = 'Gunshots reported in a gang territory!',
            type = 'warning',
            duration = 7000
        })
    end
end)

-- Play Effects When a Gang Fight Starts
RegisterNetEvent('gangWars:gangFightStarted')
AddEventHandler('gangWars:gangFightStarted', function(coords)
    PlaySoundFromCoord(-1, "BANG", coords.x, coords.y, coords.z, "DLC_IE_Explosive_Ammo_Sounds", true, 120, true)
    StartParticleFxLoopedAtCoord("scr_rcbarry2", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
end)

-- Detect If a Player Shoots a Gang Member and Notify the Server
Citizen.CreateThread(function()
    while true do
        Wait(1000)  -- Check every second
        local playerPed = PlayerPedId()
        if IsPedShooting(playerPed) then
            local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if DoesEntityExist(entity) and IsPedAPlayer(entity) == false then
                local entityModel = GetEntityModel(entity)
                
                for gangName, gangData in pairs(Config.Gangs) do
                    for _, model in ipairs(gangData.models) do
                        if GetHashKey(model) == entityModel then
                            print("^1WARNING:^0 Player has attacked " .. gangName .. "! Retaliation incoming.")
                            TriggerServerEvent('gangWars:playerAttackedGang', gangName)
                        end
                    end
                end
            end
        end
    end
end)

-- Player Command to Join a Gang
RegisterCommand('joingang', function(source, args)
    local gang = args[1]  -- Example: /joingang Ballas
    if not Config.Gangs[gang] then
        TriggerEvent('ox_lib:notify', {title = 'Error', description = 'Invalid gang.', type = 'error', duration = 5000})
        return
    end
    TriggerServerEvent('gangWars:playerJoinedGang', gang)
end, false)
