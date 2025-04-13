local QBCore = exports['qb-core']:GetCoreObject()

-- Ensure we're using the same Config structure as client.lua
Config = Config or { Gangs = {}, PoliceJobs = {} }

local lastWarTime = {}
local warCooldown = 600000  -- 10 minutes cooldown
local gangMembers = {} -- Track players in gangs: {gangName = {player1, player2, ...}}

-- Debug logging - Use pcall to prevent errors if JSON encoding fails
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for config to load
    print("^2DEBUG:^0 Server script loaded")
    local status, result = pcall(function()
        for gang, data in pairs(Config.Gangs or {}) do
            print("^2DEBUG:^0 Gang loaded: " .. gang)
            -- Initialize gang members tracker
            gangMembers[gang] = {}
        end
    end)
    
    if not status then
        print("^1ERROR:^0 Failed to print config: " .. tostring(result))
    end
end)

-- Safe notification function for server-side
local function SafeNotifyPlayer(playerId, data)
    if not playerId then return end
    
    -- Use basic chat notification as fallback if ox_lib fails
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {255, 0, 0},
        multiline = true,
        args = {data.title, data.description}
    })
    
    -- Try ox_lib notify if available (will silently fail if not)
    pcall(function()
        TriggerClientEvent('ox_lib:notify', playerId, data)
    end)
end

-- Track player's gang when they load
RegisterNetEvent('QBCore:Server:PlayerLoaded')
AddEventHandler('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.metadata and Player.PlayerData.metadata.gang then
        local gangName = Player.PlayerData.metadata.gang
        
        -- Make sure gang exists
        if Config.Gangs[gangName] then
            -- Add player to gang member list
            if not gangMembers[gangName] then
                gangMembers[gangName] = {}
            end
            
            table.insert(gangMembers[gangName], src)
            print("^3INFO:^0 Player " .. src .. " loaded with gang: " .. gangName)
        end
    end
end)

-- Handle player disconnecting
AddEventHandler('playerDropped', function()
    local src = source
    
    -- Remove player from any gang member list
    for gang, members in pairs(gangMembers) do
        for i, playerId in ipairs(members) do
            if playerId == src then
                table.remove(gangMembers[gang], i)
                print("^3INFO:^0 Player " .. src .. " removed from gang: " .. gang)
                break
            end
        end
    end
end)

-- Handle a player joining a gang
RegisterNetEvent('gangWars:playerJoinedGang')
AddEventHandler('gangWars:playerJoinedGang', function(gangName)
    local src = source
    if not gangName or not Config.Gangs[gangName] then
        SafeNotifyPlayer(src, {
            title = 'Error',
            description = 'Invalid gang name',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Remove from old gang if present
    if Player.PlayerData.metadata and Player.PlayerData.metadata.gang then
        local oldGang = Player.PlayerData.metadata.gang
        
        if gangMembers[oldGang] then
            for
