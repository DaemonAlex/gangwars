RegisterNetEvent("gangFightNotification")
AddEventHandler("gangFightNotification", function(location)
  SetNotificationTextEntry("STRING")
  AddTextComponentString("Gang fight detected nearby!")
  DrawNotification(false, false)
end)

RegisterNetEvent("targetedNotification")
AddEventHandler("targetedNotification", function(gangName)
  SetNotificationTextEntry("STRING")
  AddTextComponentString("You have been targeted by the ".. gangName.. " gang!")
  DrawNotification(false, false)
end)

local gangMembers = {}
RegisterNetEvent("gangMemberSpawned")
AddEventHandler("gangMemberSpawned", function(gangMember)
  table.insert(gangMembers, gangMember)
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(1000)
   
    for _, gangMember in ipairs(gangMembers) do
      local ped = GetPedFromHandle(gangMember.pedHandle)
      if DoesEntityExist(ped) then
      
        DrawMarker(1, gangMember.location.x, gangMember.location.y, gangMember.location.z, 0, 255, 0, 255, 1.0, 1.0, 1.0, 1.0, 1.0, 255, 255, 255, 255)
      end
    end
  end
end)

RegisterNetEvent("gangMemberDeleted")
AddEventHandler("gangMemberDeleted", function(gangMember)
  for i, member in ipairs(gangMembers) do
    if member.pedHandle == gangMember.pedHandle then
      table.remove(gangMembers, i)
    end
  end
end)


Citizen.CreateThread(function()
  while true do
    Citizen.Wait(1000)
    for _, gangMember in ipairs(gangMembers) do
      local ped = GetPedFromHandle(gangMember.pedHandle)
      if DoesEntityExist(ped) then
        local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), gangMember.location.x, gangMember.location.y, gangMember.location.z)
        if distance < 5.0 then
      
          SetNotificationTextEntry("STRING")
          AddTextComponentString("Gang Member: ".. gangMember.name)
          AddTextComponentString("Gang: ".. gangMember.gangName)
          DrawNotification(false, false)
        end
      end
    end
  end
end)
