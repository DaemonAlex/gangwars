local QBCore = exports['qb-core']:GetCoreObject()

-- Ensure we're using the same Config structure as client.lua
Config = Config or { Gangs = {}, PoliceJobs = {} }

local lastWarTime = {}
local warCooldown = 600000  -- 10 minutes cooldown

-- Debug logging - Use pcall to prevent errors if JSON encoding fails
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for config to load
    print("^2DEBUG:^0 Server script loaded")
    local status, result = pcall(function()
        for gang, data in pairs(Config.Gangs or {}) do
            print("^2DEBUG:^0 Gang loaded: " .. gang)
        end
    end)
    
    if not status then
        print("^1ERROR:^0 Failed to print config: " .. tostring(result))
    end
end)

-- Safe notification function for server-side
local function SafeNotifyPlayer(playerId, data)
    if not playerId then return end
    
    -- Use basic chat notification as fallback if ox_lib fails
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {255, 0, 0},
        multiline = true,
        args = {data.title, data.description}
    })
    
    -- Try ox_lib notify if available (will silently fail if not)
    pcall(function()
        TriggerClientEvent('ox_lib:notify', playerId, data)
    end)
end

-- Handle a player joining a gang
RegisterNetEvent('gangWars:playerJoinedGang')
AddEventHandler('gangWars:playerJoinedGang', function(gangName)
    local src = source
    if not gangName or not Config.Gangs[gangName] then
        SafeNotifyPlayer(src, {
            title = 'Error',
            description = 'Invalid gang name',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    print("^3INFO:^0 Player " .. src .. " joined gang: " .. gangName)
    
    -- Update player's metadata to include gang affiliation
    -- This uses QBCore's metadata system to track gang membership
    Player.Functions.SetMetaData('gang', gangName)
    
    SafeNotifyPlayer(src, {
        title = 'Gang Joined',
        description = 'You are now a member of ' .. gangName,
        type = 'success',
        duration = 5000
    })
    
    -- Broadcast to nearby players
    TriggerClientEvent('gangWars:notifyGangActivity', -1, 
        'A new member has joined ' .. gangName .. '!', 
        Config.Gangs[gangName].territory[1])
end)

-- Trigger a gang war event
RegisterNetEvent('gangWars:triggerGangWar')
AddEventHandler('gangWars:triggerGangWar', function(gangName)
    if not gangName or not Config.Gangs[gangName] then
        print("^1ERROR:^0 Invalid gang war trigger. Gang not found: " .. tostring(gangName))
        return
    end

    print("^3INFO:^0 Gang War Started: " .. gangName)
    
    -- Send the entire gang data to the client for spawning members
    TriggerClientEvent('gangwars:spawnGangMembers', -1, Config.Gangs[gangName])
    
    -- Send just the first territory point for effects and notifications
    if Config.Gangs[gangName].territory and #Config.Gangs[gangName].territory > 0 then
        TriggerClientEvent('gangWars:gangFightStarted', -1, Config.Gangs[gangName].territory[1])
        TriggerClientEvent('gangWars:notifyGangActivity', -1, 'A gang war has broken out in ' .. gangName .. ' territory!', Config.Gangs[gangName].territory[1])
    else
        print("^1ERROR:^0 No territory data for gang: " .. gangName)
    end
    
    -- Record this war time
    lastWarTime[gangName] = GetGameTimer()
end)

-- Function to get players in a specific territory
function GetPlayersInTerritory(territory, radius)
    local playersInArea = {}
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        local coords = GetEntityCoords(ped)
        
        -- Check if player is within radius of territory point
        local distance = #(vector3(coords.x, coords.y, coords.z) - 
                         vector3(territory.x, territory.y, territory.z))
        
        if distance <= (radius or 200.0) then
            table.insert(playersInArea, playerId)
        end
    end
    
    return playersInArea
end

-- Check for proximity wars between gangs
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)  -- Every 5 minutes
        
        -- Check that Config.Gangs exists and has data
        if not Config.Gangs or next(Config.Gangs) == nil then
            print("^1ERROR:^0 Config.Gangs is empty or not initialized")
            Citizen.Wait(60000) -- Wait longer if config isn't loaded
            goto continue
        end

        -- Check for proximity wars only if we have WarSettings configured
        if not Config.WarSettings or not Config.WarSettings.proximityThreshold then
            print("^1WARNING:^0 Config.WarSettings not properly configured, skipping proximity checks")
            goto continue
        end

        for gangName, gangData in pairs(Config.Gangs) do
            for rivalGang, rivalData in pairs(Config.Gangs) do
                if gangName ~= rivalGang then
                    local currentTime = GetGameTimer()
                    if not lastWarTime[gangName] or currentTime - lastWarTime[gangName] > warCooldown then
                        -- Make sure territory data exists and has at least one point
                        if gangData.territory and rivalData.territory and 
                           #gangData.territory > 0 and #rivalData.territory > 0 then
                           
                            local distance = #(vector3(gangData.territory[1].x, gangData.territory[1].y, gangData.territory[1].z) - 
                                               vector3(rivalData.territory[1].x, rivalData.territory[1].y, rivalData.territory[1].z))

                            if distance < Config.WarSettings.proximityThreshold then 
                                print("^3INFO:^0 Proximity gang war triggered between " .. gangName .. " and " .. rivalGang)
                                TriggerEvent('gangWars:triggerGangWar', gangName)
                                TriggerEvent('gangWars:triggerGangWar', rivalGang)
                                lastWarTime[gangName] = currentTime
                                lastWarTime[rivalGang] = currentTime
                                break -- Only start one war per gang per cycle
                            end
                        else
                            print("^1ERROR:^0 Missing territory data for " .. gangName .. " or " .. rivalGang)
                        end
                    end
                end
            end
        end
        
        ::continue::
    end
end)

-- Schedule random gang wars
Citizen.CreateThread(function()
    while true do
        -- Use WarSettings if available, or default to 4 hours
        local interval = (Config.WarSettings and Config.WarSettings.randomWarInterval) or 14400000
        Citizen.Wait(interval)

        -- Get all available gangs from config
        local gangList = {}
        for gang, _ in pairs(Config.Gangs or {}) do
            table.insert(gangList, gang)
        end
        
        if #gangList < 2 then
            print("^1ERROR:^0 Not enough gangs configured for a random war")
            goto continue
        end

        -- Randomize selection
        math.randomseed(GetGameTimer())
        
        -- Select two random gangs
        local idx1 = math.random(#gangList)
        local gang1 = gangList[idx1]
        table.remove(gangList, idx1)
        
        local idx2 = math.random(#gangList)
        local gang2 = gangList[idx2]
        
        print("^3INFO:^0 A major gang war has started between " .. gang1 .. " and " .. gang2 .. "!")
        TriggerEvent('gangWars:triggerGangWar', gang1)
        TriggerEvent('gangWars:triggerGangWar', gang2)
        
        ::continue::
    end
end)

-- Handle player attacking gang member
RegisterNetEvent('gangWars:playerAttackedGang')
AddEventHandler('gangWars:playerAttackedGang', function(gangName)
    local src = source
    
    if not gangName or not Config.Gangs[gangName] then
        print("^1ERROR:^0 Invalid gang retaliation. Gang not found: " .. tostring(gangName))
        return
    end

    print("^1ALERT:^0 Player " .. src .. " attack detected on " .. gangName .. "! Retaliation initiated.")
    
    -- Get player's gang affiliation
    local Player = QBCore.Functions.GetPlayer(src)
    local playerGang = nil
    
    if Player then
        playerGang = Player.PlayerData.metadata and Player.PlayerData.metadata.gang
    end
    
    -- If player is in a rival gang, this could escalate to a full gang war
    if playerGang and playerGang ~= gangName and Config.Gangs[playerGang] then
        -- 50% chance of a full gang war
        if math.random() < 0.5 then
            print("^1ALERT:^0 Gang war escalation between " .. gangName .. " and " .. playerGang)
            TriggerEvent('gangWars:triggerGangWar', gangName)
            TriggerEvent('gangWars:triggerGangWar', playerGang)
            return
        end
    end
    
    -- Otherwise just trigger retaliation from attacked gang
    TriggerEvent('gangWars:triggerGangWar', gangName)
end)

-- Add new command for direct local spawning
RegisterCommand('forcespawn', function(source, args, rawCommand)
    local src = source
    local gangName = args[1]
    
    if not gangName or not Config.Gangs[gangName] then
        local gangs = {}
        for gang, _ in pairs(Config.Gangs) do
            table.insert(gangs, gang)
        end
        
        SafeNotifyPlayer(src, {
            title = 'Error',
            description = 'Invalid gang. Available: ' .. table.concat(gangs, ', '),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    print("^3INFO:^0 Player " .. src .. " requested direct spawn of " .. gangName)
    TriggerClientEvent('gangwars:spawnGangMembers', src, Config.Gangs[gangName])
    
    SafeNotifyPlayer(src, {
        title = 'Gang Spawned',
        description = 'Spawned ' .. gangName .. ' gang members at your location',
        type = 'success',
        duration = 5000
    })
end, false)

-- Add debug command for testing
RegisterCommand('testwar', function(source, args, rawCommand)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    -- Check if player is admin (can be customized for your server)
    if player and (player.PlayerData.permission == "admin" or player.PlayerData.permission == "god") then
        local gangName = args[1]
        if gangName and Config.Gangs[gangName] then
            print("^3INFO:^0 Admin " .. src .. " triggered test war for " .. gangName)
            TriggerEvent('gangWars:triggerGangWar', gangName)
        else
            local gangs = {}
            for gang, _ in pairs(Config.Gangs) do
                table.insert(gangs, gang)
            end
            SafeNotifyPlayer(src, {
                title = 'Error',
                description = 'Invalid gang. Available: ' .. table.concat(gangs, ', '),
                type = 'error',
                duration = 5000
            })
        end
    else
        SafeNotifyPlayer(src, {
            title = 'Error',
            description = 'You do not have permission to use this command',
            type = 'error',
            duration = 5000
        })
    end
end, true) -- restricted command

-- Add command to easily see and teleport to gang territories
RegisterCommand('teleport', function(source, args, rawCommand)
    local src = source
    local gangName = args[1]
    
    if not gangName or not Config.Gangs[gangName] then
        local gangs = {}
        for gang, _ in pairs(Config.Gangs) do
            table.insert(gangs, gang)
        end
        
        SafeNotifyPlayer(src, {
            title = 'Error',
            description = 'Invalid gang. Available: ' .. table.concat(gangs, ', '),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    if Config.Gangs[gangName].territory and #Config.Gangs[gangName].territory > 0 then
        local pos = Config.Gangs[gangName].territory[1]
        TriggerClientEvent('QBCore:Command:TeleportToCoords', src, pos.x, pos.y, pos.z)
        
        SafeNotifyPlayer(src, {
            title = 'Teleported',
            description = 'You\'ve been teleported to ' .. gangName .. ' territory',
            type = 'success',
            duration = 5000
        })
    else
        SafeNotifyPlayer(src, {
            title = 'Error',
            description = 'No territory coordinates found for ' .. gangName,
            type = 'error',
            duration = 5000
        })
    end
end, false)

-- Register server event for ambient gang population near players
RegisterNetEvent('gangWars:requestAmbientGangs')
AddEventHandler('gangWars:requestAmbientGangs', function(playerLocation)
    local src = source
    
    -- Find closest gang territory
    local closestGang = nil
    local closestDist = 99999.0
    
    for gangName, gangData in pairs(Config.Gangs) do
        if gangData.territory and #gangData.territory > 0 then
            for _, territoryPoint in ipairs(gangData.territory) do
                local dist = #(vector3(playerLocation.x, playerLocation.y, playerLocation.z) - 
                              vector3(territoryPoint.x, territoryPoint.y, territoryPoint.z))
                
                if dist < closestDist then
                    closestDist = dist
                    closestGang = gangName
                end
            end
        end
    end
    
    -- If player is near a territory, trigger gang spawning
    if closestGang and closestDist < 200.0 then
        print("^3INFO:^0 Ambient gang population for " .. closestGang .. " near player " .. src)
        TriggerClientEvent('gangwars:spawnGangMembers', src, Config.Gangs[closestGang])
    end
end)

-- Initialization
print("^2INFO:^0 Gang Wars server script initialized")
