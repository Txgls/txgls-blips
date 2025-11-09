local Config = {
    DatabaseResource = 'oxmysql'
}

local function ExecuteQuery(query, parameters, callback)
    if Config.DatabaseResource == 'oxmysql' then
        exports.oxmysql:execute(query, parameters, callback)
    elseif Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.execute(query, parameters, callback)
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, parameters, callback)
    end
end

local function FetchQuery(query, parameters, callback)
    if Config.DatabaseResource == 'oxmysql' then
        exports.oxmysql:fetch(query, parameters, callback)
    elseif Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.fetchAll(query, parameters, callback)
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, parameters, callback)
    end
end

local function LoadBlipsFromDatabase()
    local query = "SELECT * FROM txgls_blips ORDER BY created_at ASC"
    
    FetchQuery(query, {}, function(results)
        if results then
            print('^2[TXGLS-BLIPS]^7 Loaded ' .. #results .. ' blips from database')
            
            for _, player in ipairs(GetPlayers()) do
                TriggerClientEvent('txgls-blips:loadBlips', player, results)
            end
        else
            print('^1[TXGLS-BLIPS]^7 Failed to load blips from database')
        end
    end)
end

RegisterNetEvent('txgls-blips:createBlip')
AddEventHandler('txgls-blips:createBlip', function(blipData)
    local source = source
    local playerName = GetPlayerName(source)
    local playerIdentifier = GetPlayerIdentifier(source, 0)
    
    if not blipData.name or not blipData.sprite or not blipData.color or not blipData.size or
       not blipData.coords or not blipData.coords.x or not blipData.coords.y or not blipData.coords.z then
        TriggerClientEvent('txgls-blips:notify', source, 'Invalid blip data provided', 'error')
        return
    end
    
    local name = tostring(blipData.name):gsub('[^%w%s%-_]', '')
    local sprite = tonumber(blipData.sprite)
    local color = tonumber(blipData.color)
    local size = tonumber(blipData.size)
    local x = tonumber(blipData.coords.x)
    local y = tonumber(blipData.coords.y)
    local z = tonumber(blipData.coords.z)
    
    if sprite < 1 or sprite > 826 then
        TriggerClientEvent('txgls-blips:notify', source, 'Sprite ID must be between 1 and 826', 'error')
        return
    end
    
    if color < 0 or color > 85 then
        TriggerClientEvent('txgls-blips:notify', source, 'Color ID must be between 0 and 85', 'error')
        return
    end
    
    if size < 0.5 or size > 1.0 then
        TriggerClientEvent('txgls-blips:notify', source, 'Size must be between 0.5 and 1.0', 'error')
        return
    end
    
    if not x or not y or not z then
        TriggerClientEvent('txgls-blips:notify', source, 'Invalid coordinates provided', 'error')
        return
    end
    
    local checkQuery = "SELECT id FROM txgls_blips WHERE name = ?"
    FetchQuery(checkQuery, {name}, function(existing)
        if existing and #existing > 0 then
            TriggerClientEvent('txgls-blips:notify', source, 'A blip with this name already exists', 'error')
            return
        end
        
        local insertQuery = [[
            INSERT INTO txgls_blips (name, sprite, color, size, x, y, z, created_by) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]]
        
        ExecuteQuery(insertQuery, {name, sprite, color, size, x, y, z, playerIdentifier}, function(result)
            if result and result.affectedRows and result.affectedRows > 0 then
                print('^2[TXGLS-BLIPS]^7 ' .. playerName .. ' created blip: ' .. name)
                
                local newBlip = {
                    id = result.insertId,
                    name = name,
                    sprite = sprite,
                    color = color,
                    size = size,
                    coords = {x = x, y = y, z = z},
                    created_by = playerIdentifier,
                    created_at = os.date('%Y-%m-%d %H:%M:%S')
                }
                
                TriggerClientEvent('txgls-blips:blipCreated', -1, newBlip)
                TriggerClientEvent('txgls-blips:notify', source, 'Blip "' .. name .. '" created successfully!', 'success')
            else
                print('^1[TXGLS-BLIPS]^7 Failed to create blip: ' .. name)
                TriggerClientEvent('txgls-blips:notify', source, 'Failed to create blip in database', 'error')
            end
        end)
    end)
end)

RegisterNetEvent('txgls-blips:deleteBlip')
AddEventHandler('txgls-blips:deleteBlip', function(blipName)
    local source = source
    local playerName = GetPlayerName(source)
    
    if not blipName or blipName == '' then
        TriggerClientEvent('txgls-blips:notify', source, 'Invalid blip name provided', 'error')
        return
    end
    
    local name = tostring(blipName):gsub('[^%w%s%-_]', '')
    
    local checkQuery = "SELECT id FROM txgls_blips WHERE name = ?"
    FetchQuery(checkQuery, {name}, function(existing)
        if not existing or #existing == 0 then
            TriggerClientEvent('txgls-blips:notify', source, 'Blip "' .. name .. '" not found', 'error')
            return
        end
        
        local deleteQuery = "DELETE FROM txgls_blips WHERE name = ?"
        ExecuteQuery(deleteQuery, {name}, function(result)
            if result and result.affectedRows and result.affectedRows > 0 then
                print('^3[TXGLS-BLIPS]^7 ' .. playerName .. ' deleted blip: ' .. name)
                
                TriggerClientEvent('txgls-blips:blipDeleted', -1, name)
                TriggerClientEvent('txgls-blips:notify', source, 'Blip "' .. name .. '" deleted successfully!', 'success')
            else
                print('^1[TXGLS-BLIPS]^7 Failed to delete blip: ' .. name)
                TriggerClientEvent('txgls-blips:notify', source, 'Failed to delete blip from database', 'error')
            end
        end)
    end)
end)

RegisterNetEvent('txgls-blips:requestBlips')
AddEventHandler('txgls-blips:requestBlips', function()
    local source = source
    
    local query = "SELECT * FROM txgls_blips ORDER BY created_at ASC"
    FetchQuery(query, {}, function(results)
        if results then
            TriggerClientEvent('txgls-blips:loadBlips', source, results)
        else
            TriggerClientEvent('txgls-blips:loadBlips', source, {})
        end
    end)
end)

RegisterNetEvent('txgls-blips:updateBlipCoords')
AddEventHandler('txgls-blips:updateBlipCoords', function(blipName, newCoords)
    local source = source
    local playerName = GetPlayerName(source)
    
    if not blipName or not newCoords or not newCoords.x or not newCoords.y or not newCoords.z then
        TriggerClientEvent('txgls-blips:notify', source, 'Invalid data provided', 'error')
        return
    end
    
    local name = tostring(blipName):gsub('[^%w%s%-_]', '')
    local x = tonumber(newCoords.x)
    local y = tonumber(newCoords.y)
    local z = tonumber(newCoords.z)
    
    local updateQuery = "UPDATE txgls_blips SET x = ?, y = ?, z = ? WHERE name = ?"
    ExecuteQuery(updateQuery, {x, y, z, name}, function(result)
        if result and result.affectedRows and result.affectedRows > 0 then
            print('^3[TXGLS-BLIPS]^7 ' .. playerName .. ' updated blip coordinates: ' .. name)
            TriggerClientEvent('txgls-blips:blipUpdated', -1, name, {x = x, y = y, z = z})
            TriggerClientEvent('txgls-blips:notify', source, 'Blip coordinates updated!', 'success')
        else
            TriggerClientEvent('txgls-blips:notify', source, 'Failed to update blip coordinates', 'error')
        end
    end)
end)


AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[TXGLS-BLIPS]^7 Loading blips from database...')
        
        Citizen.Wait(2000)
        LoadBlipsFromDatabase()
    end
end)

AddEventHandler('playerConnecting', function()
    local source = source
    Citizen.Wait(5000)
    
    local query = "SELECT * FROM txgls_blips ORDER BY created_at ASC"
    FetchQuery(query, {}, function(results)
        if results then
            TriggerClientEvent('txgls-blips:loadBlips', source, results)
        end
    end)
end)
