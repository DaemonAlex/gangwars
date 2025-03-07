print("^2DEBUG:^0 Config:", Config)
print("^2DEBUG:^0 Config.Gangs:", Config.Gangs)

local Ox = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()

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

function SpawnGangMembers(gangName)
    if not Config.Gangs[gangName] then
        print("^1ERROR:^0 Invalid gang name: " .. tostring(gangName))
        return
    end

    local gangData = Config.Gangs[gangName]

    for _, spawnPoint in pairs({gangData.territory}) do
        local model = gangData.models[math.random(#gangData.models)]
        local vehicle = gangData.vehicles[math.random(#gangData.vehicles)]

        local ped = CreatePed(4, GetHashKey(model), spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, true)
        SetPedCombatAttributes(ped, 46, true) -- Make them aggressive
        GiveWeaponToPed(ped, GetHashKey("WEAPON_MICROSMG"), 255, false, true)
        TaskCombatHatedTargetsAroundPed(ped, 50.0, 0)

        RequestModel(GetHashKey(vehicle))
        while not HasModelLoaded(GetHashKey(vehicle)) do
            Citizen.Wait(100)
        end

        local spawnedVehicle = CreateVehicle(GetHashKey(vehicle), spawnPoint.x + 2, spawnPoint.y + 2, spawnPoint.z, 0.0, true, false)
        SetPedIntoVehicle(ped, spawnedVehicle, -1)

        SetEntityAsNoLongerNeeded(ped)
        SetEntityAsNoLongerNeeded(spawnedVehicle)
    end

    print("^2INFO:^0 Spawned gang members for " .. gangName)
end

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

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        for gangName, gangData in pairs(Config.Gangs) do
            for rivalGang, rivalData in pairs(Config.Gangs) do
                if gangName ~= rivalGang then
                    local distance = #(vector3(gangData.territory.x, gangData.territory.y, gangData.territory.z) - 
                                       vector3(rivalData.territory.x, rivalData.territory.y, rivalData.territory.z))
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
        Citizen.Wait(14400000) 
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

RegisterNetEvent('gangWars:playerAttackedGang')
AddEventHandler('gangWars:playerAttackedGang', function(gangName)
    if Config.Gangs[gangName] then
        print("^1ALERT:^0 Player attack detected on " .. gangName .. "! Retaliation initiated.")
        TriggerEvent('gangWars:triggerGangWar', gangName)
    end
end)

RegisterNetEvent("gangwars:spawnGangMembers")
AddEventHandler("gangwars:spawnGangMembers", function(gangData)
    local src = source
    TriggerClientEvent("gangwars:spawnGangMembers", src, gangData)
end)
