print("^2DEBUG:^0 Config:", Config)
print("^2DEBUG:^0 Config.Gangs:", Config.Gangs)

local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()

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
        Citizen.Wait(300000)  -- Check every 5 minutes

        for gangName, gangData in pairs(Config.Gangs) do
            for rivalGang, rivalData in pairs(Config.Gangs) do
                if gangName ~= rivalGang then
                    local distance = #(vector3(gangData.territory[1].x, gangData.territory[1].y, gangData.territory[1].z) - 
                                       vector3(rivalData.territory[1].x, rivalData.territory[1].y, rivalData.territory[1].z))

                    if distance < 100 then
                        TriggerEvent('gangWars:triggerGangWar', gangName)
                        TriggerEvent('gangWars:triggerGangWar', rivalGang)
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(14400000)  -- Every 4 hours

        local gangList = {"Ballas", "Vagos", "Families"}
        local randomGang1 = gangList[math.random(#gangList)]
        local randomGang2 = gangList[math.random(#gangList)]
        
        if randomGang1 ~= randomGang2 then
            print("^3INFO:^0 A major gang war has started between " .. randomGang1 .. " and " .. randomGang2 .. "!")
            TriggerEvent('gangWars:triggerGangWar', randomGang1)
            TriggerEvent('gangWars:triggerGangWar', randomGang2)
        end
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
