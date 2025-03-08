fx_version 'cerulean'
games { 'gta5' }

lua54 'yes'

author 'Deamonalex'
description 'Dynamic Gang Wars Script with Enhanced Interactions using ox_lib'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',  -- Ensure ox_lib loads first
    'config.lua'
}

client_script 'client.lua'
server_script 'server.lua'

dependency 'ox_lib'
