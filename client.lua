-- ============================================
-- GANG AMBIENT AI - Client
-- Handles NPC spawning, combat AI, and throttling
-- ============================================

local QBCore = exports['qb-core']:GetCoreObject()

-- State tracking
local spawnedNPCs = {}          -- All spawned NPCs { entity, gangName, spawnTime }
local playerGang = nil          -- Player's gang from rcore
local playerRelationshipHash = nil
local nearbyTerritories = {}    -- Cached nearby territory data
local lastSpawnTime = {}        -- Cooldown tracking per territory
local inCombat = false          -- Is player in combat

-- ============================================
-- TIERED PROXIMITY THROTTLING
-- ============================================

local currentTickRate = Config.AmbientSpawning.tickRates.background

local function GetOptimalTickRate()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Check if player is in combat
    if IsPedInMeleeCombat(ped) or IsPedShooting(ped) then
        inCombat = true
        return Config.AmbientSpawning.tickRates.combat
    end

    -- Check distance to nearest gang NPC
    local nearestNPCDist = 999.0
    for _, npcData in pairs(spawnedNPCs) do
        if DoesEntityExist(npcData.entity) then
            local npcCoords = GetEntityCoords(npcData.entity)
            local dist = #(coords - npcCoords)
            if dist < nearestNPCDist then
                nearestNPCDist = dist
            end
        end
    end

    inCombat = false

    if nearestNPCDist < 20.0 then
        return Config.AmbientSpawning.tickRates.combat
    elseif nearestNPCDist < 50.0 then
        return Config.AmbientSpawning.tickRates.nearby
    elseif nearestNPCDist < 150.0 then
        return Config.AmbientSpawning.tickRates.distant
    end

    return Config.AmbientSpawning.tickRates.background
end

-- ============================================
-- PLAYER RELATIONSHIP SYNC
-- ============================================

RegisterNetEvent('gangai:client:setPlayerRelationship', function(gang, hash)
    playerGang = gang
    playerRelationshipHash = hash

    if gang then
        local ped = PlayerPedId()
        SetPedRelationshipGroupHash(ped, hash)

        if Config.Debug then
            print('[GangAI] Player relationship set to gang: ' .. gang)
        end
    end
end)

-- Sync relationship on spawn/load
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    TriggerServerEvent('gangai:server:syncPlayerRelationship')
end)

AddEventHandler('QBCore:Client:OnGangUpdate', function(gang)
    TriggerServerEvent('gangai:server:syncPlayerRelationship')
end)

-- ============================================
-- ADVANCED COMBAT AI
-- ============================================

local function ApplyCombatAI(ped, gangData)
    local style = Config.CombatAI.styles[gangData.combatStyle] or Config.CombatAI.styles.balanced

    -- Base combat attributes
    SetPedCombatMovement(ped, style.combatMovement)
    SetPedCombatRange(ped, style.combatRange)
    SetPedCombatAbility(ped, 2) -- Professional

    -- Accuracy
    local accuracy = math.random(Config.CombatAI.accuracy.min, Config.CombatAI.accuracy.max)
    SetPedAccuracy(ped, accuracy)

    -- Perception
    SetPedSeeingRange(ped, 100.0)
    SetPedHearingRange(ped, 80.0)
    SetPedAlertness(ped, 3)

    -- Combat attributes
    SetPedCombatAttributes(ped, 46, true)  -- Can fight armed peds on foot
    SetPedCombatAttributes(ped, 5, true)   -- Can attack you
    SetPedCombatAttributes(ped, 0, true)   -- Can use cover

    -- Cover system
    if Config.CombatAI.enableCoverSystem and style.useCover then
        SetPedCombatAttributes(ped, 1, true)  -- Will use cover
        SetPedCombatAttributes(ped, 2, true)  -- Can do drivebys
    end

    -- Flee behavior
    if Config.CombatAI.enableRetreat and style.fleeHealthThreshold > 0 then
        SetPedFleeAttributes(ped, 0, false) -- Don't flee immediately
        -- Monitor health for retreat
        CreateThread(function()
            while DoesEntityExist(ped) and not IsEntityDead(ped) do
                Wait(1000)
                local health = GetEntityHealth(ped)
                local maxHealth = GetEntityMaxHealth(ped)
                local healthPercent = (health / maxHealth) * 100

                if healthPercent <= style.fleeHealthThreshold then
                    TaskSmartFleePed(ped, PlayerPedId(), 100.0, -1, false, false)
                    break
                end
            end
        end)
    end
end

-- Recruitment system - NPC calls for backup
local function TriggerRecruitment(ped, gangName)
    if not Config.CombatAI.enableRecruitment then return end

    local gangData = Config.GangData[gangName]
    if not gangData then return end

    local style = Config.CombatAI.styles[gangData.combatStyle]
    if not style or not style.recruitNearby then return end

    local pedCoords = GetEntityCoords(ped)
    local recruits = 0

    -- Find nearby peds to recruit
    for _, npcData in pairs(spawnedNPCs) do
        if npcData.gangName == gangName and DoesEntityExist(npcData.entity) and npcData.entity ~= ped then
            local dist = #(pedCoords - GetEntityCoords(npcData.entity))

            if dist < Config.CombatAI.recruitmentRadius then
                -- Make this NPC join the fight
                if not IsPedInCombat(npcData.entity) then
                    TaskCombatHatedTargetsAroundPed(npcData.entity, 100.0, 0)
                    recruits = recruits + 1

                    if recruits >= Config.CombatAI.maxRecruits then
                        break
                    end
                end
            end
        end
    end

    if Config.Debug and recruits > 0 then
        print('[GangAI] Recruited ' .. recruits .. ' nearby ' .. gangName .. ' NPCs')
    end
end

-- ============================================
-- NPC SPAWNING
-- ============================================

local function SpawnGangNPC(gangName, gangData, coords, relationshipHash)
    -- Select random model
    local modelName = gangData.models[math.random(#gangData.models)]
    local modelHash = GetHashKey(modelName)

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end

    if not HasModelLoaded(modelHash) then
        if Config.Debug then
            print('[GangAI] Failed to load model: ' .. modelName)
        end
        return nil
    end

    -- Random offset from center
    local angle = math.random() * 2 * math.pi
    local dist = math.random() * Config.AmbientSpawning.spawnRadius * 0.5
    local spawnX = coords.x + dist * math.cos(angle)
    local spawnY = coords.y + dist * math.sin(angle)
    local spawnZ = coords.z

    -- Get ground Z
    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 10.0, false)
    if foundGround then
        spawnZ = groundZ
    end

    local ped = CreatePed(4, modelHash, spawnX, spawnY, spawnZ, math.random(0, 360) + 0.0, true, true)

    if not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end

    -- Set relationship group
    SetPedRelationshipGroupHash(ped, relationshipHash)

    -- Give weapon
    if gangData.weapons and #gangData.weapons > 0 then
        local weapon = gangData.weapons[math.random(#gangData.weapons)]
        GiveWeaponToPed(ped, GetHashKey(weapon), 255, false, true)
    end

    -- Apply combat AI
    ApplyCombatAI(ped, gangData)

    -- Apply scenario if peaceful
    if gangData.scenarios and #gangData.scenarios > 0 and not inCombat then
        local scenario = gangData.scenarios[math.random(#gangData.scenarios)]
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end

    -- Set as enemy to player (if different gang)
    if playerGang ~= gangName then
        SetPedAsEnemy(ped, true)
    end

    SetModelAsNoLongerNeeded(modelHash)

    -- Track this NPC
    local npcData = {
        entity = ped,
        gangName = gangName,
        spawnTime = GetGameTimer(),
        coords = vector3(spawnX, spawnY, spawnZ)
    }
    spawnedNPCs[ped] = npcData

    -- Despawn timer
    SetTimeout(Config.AmbientSpawning.despawnDelay, function()
        if DoesEntityExist(ped) and not IsPedInCombat(ped) then
            DeleteEntity(ped)
            spawnedNPCs[ped] = nil
            TriggerServerEvent('gangai:server:npcDespawned', 1)
        end
    end)

    return ped
end

-- Spawn ambient NPCs event
RegisterNetEvent('gangai:client:spawnAmbientNPCs', function(data)
    if not data or not data.gangData then return end

    for i = 1, data.count do
        local ped = SpawnGangNPC(data.gangName, data.gangData, data.coords, data.relationshipHash)
        if ped then
            Wait(100) -- Stagger spawns
        end
    end

    if Config.Debug then
        print('[GangAI] Spawned ' .. data.count .. ' ' .. data.gangName .. ' NPCs')
    end
end)

-- Spawn war reinforcements
RegisterNetEvent('gangai:client:spawnWarReinforcements', function(data)
    if not data or not data.gangData then return end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local dist = #(playerCoords - vector3(data.coords.x, data.coords.y, data.coords.z))

    -- Only spawn if player is nearby
    if dist > 300.0 then return end

    for i = 1, data.count do
        local ped = SpawnGangNPC(data.gangName, data.gangData, data.coords, data.relationshipHash)
        if ped then
            -- War NPCs are immediately aggressive
            TaskCombatHatedTargetsAroundPed(ped, 150.0, 0)
            Wait(100)
        end
    end

    if Config.Debug then
        local role = data.isDefender and 'defenders' or 'attackers'
        print('[GangAI] Spawned ' .. data.count .. ' ' .. data.gangName .. ' ' .. role)
    end
end)

-- Clear all NPCs
RegisterNetEvent('gangai:client:clearAllNPCs', function()
    local count = 0
    for ped, _ in pairs(spawnedNPCs) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
            count = count + 1
        end
    end
    spawnedNPCs = {}

    if Config.Debug then
        print('[GangAI] Cleared ' .. count .. ' NPCs')
    end
end)

-- ============================================
-- COMBAT DETECTION
-- ============================================

CreateThread(function()
    while true do
        local tickRate = GetOptimalTickRate()
        Wait(tickRate)

        local ped = PlayerPedId()

        -- Check if player is shooting at gang NPCs
        if IsPedShooting(ped) then
            local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())

            if DoesEntityExist(entity) and not IsPedAPlayer(entity) then
                -- Check if this is one of our spawned NPCs
                local npcData = spawnedNPCs[entity]
                if npcData then
                    -- Trigger recruitment for that gang
                    TriggerRecruitment(entity, npcData.gangName)

                    -- Notify police
                    local coords = GetEntityCoords(entity)
                    TriggerServerEvent('gangai:server:notifyPolice', 'Shots fired in gang territory!', coords)
                end
            end
        end
    end
end)

-- ============================================
-- AMBIENT SPAWNING LOOP
-- Uses rcore territories when available
-- ============================================

CreateThread(function()
    Wait(5000) -- Initial delay

    while true do
        local tickRate = GetOptimalTickRate()
        Wait(tickRate)

        if not Config.AmbientSpawning.enabled then
            Wait(5000)
            goto continue
        end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        -- Try to get territories from rcore
        local territories = {}

        local rcoreAvailable = GetResourceState(Config.Integration.rcoreResource) == 'started'
        if rcoreAvailable then
            local success, zones = pcall(function()
                return exports[Config.Integration.rcoreResource]:GetNearbyZones(coords, Config.AmbientSpawning.playerTriggerDistance)
            end)

            if success and zones then
                for _, zone in ipairs(zones) do
                    if zone.owner and zone.owner ~= 'none' then
                        territories[#territories + 1] = {
                            gangName = zone.owner:lower(),
                            coords = zone.coords,
                            zoneId = zone.id
                        }
                    end
                end
            end
        end

        -- Process each territory
        for _, territory in ipairs(territories) do
            local gangData = Config.GangData[territory.gangName]
            if gangData then
                -- Check cooldown
                local lastSpawn = lastSpawnTime[territory.zoneId] or 0
                if GetGameTimer() - lastSpawn > Config.AmbientSpawning.respawnCooldown then

                    -- Determine heat level
                    local heatLevel = 'peaceful'
                    if inCombat then
                        heatLevel = 'wartime'
                    end

                    -- Request spawn from server
                    TriggerServerEvent('gangai:server:requestAmbientSpawn', territory.gangName, territory.coords, heatLevel)
                    lastSpawnTime[territory.zoneId] = GetGameTimer()
                end
            end
        end

        ::continue::
    end
end)

-- ============================================
-- CLEANUP LOOP
-- Despawn distant NPCs
-- ============================================

CreateThread(function()
    while true do
        Wait(Config.CleanupInterval or 60000)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local cleaned = 0

        for npcPed, npcData in pairs(spawnedNPCs) do
            if DoesEntityExist(npcPed) then
                local npcCoords = GetEntityCoords(npcPed)
                local dist = #(coords - npcCoords)

                -- Despawn if too far and not in combat
                if dist > Config.AmbientSpawning.despawnDistance and not IsPedInCombat(npcPed) then
                    DeleteEntity(npcPed)
                    spawnedNPCs[npcPed] = nil
                    cleaned = cleaned + 1
                end
            else
                -- Entity no longer exists, clean up tracking
                spawnedNPCs[npcPed] = nil
                cleaned = cleaned + 1
            end
        end

        if cleaned > 0 then
            TriggerServerEvent('gangai:server:npcDespawned', cleaned)
            if Config.Debug then
                print('[GangAI] Cleaned up ' .. cleaned .. ' distant/dead NPCs')
            end
        end
    end
end)

-- ============================================
-- INITIALIZATION
-- ============================================

CreateThread(function()
    Wait(3000)

    -- Sync player relationship
    TriggerServerEvent('gangai:server:syncPlayerRelationship')

    if Config.Debug then
        print('[GangAI] Client initialized')
        print('[GangAI] Tick rates: combat=' .. Config.AmbientSpawning.tickRates.combat ..
              'ms, nearby=' .. Config.AmbientSpawning.tickRates.nearby ..
              'ms, distant=' .. Config.AmbientSpawning.tickRates.distant ..
              'ms, background=' .. Config.AmbientSpawning.tickRates.background .. 'ms')
    end
end)
