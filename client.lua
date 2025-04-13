local QBCore = exports['qb-core']:GetCoreObject()
Config = Config or { Gangs = {}, PoliceJobs = {} }

-- Debug logging
print("^2DEBUG:^0 Client script loaded")

-- Safe notification function that handles different ox_lib versions
local function SafeNotify(data)
    -- Check if ox_lib is loaded
    if not exports.ox_lib then
        print("^1ERROR:^0 ox_lib is not loaded properly")
        return
    end
    
    -- Try to call notification in a safe manner
    local success, error = pcall(function()
        -- Newer versions of ox_lib use lib.notify(data)
        exports.ox_lib:notify(data)
    end)
    
    if not success then
        print("^1WARNING:^0 Failed to show notification: " .. tostring(error))
        -- Fallback to basic notification
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(data.title .. ": " .. data.description)
        EndTextCommandThefeedPostTicker(true, true)
    end
end

-- Handle notification of gang activity
RegisterNetEvent('gangWars:notifyGangActivity')
AddEventHandler('gangWars:notifyGangActivity', function(message, gangTerritoryPoint)
    if not gangTerritoryPoint then
        print("^1ERROR:^0 No territory data provided for notification")
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - 
                      vector3(gangTerritoryPoint.x, gangTerritoryPoint.y, gangTerritoryPoint.z))
    
    if distance < (Config.NotificationDistance or 500.0) then
        SafeNotify({
            title = 'Gang Activity',
            description = message,
            type = 'error',
            duration = 5000
        })
    end

    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.job and Config.PoliceJobs and Config.PoliceJobs[playerData.job.name] then
        SafeNotify({
            title = 'Police Alert',
            description = 'Gunshots reported in a gang territory!',
            type = 'warning',
            duration = 7000
        })
    end
end)

-- Handle gang fight effects
RegisterNetEvent('gangWars:gangFightStarted')
AddEventHandler('gangWars:gangFightStarted', function(coords)
    if not coords then
        print("^1ERROR:^0 No coordinates provided for gang fight effects")
        return
    end
    
    -- Play gang war sounds
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

-- Check if player is shooting at gang members
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
                    goto continue
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
        
        ::continue::
    end
end)

-- Debug function to directly spawn gang members for a specific gang
function SpawnGangMembersForTesting(gangName)
    if not gangName or not Config.Gangs[gangName] then
        print("^1ERROR:^0 Invalid gang name for testing: " .. tostring(gangName))
        return
    end
    
    local gangData = Config.Gangs[gangName]
    
    -- Directly call the spawn function
    print("^3INFO:^0 Manually spawning gang members for " .. gangName)
    
    -- Send event to self to spawn members
    TriggerEvent('gangwars:spawnGangMembers', gangData)
end

-- Spawn gang members event handler
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
    
    -- Create a relationship group for these gang members
    local relationshipGroup = "GANG_" .. math.random(9999)
    AddRelationshipGroup(relationshipGroup)
    SetRelationshipBetweenGroups(5, GetHashKey(relationshipGroup), GetHashKey("PLAYER"))
    
    for i = 1, numPedsToSpawn do
        -- Make sure we have territory points to use
        if #gangData.territory == 0 then
            print("^1ERROR:^0 No territory points available for gang")
            return
        end
        
        local spawnPoint = gangData.territory[math.random(#gangData.territory)]
        local model = gangData.models[math.random(#gangData.models)]

        RequestModel(GetHashKey(model))
        while not HasModelLoaded(GetHashKey(model)) do
            Citizen.Wait(100)
        end

        local ped = CreatePed(4, GetHashKey(model), spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, true)

        -- Assign Weapons if enabled
        if Config.GangSpawnSettings and Config.GangSpawnSettings.armed then
            GiveWeaponToPed(ped, GetHashKey("WEAPON_MICROSMG"), 255, false, true)
        end
        
        -- Make NPCs Aggressive
        SetPedCombatAttributes(ped, 46, true)  
        SetPedCombatAttributes(ped, 5, true)  
        SetPedAsEnemy(ped, true)
        SetPedRelationshipGroupHash(ped, GetHashKey(relationshipGroup))

        -- Improved NPC Combat Behavior
        Citizen.Wait(math.random(1000, 3000))  
        TaskCombatHatedTargetsAroundPed(ped, 150.0, 0)  
        SetPedCombatMovement(ped, 3)  
        SetPedCombatAbility(ped, 2)  
        SetPedCombatRange(ped, 2)  
        SetPedCombatAttributes(ped, 46, true)  
        SetPedCombatAttributes(ped, 0, true)  
        
        if Config.GangSpawnSettings and Config.GangSpawnSettings.armed then
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_MICROSMG"), true)  
        end
        
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

-- Join gang command
RegisterCommand('joingang', function(source, args)
    local gang = args[1]
    if not gang or not Config.Gangs[gang] then
        local availableGangs = getGangNames()
        SafeNotify({
            title = 'Error',
            description = 'Invalid gang name. Available: ' .. table.concat(availableGangs, ', '),
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
    for name, _ in pairs(Config.Gangs or {}) do
        table.insert(names, name)
    end
    return names
end

-- Add debug command to check gang information
RegisterCommand('checkgangs', function()
    if Config and Config.Gangs then
        local message = "Loaded Gangs: "
        local gangs = getGangNames()
        message = message .. table.concat(gangs, ", ")
        
        SafeNotify({
            title = 'Gang Info',
            description = message,
            type = 'info',
            duration = 5000
        })
    else
        SafeNotify({
            title = 'Error',
            description = 'Config.Gangs is not loaded properly',
            type = 'error',
            duration = 5000
        })
    end
end, false)

-- Add direct spawn testing command
RegisterCommand('spawngang', function(source, args)
    local gangName = args[1]
    if not gangName then
        gangName = 'Ballas' -- Default if no gang specified
    end
    SpawnGangMembersForTesting(gangName)
end, false)

-- Add this initialization code for testing
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Wait for everything to load
    print("^2DEBUG:^0 GangWars script initialized")
    print("^2DEBUG:^0 Gang territories loaded:")
    
    if Config and Config.Gangs then
        for gang, data in pairs(Config.Gangs) do
            if data.territory and #data.territory > 0 then
                print("^2DEBUG:^0 " .. gang .. ": " .. data.territory[1].x .. ", " .. data.territory[1].y .. ", " .. data.territory[1].z)
            else
                print("^1ERROR:^0 No territory data for " .. gang)
            end
        end
    else
        print("^1ERROR:^0 Config.Gangs not loaded properly")
    end
end)
