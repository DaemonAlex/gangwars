QBCore = exports['qb-core']:GetCoreObject()

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
    local spawnX = gang.territory.x + offset.x
    local spawnY = gang.territory.y + offset.y
    local spawnZ = gang.territory.z + offset.z
    local coords = vector3(spawnX, spawnY, spawnZ)

    local modelPool = {table.unpack(gang.models), table.unpack(gang.streetVibeModels), table.unpack(gang.homelessModels), table.unpack(gang.workingModels)}
    local pedModel = modelPool[math.random(#modelPool)]
    local ped = ox_lib:SpawnPed(pedModel, coords, true, true) // Ensure peds are networked
    SetPedAsGroupMember(ped, gangName)
    SetPedRelationshipGroupHash(ped, GetHashKey(gangName))
    TaskWanderStandard(ped, 10.0, 10)
    if armed and math.random(1, 100) <= 80 then  // 80% chance to arm the member
        GiveWeaponToPed(ped, GetHashKey("WEAPON_PISTOL"), 255, false, true)
    end
}

function spawnGangVehicle(gangName, offset)
    local gang = Config.Gangs[gangName]
    local vehicleModel = gang.vehicles[math.random(#gang.vehicles)]
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(500)
    end

    local spawnX = gang.territory.x + offset.x + 20 // Offset to spawn out of direct sight
    local spawnY = gang.territory.y + offset.y + 20
    local spawnZ = gang.territory.z
    local vehicle = CreateVehicle(GetHashKey(vehicleModel), spawnX, spawnY, spawnZ, 0.0, true, false)
    SetVehicleColourCombination(vehicle, math.random(0, 12))
    return vehicle
}

function gangFight(gangName)
    local gang = Config.Gangs[gangName]
    local memberOffset = {x = math.random(-20, 20), y = math.random(-20, 20), z = 0}
    spawnGangMember(gangName, memberOffset, true)
    local vehicleOffset = {x = -30, y = -30, z = 0} // Additional offset for vehicle spawn
    spawnGangVehicle(gangName, vehicleOffset)
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
        }
    end
end)
