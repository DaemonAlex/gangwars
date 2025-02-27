local Ox = exports.ox_lib

RegisterNetEvent('gangWars:notifyGangActivity')
AddEventHandler('gangWars:notifyGangActivity', function(message)
    Ox.ShowNotification({
        title = 'Gang Activity',
        description = message,
        type = 'error',
        duration = 5000
    })
end)

RegisterNetEvent('gangWars:gangFightStarted')
AddEventHandler('gangWars:gangFightStarted', function(coords)
    PlaySoundFromCoord(-1, "BANG", coords.x, coords.y, coords.z, "DLC_IE_Explosive_Ammo_Sounds", true, 120, true)
    StartParticleFxLoopedAtCoord("scr_rcbarry2", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
end)

RegisterNetEvent('gangWars:playerEnteredTerritory')
AddEventHandler('gangWars:playerEnteredTerritory', function(territory)
    Ox.ShowNotification({
        title = 'Territory Alert',
        description = 'You have entered ' .. territory .. '. Watch your back!',
        type = 'warning',
        duration = 7500
    })
end)

RegisterNetEvent('gangWars:notifyPathfinding')
AddEventHandler('gangWars:notifyPathfinding', function(ped, destination)
    TaskGoToCoordAnyMeans(ped, destination.x, destination.y, destination.z, 1.0, 0, 0, 786603, 0xbf800000)
end)
