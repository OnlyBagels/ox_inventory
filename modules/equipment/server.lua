-- Equipment System Server Module for ox_inventory

-- Equipment slot definitions for ox_inventory
local EquipmentSlots = {
    primary = { slot = 'primary', type = 'primary' },
    secondary = { slot = 'secondary', type = 'secondary' },
    melee = { slot = 'melee', type = 'melee' },
    armor = { slot = 'armor', type = 'armor' },
    bag = { slot = 'bag', type = 'bag' },
    wallet = { slot = 'wallet', type = 'wallet' }
}

-- Helper function to determine equipment type from item name
function GetItemEquipmentType(itemName)
    local equipmentTypes = {
        -- Primary Weapons
        ['weapon_assaultrifle'] = 'primary',
        ['weapon_carbinerifle'] = 'primary',
        ['weapon_advancedrifle'] = 'primary',
        ['weapon_pumpshotgun'] = 'primary',
        ['weapon_sawnoffshotgun'] = 'primary',
        
        -- Secondary Weapons
        ['weapon_pistol'] = 'secondary',
        ['weapon_combatpistol'] = 'secondary',
        ['weapon_appistol'] = 'secondary',
        ['weapon_stungun'] = 'secondary',
        ['weapon_flaregun'] = 'secondary',
        
        -- Melee Weapons
        ['weapon_knife'] = 'melee',
        ['weapon_bat'] = 'melee',
        ['weapon_crowbar'] = 'melee',
        ['weapon_hammer'] = 'melee',
        ['weapon_machete'] = 'melee',
        ['weapon_switchblade'] = 'melee',
        
        -- Body Armor
        ['bulletproof'] = 'armor',
        ['police_vest'] = 'armor',
        ['heavy_armor'] = 'armor',
        ['light_armor'] = 'armor',
        
        -- Bags
        ['backpack'] = 'bag',
        ['duffel_bag'] = 'bag',
        ['sports_bag'] = 'bag',
        ['school_bag'] = 'bag',
        
        -- Wallets
        ['wallet'] = 'wallet',
        ['id_card'] = 'wallet',
        ['driver_license'] = 'wallet'
    }
    
    return equipmentTypes[itemName]
end

-- Function to get player equipment (items assigned to slots, not necessarily equipped)
function Inventory.GetPlayerEquipment(source)
    local inv = Inventory(source)
    if not inv then return {} end
    
    local equipment = {}
    for slotType, config in pairs(EquipmentSlots) do
        for _, item in pairs(inv.items) do
            if item and item.metadata and item.metadata.assignedToSlot == slotType then
                equipment[slotType] = item
                break
            end
        end
    end
    
    return equipment
end

-- Function to assign item to equipment slot (doesn't equip, just assigns)
function Inventory.AssignToEquipmentSlot(source, itemName, fromSlot, equipmentType)
    local inv = Inventory(source)
    if not inv then return false end
    
    local item = inv.items[fromSlot]
    if not item or item.name ~= itemName then return false end
    
    -- Verify item can go in this slot
    local expectedType = GetItemEquipmentType(itemName)
    if expectedType ~= equipmentType then return false end
    
    -- Check if there's already an item assigned to this slot
    for slot, invItem in pairs(inv.items) do
        if invItem and invItem.metadata and invItem.metadata.assignedToSlot == equipmentType then
            -- Remove previous assignment
            invItem.metadata.assignedToSlot = nil
            break
        end
    end
    
    -- Assign item to slot
    item.metadata = item.metadata or {}
    item.metadata.assignedToSlot = equipmentType
    
    inv.changed = true
    
    TriggerClientEvent('ox_inventory:updateSlots', source, {
        { item = item, inventory = source }
    }, inv.weight)
    
    if server.loglevel > 0 then
        lib.logger(source, 'assignEquipment', ('Player assigned %s to %s slot'):format(itemName, equipmentType))
    end
    
    return true
end

-- Function to remove item from equipment slot
function Inventory.RemoveFromEquipmentSlot(source, equipmentType)
    local inv = Inventory(source)
    if not inv then return false end
    
    -- Find item assigned to this slot
    for slot, item in pairs(inv.items) do
        if item and item.metadata and item.metadata.assignedToSlot == equipmentType then
            item.metadata.assignedToSlot = nil
            
            inv.changed = true
            
            TriggerClientEvent('ox_inventory:updateSlots', source, {
                { item = item, inventory = source }
            }, inv.weight)
            
            if server.loglevel > 0 then
                lib.logger(source, 'removeEquipment', ('Player removed %s from %s slot'):format(item.name, equipmentType))
            end
            
            return true
        end
    end
    
    return false
end

-- Function to apply utility equipment effects (auto-equip for armor/bag/wallet)
function Inventory.ApplyUtilityEquipment(source, equipmentType)
    local equipment = Inventory.GetPlayerEquipment(source)
    local item = equipment[equipmentType]
    
    if not item then return false end
    
    -- Mark as equipped for utility items
    item.metadata = item.metadata or {}
    item.metadata.equipped = true
    
    -- Trigger client effects
    TriggerClientEvent('ox_inventory:utilityEquipmentChanged', source, equipmentType, item, true)
    
    -- Update QBOX metadata
    local Player = exports.qbx_core:GetPlayer(source)
    if Player then
        local metadata = Player.PlayerData.metadata.equipment or {}
        metadata[equipmentType] = item
        Player.Functions.SetMetaData('equipment', metadata)
    end
    
    if server.loglevel > 0 then
        lib.logger(source, 'equipUtility', ('Player equipped %s as %s'):format(item.name, equipmentType))
    end
    
    return true
end

-- Function to remove utility equipment effects
function Inventory.RemoveUtilityEquipment(source, equipmentType)
    local equipment = Inventory.GetPlayerEquipment(source)
    local item = equipment[equipmentType]
    
    if item and item.metadata then
        item.metadata.equipped = false
    end
    
    -- Trigger client effects removal
    TriggerClientEvent('ox_inventory:utilityEquipmentChanged', source, equipmentType, nil, false)
    
    -- Update QBOX metadata
    local Player = exports.qbx_core:GetPlayer(source)
    if Player then
        local metadata = Player.PlayerData.metadata.equipment or {}
        metadata[equipmentType] = nil
        Player.Functions.SetMetaData('equipment', metadata)
    end
    
    if server.loglevel > 0 then
        lib.logger(source, 'unequipUtility', ('Player unequipped %s from %s'):format(item and item.name or 'unknown', equipmentType))
    end
    
    return true
end

-- Enhanced weight calculation including bag bonuses
function Inventory.GetPlayerMaxWeight(source)
    local baseWeight = 85000 -- 85kg base
    local equipment = Inventory.GetPlayerEquipment(source)
    
    if equipment.bag and equipment.bag.metadata and equipment.bag.metadata.equipped then
        local extraWeight = equipment.bag.metadata.extraWeight or 0
        return baseWeight + extraWeight
    end
    
    return baseWeight
end

-- Override existing CanCarryItem to include bag weight bonuses
local originalCanCarryItem = Inventory.CanCarryItem

function Inventory.CanCarryItem(inv, item, count, metadata)
    if type(inv) == 'number' then
        -- Get max weight including bag bonus
        local maxWeight = Inventory.GetPlayerMaxWeight(inv)
        local playerInv = Inventory(inv)
        if playerInv then
            playerInv.maxWeight = maxWeight
        end
    end
    
    return originalCanCarryItem(inv, item, count, metadata)
end

-- Server callbacks for equipment system

-- Callback to get player equipment
lib.callback.register('ox_inventory:getPlayerEquipment', function(source)
    return Inventory.GetPlayerEquipment(source)
end)

-- Callback to assign item to equipment slot
lib.callback.register('ox_inventory:assignToEquipmentSlot', function(source, itemName, fromSlot, equipmentType)
    return Inventory.AssignToEquipmentSlot(source, itemName, fromSlot, equipmentType)
end)

-- Callback to remove item from equipment slot
lib.callback.register('ox_inventory:removeFromEquipmentSlot', function(source, equipmentType)
    return Inventory.RemoveFromEquipmentSlot(source, equipmentType)
end)

-- Server events for utility equipment
RegisterServerEvent('ox_inventory:applyUtilityEquipment', function(equipmentType)
    local source = source
    Inventory.ApplyUtilityEquipment(source, equipmentType)
end)

RegisterServerEvent('ox_inventory:removeUtilityEquipment', function(equipmentType)
    local source = source
    Inventory.RemoveUtilityEquipment(source, equipmentType)
end)

-- Function to load player equipment on character load
AddEventHandler('QBCore:Server:PlayerLoaded', function(src)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    -- Load equipment from metadata
    local savedEquipment = Player.PlayerData.metadata.equipment or {}
    
    -- Apply saved equipment to inventory
    local inv = Inventory(src)
    if inv then
        for equipType, savedItem in pairs(savedEquipment) do
            -- Find the item in inventory and restore assignment
            for slot, invItem in pairs(inv.items) do
                if invItem and invItem.name == savedItem.name then
                    invItem.metadata = invItem.metadata or {}
                    invItem.metadata.assignedToSlot = equipType
                    
                    -- If it's a utility item and was equipped, restore equipped state
                    if (equipType == 'armor' or equipType == 'bag' or equipType == 'wallet') and savedItem.equipped then
                        invItem.metadata.equipped = true
                        -- Trigger client effects
                        TriggerClientEvent('ox_inventory:utilityEquipmentChanged', src, equipType, invItem, true)
                    end
                    
                    break
                end
            end
        end
    end
end)

-- Function to save equipment on character save
AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    -- Save current equipment to metadata
    local equipment = Inventory.GetPlayerEquipment(src)
    Player.Functions.SetMetaData('equipment', equipment)
end)

-- Auto-save equipment periodically
CreateThread(function()
    while true do
        Wait(300000) -- Save every 5 minutes
        
        local players = exports.qbx_core:GetQBPlayers()
        for src, Player in pairs(players) do
            if Player then
                local equipment = Inventory.GetPlayerEquipment(src)
                Player.Functions.SetMetaData('equipment', equipment)
            end
        end
    end
end)

-- Export functions for other resources
exports('GetPlayerEquipment', Inventory.GetPlayerEquipment)
exports('AssignToEquipmentSlot', Inventory.AssignToEquipmentSlot)
exports('RemoveFromEquipmentSlot', Inventory.RemoveFromEquipmentSlot)
exports('ApplyUtilityEquipment', Inventory.ApplyUtilityEquipment)
exports('RemoveUtilityEquipment', Inventory.RemoveUtilityEquipment)
exports('GetPlayerMaxWeight', Inventory.GetPlayerMaxWeight)