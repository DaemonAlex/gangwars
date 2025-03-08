Config = Config or {}

Config.Gangs = {
    ['Ballas'] = {
        territory = {
            { x = 114.3, y = -1961.1, z = 21.3 },
            { x = 118.3, y = -1959.1, z = 21.3 },
            { x = 110.2, y = -1965.0, z = 21.3 }
        },
        models = { 'g_m_y_ballaorig_01', 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'csb_ballasog' },
        vehicles = { 'buccaneer', 'peyote', 'voodoo' }
    },
    ['Vagos'] = {
        territory = {
            { x = 325.2, y = -2050.4, z = 20.9 },
            { x = 330.2, y = -2048.4, z = 20.9 },
            { x = 322.0, y = -2053.0, z = 20.9 }
        },
        models = { 'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03', 'csb_ortega' },
        vehicles = { 'tornado3', 'chino', 'buccaneer2' }
    },
    ['Families'] = {
        territory = {
            { x = -154.6, y = -1608.4, z = 34.8 },
            { x = -152.0, y = -1610.4, z = 34.8 },
            { x = -156.0, y = -1612.0, z = 34.8 }
        },
        models = { 'g_f_y_families_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01', 'csb_ramp_gang' },
        vehicles = { 'greenwood', 'manana', 'tornado' }
    },
    ['Triads'] = {
        territory = {
            { x = -820.4, y = -700.3, z = 27.9 },
            { x = -825.0, y = -695.2, z = 27.9 },
            { x = -815.5, y = -705.6, z = 27.9 }
        },
        models = { 'g_m_m_chigoon_01', 'g_m_m_chigoon_02', 'g_m_y_korean_01', 'g_m_y_korean_02' },
        vehicles = { 'tailgater', 'sultan', 'schafter2' }
    },
    ['Madrazo'] = {
        territory = {
            { x = 1391.5, y = 1152.2, z = 114.3 },
            { x = 1395.0, y = 1155.2, z = 114.3 },
            { x = 1387.0, y = 1149.4, z = 114.3 }
        },
        models = { 'g_m_m_armboss_01', 'g_m_m_armlieut_01', 'g_m_m_armgoon_01', 'csb_mweather' },
        vehicles = { 'xls', 'granger', 'mesa' }
    }
}

Config.NotificationDistance = 500.0 

Config.PoliceJobs = {
    police = true,
    sheriff = true,
    statepolice = true
}

Config.GangSpawnSettings = {
    minPeds = 2,
    maxPeds = 5,
    armed = true -- If false, gang NPCs spawn unarmed
}
