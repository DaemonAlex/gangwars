if not Config then
    print("^1ERROR:^0 Config is not loaded! Check fxmanifest.lua.")
end

local Ox = exports.ox_lib

-- Define Gangs and Their Territories
Config.Gangs = {
    ['Ballas'] = {
        territory = {x = 114.3, y = -1961.1, z = 21.3},
        models = {'g_m_y_ballaorig_01', 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'csb_ballasog'},
        vehicles = {'buccaneer', 'peyote', 'voodoo'}
    },
    ['Vagos'] = {
        territory = {x = 325.2, y = -2050.4, z = 20.9},
        models = {'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03', 'csb_ortega'},
        vehicles = {'tornado3', 'chino', 'buccaneer2'}
    },
    ['Families'] = {
        territory = {x = -154.6, y = -1608.4, z = 34.8},
        models = {'g_f_y_families_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01', 'csb_ramp_gang'},
        vehicles = {'greenwood', 'manana', 'tornado'}
    },
    ['Triads'] = {
        territory = {x = -820.4, y = -700.3, z = 27.9},
        models = {'g_m_m_chigoon_01', 'g_m_m_chigoon_02', 'g_m_y_korean_01', 'g_m_y_korean_02'},
        vehicles = {'tailgater', 'sultan', 'schafter2'}
    },
    ['Madrazo'] = {
        territory = {x = 1391.5, y = 1152.2, z = 114.3},
        models = {'g_m_m_armboss_01', 'g_m_m_armlieut_01', 'g_m_m_armgoon_01', 'csb_mweather'},
        vehicles = {'xls', 'granger', 'mesa'}
    }
}

-- Gang War Trigger System
RegisterNetEvent('gangWars:triggerGangWar')
AddEventHandler('gangWars:triggerGangWar', function(gangName)
    if Config.Gangs[gangName] then
        print("^3INFO:^0 Gang War Started: " .. gangName)
        SpawnGangMembers(gangName)
        TriggerClientEvent('gangWars:gangFightStarted', -1, Config.Gangs[gangName].territory)
    else
        print("^1ERROR:^0 Gang not found: " .. gangName)
    end
end)

-- Automatic Gang War Trigger: If a rival gang enters another's turf
Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Check every 60 seconds
        for gangName, gangData in pairs(Config.Gangs) do
            for rivalGang, rivalData in pairs(Config.Gangs) do
                if gangName ~= rivalGang then
                    local distance = #(vector3(gangData.territory.x, gangData.territory.y, gangData.territory.z) -
                                       vector3(rivalData.territory.x, rivalData.territory.y, rivalData.territory.z))
                    if distance < 100 then  -- If territories are close, a war starts
                        TriggerEvent('gangWars:triggerGangWar', gangName)
                        TriggerEvent('gangWars:triggerGangWar', rivalGang)
                    end
                end
            end
        end
    end
end)

-- Random War Timer: Every 4 hours, start a fight between two gangs
Citizen.CreateThread(function()
    while true do
        Wait(14400000) -- 4 hours (4 * 60 * 60 * 1000 milliseconds)
        local gangList = {"Ballas", "Vagos", "Families", "Triads", "Madrazo"}
        local randomGang1 = gangList[math.random(#gangList)]
        local randomGang2 = gangList[math.random(#gangList)]
        
        if randomGang1 ~= randomGang2 then
            print("^3INFO:^0 A major gang war has started between " .. randomGang1 .. " and " .. randomGang2 .. "!")
            TriggerEvent('gangWars:triggerGangWar', randomGang1)
            TriggerEvent('gangWars:triggerGangWar', randomGang2)
        end
    end
end)

-- Player-Triggered War: If a player attacks a gang, they fight back
RegisterNetEvent('gangWars:playerAttackedGang')
AddEventHandler('gangWars:playerAttackedGang', function(gangName)
    if Config.Gangs[gangName] then
        print("^1ALERT:^0 Player attack detected on " .. gangName .. "! Retaliation initiated.")
        TriggerEvent('gangWars:triggerGangWar', gangName)
    end
end)
