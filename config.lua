Config = Config or {}

Config.Gangs = {
    ['Ballas'] = {
        territory = {
            { x = 114.3, y = -1961.1, z = 21.3 },
            { x = 118.3, y = -1959.1, z = 21.3 },
            { x = 110.2, y = -1965.0, z = 21.3 }
        },
        models = { 'g_m_y_ballaorig_01', 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'csb_ballasog' },
        vehicles = { 'buccaneer', 'peyote', 'voodoo' },
        weapons = { 'WEAPON_MICROSMG', 'WEAPON_PISTOL', 'WEAPON_BAT', 'WEAPON_KNIFE' },
        color = { id = 27, r = 128, g = 0, b = 128, alpha = 128 }, -- Purple
        props = { 'prop_drug_package', 'prop_mp_drug_package', 'prop_drug_bottle' },
        clothing = {
            [0] = { drawable = 0, texture = 0 },    -- Face
            [1] = { drawable = 5, texture = 0 },    -- Mask
            [2] = { drawable = 0, texture = 1 },    -- Hair
            [3] = { drawable = 0, texture = 0 },    -- Torso
            [4] = { drawable = 5, texture = 2 },    -- Legs
            [8] = { drawable = 0, texture = 0 },    -- T-shirt
            [11] = { drawable = 15, texture = 6 }   -- Jacket
        }
    },
    ['Vagos'] = {
        territory = {
            { x = 325.2, y = -2050.4, z = 20.9 },
            { x = 330.2, y = -2048.4, z = 20.9 },
            { x = 322.0, y = -2053.0, z = 20.9 }
        },
        models = { 'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03', 'csb_ortega' },
        vehicles = { 'tornado3', 'chino', 'buccaneer2' },
        weapons = { 'WEAPON_MICROSMG', 'WEAPON_PISTOL', 'WEAPON_MACHETE', 'WEAPON_CROWBAR' },
        color = { id = 5, r = 255, g = 255, b = 0, alpha = 128 }, -- Yellow
        props = { 'prop_drug_package_02', 'hei_prop_drug_statue_box_01', 'hei_prop_heist_drug_tub_01' },
        clothing = {
            [0] = { drawable = 0, texture = 0 },
            [1] = { drawable = 0, texture = 0 },
            [2] = { drawable = 0, texture = 0 },
            [3] = { drawable = 0, texture = 0 },
            [4] = { drawable = 5, texture = 0 },    -- Yellow pants
            [8] = { drawable = 0, texture = 0 },
            [11] = { drawable = 14, texture = 7 }   -- Yellow jacket
        }
    },
    ['Families'] = {
        territory = {
            { x = -154.6, y = -1608.4, z = 34.8 },
            { x = -152.0, y = -1610.4, z = 34.8 },
            { x = -156.0, y = -1612.0, z = 34.8 }
        },
        models = { 'g_f_y_families_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01', 'csb_ramp_gang' },
        vehicles = { 'greenwood', 'manana', 'tornado' },
        weapons = { 'WEAPON_MICROSMG', 'WEAPON_PISTOL', 'WEAPON_HEAVYPISTOL', 'WEAPON_SWITCHBLADE' },
        color = { id = 2, r = 0, g = 128, b = 0, alpha = 128 }, -- Green
        props = { 'hei_prop_drug_package_02', 'hei_prop_drug_package_01', 'prop_weed_01' },
        clothing = {
            [0] = { drawable = 0, texture = 0 },
            [1] = { drawable = 0, texture = 0 },
            [2] = { drawable = 0, texture = 0 },
            [3] = { drawable = 0, texture = 0 },
            [4] = { drawable = 1, texture = 4 },    -- Green pants
            [8] = { drawable = 0, texture = 0 },
            [11] = { drawable = 14, texture = 0 }   -- Green jacket
        }
    },
    ['Triads'] = {
        territory = {
            { x = -820.4, y = -700.3, z = 27.9 },
            { x = -825.0, y = -695.2, z = 27.9 },
            { x = -815.5, y = -705.6, z = 27.9 }
        },
        models = { 'g_m_m_chigoon_01', 'g_m_m_chigoon_02', 'g_m_y_korean_01', 'g_m_y_korean_02' },
        vehicles = { 'tailgater', 'sultan', 'schafter2' },
        weapons = { 'WEAPON_ASSAULTSMG', 'WEAPON_APPISTOL', 'WEAPON_KNIFE', 'WEAPON_COMBATPISTOL' },
        color = { id = 1, r = 255, g = 0, b = 0, alpha = 128 }, -- Red
        props = { 'h4_prop_h4_coke_bale_01a', 'h4_prop_h4_coke_bottle_01a', 'h4_prop_h4_coke_metalbowl_01' },
        clothing = {
            [0] = { drawable = 0, texture = 0 },
            [1] = { drawable = 0, texture = 0 },
            [2] = { drawable = 0, texture = 0 },
            [3] = { drawable = 0, texture = 0 },
            [4] = { drawable = 4, texture = 0 },    -- Black pants
            [8] = { drawable = 0, texture = 0 },
            [11] = { drawable = 16, texture = 0 }   -- Black suit
        }
    },
    ['Madrazo'] = {
        territory = {
            { x = 1391.5, y = 1152.2, z = 114.3 },
            { x = 1395.0, y = 1155.2, z = 114.3 },
            { x = 1387.0, y = 1149.4, z = 114.3 }
        },
        models = { 'g_m_m_armboss_01', 'g_m_m_armlieut_01', 'g_m_m_armgoon_01', 'csb_mweather' },
        vehicles = { 'xls', 'granger', 'mesa' },
        weapons = { 'WEAPON_ADVANCEDRIFLE', 'WEAPON_PISTOL50', 'WEAPON_BULLPUPRIFLE', 'WEAPON_HEAVYPISTOL' },
        color = { id = 40, r = 64, g = 64, b = 64, alpha = 128 }, -- Dark Grey
        props = { 'prop_box_guncase_01a', 'prop_box_guncase_02a', 'hei_prop_carrier_crate_01a' },
        clothing = {
            [0] = { drawable = 0, texture = 0 },
            [1] = { drawable = 0, texture = 0 },
            [2] = { drawable = 0, texture = 0 },
            [3] = { drawable = 0, texture = 0 },
            [4] = { drawable = 4, texture = 0 },    -- Dark pants
            [8] = { drawable = 0, texture = 0 },
            [11] = { drawable = 12, texture = 2 }   -- Classy suit jacket
        }
    }
}

Config.NotificationDistance = 500.0 

Config.PoliceJobs = {
    police = true,
    sheriff = true,
    statepolice = true
}

Config.TerritoryRadius = 100.0  -- Radius of gang territory in units

Config.GangSpawnSettings = {
    minPeds = 2,          -- Minimum peds to spawn per gang
    maxPeds = 5,          -- Maximum peds to spawn per gang
    armed = true,         -- If false, gang NPCs spawn unarmed
    despawnTime = 300000  -- Time until gang members despawn (5 minutes)
}

-- Enable ambient gang population in territories
Config.EnableAmbientGangs = true

-- Additional settings
Config.WarSettings = {
    proximityThreshold = 1000.0, -- Distance between territories to trigger wars
    randomWarInterval = 14400000, -- Time between random wars (4 hours)
    proximityWarInterval = 300000, -- Time between proximity war checks (5 minutes)
    warCooldown = 600000 -- Cooldown period after a war (10 minutes)
}

-- Gang-specific preferences for ambience
Config.Ambience = {
    ['Ballas'] = {
        scenerios = {
            'WORLD_HUMAN_DRUG_DEALER',
            'WORLD_HUMAN_HANG_OUT_STREET', 
            'WORLD_HUMAN_SMOKING'
        },
        idleAnimation = {
            dict = 'amb@world_human_guard_stand@male@base',
            anim = 'base'
        }
    },
    ['Triads'] = {
        scenerios = {
            'WORLD_HUMAN_STAND_MOBILE', 
            'WORLD_HUMAN_SMOKING', 
            'WORLD_HUMAN_CLIPBOARD'
        },
        idleAnimation = {
            dict = 'amb@world_human_stand_guard@male@base',
            anim = 'base'
        }
    },
    ['Madrazo'] = {
        scenerios = {
            'WORLD_HUMAN_GUARD_STAND', 
            'WORLD_HUMAN_SMOKING', 
            'WORLD_HUMAN_DRINKING'
        },
        idleAnimation = {
            dict = 'amb@world_human_stand_guard@male@base',
            anim = 'base'
        }
    },
    ['Vagos'] = {
        scenerios = {
            'WORLD_HUMAN_DRINKING', 
            'WORLD_HUMAN_SMOKING', 
            'WORLD_HUMAN_LEANING'
        },
        idleAnimation = {
            dict = 'amb@world_human_hang_out_street@male_c@base',
            anim = 'base'
        }
    },
    ['Families'] = {
        scenerios = {
            'WORLD_HUMAN_STAND_IMPATIENT', 
            'WORLD_HUMAN_SMOKING_POT', 
            'WORLD_HUMAN_DRINKING'
        },
        idleAnimation = {
            dict = 'amb@world_human_stand_guard@male@base',
            anim = 'base'
        }
    }
}

-- Visual Props for gang territories (will be randomly placed)
Config.TerritoryProps = {
    ['Ballas'] = {
        { model = 'prop_drug_package', heading = true },
        { model = 'prop_beach_fire', heading = false },
        { model = 'prop_speaker_07', heading = true },
        { model = 'prop_food_cb_tray_02', heading = true }
    },
    ['Vagos'] = {
        { model = 'prop_drug_package_02', heading = true },
        { model = 'prop_beer_box_01', heading = true },
        { model = 'prop_gate_tep_01_l', heading = true },
        { model = 'prop_bbq_3', heading = true }
    },
    ['Families'] = {
        { model = 'hei_prop_drug_package_02', heading = true },
        { model = 'prop_weed_01', heading = false },
        { model = 'prop_beachflag_01', heading = true },
        { model = 'prop_bench_03', heading = true }
    },
    ['Triads'] = {
        { model = 'prop_box_ammo03a', heading = true },
        { model = 'prop_cs_paper_cup', heading = true },
        { model = 'prop_table_08', heading = true },
        { model = 'prop_bin_12', heading = true }
    },
    ['Madrazo'] = {
        { model = 'prop_box_guncase_01a', heading = true },
        { model = 'prop_cs_documents_01', heading = true },
        { model = 'prop_yacht_table_02', heading = true },
        { model = 'prop_fruit_basket', heading = true }
    }
}

-- Gang reputation system
Config.RepSystem = {
    enabled = true,
    baseReputation = 100,
    reputationGain = {
        joinGang = 50,
        killRival = 10,
        defendTerritory = 20,
        winWar = 30
    },
    reputationLoss = {
        leaveGang = 100,
        attackOwnGang = 50,
        dieInWar = 10,
        loseWar = 20
    },
    benefitsThresholds = {
        [50] = "Basic gang member - standard weapons",
        [100] = "Regular gang member - better weapons and armor",
        [200] = "Experienced gang member - vehicle access",
        [300] = "Trusted gang member - special weapons and abilities",
        [500] = "Lieutenant - command abilities and best gear"
    }
}
