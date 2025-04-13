local QBCore = exports['qb-core']:GetCoreObject()
Config = Config or { Gangs = {}, PoliceJobs = {} }

-- Debug logging
print("^2DEBUG:^0 Client script loaded")

-- Track spawned gang members for better management
local spawnedGangMembers = {}
local activeBlips = {}
local playerGang = nil
local isInGangTerritory = false
local currentTerritoryGang = nil

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

-- Get player's current gang from QBCore metadata
local function GetPlayerGang()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.metadata and playerData.metadata.gang then
        return playerData.metadata.gang
    end
    return nil
end

-- Refresh player's gang information
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000) -- Wait for metadata to be available
    playerGang = GetPlayerGang()
    print("^3INFO:^0 Player gang loaded: " .. tostring(playerGang))
end)

-- Update gang status when metadata changes
RegisterNetEvent('QBCore:Player:SetPlayerData')
AddEventHandler('QBCore:Player:SetPlayerData', function(PlayerData)
    if PlayerData.metadata and PlayerData.metadata.gang then
        local oldGang = playerGang
        playerGang = PlayerData.metadata.gang
        if oldGang ~= playerGang then
            print("^3INFO:^0 Player gang changed to: " .. tostring(playerGang))
        end
    end
end)

-- Handle notification of gang activity
RegisterNetEvent('gangWars:notifyGangActivity')
AddEventHandler('gangWars:notifyGangActivity', function(message, gangTerritoryPoint, gangName)
    if not gangTerritoryPoint then
        print("^1ERROR:^0 No territory data provided for notification")
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - 
                      vector3(gangTerritoryPoint.x, gangTerritoryPoint.y, gangTerritoryPoint.z))
    
    if distance < (Config.NotificationDistance or 500.0) then
        local alertType = 'error'
        
        -- If player is in the same gang, use different notification type
        if playerGang and gangName and playerGang == gangName then
            alertType = 'inform'
        end
        
        SafeNotify({
            title = 'Gang Activity',
            description = message,
            type = alertType,
            duration = 5000
        })
    end

    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.job and Config.PoliceJobs and Config.PoliceJobs[playerData.job.name] then
        SafeNotify({
            title = 'Police Alert',
            description = 'Reported gang activity in progress!',
            type = 'warning',
            duration = 7000
        })
    end
end)

-- Handle gang fight effects
RegisterNetEvent('gangWars:gangFightStarted')
AddEventHandler('gangWars:gangFightStarted', function(coords, gangName)
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
    
    -- Set color based on gang
    if gangName and Config.Gangs[gangName] and Config.Gangs[gangName].color then
        local color = Config.Gangs[gangName].color
        SetParticleFxLoopedColour(effect, color.r/255, color.g/255, color.b/255, 0)
    else
        SetParticleFxLoopedColour(effect, 1.0, 0.0, 0.0, 0)
    end
    
    Citizen.Wait(5000)
    StopParticleFxLooped(effect, 0)
end)

-- Check if player is shooting at gang members
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)  -- Reduced check frequency for performance
        
        local playerPed = PlayerPedId()
        
        if IsPedShooting(playerPed) then
            local success, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            
            if success and DoesEntityExist(entity) and not IsPedAPlayer(entity) then
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
                                
                                -- Only alert server if player is not in this gang
                                if not playerGang or playerGang ~= gangName then
                                    TriggerServerEvent('gangWars:playerAttackedGang', gangName)
                                end
                                
                                goto continue
                            end
                        end
                    end
                end
            end
        end
        
        ::continue::
    end
end)

-- Spawn gang members with improved targeting
RegisterNetEvent("gangwars:spawnGangMembers")
AddEventHandler("gangwars:spawnGangMembers", function(gangData, spawnNearPlayer)
    if not gangData or not gangData.territory or not gangData.models then
        print("^1ERROR:^0 Invalid gang data provided for spawning members")
        return
    end
    
    local minPeds = (Config.GangSpawnSettings and Config.GangSpawnSettings.minPeds) or 2
    local maxPeds = (Config.GangSpawnSettings and Config.GangSpawnSettings.maxPeds) or 5
    local numPedsToSpawn = math.random(minPeds, maxPeds)
    
    -- Clean up any existing gang members for this gang
    CleanupGangMembers(gangData.name)
    
    print("^3INFO:^0 Spawning " .. numPedsToSpawn .. " gang members for " .. gangData.name)
    
    -- Create a relationship group for these gang members
    local relationshipGroup = "GANG_" .. gangData.name
    AddRelationshipGroup(relationshipGroup)
    
    -- Only set player as enemy if not in this gang
    if not playerGang or playerGang ~= gangData.name then
        SetRelationshipBetweenGroups(5, GetHashKey(relationshipGroup), GetHashKey("PLAYER"))
    else
        -- Friendly to player if in the same gang
        SetRelationshipBetweenGroups(0, GetHashKey(relationshipGroup), GetHashKey("PLAYER"))
    end
    
    -- Set relationships with other gangs (all other gangs are enemies)
    for otherGangName, _ in pairs(Config.Gangs) do
        if otherGangName ~= gangData.name then
            local otherRelGroup = "GANG_" .. otherGangName
            SetRelationshipBetweenGroups(5, GetHashKey(relationshipGroup), GetHashKey(otherRelGroup))
        end
    end
    
    -- Choose spawn locations
    local spawnPoints = {}
    if spawnNearPlayer then
        -- Spawn near player
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Generate points around player
        for i = 1, numPedsToSpawn do
            local angle = math.rad(math.random(0, 359))
            local distance = math.random(20, 50)
            local x = playerCoords.x + math.cos(angle) * distance
            local y = playerCoords.y + math.sin(angle) * distance
            
            -- Find ground Z
            local groundZ = 0
            local ground, z = GetGroundZFor_3dCoord(x, y, 1000.0, 0)
            if ground then groundZ = z end
            
            table.insert(spawnPoints, {x = x, y = y, z = groundZ})
        end
    else
        -- Use territory points
        if #gangData.territory == 0 then
            print("^1ERROR:^0 No territory points available for gang")
            return
        end
        
        -- Select random territory point
        local basePoint = gangData.territory[math.random(#gangData.territory)]
        
        -- Generate points around territory
        for i = 1, numPedsToSpawn do
            local angle = math.rad(math.random(0, 359))
            local distance = math.random(5, 20)
            local x = basePoint.x + math.cos(angle) * distance
            local y = basePoint.y + math.sin(angle) * distance
            
            -- Find ground Z
            local groundZ = 0
            local ground, z = GetGroundZFor_3dCoord(x, y, 1000.0, 0)
            if ground then groundZ = z end
            
            table.insert(spawnPoints, {x = x, y = y, z = groundZ})
        end
    end
    
    -- Spawn peds at selected locations
    for i = 1, numPedsToSpawn do
        local spawnPoint = spawnPoints[i]
        local model = gangData.models[math.random(#gangData.models)]

        RequestModel(GetHashKey(model))
        while not HasModelLoaded(GetHashKey(model)) do
            Citizen.Wait(10)
        end

        local ped = CreatePed(4, GetHashKey(model), spawnPoint.x, spawnPoint.y, spawnPoint.z, math.random(0, 359) + 0.0, true, true)
        
        -- Track this ped for cleanup
        table.insert(spawnedGangMembers, {ped = ped, gang = gangData.name, time = GetGameTimer()})

        -- Set ped appearance and behavior
        SetPedDefaultComponentVariation(ped)
        SetPedRandomProps(ped)
        
        -- Assign Weapons if enabled
        if Config.GangSpawnSettings and Config.GangSpawnSettings.armed then
            -- Assign weapon based on gang preference if defined
            local weapon = "WEAPON_MICROSMG"
            if gangData.weapons and #gangData.weapons > 0 then
                weapon = gangData.weapons[math.random(#gangData.weapons)]
            end
            GiveWeaponToPed(ped, GetHashKey(weapon), 255, false, true)
            SetCurrentPedWeapon(ped, GetHashKey(weapon), true)
        end
        
        -- Set ped behavior
        SetPedRelationshipGroupHash(ped, GetHashKey(relationshipGroup))
        SetPedAsEnemy(ped, false) -- We'll control who they attack via relationship groups
        
        -- Make them stay in their area
        TaskWanderInArea(ped, spawnPoint.x, spawnPoint.y, spawnPoint.z, 20.0, 1.0, 1.0)
        
        -- Configure combat behavior
        SetPedCombatAttributes(ped, 46, true)  -- BF_CanFightArmedPedsWhenNotArmed
        SetPedCombatAttributes(ped, 5, true)   -- BF_AlwaysFight
        SetPedCombatAttributes(ped, 0, true)   -- BF_CanUseVehicles
        SetPedCombatMovement(ped, 3)           -- Move freely during combat
        SetPedCombatAbility(ped, 2)            -- Professional ability
        SetPedCombatRange(ped, 2)              -- Far
        SetPedAccuracy(ped, 60)                -- 60% accuracy
        SetPedSeeingRange(ped, 100.0)
        SetPedHearingRange(ped, 80.0)
        SetPedAlertness(ped, 3)
        
        -- Make them acknowledge threats
        TaskSetBlockingOfNonTemporaryEvents(ped, true)
        
        -- Give gang members matching clothing if specified
        if gangData.clothing then
            for component, data in pairs(gangData.clothing) do
                SetPedComponentVariation(ped, component, data.drawable, data.texture, data.palette or 0)
            end
        end
        
        SetModelAsNoLongerNeeded(GetHashKey(model))
    end
    
    -- Schedule cleanup after some time
    Citizen.SetTimeout(Config.GangSpawnSettings.despawnTime or 300000, function() -- Default 5 minutes
        CleanupGangMembers(gangData.name)
    end)
end)

-- Clean up gang members for a specific gang
function CleanupGangMembers(gangName)
    local newList = {}
    for _, data in ipairs(spawnedGangMembers) do
        if data.gang == gangName then
            if DoesEntityExist(data.ped) then
                DeleteEntity(data.ped)
            end
        else
            table.insert(newList, data)
        end
    end
    spawnedGangMembers = newList
end

-- Create map blips for gang territories
function CreateGangBlips()
    -- Clean up existing blips
    for _, blip in ipairs(activeBlips) do
        RemoveBlip(blip)
    end
    activeBlips = {}
    
    -- Create new blips for each gang territory
    if Config and Config.Gangs then
        for gangName, gangData in pairs(Config.Gangs) do
            if gangData.territory and #gangData.territory > 0 then
                for _, territory in ipairs(gangData.territory) do
                    local blip = AddBlipForRadius(territory.x, territory.y, territory.z, 100.0)
                    
                    -- Set blip appearance based on gang color or default
                    if gangData.color then
                        SetBlipColour(blip, gangData.color.id or 1)
                        SetBlipAlpha(blip, gangData.color.alpha or 128)
                    else
                        SetBlipColour(blip, 1) -- Red default
                        SetBlipAlpha(blip, 128)
                    end
                    
                    -- Add central marker blip
                    local centerBlip = AddBlipForCoord(territory.x, territory.y, territory.z)
                    SetBlipSprite(centerBlip, 6) -- Territory sprite
                    SetBlipDisplay(centerBlip, 4)
                    SetBlipScale(centerBlip, 0.8)
                    SetBlipAsShortRange(centerBlip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString(gangName .. " Territory")
                    EndTextCommandSetBlipName(centerBlip)
                    
                    if gangData.color then
                        SetBlipColour(centerBlip, gangData.color.id or 1)
                    else
                        SetBlipColour(centerBlip, 1) -- Red default
                    end
                    
                    table.insert(activeBlips, blip)
                    table.insert(activeBlips, centerBlip)
                end
            end
        end
    end
end

-- Check if player is in a gang territory
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Check every second
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local inTerritory = false
        local territoryGang = nil
        local closestDistance = 9999.0
        
        if Config and Config.Gangs then
            for gangName, gangData in pairs(Config.Gangs) do
                if gangData.territory and #gangData.territory > 0 then
                    for _, territory in ipairs(gangData.territory) do
                        local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - 
                                           vector3(territory.x, territory.y, territory.z))
                        
                        if distance < (Config.TerritoryRadius or 100.0) and distance < closestDistance then
                            inTerritory = true
                            territoryGang = gangName
                            closestDistance = distance
                        end
                    end
                end
            end
        end
        
        -- Territory status changed
        if inTerritory ~= isInGangTerritory or territoryGang ~= currentTerritoryGang then
            isInGangTerritory = inTerritory
            
            if inTerritory then
                -- Entering territory
                currentTerritoryGang = territoryGang
                
                local territoryStatus = "hostile"
                if playerGang and playerGang == territoryGang then
                    territoryStatus = "friendly"
                end
                
                -- Notify player
                SafeNotify({
                    title = 'Gang Territory',
                    description = 'You\'ve entered ' .. territoryGang .. ' territory',
                    type = territoryStatus == "friendly" ? 'inform' : 'warning',
                    duration = 5000
                })
                
                -- Request ambient gang presence if enabled
                if Config.EnableAmbientGangs then
                    TriggerServerEvent('gangWars:requestAmbientGangs', {
                        x = playerCoords.x,
                        y = playerCoords.y,
                        z = playerCoords.z
                    }, territoryGang)
                end
                
            else
                -- Leaving territory
                if currentTerritoryGang then
                    SafeNotify({
                        title = 'Gang Territory',
                        description = 'You\'ve left ' .. currentTerritoryGang .. ' territory',
                        type = 'inform',
                        duration = 3000
                    })
                    currentTerritoryGang = nil
                end
            end
        end
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

-- Leave gang command
RegisterCommand('leavegang', function()
    if playerGang then
        TriggerServerEvent('gangWars:playerLeftGang', playerGang)
    else
        SafeNotify({
            title = 'Error',
            description = 'You are not in a gang',
            type = 'error',
            duration = 3000
        })
    end
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
        
        -- Add player's gang status
        if playerGang then
            message = message .. "\nYour gang: " .. playerGang
        else
            message = message .. "\nYou are not in a gang"
        end
        
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
    
    if not Config.Gangs[gangName] then
        SafeNotify({
            title = 'Error',
            description = 'Invalid gang name: ' .. gangName,
            type = 'error',
            duration = 3000
        })
        return
    end
    
    -- Add name field to gangData for tracking
    local gangData = Config.Gangs[gangName]
    gangData.name = gangName
    
    -- Spawn near player
    TriggerEvent('gangwars:spawnGangMembers', gangData, true)
end, false)

-- Initialize blips when resource starts
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Wait for everything to load
    print("^2DEBUG:^0 GangWars script initialized")
    
    CreateGangBlips() -- Create territory blips
    
    -- Create visible props and markers for gang territories
    if Config and Config.Gangs then
        for gangName, gangData in pairs(Config.Gangs) do
            if gangData.territory and #gangData.territory > 0 then
                for _, territory in ipairs(gangData.territory) do
                    print("^2DEBUG:^0 Creating visual indicators for " .. gangName .. " at " .. territory.x .. ", " .. territory.y .. ", " .. territory.z)
                    
                    -- Create persistent marker
                    Citizen.CreateThread(function()
                        local color = gangData.color or {r = 255, g = 0, b = 0}
                        
                        while true do
                            Citizen.Wait(0)
                            
                            local playerCoords = GetEntityCoords(PlayerPedId())
                            local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - 
                                              vector3(territory.x, territory.y, territory.z))
                            
                            -- Only draw when player is close (performance optimization)
                            if distance < 100.0 then
                                -- Draw marker
                                DrawMarker(
                                    1, -- Type: cylinder
                                    territory.x, territory.y, territory.z - 1.0,
                                    0.0, 0.0, 0.0, -- Direction
                                    0.0, 0.0, 0.0, -- Rotation
                                    4.0, 4.0, 1.0, -- Scale
                                    color.r, color.g, color.b, 100, -- Color with alpha
                                    false, false, 2, false, nil, nil, false -- Additional settings
                                )
                            elseif distance > 200.0 then
                                -- Performance optimization - sleep longer when far away
                                Citizen.Wait(1000)
                            end
                        end
                    end)
                    
                    -- Place gang props if configured
                    if gangData.props and #gangData.props > 0 then
                        -- Get a random prop from the gang's list
                        local propModel = gangData.props[math.random(#gangData.props)]
                        
                        -- Load and place prop
                        RequestModel(GetHashKey(propModel))
                        while not HasModelLoaded(GetHashKey(propModel)) do
                            Citizen.Wait(10)
                        end
                        
                        local prop = CreateObject(
                            GetHashKey(propModel), 
                            territory.x, territory.y, territory.z, 
                            false, false, false
                        )
                        PlaceObjectOnGroundProperly(prop)
                        FreezeEntityPosition(prop, true)
                        SetEntityAsMissionEntity(prop, true, true)
                        SetModelAsNoLongerNeeded(GetHashKey(propModel))
                    end
                end
            end
        end
    end
    
    -- Clean up old gang members periodically
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) -- Check every minute
            
            local currentTime = GetGameTimer()
            local newList = {}
            
            for _, data in ipairs(spawnedGangMembers) do
                local timeAlive = currentTime - data.time
                
                -- Remove gang members after 10 minutes regardless
                if timeAlive > 600000 then
                    if DoesEntityExist(data.ped) then
                        DeleteEntity(data.ped)
                    end
                else
                    table.insert(newList, data)
                end
            end
            
            spawnedGangMembers = newList
        end
    end)
end)
