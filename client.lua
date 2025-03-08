local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()
Config = Config or { Gangs = {}, PoliceJobs = {} }

RegisterNetEvent('gangWars:notifyGangActivity')
AddEventHandler('gangWars:notifyGangActivity', function(message, gangTerritory)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(gangTerritory.x, gangTerritory.y, gangTerritory.z))
    
    if distance < 500.0 then
        lib.notify({
            title = 'Gang Activity',
            description = message,
            type = 'error',
            duration = 5000
        })
    end

    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.job and Config.PoliceJobs and Config.PoliceJobs[playerData.job.name] then
        lib.notify({
            title = 'Police Alert',
            description = 'Gunshots reported in a gang territory!',
            type = 'warning',
            duration = 7000
        })
    end
end)

RegisterNetEvent('gangWars:gangFightStarted')
AddEventHandler('gangWars:gangFightStarted', function(coords)
    PlaySoundFromCoord(-1, "GENERIC_GUN_SHOT", coords.x, coords.y, coords.z, "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true, 120, true)
    StartParticleFxLoopedAtCoord("scr_rcbarry2", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)  
        local playerPed = PlayerPedId()
        if IsPedShooting(playerPed) then
            local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
                local entityModel = GetEntityModel(entity)

                for gangName, gangData in pairs(Config.Gangs) do
                    for _, model in ipairs(gangData.models) do
                        if GetHashKey(model) == entityModel then
                            TriggerServerEvent('gangWars:playerAttackedGang', gangName)
                            return  
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("gangwars:spawnGangMembers")
AddEventHandler("gangwars:spawnGangMembers", function(gangData)
    for _, spawnPoint in ipairs(gangData.territory) do
        local model = gangData.models[math.random(#gangData.models)]

        RequestModel(GetHashKey(model))
        while not HasModelLoaded(GetHashKey(model)) do
            Citizen.Wait(100)
        end

        local ped = CreatePed(4, GetHashKey(model), spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, true)

        -- Assign Weapons & Make NPCs Aggressive
        GiveWeaponToPed(ped, GetHashKey("WEAPON_MICROSMG"), 255, false, true)
        SetPedCombatAttributes(ped, 46, true)  
        SetPedCombatAttributes(ped, 5, true)  
        SetPedAsEnemy(ped, true)
        SetPedRelationshipGroupHash(ped, GetHashKey("GANG_GROUP"))

        -- Improved NPC Combat Behavior
        Citizen.Wait(math.random(1000, 3000))  
        TaskCombatHatedTargetsAroundPed(ped, 150.0, 0)  
        SetPedCombatMovement(ped, 3)  
        SetPedCombatAbility(ped, 2)  
        SetPedCombatRange(ped, 2)  
        SetPedCombatAttributes(ped, 46, true)  
        SetPedCombatAttributes(ped, 0, true)  
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_MICROSMG"), true)  
        SetPedAccuracy(ped, 60)  
        SetPedSeeingRange(ped, 100.0)  
        SetPedHearingRange(ped, 80.0)  
        SetPedAlertness(ped, 3)  
        TaskReloadWeapon(ped, true)  

        SetModelAsNoLongerNeeded(GetHashKey(model))
    end
end)

RegisterCommand('joingang', function(source, args)
    local gang = args[1]
    if not gang or not Config.Gangs[gang] then
        lib.notify({
            title = 'Error',
            description = 'Invalid gang name. Available: Ballas, Vagos, Families.',
            type = 'error',
            duration = 5000
        })
        return
    end
    TriggerServerEvent('gangWars:playerJoinedGang', gang)
end, false)
