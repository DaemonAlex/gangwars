fx_version 'cerulean'
games { 'gta5' }

author 'Deamonalex'
description 'Dynamic Gang Wars Script with Enhanced Interactions using ox_lib'
version '1.0.0'

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'  
client_script 'client.lua'
server_script 'server.lua'

dependency 'ox_lib'
