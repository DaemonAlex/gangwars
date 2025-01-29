-- Gangs
local gangs = {
  {
    name = "Ballas",
    color = "blue",
    members = {}
  },
  {
    name = "Grove Street",
    color = "green",
    members = {}
  },
  {
    name = "Vagos",
    color = "purple",
    members = {}
  }
}

-- Ped models
local pedModels = {
  -- Ballas
  GetHashKey("g_m_y_ballaeast_01"),
  GetHashKey("g_m_y_ballaorig_01"),
  GetHashKey("g_m_y_ballasout_01"),
  -- Grove Street
  GetHashKey("g_m_y_grove_01"),
  GetHashKey("g_m_y_grove_02"),
  GetHashKey("g_m_y_grove_03"),
  -- Vagos
  GetHashKey("g_m_y_vagos_01"),
  GetHashKey("g_m_y_vagos_02"),
  GetHashKey("g_m_y_vagos_03"),
  -- Other peds
  GetHashKey("cs_ballasog"),
  GetHashKey("cs_grove_01"),
  GetHashKey("cs_vagos_01"),
  GetHashKey("g_m_y_mexgoon_01"),
  GetHashKey("g_m_y_mexgoon_02"),
  GetHashKey("g_m_y_mexgoon_03")
}

-- Function to create gang members
local function createGangMember(gang)
  local ped = CreatePed(26, pedModels[math.random(1, #pedModels)], 0, 0, 0)
  SetPedAsGroupMember(ped, gang.name)
  SetPedRelationshipGroupHash(ped, GetHashKey(gang.name))
  SetPedDefaultComponentVariation(ped)
  SetPedRandomProps(ped)
  gang.members[#gang.members + 1] = ped
end

-- Function to spawn gang members
local function spawnGangMembers()
  for _, gang in ipairs(gangs) do
    for i = 1, 5 do
      createGangMember(gang)
    end
  end
end

local function makeGangsFight()
  for _, gang1 in ipairs(gangs) do
    for _, gang2 in ipairs(gangs) do
      if gang1 ~= gang2 then
        local chance = math.random(1, 100)
        if chance <= 10 and isPlayerNearby(gang1.members[1]) then
          local ped1 = gang1.members[math.random(1, #gang1.members)]
          local ped2 = gang2.members[math.random(1, #gang2.members)]
          SetPedRelationshipGroupHash(ped1, GetHashKey(gang2.name), -1000)
          SetPedRelationshipGroupHash(ped2, GetHashKey(gang1.name), -1000)
        end
      end
    end
  end
end

local function isPlayerNearby(ped)
  local players = GetActivePlayers()
  for _, player in ipairs(players) do
    local playerPed = GetPlayerPed(player)
    local distance = GetDistanceBetweenPeds(ped, playerPed)
    if distance < 50.0 then
      return true
    end
  end
  return false
end

-- Function to target a player
local function targetPlayer(playerId, gangId)
  -- Set a timer and store the player's ID and gang ID
  local timer = 15 * 60 * 1000 -- 15 minutes
  local targetedPlayer = {
    id = playerId,
    gangId = gangId,
    timer = timer
  }
  table.insert(targetedPlayers, targetedPlayer)
end

local function isPlayerTargeted(playerId)
  -- Check if the player is in the targetedPlayers table
  for _, targetedPlayer in ipairs(targetedPlayers) do
    if targetedPlayer.id == playerId then
      return true
    end
  end
  return false
end

Citizen.CreateThread(function()
  spawnGangMembers()
  while true do
    Citizen.Wait(1000)
    makeGangsFight()
  end
end)

-- Targeted players table
local targetedPlayers = {}
