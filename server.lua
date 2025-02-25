local Ox = exports.ox_lib

Config.Gangs = {
    ['Ballas'] = {
        territory = {x = 114.3, y = -1961.1, z = 21.3},
        models = {'g_m_y_ballaorig_01', 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'csb_ballasog'},
        streetVibeModels = {'a_m_y_hipster_01', 'a_m_y_hipster_02', 'a_m_y_hipster_03'},
        homelessModels = {'a_m_o_soucent_03', 'a_m_m_tramp_01'},
        workingModels = {'s_m_y_construct_01', 's_m_y_construct_02'},
        vehicles = {'buccaneer', 'peyote', 'voodoo', 'daemon', 'hexer'}
    },
    ['Families'] = {
        territory = {x = -154.6, y = -1608.4, z = 34.8},
        models = {'g_f_y_families_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01', 'csb_ramp_gang'},
        streetVibeModels = {'a_m_y_stbla_01', 'a_m_y_stbla_02', 'a_m_y_stbla_03'},
        homelessModels = {'a_m_m_trampbeac_01', 'a_m_o_tramp_01'},
        workingModels = {'s_m_y_garbage', 's_m_y_dockwork_01'},
        vehicles = {'greenwood', 'manana', 'tornado', 'bagger', 'double'}
    },
    ['Vagos'] = {
        territory = {x = 334.2, y = -2036.2, z = 21.2},
        models = {'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03', 'g_f_y_vagos_01'},
        streetVibeModels = {'a_m_m_soucent_01', 'a_m_m_soucent_02', 'a_m_m_soucent_04'},
        homelessModels = {'a_m_m_tramp_01', 'a_m_o_soucent_03'},
        workingModels = {'s_m_m_autoshop_01', 's_m_m_autoshop_02'},
        vehicles = {'emperor', 'tornado', 'chino', 'sanctus', 'innovation'}
    }
}

function spawnGangMember(gangName, offset, armed)
    local gang = Config.Gangs[gangName]
    local coords = vector3(gang.territory.x + offset.x, gang.territory.y + offset.y, gang.territory.z)
    local modelPool = {table.unpack(gang.models), table.unpack(gang.streetVibeModels), table.unpack(gang.homelessModels), table.unpack(gang.workingModels)}
    local pedModel = modelPool[math.random(#modelPool)]

    local ped = Ox.spawnPed({
        model = pedModel,
        coords = coords,
        heading = math.random(360),
        isNetwork = true,
        isInvincible = false,
        freeze = false
    })

    SetPedAsGroupMember(ped, gangName)
    SetPedRelationshipGroupHash(ped, GetHashKey(gangName))
    TaskWanderStandard(ped, 10.0, 10)
    if armed and math.random(1, 100) <= 80 then
        GiveWeaponToPed(ped, GetHashKey("WEAPON_PISTOL"), 255, false, true)
    end
}

function spawnGangVehicle(gangName, offset)
    local gang = Config.Gangs[gangName]
    local coords = vector3(gang.territory.x + offset.x, gang.territory.y + offset.y, gang.territory.z)
    local vehicleModel = gang.vehicles[math.random(#gang.vehicles)]

    local vehicle = Ox.spawnVehicle({
        model = vehicleModel,
        coords = coords,
        heading = math.random(360),
        isNetwork = true,
        persistent = false
    })

    SetVehicleColourCombination(vehicle, math.random(0, 12))
    return vehicle
}

function gangFight(gangName)
    local gang = Config.Gangs[gangName]
    local offset = {x = math.random(-20, 20), y = math.random(-20, 20), z = 0}
    spawnGangMember(gangName, offset, true)
    offset = {x = offset.x + 10, y = offset.y + 10, z = 0}  -- Offset for vehicles to spawn nearby
    spawnGangVehicle(gangName, offset)
}

Citizen.CreateThread(function()
    while true do
        local waitTime = math.random(15, 30) * 60000
        Citizen.Wait(waitTime)
        for gangName, _ in pairs(Config.Gangs) do
            local offset = {x = math.random(-10, 10), y = math.random(-10, 10), z = 0}
            spawnGangMember(gangName, offset, false)
            if math.random(1, 100) <= 50 then
                gangFight(gangName)
            }
        end
    end
end)
