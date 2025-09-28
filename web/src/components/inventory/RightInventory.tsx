import React from 'react';
import InventoryGrid from './InventoryGrid';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';

const RightInventory: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);

  // If there's no right inventory (secondary inventory), show the main player inventory
  const leftInventory = useAppSelector((state) => state.inventory.leftInventory);
  const displayInventory = rightInventory || leftInventory;

  return (
    <div className="right-inventory-container">
      {displayInventory && <InventoryGrid inventory={displayInventory} />}
    </div>
  );
};

export default RightInventory;
