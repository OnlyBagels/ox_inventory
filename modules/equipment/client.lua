-- Equipment System Client Module for ox_inventory
-- Mirrors hotbar system but for equipment slots with scroll wheel cycling

-- Equipment keybinds (different from hotbar 1-5)
local equipmentKeys = {
    primary = 157,   -- F1 key  
    secondary = 158, -- F2 key
    melee = 160      -- F3 key
}

-- Current equipped weapon tracker
local currentWeaponSlot = nil

-- Equipment slots data (mirrors hotbar structure)
local equipmentSlots = {
    primary = { slot = 1, item = nil },
    secondary = { slot = 2, item = nil },
    melee = { slot = 3, item = nil },
    armor = { slot = 4, item = nil },
    bag = { slot = 5, item = nil },
    wallet = { slot = 6, item = nil }
}

-- Function to check if item is weapon
local function isWeapon(itemName)
    return itemName:find('^weapon_') ~= nil
end

-- Function to check if item is utility (auto-equip)
local function isUtility(itemName)
    local utilityItems = {
        'bulletproof', 'police_vest', 'heavy_armor', 'light_armor',
        'backpack', 'duffel_bag', 'sports_bag', 'school_bag',
        'wallet', 'id_card', 'driver_license'
    }
    
    for _, utility in pairs(utilityItems) do
        if itemName == utility then return true end
    end
    return false
end

-- Function to get equipment type from item name (mirrors hotbar logic)
local function getEquipmentType(itemName)
    if itemName:find('^weapon_assault') or itemName:find('^weapon_carbine') or 
       itemName:find('^weapon_pump') or itemName:find('^weapon_sawnoff') then
        return 'primary'
    elseif itemName:find('^weapon_pistol') or itemName:find('^weapon_combat') or 
           itemName:find('^weapon_app') or itemName:find('^weapon_stun') or itemName:find('^weapon_flare') then
        return 'secondary'
    elseif itemName:find('^weapon_knife') or itemName:find('^weapon_bat') or 
           itemName:find('^weapon_crowbar') or itemName:find('^weapon_hammer') or 
           itemName:find('^weapon_machete') or itemName:find('^weapon_switch') then
        return 'melee'
    elseif itemName:find('armor') or itemName:find('vest') or itemName:find('bulletproof') then
        return 'armor'
    elseif itemName:find('bag') or itemName:find('backpack') then
        return 'bag'
    elseif itemName:find('wallet') or itemName:find('id_card') or itemName:find('license') then
        return 'wallet'
    end
    
    return nil
end

-- Equipment slot assignment (like hotbar drag/drop)
RegisterNUICallback('assignToEquipmentSlot', function(data, cb)
    local itemName = data.itemName
    local equipmentType = data.equipmentType
    local fromSlot = data.fromSlot
    
    print("Equipment Debug: Assigning", itemName, "to", equipmentType, "from slot", fromSlot)
    
    -- Verify item can go in this slot
    local expectedType = getEquipmentType(itemName)
    if expectedType ~= equipmentType then
        print("Equipment Debug: Item type mismatch")
        cb(false)
        return
    end
    
    -- Update local equipment slot data
    equipmentSlots[equipmentType].item = {
        name = itemName,
        slot = fromSlot,
        count = 1 -- Equipment items are always count 1
    }
    
    -- For utility items, auto-apply effects
    if isUtility(itemName) then
        ApplyUtilityEffect(equipmentType, itemName)
    end
    
    cb(true)
end)

-- Remove from equipment slot
RegisterNUICallback('removeFromEquipmentSlot', function(data, cb)
    local equipmentType = data.equipmentType
    
    print("Equipment Debug: Removing item from", equipmentType, "slot")
    
    -- If it's the currently equipped weapon, unequip it
    if (equipmentType == 'primary' or equipmentType == 'secondary' or equipmentType == 'melee') and 
       currentWeaponSlot == equipmentType then
        SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED'), true)
        currentWeaponSlot = nil
    end
    
    -- Remove utility effects
    if isUtility(equipmentSlots[equipmentType].item and equipmentSlots[equipmentType].item.name or '') then
        RemoveUtilityEffect(equipmentType)
    end
    
    -- Clear slot
    equipmentSlots[equipmentType].item = nil
    
    cb(true)
end)

-- Get equipment data (like hotbar)
RegisterNUICallback('getPlayerEquipment', function(data, cb)
    cb(equipmentSlots)
end)

-- Weapon cycling with scroll wheel (like hotbar weapon switching)
CreateThread(function()
    while true do
        Wait(0)
        
        -- Only check when not in inventory
        if not exports.ox_inventory:IsInventoryOpen() and not IsPauseMenuActive() then
            if IsControlJustPressed(0, 14) then -- Mouse wheel up
                CycleWeapon(1)
            elseif IsControlJustPressed(0, 15) then -- Mouse wheel down
                CycleWeapon(-1)
            end
            
            -- Optional: F1, F2, F3 direct weapon selection
            for equipType, keyCode in pairs(equipmentKeys) do
                if IsControlJustPressed(0, keyCode) then
                    SelectWeapon(equipType)
                end
            end
        end
    end
end)

-- Function to cycle through available weapons (like hotbar)
function CycleWeapon(direction)
    local availableWeapons = {}
    
    -- Get available weapon slots (like hotbar checks)
    if equipmentSlots.primary.item then table.insert(availableWeapons, 'primary') end
    if equipmentSlots.secondary.item then table.insert(availableWeapons, 'secondary') end
    if equipmentSlots.melee.item then table.insert(availableWeapons, 'melee') end
    
    if #availableWeapons == 0 then
        -- No weapons available, go unarmed
        SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED'), true)
        currentWeaponSlot = nil
        return
    end
    
    local currentIndex = 0
    if currentWeaponSlot then
        for i, weaponType in ipairs(availableWeapons) do
            if weaponType == currentWeaponSlot then
                currentIndex = i
                break
            end
        end
    end
    
    -- Calculate next weapon index
    local nextIndex = currentIndex + direction
    if nextIndex > #availableWeapons then
        nextIndex = 0 -- Go to unarmed
    elseif nextIndex < 0 then
        nextIndex = #availableWeapons
    end
    
    if nextIndex == 0 then
        -- Unarmed
        SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED'), true)
        currentWeaponSlot = nil
    else
        -- Equip weapon
        local weaponType = availableWeapons[nextIndex]
        SelectWeapon(weaponType)
    end
end

-- Function to select specific weapon (like hotbar selection)
function SelectWeapon(weaponType)
    local weapon = equipmentSlots[weaponType].item
    if not weapon then return end
    
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(weapon.name)
    
    -- Give weapon if not already has it (like hotbar)
    if not HasPedGotWeapon(ped, weaponHash, false) then
        -- Get item data from inventory for ammo/components
        local inventory = exports.ox_inventory:GetPlayerItems()
        local itemData = nil
        
        for _, item in pairs(inventory) do
            if item.slot == weapon.slot then
                itemData = item
                break
            end
        end
        
        local ammo = itemData and itemData.metadata and itemData.metadata.ammo or 250
        GiveWeaponToPed(ped, weaponHash, ammo, false, true)
        
        -- Set weapon components if any
        if itemData and itemData.metadata and itemData.metadata.components then
            for _, component in pairs(itemData.metadata.components) do
                local componentHash = GetHashKey(component)
                GiveWeaponComponentToPed(ped, weaponHash, componentHash)
            end
        end
    end
    
    -- Switch to weapon
    SetCurrentPedWeapon(ped, weaponHash, true)
    currentWeaponSlot = weaponType
    
    print("Equipment Debug: Equipped", weapon.name, "from", weaponType, "slot")
end

-- Utility equipment effects
function ApplyUtilityEffect(equipmentType, itemName)
    local ped = PlayerPedId()
    
    if equipmentType == 'armor' then
        SetPedArmour(ped, 100) -- Default armor value
        
    elseif equipmentType == 'bag' then
        -- Update carry weight (would need server-side implementation)
        TriggerServerEvent('ox_inventory:updateMaxWeight', 120000) -- +35kg example
        
    elseif equipmentType == 'wallet' then
        LocalPlayer.state.hasWallet = true
    end
    
    print("Equipment Debug: Applied", equipmentType, "effect for", itemName)
end

function RemoveUtilityEffect(equipmentType)
    local ped = PlayerPedId()
    
    if equipmentType == 'armor' then
        SetPedArmour(ped, 0)
        
    elseif equipmentType == 'bag' then
        TriggerServerEvent('ox_inventory:updateMaxWeight', 85000) -- Reset to default
        
    elseif equipmentType == 'wallet' then
        LocalPlayer.state.hasWallet = false
    end
    
    print("Equipment Debug: Removed", equipmentType, "effect")
end

-- Update equipment when inventory changes
RegisterNetEvent('ox_inventory:updateSlots', function(data, weight)
    -- Update NUI with current equipment
    SendNUIMessage({
        action = 'updateEquipment',
        equipment = equipmentSlots
    })
end)

-- Sync equipment on player load
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    
    -- Initialize equipment slots
    for equipType, slot in pairs(equipmentSlots) do
        slot.item = nil
    end
    
    SendNUIMessage({
        action = 'updateEquipment',
        equipment = equipmentSlots
    })
end)

-- Export functions
exports('cycleWeapon', CycleWeapon)
exports('selectWeapon', SelectWeapon)
exports('getCurrentWeapon', function() return currentWeaponSlot end)
exports('getEquipmentSlots', function() return equipmentSlots end)