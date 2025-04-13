local QBCore = exports['qb-core']:GetCoreObject()

-- Ensure we're using the same Config structure as client.lua
Config = Config or { Gangs = {}, PoliceJobs = {} }

local lastWarTime = {}
local warCooldown = 600000  -- 10 minutes cooldown
local gangMembers = {} -- Track players in gangs: {gangName = {player1, player2, ...}}

-- Debug logging - Use pcall to prevent errors if JSON encoding fails
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for config to load
    print("^2DEBUG:^0 Server script loaded")
    local status, result = pcall(function()
        for gang, data in pairs(Config.Gangs or {}) do
            print("^2DEBUG:^0 Gang loaded: " .. gang)
            -- Initialize gang members tracker
            gangMembers[gang] = {}
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

-- Track player's gang when they load
RegisterNetEvent('QBCore:Server:PlayerLoaded')
AddEventHandler('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.metadata and Player.PlayerData.metadata.gang then
        local gangName = Player.PlayerData.metadata.gang
        
        -- Make sure gang exists
        if Config.Gangs[gangName] then
            -- Add player to gang member list
            if not gangMembers[gangName] then
                gangMembers[gangName] = {}
            end
            
            table.insert(gangMembers[gangName], src)
            print("^3INFO:^0 Player " .. src .. " loaded with gang: " .. gangName)
        end
    end
end)

-- Handle player disconnecting
AddEventHandler('playerDropped', function()
    local src = source
    
    -- Remove player from any gang member list
    for gang, members in pairs(gangMembers) do
        for i, playerId in ipairs(members) do
            if playerId == src then
                table.remove(gangMembers[gang], i)
                print("^3INFO:^0 Player " .. src .. " removed from gang: " .. gang)
                break
            end
        end
    end
end)

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
    
    -- Remove from old gang if present
    if Player.PlayerData.metadata and Player.PlayerData.metadata.gang then
        local oldGang = Player.PlayerData.metadata.gang
        
        if gangMembers[oldGang] then
            for i, playerId in ipairs(gangMembers[oldGang]) do
                if playerId == src then
                    table.remove(gangMembers[oldGang], i)
                    break
                end
            end
        end
    end
    
    print("^3INFO:^0 Player " .. src .. " joined gang: " .. gangName)
    
    -- Update player's metadata to include gang affiliation
    Player.Functions.SetMetaData('gang', gangName)
    
    -- Add to gang members list
    if not gangMembers[gangName] then
        gangMembers[gangName] = {}
    end
    table.insert(gangMembers[gangName], src)
    
    SafeNotifyPlayer(src, {
        title = 'Gang Joined',
        description = 'You are now a member of ' .. gangName,
        type = 'success',
        duration = 5000
    })
    
    -- Broadcast to nearby players
    local gangData = Config.Gangs[gangName]
    if gangData and gangData.territory and #gangData.territory > 0 then
        TriggerClientEvent('gangWars:notifyGangActivity', -1, 
            'A new member has joined ' .. gangName .. '!', 
            gangData.territory[1], 
            gangName)
    end
end)

-- Handle a player leaving a gang
RegisterNetEvent('gangWars:playerLeftGang')
AddEventHandler('gangWars:playerLeftGang', function(gangName)
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
    
    -- Check if player is actually in this gang
    if not Player.PlayerData.metadata or Player.PlayerData.metadata.gang ~= gangName then
        SafeNotifyPlayer(src, {
            title = 'Error',
            description = 'You are not a member of ' .. gangName,
            type = 'error',
            duration = 5000
        })
        return
    end
    
    print("^3INFO:^0 Player " .. src .. " left gang: " .. gangName)
    
    -- Update player's metadata to remove gang affiliation
    Player.Functions.SetMetaData('gang', nil)
    
    -- Remove from gang members list
    if gangMembers[gangName] then
        for i, playerId in ipairs(gangMembers[gangName]) do
            if playerId == src then
                table.remove(gangMembers[gangName], i)
                break
            end
        end
    end
    
    SafeNotifyPlayer(src, {
        title = 'Gang Left',
        description = 'You have left ' .. gangName,
        type = 'inform',
        duration = 5000
    })
    
    -- Broadcast to nearby players
    local gangData = Config.Gangs[gangName]
    if gangData and gangData.territory and #gangData.territory > 0 then
        TriggerClientEvent('gangWars:notifyGangActivity', -1, 
            'A member has left ' .. gangName .. '!', 
            gangData.territory[1],
            gangName)
    end
end)

-- Trigger a gang war event
RegisterNetEvent('gangWars:triggerGangWar')
AddEventHandler('gangWars:triggerGangWar', function(gangName, rivalGangName)
    if not gangName or not Config.Gangs[gangName] then
        print("^1ERROR:^0 Invalid gang war trigger. Gang not found: " .. tostring(gangName))
        return
    end

    print("^3INFO:^0 Gang War Started: " .. gangName)
    
    -- Add gang name to data before sending
    local gangData = table.copy(Config.Gangs[gangName])
    gangData.name = gangName
    
    -- Send the gang data to all players for spawning members
    TriggerClientEvent('gangwars:spawnGangMembers', -1, gangData)
    
    -- Send event with gang name for effects and notifications
    if gangData.territory and #gangData.territory > 0 then
        TriggerClientEvent('gangWars:gangFightStarted', -1, gangData.territory[1], gangName)
        
        local warMessage = 'A gang war has broken out in ' .. gangName .. ' territory!'
        if rivalGangName then
            warMessage = gangName .. ' is at war with ' .. rivalGangName .. '!'
        end
        
        TriggerClientEvent('gangWars:notifyGangActivity', -1, warMessage, gangData.territory[1], gangName)
    else
        print("^1ERROR:^0 No territory data for gang: " .. gangName)
    end
    
    -- Record this war time
    lastWarTime[gangName] = GetGameTimer()
    
    -- Notify gang members directly
    if gangMembers[gangName] then
        for _, playerId in ipairs(gangMembers[gangName]) do
            SafeNotifyPlayer(playerId, {
                title = 'Gang War Alert',
                description = 'Your gang is under attack! Defend your territory!',
                type = 'warning',
                duration = 10000
            })
        end
    end
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

-- Table deep copy function
function table.copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.copy(orig_key)] = table.copy(orig_value)
        end
        setmetatable(copy, table.copy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
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
                    local warCooldownTime = Config.WarSettings.warCooldown or warCooldown
                    
                    if not lastWarTime[gangName] or currentTime - lastWarTime[gangName] > warCooldownTime then
                        -- Make sure territory data exists and has at least one point
                        if gangData.territory and rivalData.territory and 
                           #gangData.territory > 0 and #rivalData.territory > 0 then
                           
                            local distance = #(vector3(gangData.territory[1].x, gangData.territory[1].y, gangData.territory[1].z) - 
                                               vector3(rivalData.territory[1].x, rivalData.territory[1].y, rivalData.territory[1].z))

                            if distance < Config.WarSettings.proximityThreshold then 
                                print("^3INFO:^0 Proximity gang war triggered between " .. gangName .. " and " .. rivalGang)
                                
                                -- Check if members are active
                                local gang1Active = gangMembers[gangName] and #gangMembers[gangName] > 0
                                local gang2Active = gangMembers[rivalGang] and #gangMembers[rivalGang] > 0
                                
                                -- Only trigger war if at least one gang has active members
                                if gang1Active or gang2Active then
                                    TriggerEvent('gangWars:triggerGangWar', gangName, rivalGang)
                                    TriggerEvent('gangWars:triggerGangWar', rivalGang, gangName)
                                    lastWarTime[gangName] = currentTime
                                    lastWarTime[rivalGang] = currentTime
                                    break -- Only start one war per gang per cycle
                                else
                                    print("^3INFO:^0 Skipped war - no active gang members")
                                end
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
        
        -- Check if any members are active
        local gang1Active = gangMembers[gang1] and #gangMembers[gang1] > 0
        local gang2Active = gangMembers[gang2] and #gangMembers[gang2] > 0
        local playersOnline = #GetPlayers() > 0
        
        -- Only start war if players are online
        if playersOnline then
            print("^3INFO:^0 A major gang war has started between " .. gang1 .. " and " .. gang2 .. "!")
            TriggerEvent('gangWars:triggerGangWar', gang1, gang2)
            TriggerEvent('gangWars:triggerGangWar', gang2, gang1)
        else
            print("^3INFO:^0 Skipped random war - no players online")
        end
        
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

    -- Get player's gang affiliation
    local Player = QBCore.Functions.GetPlayer(src)
    local playerGang = nil
    
    if Player then
        playerGang = Player.PlayerData.metadata and Player.PlayerData.metadata.gang
    end
    
    -- Ignore if player is in the same gang (shouldn't happen with client check, but just in case)
    if playerGang and playerGang == gangName then
        print("^3INFO:^0 Player " .. src .. " attacked own gang " .. gangName .. " - ignoring")
        return
    end
    
    print("^1ALERT:^0 Player " .. src .. " attack detected on " .. gangName .. "! Retaliation initiated.")
    
    -- If player is in a rival gang, this could escalate to a full gang war
    if playerGang and playerGang ~= gangName and Config.Gangs[playerGang] then
        -- 50% chance of a full gang war
        if math.random() < 0.5 then
            print("^1ALERT:^0 Gang war escalation between " .. gangName .. " and " .. playerGang)
            TriggerEvent('gangWars:triggerGangWar', gangName, playerGang)
            TriggerEvent('gangWars:triggerGangWar', playerGang, gangName)
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
    
    -- Add name to gang data
    local gangData = table.copy(Config.Gangs[gangName])
    gangData.name = gangName
    
    TriggerClientEvent('gangwars:spawnGangMembers', src, gangData, true)
    
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
AddEventHandler('gangWars:requestAmbientGangs', function(playerLocation, territoryGang)
    local src = source
    
    if territoryGang and Config.Gangs[territoryGang] then
        print("^3INFO:^0 Ambient gang population for " .. territoryGang .. " near player " .. src)
        
        -- Add name to gang data
        local gangData = table.copy(Config.Gangs[territoryGang])
        gangData.name = territoryGang
        
        TriggerClientEvent('gangwars:spawnGangMembers', src, gangData, false)
        return
    end
    
    -- If no territory gang specified, find closest
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
        
        -- Add name to gang data
        local gangData = table.copy(Config.Gangs[closestGang])
        gangData.name = closestGang
        
        TriggerClientEvent('gangwars:spawnGangMembers', src, gangData, false)
    end
end)

-- Initialization
print("^2INFO:^0 Gang Wars server script initialized")
