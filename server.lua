local lib = exports.ox_lib
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

-- Handle a player joining a gang
RegisterNetEvent('gangWars:playerJoinedGang')
AddEventHandler('gangWars:playerJoinedGang', function(gangName)
    local src = source
    if not gangName or not Config.Gangs[gangName] then
        TriggerClientEvent('ox_lib:notify', src, {
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
    
    -- Here you could add code to set player's gang information in your framework
    -- For example, updating their metadata or gang status
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Gang Joined',
        description = 'You are now a member of ' .. gangName,
        type = 'success',
        duration = 5000
    })
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
end)

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

        for gangName, gangData in pairs(Config.Gangs) do
            for rivalGang, rivalData in pairs(Config.Gangs) do
                if gangName ~= rivalGang then
                    local currentTime = GetGameTimer()
                    if not lastWarTime[gangName] or currentTime - lastWarTime[gangName] > warCooldown then
                        -- Make sure territory data exists
                        if gangData.territory and rivalData.territory and 
                           gangData.territory[1] and rivalData.territory[1] then
                           
                            local distance = #(vector3(gangData.territory[1].x, gangData.territory[1].y, gangData.territory[1].z) - 
                                               vector3(rivalData.territory[1].x, rivalData.territory[1].y, rivalData.territory[1].z))

                            if distance < 1000 then -- Increased distance for testing
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
        Citizen.Wait(14400000)  -- Every 4 hours

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
    TriggerEvent('gangWars:triggerGangWar', gangName)
end)

-- Add debug command for testing
RegisterCommand('testwar', function(source, args, rawCommand)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    -- Check if player is admin
    if player and player.PlayerData.permission == "admin" then
        local gangName = args[1]
        if gangName and Config.Gangs[gangName] then
            print("^3INFO:^0 Admin " .. src .. " triggered test war for " .. gangName)
            TriggerEvent('gangWars:triggerGangWar', gangName)
        else
            local gangs = {}
            for gang, _ in pairs(Config.Gangs) do
                table.insert(gangs, gang)
            end
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Error',
                description = 'Invalid gang. Available: ' .. table.concat(gangs, ', '),
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You do not have permission to use this command',
            type = 'error'
        })
    end
end, true) -- restricted command
