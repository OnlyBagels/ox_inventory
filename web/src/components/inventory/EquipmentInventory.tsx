import React from 'react';
import InventorySlot from './InventorySlot';
import { useAppSelector } from '../../store';
import { useDrop } from 'react-dnd';
import { fetchNui } from '../../utils/fetchNui';

// Equipment slot types mapping (mirrors hotbar structure)
const EQUIPMENT_SLOTS = {
  primary: { slot: 1, label: 'Primary Weapon', color: '#dc2626', keyBind: 'F1' },
  secondary: { slot: 2, label: 'Secondary Weapon', color: '#059669', keyBind: 'F2' },
  melee: { slot: 3, label: 'Melee Weapon', color: '#eab308', keyBind: 'F3' },
  armor: { slot: 4, label: 'Body Armor', color: '#10b981', keyBind: '' },
  bag: { slot: 5, label: 'Bag', color: '#3b82f6', keyBind: '' },
  wallet: { slot: 6, label: 'Wallet', color: '#8b5cf6', keyBind: '' },
};

// Equipment slot component (mirrors hotbar slot)
const EquipmentSlot: React.FC<{
  equipmentType: string;
  config: any;
  item: any;
  onDrop: (item: any, equipmentType: string) => void;
  onRemove: (equipmentType: string) => void;
}> = ({ equipmentType, config, item, onDrop, onRemove }) => {
  const isBusy = useAppSelector((state) => state.inventory.isBusy);

  const [{ isOver, canDrop }, drop] = useDrop({
    accept: 'inventory-item',
    drop: (draggedItem: any) => {
      onDrop(draggedItem, equipmentType);
    },
    canDrop: (draggedItem: any) => {
      // Check if item can be equipped in this slot (like hotbar logic)
      const itemName = draggedItem.name;
      return canEquipInSlot(itemName, equipmentType);
    },
    collect: (monitor) => ({
      isOver: monitor.isOver(),
      canDrop: monitor.canDrop(),
    }),
  });

  const handleRightClick = () => {
    if (item) {
      onRemove(equipmentType);
    }
  };

  return (
    <div
      ref={drop}
      className="equipment-slot-container"
      style={{ pointerEvents: isBusy ? 'none' : 'auto' }}
      onContextMenu={handleRightClick}
    >
      <div
        className="equipment-slot-wrapper"
        style={{
          borderColor: config.color,
          backgroundColor: isOver && canDrop ? 'rgba(59, 130, 246, 0.2)' : undefined,
        }}
      >
        {item ? (
          <InventorySlot item={item} inventoryType="equipment" inventoryGroups={{}} inventoryId="equipment" />
        ) : (
          <div className="inventory-slot" />
        )}

        <div className="equipment-slot-label">
          {config.label}
          {config.keyBind && <span className="equipment-keybind">({config.keyBind})</span>}
        </div>
      </div>
    </div>
  );
};

// Function to check if item can be equipped in slot (mirrors hotbar logic)
const canEquipInSlot = (itemName: string, equipmentType: string): boolean => {
  if (equipmentType === 'primary') {
    return (
      itemName.includes('assault') ||
      itemName.includes('carbine') ||
      itemName.includes('pump') ||
      itemName.includes('sawnoff')
    );
  } else if (equipmentType === 'secondary') {
    return itemName.includes('pistol') || itemName.includes('stun') || itemName.includes('flare');
  } else if (equipmentType === 'melee') {
    return (
      itemName.includes('knife') ||
      itemName.includes('bat') ||
      itemName.includes('crowbar') ||
      itemName.includes('hammer') ||
      itemName.includes('machete') ||
      itemName.includes('switch')
    );
  } else if (equipmentType === 'armor') {
    return itemName.includes('armor') || itemName.includes('vest') || itemName.includes('bulletproof');
  } else if (equipmentType === 'bag') {
    return itemName.includes('bag') || itemName.includes('backpack');
  } else if (equipmentType === 'wallet') {
    return itemName.includes('wallet') || itemName.includes('id_card') || itemName.includes('license');
  }

  return false;
};

const EquipmentInventory: React.FC = () => {
  const leftInventory = useAppSelector((state) => state.inventory.leftInventory);
  const isBusy = useAppSelector((state) => state.inventory.isBusy);

  // Equipment state (like hotbar state)
  const [equipmentSlots, setEquipmentSlots] = React.useState<{ [key: string]: any }>({});

  // Load equipment on mount (like hotbar)
  React.useEffect(() => {
    fetchNui('getPlayerEquipment').then((equipment) => {
      setEquipmentSlots(equipment || {});
    });
  }, []);

  // Handle dropping items to equipment slots (like hotbar)
  const handleDrop = async (draggedItem: any, equipmentType: string) => {
    const success = await fetchNui('assignToEquipmentSlot', {
      itemName: draggedItem.name,
      equipmentType: equipmentType,
      fromSlot: draggedItem.slot,
    });

    if (success) {
      // Update local state (like hotbar)
      setEquipmentSlots((prev) => ({
        ...prev,
        [equipmentType]: {
          item: {
            name: draggedItem.name,
            slot: draggedItem.slot,
            count: 1,
          },
        },
      }));
    }
  };

  // Handle removing items from equipment slots
  const handleRemove = async (equipmentType: string) => {
    const success = await fetchNui('removeFromEquipmentSlot', {
      equipmentType: equipmentType,
    });

    if (success) {
      setEquipmentSlots((prev) => ({
        ...prev,
        [equipmentType]: { item: null },
      }));
    }
  };

  return (
    <div className="equipment-inventory" style={{ pointerEvents: isBusy ? 'none' : 'auto' }}>
      <div className="equipment-header">
        <p>EQUIPMENT</p>
      </div>

      <div className="equipment-slots">
        {Object.entries(EQUIPMENT_SLOTS).map(([slotType, config]) => {
          const slotData = equipmentSlots[slotType];
          const item = slotData?.item || null;

          return (
            <EquipmentSlot
              key={slotType}
              equipmentType={slotType}
              config={config}
              item={item}
              onDrop={handleDrop}
              onRemove={handleRemove}
            />
          );
        })}
      </div>
    </div>
  );
};

export default EquipmentInventory;
