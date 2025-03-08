print("^2DEBUG:^0 Config:", Config)
print("^2DEBUG:^0 Config.Gangs:", Config.Gangs)

local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()

Config = Config or { Gangs = {} }

local lastWarTime = {}
local warCooldown = 600000  -- 10 minutes cooldown

RegisterNetEvent('gangWars:triggerGangWar')
AddEventHandler('gangWars:triggerGangWar', function(gangName)
    if not gangName or not Config.Gangs[gangName] then
        print("^1ERROR:^0 Invalid gang war trigger. Gang not found: " .. tostring(gangName))
        return
    end

    print("^3INFO:^0 Gang War Started: " .. gangName)
    
    TriggerClientEvent('gangwars:spawnGangMembers', -1, Config.Gangs[gangName])
    TriggerClientEvent('gangWars:gangFightStarted', -1, Config.Gangs[gangName].territory)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)  -- Every 5 minutes

        for gangName, gangData in pairs(Config.Gangs) do
            for rivalGang, rivalData in pairs(Config.Gangs) do
                if gangName ~= rivalGang then
                    local currentTime = GetGameTimer()
                    if not lastWarTime[gangName] or currentTime - lastWarTime[gangName] > warCooldown then
                        local distance = #(vector3(gangData.territory[1].x, gangData.territory[1].y, gangData.territory[1].z) - 
                                           vector3(rivalData.territory[1].x, rivalData.territory[1].y, rivalData.territory[1].z))

                        if distance < 100 then
                            TriggerEvent('gangWars:triggerGangWar', gangName)
                            TriggerEvent('gangWars:triggerGangWar', rivalGang)
                            lastWarTime[gangName] = currentTime
                            lastWarTime[rivalGang] = currentTime
                        end
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(14400000)  -- Every 4 hours

        local gangList = { "Ballas", "Vagos", "Families" }
        math.randomseed(GetGameTimer())  
        local shuffledGangs = {}

        while #gangList > 0 do
            local index = math.random(#gangList)
            table.insert(shuffledGangs, gangList[index])
            table.remove(gangList, index)
        end

        local gang1, gang2 = shuffledGangs[1], shuffledGangs[2]
        print("^3INFO:^0 A major gang war has started between " .. gang1 .. " and " .. gang2 .. "!")
        TriggerEvent('gangWars:triggerGangWar', gang1)
        TriggerEvent('gangWars:triggerGangWar', gang2)
    end
end)

RegisterNetEvent('gangWars:playerAttackedGang')
AddEventHandler('gangWars:playerAttackedGang', function(gangName)
    if not gangName or not Config.Gangs[gangName] then
        print("^1ERROR:^0 Invalid gang retaliation. Gang not found: " .. tostring(gangName))
        return
    end

    print("^1ALERT:^0 Player attack detected on " .. gangName .. "! Retaliation initiated.")
    TriggerEvent('gangWars:triggerGangWar', gangName)
end)
