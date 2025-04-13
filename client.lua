local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()
Config = Config or { Gangs = {}, PoliceJobs = {} }

-- Debug logging
print("^2DEBUG:^0 Client script loaded")

RegisterNetEvent('gangWars:notifyGangActivity')
AddEventHandler('gangWars:notifyGangActivity', function(message, gangTerritory)
    if not gangTerritory then
        print("^1ERROR:^0 No territory data provided for notification")
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(gangTerritory.x, gangTerritory.y, gangTerritory.z))
    
    if distance < (Config.NotificationDistance or 500.0) then
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
    if not coords then
        print("^1ERROR:^0 No coordinates provided for gang fight effects")
        return
    end
    
    PlaySoundFromCoord(-1, "GENERIC_SHOT_FIRED", coords.x, coords.y, coords.z, "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true, 120, true)
    
    -- Start a particle effect at the coordinates
    RequestNamedPtfxAsset("scr_rcbarry2")
    while not HasNamedPtfxAssetLoaded("scr_rcbarry2") do
        Citizen.Wait(100)
    end
    
    UseParticleFxAssetNextCall("scr_rcbarry2")
    local effect = StartParticleFxLoopedAtCoord("scr_clown_appears", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    SetParticleFxLoopedColour(effect, 1.0, 0.0, 0.0, 0)
    Citizen.Wait(5000)
    StopParticleFxLooped(effect, 0)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)  
        local playerPed = PlayerPedId()
        if IsPedShooting(playerPed) then
            local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
                local entityModel = GetEntityModel(entity)

                -- Check if Config.Gangs exists
                if not Config.Gangs then
                    print("^1ERROR:^0 Config.Gangs is nil or not loaded properly")
                    Citizen.Wait(5000) -- Wait longer before next check
                    return
                end

                for gangName, gangData in pairs(Config.Gangs) do
                    -- Make sure gangData.models exists
                    if gangData and gangData.models then
                        for _, model in ipairs(gangData.models) do
                            if GetHashKey(model) == entityModel then
                                print("^3INFO:^0 Player attacked gang member from " .. gangName)
                                TriggerServerEvent('gangWars:playerAttackedGang', gangName)
                                return  
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Fixed event handler for spawning gang members
RegisterNetEvent("gangwars:spawnGangMembers")
AddEventHandler("gangwars:spawnGangMembers", function(gangData)
    if not gangData or not gangData.territory or not gangData.models then
        print("^1ERROR:^0 Invalid gang data provided for spawning members")
        return
    end
    
    local minPeds = (Config.GangSpawnSettings and Config.GangSpawnSettings.minPeds) or 2
    local maxPeds = (Config.GangSpawnSettings and Config.GangSpawnSettings.maxPeds) or 5
    local numPedsToSpawn = math.random(minPeds, maxPeds)
    
    print("^3INFO:^0 Spawning " .. numPedsToSpawn .. " gang members")
    
    for i = 1, numPedsToSpawn do
        local spawnPoint = gangData.territory[math.random(#gangData.territory)]
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
        
        -- Clean up ped after some time
        Citizen.SetTimeout(120000, function() -- 2 minutes
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end)
    end
end)

RegisterCommand('joingang', function(source, args)
    local gang = args[1]
    if not gang or not Config.Gangs[gang] then
        lib.notify({
            title = 'Error',
            description = 'Invalid gang name. Available: ' .. table.concat(getGangNames(), ', '),
            type = 'error',
            duration = 5000
        })
        return
    end
    TriggerServerEvent('gangWars:playerJoinedGang', gang)
end, false)

-- Helper function to get all gang names
function getGangNames()
    local names = {}
    for name, _ in pairs(Config.Gangs) do
        table.insert(names, name)
    end
    return names
end

-- Add this initialization code for testing
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Wait for everything to load
    print("^2DEBUG:^0 GangWars script initialized")
    print("^2DEBUG:^0 Gang territories loaded:")
    
    if Config and Config.Gangs then
        for gang, data in pairs(Config.Gangs) do
            if data.territory and data.territory[1] then
                print("^2DEBUG:^0 " .. gang .. ": " .. data.territory[1].x .. ", " .. data.territory[1].y .. ", " .. data.territory[1].z)
            else
                print("^1ERROR:^0 No territory data for " .. gang)
            end
        end
    else
        print("^1ERROR:^0 Config.Gangs not loaded properly")
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
