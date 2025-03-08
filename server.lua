print("^2DEBUG:^0 Config:", Config)
print("^2DEBUG:^0 Config.Gangs:", Config.Gangs)

local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()

Config.Gangs = {
    ['Ballas'] = {
        territory = {
            {x = 114.3, y = -1961.1, z = 21.3},
            {x = 118.3, y = -1959.1, z = 21.3}
        },
        models = {'g_m_y_ballaorig_01', 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'csb_ballasog'},
        vehicles = {'buccaneer', 'peyote', 'voodoo'}
    },
    ['Vagos'] = {
        territory = {
            {x = 325.2, y = -2050.4, z = 20.9},
            {x = 330.2, y = -2048.4, z = 20.9}
        },
        models = {'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03', 'csb_ortega'},
        vehicles = {'tornado3', 'chino', 'buccaneer2'}
    },
    ['Families'] = {
        territory = {
            {x = -154.6, y = -1608.4, z = 34.8},
            {x = -152.0, y = -1610.4, z = 34.8}
        },
        models = {'g_f_y_families_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01', 'csb_ramp_gang'},
        vehicles = {'greenwood', 'manana', 'tornado'}
    }
}

RegisterNetEvent('gangWars:triggerGangWar')
AddEventHandler('gangWars:triggerGangWar', function(gangName)
    if Config.Gangs[gangName] then
        print("^3INFO:^0 Gang War Started: " .. gangName)
        
        TriggerClientEvent('gangwars:spawnGangMembers', -1, Config.Gangs[gangName])

        TriggerClientEvent('gangWars:gangFightStarted', -1, Config.Gangs[gangName].territory)
    else
        print("^1ERROR:^0 Gang not found: " .. gangName)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)  -- Check every 60 seconds

        for gangName, gangData in pairs(Config.Gangs) do
            for rivalGang, rivalData in pairs(Config.Gangs) do
                if gangName ~= rivalGang then
                    local distance = #(vector3(gangData.territory[1].x, gangData.territory[1].y, gangData.territory[1].z) - 
                                       vector3(rivalData.territory[1].x, rivalData.territory[1].y, rivalData.territory[1].z))

                    if distance < 100 then  -- If territories are close, start a war
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
    if Config.Gangs[gangName] then
        print("^1ALERT:^0 Player attack detected on " .. gangName .. "! Retaliation initiated.")
        TriggerEvent('gangWars:triggerGangWar', gangName)
    end
end)
