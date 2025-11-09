local blips = {}
local isUIOpen = false

function CreateCustomBlip(blipData)
    local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
    SetBlipSprite(blip, blipData.sprite)
    SetBlipColour(blip, blipData.color)
    SetBlipScale(blip, blipData.size or 1.0)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipData.name)
    EndTextCommandSetBlipName(blip)
    
    blipData.id = blip
    table.insert(blips, blipData)
    return blip
end

function DeleteCustomBlip(blipName)
    for i, blipData in ipairs(blips) do
        if blipData.name == blipName then
            RemoveBlip(blipData.id)
            table.remove(blips, i)
            return true
        end
    end
    return false
end

function GetAllBlips()
    return blips
end

function ClearAllBlips()
    for _, blipData in ipairs(blips) do
        RemoveBlip(blipData.id)
    end
    blips = {}
end

RegisterNetEvent('txgls-blips:loadBlips')
AddEventHandler('txgls-blips:loadBlips', function(databaseBlips)
    ClearAllBlips()
    
    for _, dbBlip in ipairs(databaseBlips) do
        local blipData = {
            name = dbBlip.name,
            sprite = dbBlip.sprite,
            color = dbBlip.color,
            size = tonumber(dbBlip.size) or 1.0,
            coords = {
                x = tonumber(dbBlip.x),
                y = tonumber(dbBlip.y),
                z = tonumber(dbBlip.z)
            },
            created_by = dbBlip.created_by,
            created_at = dbBlip.created_at
        }
        CreateCustomBlip(blipData)
    end
    
    if isUIOpen then
        SendNUIMessage({
            type = "updateBlips",
            blips = GetAllBlips()
        })
    end
end)

RegisterNetEvent('txgls-blips:blipCreated')
AddEventHandler('txgls-blips:blipCreated', function(blipData)
    CreateCustomBlip(blipData)
    
    if isUIOpen then
        SendNUIMessage({
            type = "updateBlips",
            blips = GetAllBlips()
        })
    end
end)

RegisterNetEvent('txgls-blips:blipDeleted')
AddEventHandler('txgls-blips:blipDeleted', function(blipName)
    DeleteCustomBlip(blipName)
    
    if isUIOpen then
        SendNUIMessage({
            type = "updateBlips",
            blips = GetAllBlips()
        })
    end
end)

RegisterNetEvent('txgls-blips:blipUpdated')
AddEventHandler('txgls-blips:blipUpdated', function(blipName, newCoords)
    for i, blipData in ipairs(blips) do
        if blipData.name == blipName then
            RemoveBlip(blipData.id)
            
            blipData.coords = newCoords
            
            local blip = AddBlipForCoord(newCoords.x, newCoords.y, newCoords.z)
            SetBlipSprite(blip, blipData.sprite)
            SetBlipColour(blip, blipData.color)
            SetBlipScale(blip, blipData.size or 1.0)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(blipData.name)
            EndTextCommandSetBlipName(blip)
            
            blipData.id = blip
            break
        end
    end
    
    if isUIOpen then
        SendNUIMessage({
            type = "updateBlips",
            blips = GetAllBlips()
        })
    end
end)

RegisterNetEvent('txgls-blips:clearAllBlips')
AddEventHandler('txgls-blips:clearAllBlips', function()
    ClearAllBlips()
    
    if isUIOpen then
        SendNUIMessage({
            type = "updateBlips",
            blips = GetAllBlips()
        })
    end
end)

RegisterNetEvent('txgls-blips:notify')
AddEventHandler('txgls-blips:notify', function(message, type)
    if isUIOpen then
        SendNUIMessage({
            type = "notification",
            message = message,
            notificationType = type or "info"
        })
    else
        local color = {255, 255, 255}
        if type == "success" then
            color = {0, 255, 0}
        elseif type == "error" then
            color = {255, 0, 0}
        end
        
        TriggerEvent('chat:addMessage', {
            color = color,
            multiline = true,
            args = {"BLIPS", message}
        })
    end
end)

RegisterCommand('createblip', function(source, args, rawCommand)
    if #args < 7 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"BLIPS", "Usage: /createblip [name] [sprite] [color] [size] [x] [y] [z]"}
        })
        return
    end
    
    local name = args[1]
    local sprite = tonumber(args[2])
    local color = tonumber(args[3])
    local size = tonumber(args[4])
    local x = tonumber(args[5])
    local y = tonumber(args[6])
    local z = tonumber(args[7])
    
    if not sprite or not color or not size or not x or not y or not z then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"BLIPS", "Invalid parameters. Make sure sprite, color, size, and coordinates are numbers."}
        })
        return
    end
    
    if size < 0.5 or size > 1.0 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"BLIPS", "Size must be between 0.5 and 1.0"}
        })
        return
    end
    
    local blipData = {
        name = name,
        sprite = sprite,
        color = color,
        size = size,
        coords = {x = x, y = y, z = z}
    }
    
    TriggerServerEvent('txgls-blips:createBlip', blipData)
end)

RegisterCommand('deleteblip', function(source, args, rawCommand)
    if #args < 1 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"BLIPS", "Usage: /deleteblip [name]"}
        })
        return
    end
    
    local name = args[1]
    TriggerServerEvent('txgls-blips:deleteBlip', name)
end)

RegisterCommand('blips', function(source, args, rawCommand)
    if not isUIOpen then
        OpenBlipUI()
    else
        CloseBlipUI()
    end
end)

function OpenBlipUI()
    isUIOpen = true
    SetNuiFocus(true, true)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    SendNUIMessage({
        type = "openUI",
        blips = GetAllBlips(),
        playerCoords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
    })
end

function CloseBlipUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closeUI"
    })
end

RegisterNUICallback('closeUI', function(data, cb)
    CloseBlipUI()
    cb('ok')
end)

RegisterNUICallback('createBlip', function(data, cb)
    local blipData = {
        name = data.name,
        sprite = data.sprite,
        color = data.color,
        size = data.size,
        coords = {x = data.x, y = data.y, z = data.z}
    }
    
    TriggerServerEvent('txgls-blips:createBlip', blipData)
    cb('ok')
end)

RegisterNUICallback('deleteBlip', function(data, cb)
    TriggerServerEvent('txgls-blips:deleteBlip', data.name)
    cb('ok')
end)

RegisterNUICallback('teleportToBlip', function(data, cb)
    for _, blipData in ipairs(blips) do
        if blipData.name == data.name then
            SetEntityCoords(PlayerPedId(), blipData.coords.x, blipData.coords.y, blipData.coords.z, false, false, false, true)
            TriggerEvent('txgls-blips:notify', 'Teleported to blip: ' .. data.name, 'success')
            break
        end
    end
    cb('ok')
end)

RegisterNUICallback('getCurrentPosition', function(data, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z
    })
end)

AddEventHandler('playerSpawned', function()
    Citizen.Wait(2000)
    TriggerServerEvent('txgls-blips:requestBlips')
end)
