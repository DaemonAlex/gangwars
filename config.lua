Config = Config or {}

-- Gang Data (Territories, NPCs, and Vehicles)
Config.Gangs = {
    ['Ballas'] = {
        territory = vector3(114.3, -1961.1, 21.3),
        models = {'g_m_y_ballaorig_01', 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'csb_ballasog'},
        vehicles = {'buccaneer', 'peyote', 'voodoo'}
    },
    ['Vagos'] = {
        territory = vector3(325.2, -2050.4, 20.9),
        models = {'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03', 'csb_ortega'},
        vehicles = {'tornado3', 'chino', 'buccaneer2'}
    },
    ['Families'] = {
        territory = vector3(-154.6, -1608.4, 34.8),
        models = {'g_f_y_families_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01', 'csb_ramp_gang'},
        vehicles = {'greenwood', 'manana', 'tornado'}
    },
    ['Triads'] = {
        territory = vector3(-820.4, -700.3, 27.9),
        models = {'g_m_m_chigoon_01', 'g_m_m_chigoon_02', 'g_m_y_korean_01', 'g_m_y_korean_02'},
        vehicles = {'tailgater', 'sultan', 'schafter2'}
    },
    ['Madrazo'] = {
        territory = vector3(1391.5, 1152.2, 114.3),
        models = {'g_m_m_armboss_01', 'g_m_m_armlieut_01', 'g_m_m_armgoon_01', 'csb_mweather'},
        vehicles = {'xls', 'granger', 'mesa'}
    }
}

-- Distance for receiving notifications about gang activity
Config.NotificationDistance = 500.0 -- Players within this radius will receive gang war notifications

-- Jobs that should receive police alerts when gang fights occur
Config.PoliceJobs = {'police', 'sheriff', 'statepolice'}

-- 🚀 **Optional: Configure Gang Spawn Behavior**
Config.GangSpawnSettings = {
    minPeds = 2,   -- Minimum number of NPCs spawned per gang
    maxPeds = 5,   -- Maximum number of NPCs spawned per gang
    armed = true   -- Should NPCs spawn with weapons?
}
