Config = Config or {}

Config.Gangs = {
    ['Ballas'] = {
        territory = {
            vector3(114.3, -1961.1, 21.3),
            vector3(118.3, -1959.1, 21.3),
            vector3(110.2, -1965.0, 21.3)
        },
        models = {'g_m_y_ballaorig_01', 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'csb_ballasog'},
        vehicles = {'buccaneer', 'peyote', 'voodoo'}
    },
    ['Vagos'] = {
        territory = {
            vector3(325.2, -2050.4, 20.9),
            vector3(330.2, -2048.4, 20.9),
            vector3(322.0, -2053.0, 20.9)
        },
        models = {'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03', 'csb_ortega'},
        vehicles = {'tornado3', 'chino', 'buccaneer2'}
    },
    ['Families'] = {
        territory = {
            vector3(-154.6, -1608.4, 34.8),
            vector3(-152.0, -1610.4, 34.8),
            vector3(-156.0, -1612.0, 34.8)
        },
        models = {'g_f_y_families_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01', 'csb_ramp_gang'},
        vehicles = {'greenwood', 'manana', 'tornado'}
    },
    ['Triads'] = {
        territory = {
            vector3(-820.4, -700.3, 27.9),
            vector3(-825.0, -695.2, 27.9),
            vector3(-815.5, -705.6, 27.9)
        },
        models = {'g_m_m_chigoon_01', 'g_m_m_chigoon_02', 'g_m_y_korean_01', 'g_m_y_korean_02'},
        vehicles = {'tailgater', 'sultan', 'schafter2'}
    },
    ['Madrazo'] = {
        territory = {
            vector3(1391.5, 1152.2, 114.3),
            vector3(1395.0, 1155.2, 114.3),
            vector3(1387.0, 1149.4, 114.3)
        },
        models = {'g_m_m_armboss_01', 'g_m_m_armlieut_01', 'g_m_m_armgoon_01', 'csb_mweather'},
        vehicles = {'xls', 'granger', 'mesa'}
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
    armed = true
}
