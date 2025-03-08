local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()
local Config = Config or {}

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
        Citizen.Wait(500)  -- Reduced check time for better response
        local playerPed = PlayerPedId()
        if IsPedShooting(playerPed) then
            local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
                local entityModel = GetEntityModel(entity)

                for gangName, gangData in pairs(Config.Gangs) do
                    for _, model in ipairs(gangData.models) do
                        if GetHashKey(model) == entityModel then
                            TriggerServerEvent('gangWars:playerAttackedGang', gangName)
                            return  -- Prevent multiple triggers for one shot
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
        SetPedCombatAttributes(ped, 46, true)  -- Never flee
        SetPedCombatAttributes(ped, 5, true)   -- Can flee if health is low
        SetPedAsEnemy(ped, true)
        SetPedRelationshipGroupHash(ped, GetHashKey("GANG_GROUP"))

        -- Improved NPC Combat Behavior
        TaskCombatHatedTargetsAroundPed(ped, 150.0, 0)  -- Engage any nearby threats
        SetPedCombatMovement(ped, 3)  -- NPCs will chase players
        SetPedCombatAbility(ped, 2)  -- NPCs will shoot accurately
        SetPedCombatRange(ped, 2)  -- NPCs will attack from a distance
        SetPedCombatAttributes(ped, 46, true)  -- NPCs will never flee
        SetPedCombatAttributes(ped, 0, true)  -- NPCs will use cover
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_MICROSMG"), true)  -- Ensure they hold the gun
        SetPedAccuracy(ped, 60)  -- Improve NPC shooting accuracy
        SetPedSeeingRange(ped, 100.0)  -- NPCs detect players from a distance
        SetPedHearingRange(ped, 80.0)  -- NPCs hear gunshots nearby
        SetPedAlertness(ped, 3)  -- NPCs react faster
        TaskReloadWeapon(ped, true)  -- NPCs will reload

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
