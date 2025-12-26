-- ============================================
-- GANG AMBIENT AI - Server
-- Augments rcore_gangs with ambient NPC life
-- ============================================

local QBCore = exports['qb-core']:GetCoreObject()

-- State tracking
local activeWars = {}           -- Track active territory wars
local territoryCache = {}       -- Cache of rcore territory data
local spawnedNPCCount = 0       -- Track total spawned NPCs

-- ============================================
-- RCORE_GANGS INTEGRATION
-- ============================================

-- Check if rcore_gangs is running
local function IsRcoreAvailable()
    return GetResourceState(Config.Integration.rcoreResource) == 'started'
end

-- Get player's gang from rcore_gangs
local function GetPlayerGang(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    -- QBCore stores gang in PlayerData.gang
    local gangData = Player.PlayerData.gang
    if gangData and gangData.name and gangData.name ~= 'none' then
        return gangData.name:lower()
    end

    return nil
end

-- Get territory owner from rcore (if available)
local function GetTerritoryOwner(zoneId)
    if not IsRcoreAvailable() then return nil end

    -- Try to get territory data from rcore exports
    local success, result = pcall(function()
        return exports[Config.Integration.rcoreResource]:GetZoneOwner(zoneId)
    end)

    if success and result then
        return result:lower()
    end

    return nil
end

-- Get all rcore territories
local function SyncRcoreTerritories()
    if not IsRcoreAvailable() then return end

    local success, zones = pcall(function()
        return exports[Config.Integration.rcoreResource]:GetAllZones()
    end)

    if success and zones then
        territoryCache = zones
        if Config.Debug then
            print('^2[GangAI] Synced ' .. #zones .. ' territories from rcore_gangs')
        end
    end
end

-- ============================================
-- RELATIONSHIP MANAGEMENT
-- ============================================

-- Get relationship hash for a gang
local gangRelationshipGroups = {}

local function GetOrCreateGangRelationship(gangName)
    if gangRelationshipGroups[gangName] then
        return gangRelationshipGroups[gangName]
    end

    -- Create unique relationship group for this gang
    local groupName = 'GANG_' .. string.upper(gangName)
    local groupHash = GetHashKey(groupName)

    AddRelationshipGroup(groupName)
    gangRelationshipGroups[gangName] = groupHash

    return groupHash
end

-- Setup relationships between gang groups
local function SetupGangRelationships()
    local gangs = {}
    for gangName, _ in pairs(Config.GangData) do
        gangs[#gangs + 1] = gangName
        GetOrCreateGangRelationship(gangName)
    end

    -- Set up relationships between all gangs
    for i, gang1 in ipairs(gangs) do
        local hash1 = gangRelationshipGroups[gang1]

        for j, gang2 in ipairs(gangs) do
            local hash2 = gangRelationshipGroups[gang2]

            if gang1 == gang2 then
                -- Same gang = respect
                SetRelationshipBetweenGroups(Config.Relationships.defaultToSameGang, hash1, hash2)
            else
                -- Different gangs = hate
                SetRelationshipBetweenGroups(Config.Relationships.defaultToRivals, hash1, hash2)
            end
        end

        -- Relationship to police
        SetRelationshipBetweenGroups(Config.Relationships.defaultToPolice, hash1, GetHashKey('COP'))
    end

    if Config.Debug then
        print('^2[GangAI] Relationship groups initialized for ' .. #gangs .. ' gangs')
    end
end

-- ============================================
-- PLAYER GANG SYNC
-- Sync player relationship based on their rcore gang
-- ============================================

RegisterNetEvent('gangai:server:syncPlayerRelationship', function()
    local src = source
    local playerGang = GetPlayerGang(src)

    if playerGang and gangRelationshipGroups[playerGang] then
        TriggerClientEvent('gangai:client:setPlayerRelationship', src, playerGang, gangRelationshipGroups[playerGang])
    else
        TriggerClientEvent('gangai:client:setPlayerRelationship', src, nil, nil)
    end
end)

-- ============================================
-- AMBIENT SPAWNING
-- ============================================

-- Request ambient spawn for a territory
RegisterNetEvent('gangai:server:requestAmbientSpawn', function(gangName, coords, heatLevel)
    local src = source

    -- Validate gang exists
    gangName = gangName:lower()
    local gangData = Config.GangData[gangName]
    if not gangData then
        if Config.Debug then
            print('^1[GangAI] Unknown gang requested for spawn: ' .. gangName)
        end
        return
    end

    -- Check global NPC limit
    if spawnedNPCCount >= Config.MaxSpawnedNPCs then
        if Config.Debug then
            print('^3[GangAI] NPC limit reached, skipping spawn')
        end
        return
    end

    -- Determine spawn count based on heat level
    local density = Config.AmbientSpawning.spawnDensity[heatLevel] or Config.AmbientSpawning.spawnDensity.peaceful
    local spawnCount = math.random(density.min, density.max)

    -- Clamp to not exceed limit
    spawnCount = math.min(spawnCount, Config.MaxSpawnedNPCs - spawnedNPCCount)

    if spawnCount > 0 then
        local relationshipGroup = GetOrCreateGangRelationship(gangName)

        TriggerClientEvent('gangai:client:spawnAmbientNPCs', src, {
            gangName = gangName,
            gangData = gangData,
            coords = coords,
            count = spawnCount,
            relationshipHash = relationshipGroup
        })

        spawnedNPCCount = spawnedNPCCount + spawnCount

        if Config.Debug then
            print('^2[GangAI] Spawning ' .. spawnCount .. ' ' .. gangName .. ' NPCs (total: ' .. spawnedNPCCount .. ')')
        end
    end
end)

-- NPC despawned callback
RegisterNetEvent('gangai:server:npcDespawned', function(count)
    spawnedNPCCount = math.max(0, spawnedNPCCount - (count or 1))
end)

-- ============================================
-- WAR REINFORCEMENTS
-- Triggered when rcore starts a territory war
-- ============================================

-- Listen for rcore war events
RegisterNetEvent('rcore_gangs:server:warStarted', function(zoneId, attackingGang, defendingGang)
    if not Config.WarReinforcements.enabled then return end

    local warId = zoneId .. '_' .. os.time()
    activeWars[warId] = {
        zone = zoneId,
        attacker = attackingGang:lower(),
        defender = defendingGang:lower(),
        startTime = GetGameTimer()
    }

    if Config.Debug then
        print('^3[GangAI] War started: ' .. attackingGang .. ' vs ' .. defendingGang .. ' at zone ' .. zoneId)
    end

    -- Get zone coords from cache or rcore
    local zoneCoords = nil
    if territoryCache[zoneId] then
        zoneCoords = territoryCache[zoneId].coords
    end

    if not zoneCoords then
        if Config.Debug then
            print('^1[GangAI] Could not get zone coordinates for reinforcements')
        end
        return
    end

    -- Spawn defender waves
    for _, wave in ipairs(Config.WarReinforcements.waves) do
        SetTimeout(wave.delay, function()
            if activeWars[warId] then -- War still active
                TriggerClientEvent('gangai:client:spawnWarReinforcements', -1, {
                    gangName = defendingGang:lower(),
                    gangData = Config.GangData[defendingGang:lower()],
                    coords = zoneCoords,
                    count = wave.count,
                    isDefender = true,
                    relationshipHash = GetOrCreateGangRelationship(defendingGang:lower())
                })
            end
        end)
    end

    -- Spawn attacker waves
    if Config.WarReinforcements.spawnAttackers then
        for _, wave in ipairs(Config.WarReinforcements.attackerWaves) do
            SetTimeout(wave.delay, function()
                if activeWars[warId] then
                    TriggerClientEvent('gangai:client:spawnWarReinforcements', -1, {
                        gangName = attackingGang:lower(),
                        gangData = Config.GangData[attackingGang:lower()],
                        coords = zoneCoords,
                        count = wave.count,
                        isDefender = false,
                        relationshipHash = GetOrCreateGangRelationship(attackingGang:lower())
                    })
                end
            end)
        end
    end
end)

-- Listen for rcore war end events
RegisterNetEvent('rcore_gangs:server:warEnded', function(zoneId, winningGang)
    -- Find and remove the war
    for warId, war in pairs(activeWars) do
        if war.zone == zoneId then
            activeWars[warId] = nil

            if Config.Debug then
                print('^2[GangAI] War ended at zone ' .. zoneId .. '. Winner: ' .. tostring(winningGang))
            end
            break
        end
    end
end)

-- ============================================
-- POLICE NOTIFICATIONS
-- ============================================

RegisterNetEvent('gangai:server:notifyPolice', function(message, coords)
    local players = QBCore.Functions.GetQBPlayers()

    for _, Player in pairs(players) do
        if Player and Config.PoliceJobs[Player.PlayerData.job.name] then
            local playerCoords = GetEntityCoords(GetPlayerPed(Player.PlayerData.source))
            local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(coords.x, coords.y, coords.z))

            if distance < Config.PoliceNotifyDistance then
                TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
                    title = 'Dispatch',
                    description = message,
                    type = 'warning',
                    duration = 7000
                })
            end
        end
    end
end)

-- ============================================
-- ADMIN COMMANDS
-- ============================================

QBCore.Commands.Add('gangai', 'Gang AI admin commands', {{ name = 'action', help = 'status/spawn/clear' }, { name = 'gang', help = 'Gang name (optional)' }}, false, function(source, args)
    local action = args[1]

    if action == 'status' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Gang AI Status',
            description = 'Active NPCs: ' .. spawnedNPCCount .. '/' .. Config.MaxSpawnedNPCs .. '\nActive Wars: ' .. tableCount(activeWars),
            type = 'info',
            duration = 5000
        })
    elseif action == 'spawn' and args[2] then
        local gangName = args[2]:lower()
        if Config.GangData[gangName] then
            local ped = GetPlayerPed(source)
            local coords = GetEntityCoords(ped)
            TriggerEvent('gangai:server:requestAmbientSpawn', gangName, coords, 'wartime')
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Gang AI',
                description = 'Spawning ' .. gangName .. ' NPCs',
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'Unknown gang: ' .. args[2],
                type = 'error'
            })
        end
    elseif action == 'clear' then
        TriggerClientEvent('gangai:client:clearAllNPCs', -1)
        spawnedNPCCount = 0
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Gang AI',
            description = 'All gang NPCs cleared',
            type = 'success'
        })
    end
end, 'admin')

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ============================================
-- INITIALIZATION
-- ============================================

CreateThread(function()
    Wait(2000) -- Wait for resources to load

    -- Setup relationship groups
    SetupGangRelationships()

    -- Initial sync with rcore
    SyncRcoreTerritories()

    -- Periodic territory sync
    while true do
        Wait(Config.Integration.syncInterval)
        SyncRcoreTerritories()
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        TriggerClientEvent('gangai:client:clearAllNPCs', -1)
    end
end)

print('^2[GangAI] Server initialized - rcore_gangs augmentation mode')
