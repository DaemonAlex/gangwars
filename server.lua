if not Config then
    print("^1ERROR:^0 Config is not loaded! Check fxmanifest.lua.")
end

local Ox = exports.ox_lib

-- ✅ Define Gangs and Their Territories
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

-- ✅ Function to Spawn Gang Members
function SpawnGangMembers(gangName)
    local gang = Config.Gangs[gangName]
    if not gang then 
        print("^1ERROR:^0 Gang not found: " .. gangName)
        return 
    end

    for i = 1, 5 do  -- Spawn 5 NPCs per gang
        local pedModel = gang.models[math.random(#gang.models)]
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do Wait(10) end

        local ped = CreatePed(4, pedModel, gang.territory.x + math.random(-10, 10), gang.territory.y + math.random(-10, 10), gang.territory.z, 0.0, true, true)
        GiveWeaponToPed(ped, GetHashKey("WEAPON_PISTOL"), 250, false, true)
        TaskCombatHatedTargetsAroundPed(ped, 50.0, 0)
        SetPedRelationshipGroupHash(ped, GetHashKey(gangName))
        SetPedAccuracy(ped, 75)
        SetPedCombatMovement(ped, 2) -- 2: Will move around in combat
        SetPedCombatAbility(ped, 2) -- 2: Professional
        SetPedCombatRange(ped, 2) -- 2: Far
        SetPedCombatAttributes(ped, 46, true) -- Always fight
    end

    print("^2SUCCESS:^0 Spawned gang members for: " .. gangName)
end

-- ✅ Event to Trigger a Gang War
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

-- ✅ Event to Handle Players Joining a Gang
RegisterNetEvent('gangWars:playerJoinedGang')
AddEventHandler('gangWars:playerJoinedGang', function(gangName)
    local src = source
    if Config.Gangs[gangName] then
        print("^2SUCCESS:^0 Player " .. GetPlayerName(src) .. " joined " .. gangName)
        TriggerClientEvent('ox_lib:notify', src, {title = 'Gang Joined', description = 'You are now part of ' .. gangName, type = 'success'})
    else
        print("^1ERROR:^0 Invalid gang: " .. gangName)
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Invalid gang.', type = 'error'})
    end
end)
