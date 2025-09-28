import React from 'react';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import { useAppSelector } from '../../store';
import { Menu, MenuItem } from '../utils/menu/Menu';

const EquipmentContext: React.FC = () => {
  const contextMenu = useAppSelector((state) => state.contextMenu);
  const item = contextMenu.item;

  const handleEquipmentAction = (action: string) => {
    if (!item) return;

    switch (action) {
      case 'equip':
        fetchNui('equipItem', { name: item.name, slot: item.slot });
        break;
      case 'unequip':
        fetchNui('unequipItem', { slot: item.slot });
        break;
      case 'use':
        fetchNui('useItem', { name: item.name, slot: item.slot });
        break;
      case 'drop':
        fetchNui('dropItem', { name: item.name, slot: item.slot, count: 1 });
        break;
    }
  };

  const isEquippable = (itemName: string) => {
    const equipmentItems = [
      // Primary Weapons
      'weapon_assaultrifle',
      'weapon_carbinerifle',
      'weapon_advancedrifle',
      'weapon_pumpshotgun',
      'weapon_sawnoffshotgun',

      // Secondary Weapons
      'weapon_pistol',
      'weapon_combatpistol',
      'weapon_appistol',
      'weapon_stungun',
      'weapon_flaregun',

      // Melee Weapons
      'weapon_knife',
      'weapon_bat',
      'weapon_crowbar',
      'weapon_hammer',
      'weapon_machete',
      'weapon_switchblade',

      // Body Armor
      'bulletproof',
      'police_vest',
      'heavy_armor',
      'light_armor',

      // Bags
      'backpack',
      'duffel_bag',
      'sports_bag',
      'school_bag',

      // Wallets
      'wallet',
      'id_card',
      'driver_license',
    ];

    return equipmentItems.includes(itemName);
  };

  const isEquipped = item?.metadata?.equipped || false;

  if (!item || !isEquippable(item.name)) {
    return null;
  }

  return (
    <Menu>
      {isEquipped ? (
        <MenuItem onClick={() => handleEquipmentAction('unequip')} label={Locale.ui_unequip || 'Unequip'} />
      ) : (
        <MenuItem onClick={() => handleEquipmentAction('equip')} label={Locale.ui_equip || 'Equip'} />
      )}
      <MenuItem onClick={() => handleEquipmentAction('use')} label={Locale.ui_use || 'Use'} />
      <MenuItem onClick={() => handleEquipmentAction('drop')} label={Locale.ui_drop || 'Drop'} />
    </Menu>
  );
};

export default EquipmentContext;
