local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()

-- Ensure we're using the same Config structure as client.lua
Config = Config or { Gangs = {}, PoliceJobs = {} }

local lastWarTime = {}
local gangReputations = {}
local warCooldown = 600000  -- 10 minutes cooldown

-- Initialize gang reputation system
Citizen.CreateThread(function()
    if Config.RepSystem and Config.RepSystem.enabled then
        for gangName, _ in pairs(Config.Gangs or {}) do
            gangReputations[gangName] = Config.RepSystem.baseReputation or 100
        end
    end
end)

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
    
    -- Add reputation if rep system enabled
    if Config.RepSystem and Config.RepSystem.enabled then
        local repGain = Config.RepSystem.reputationGain.joinGang or 50
        ChangeGangReputation(gangName, repGain)
        
        -- Get player benefits based on gang reputation
        local benefits = GetGangBenefits(gangName)
        if benefits then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Gang Status',
                description = benefits,
                type = 'info',
                duration = 7000
            })
        end
    end
    
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
        
        -- Spawn territory props
        TriggerClientEvent('gangwars:spawnTerritoryProps', -1, gangName, Config.Gangs[gangName].territory)
    else
        print("^1ERROR:^0 No territory data for gang: " .. gangName)
    end
end)

-- Check for proximity wars between gangs
Citizen.CreateThread(function()
    while true do
        -- Use WarSettings if available, or default to 5 minutes
        local interval = (Config.WarSettings and Config.WarSettings.proximityWarInterval) or 300000
        Citizen.Wait(interval)
        
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
                    local cooldownTime = (Config.WarSettings and Config.WarSettings.warCooldown) or warCooldown
                    
                    if not lastWarTime[gangName] or currentTime - lastWarTime[gangName] > cooldownTime then
                        -- Make sure territory data exists and has at least one point
                        if gangData.territory and rivalData.territory and 
                           #gangData.territory > 0 and #rivalData.territory > 0 then
                           
                            local distance = #(vector3(gangData.territory[1].x, gangData.territory[1].y, gangData.territory[1].z) - 
                                              vector3(rivalData.territory[1].x, rivalData.territory[1].y, rivalData.territory[1].z))

                            if distance < Config.WarSettings.proximityThreshold then 
                                print("^3INFO:^0 Proximity gang war triggered between " .. gangName .. " and " .. rivalGang)
                                TriggerEvent('gangWars:triggerGangWar', gangName)
                                TriggerEvent('gangWars:triggerGangWar', rivalGang)
                                
                                -- Determine winner (random for now, could be based on reputation later)
                                local winner = (math.random() > 0.5) and gangName or rivalGang
                                local loser = (winner == gangName) and rivalGang or gangName
                                
                                -- Update reputations if enabled
                                if Config.RepSystem and Config.RepSystem.enabled then
                                    ChangeGangReputation(winner, Config.RepSystem.reputationGain.winWar or 30)
                                    ChangeGangReputation(loser, -(Config.RepSystem.reputationLoss.loseWar or 20))
                                    
                                    -- Announce winner
                                    TriggerClientEvent('ox_lib:notify', -1, {
                                        title = 'Gang War Results',
                                        description = winner .. ' has won the territory war against ' .. loser .. '!',
                                        type = 'info',
                                        duration = 7000
                                    })
                                end
                                
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
        
        -- Determine winner based on reputation if enabled
        if Config.RepSystem and Config.RepSystem.enabled then
            local gang1Rep = gangReputations[gang1] or 100
            local gang2Rep = gangReputations[gang2] or 100
            
            -- 70% chance higher rep gang wins, 30% chance lower rep gang wins (for underdog chance)
            local winner
            if gang1Rep > gang2Rep then
                winner = (math.random() < 0.7) and gang1 or gang2
            else
                winner = (math.random() < 0.7) and gang2 or gang1
            end
            
            local loser = (winner == gang1) and gang2 or gang1
            
            -- Update reputations
            ChangeGangReputation(winner, Config.RepSystem.reputationGain.winWar or 30)
            ChangeGangReputation(loser, -(Config.RepSystem.reputationLoss.loseWar or 20))
            
            -- Announce winner after delay
            Citizen.SetTimeout(60000, function() -- 1 minute delay
                TriggerClientEvent('ox_lib:notify', -1, {
                    title = 'Gang War Results',
                    description = winner .. ' has won the territory war against ' .. loser .. '!',
                    type = 'info',
                    duration = 7000
                })
            end)
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

    print("^1ALERT:^0 Player " .. src .. " attack detected on " .. gangName .. "! Retaliation initiated.")
    
    -- Update reputation if player attacked their own gang
    if Config.RepSystem and Config.RepSystem.enabled then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData.metadata and Player.PlayerData.metadata.gang == gangName then
            -- Player attacked their own gang
            local repLoss = Config.RepSystem.reputationLoss.attackOwnGang or 50
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Gang Reputation',
                description = 'You lost ' .. repLoss .. ' gang reputation for attacking your own gang!',
                type = 'error',
                duration = 5000
            })
            
            -- Update player's metadata with new rep
            local currentRep = Player.PlayerData.metadata.gangrep or 100
            Player.Functions.SetMetaData('gangrep', currentRep - repLoss)
        end
    end
    
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

-- Add command to check gang reputation
RegisterCommand('checkrep', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    local gangName = args[1]
    if not gangName and player.PlayerData.metadata and player.PlayerData.metadata.gang then
        gangName = player.PlayerData.metadata.gang
    end
    
    if gangName and Config.Gangs[gangName] then
        local rep = gangReputations[gangName] or Config.RepSystem.baseReputation or 100
        local benefits = GetGangBenefits(gangName)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = gangName .. ' Reputation',
            description = 'Current reputation: ' .. rep .. '\n' .. benefits,
            type = 'info',
            duration = 7000
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You are not in a gang or specified an invalid gang',
            type = 'error',
            duration = 5000
        })
    end
end, false)

-- Utility function to change gang reputation
function ChangeGangReputation(gangName, amount)
    if not Config.RepSystem or not Config.RepSystem.enabled then return end
    
    if not gangReputations[gangName] then
        gangReputations[gangName] = Config.RepSystem.baseReputation or 100
    end
    
    gangReputations[gangName] = gangReputations[gangName] + amount
    
    -- Ensure reputation doesn't go below 0
    if gangReputations[gangName] < 0 then
        gangReputations[gangName] = 0
    end
    
    print("^3INFO:^0 " .. gangName .. " reputation changed by " .. amount .. ". New total: " .. gangReputations[gangName])
    return gangReputations[gangName]
end

-- Utility function to get gang benefits based on reputation
function GetGangBenefits(gangName)
    if not Config.RepSystem or not Config.RepSystem.enabled or not gangName then return nil end
    
    local rep = gangReputations[gangName] or Config.RepSystem.baseReputation or 100
    local benefits = "No special benefits"
    
    -- Get the highest threshold the gang qualifies for
    local highestQualifiedThreshold = 0
    for threshold, _ in pairs(Config.RepSystem.benefitsThresholds or {}) do
        if rep >= threshold and threshold > highestQualifiedThreshold then
            highestQualifiedThreshold = threshold
        end
    end
    
    if highestQualifiedThreshold > 0 then
        benefits = Config.RepSystem.benefitsThresholds[highestQualifiedThreshold]
    end
    
    return benefits
end
