local CurrentActionData, this_Spawner = {}, {}
local HasAlreadyEnteredMarker = false
local LastZone, CurrentAction, CurrentActionMsg

-- Vehicle Spawn Menu
function OpenSpawnerMenu()
    if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
        elements =
        {
            {unselectable = true, icon = "fas fa-car", title = "Police Vehicles"}
        }
        for i = 1, #Config.Vehicles, 1 do
        elements[#elements+1] =
        {
            title = Config.Vehicles[i].label,
            model = Config.Vehicles[i].model
        }
        end

        ESX.OpenContext("right", elements, function(menu, data)

            print(json.encode(data)) -- check the console log for this
            result1 = json.encode(data.model)
            print(result1)
            fresult = data.model
            print(fresult)
            vehHash = fresult

            if ESX.Game.IsSpawnPointClear(Config.Zones.VehicleSpawner1.Loc, 5.0) then
                SpawnVehicle(data.model) -- check the exact key for model in data obj
                ESX.ShowNotification(TranslateCap('vehicle_spawned'), "success")
                ESX.CloseContext()
            else
                ESX.ShowNotification(TranslateCap('spawnpoint_blocked'))
            end
        end)
    end
end


function SpawnVehicle(string) -- declare parameter for the model string
    ESX.Game.SpawnVehicle(fresult, Config.Zones.VehicleSpawner1.Loc, Config.Zones.VehicleSpawner1.Heading, function(vehicle)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end)
end



-- Vehicle Return Menu
function OpenReturnMenu()
    local playerCoords = GetEntityCoords(PlayerPedId())
    vehicles = ESX.Game.GetVehiclesInArea(playerCoords, 5.0)

    if #vehicles > 0 then
        for i=1, #vehicles, 1 do
            Model = GetEntityModel(vehicles[i])

            if isVehicleListed(Model) then
                ESX.Game.DeleteVehicle(vehicles[i])
            end
        end
    end
end

function isVehicleListed(Model)
    for _,listedVehicle in pairs(Config.ListedVehicles) do
        if Model == GetHashKey(listedVehicle) then
            return true
        end
    end
    return false
end

-- Entered Marker
AddEventHandler('hasEnteredMarker', function(zone)
if zone == 'spawner_point' then
    CurrentAction = 'spawner_point'
    CurrentActionMsg = _U('press_to_enter')
    CurrentActionData = {}
elseif zone == 'deleter_point' then
    CurrentAction = 'deleter_point'
    CurrentActionMsg = _U('press_to_enter2')
    CurrentActionData = {}
end
end)

-- Exited Marker
AddEventHandler('hasExitedMarker', function()
    ESX.CloseContext()
    CurrentAction = nil
end)

-- Resource Stop
AddEventHandler('onResourceStop', function(resource)
    ESX.CloseContext()
    CurrentAction = nil
end)

-- Enter / Exit marker events & Draw Markers
CreateThread(function()
while true do
    
    if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local isInMarker, letSleep, currentZone = false, true, nil

        for k,v in pairs(Config.Zones) do
            local distance = #(playerCoords - v.Pos)
            local distance2 = #(playerCoords - v.Del)

            if distance < Config.DrawDistance then
                letSleep = false

                if Config.MenuMarker.Type ~= -1 then
                    DrawMarker(Config.MenuMarker.Type, v.Pos, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MenuMarker.x, Config.MenuMarker.y, Config.MenuMarker.z, Config.MenuMarker.r, Config.MenuMarker.g, Config.MenuMarker.b, 100, false, true, 2, false, false, false, false)
                end

                if distance < Config.MenuMarker.x then
                    isInMarker, this_Spawner, currentZone = true, v, 'spawner_point'
                end
            end

            if distance2 < Config.DrawDistance then
                letSleep = false

                if Config.DelMarker.Type ~= -1 then
                    DrawMarker(Config.DelMarker.Type, v.Del, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.DelMarker.x, Config.DelMarker.y, Config.DelMarker.z, Config.DelMarker.r, Config.DelMarker.g, Config.DelMarker.b, 100, false, true, 2, false, false, false, false)
                end

                if distance2 < Config.DelMarker.x then
                    isInMarker, this_Spawner, currentZone = true, v, 'deleter_point'
                end
            end
        end

        if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
            HasAlreadyEnteredMarker, LastZone = true, currentZone
            TriggerEvent('hasEnteredMarker', currentZone)
        end

        if not isInMarker and HasAlreadyEnteredMarker then
            HasAlreadyEnteredMarker = false
            TriggerEvent('hasExitedMarker', LastZone)
        end

        if letSleep then
            Wait(500)
        end
    else
        Wait(sleep)
    end
end
end)

-- Key Controls
CreateThread(function()
while true do
    Wait(0)

    if CurrentAction then
        ESX.ShowHelpNotification(CurrentActionMsg)

        if IsControlJustReleased(0, 38) then
            if CurrentAction == 'spawner_point' then
                OpenSpawnerMenu()
            elseif CurrentAction == 'deleter_point' then
                OpenReturnMenu()
            end

            CurrentAction = nil
        end
    else
        Wait(500)
    end
end
end)