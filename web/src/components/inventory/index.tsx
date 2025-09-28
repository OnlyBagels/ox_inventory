import React, { useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import InventoryControl from './InventoryControl';
import InventoryHotbar from './InventoryHotbar';
import { useAppDispatch, useAppSelector } from '../../store';
import { refreshSlots, setAdditionalMetadata, setupInventory } from '../../store/inventory';
import { useExitListener } from '../../hooks/useExitListener';
import type { Inventory as InventoryProps } from '../../typings';
import RightInventory from './RightInventory';
import EquipmentInventory from './EquipmentInventory';
import PocketsInventory from './PocketsInventory';
import Tooltip from '../utils/Tooltip';
import { closeTooltip } from '../../store/tooltip';
import InventoryContext from './InventoryContext';
import { closeContextMenu } from '../../store/contextMenu';
import Fade from '../utils/transitions/Fade';
import { getTotalWeight } from '../../helpers';

const Inventory: React.FC = () => {
  const [inventoryVisible, setInventoryVisible] = useState(false);
  const dispatch = useAppDispatch();
  const leftInventory = useAppSelector((state) => state.inventory.leftInventory);

  // Calculate weight using original method
  const weight = React.useMemo(
    () => (leftInventory?.maxWeight !== undefined ? Math.floor(getTotalWeight(leftInventory.items) * 1000) / 1000 : 0),
    [leftInventory?.maxWeight, leftInventory?.items]
  );

  useNuiEvent<boolean>('setInventoryVisible', setInventoryVisible);
  useNuiEvent<false>('closeInventory', () => {
    setInventoryVisible(false);
    dispatch(closeContextMenu());
    dispatch(closeTooltip());
  });
  useExitListener(setInventoryVisible);

  useNuiEvent<{
    leftInventory?: InventoryProps;
    rightInventory?: InventoryProps;
  }>('setupInventory', (data) => {
    dispatch(setupInventory(data));
    !inventoryVisible && setInventoryVisible(true);
  });

  useNuiEvent('refreshSlots', (data) => dispatch(refreshSlots(data)));

  useNuiEvent('displayMetadata', (data: Array<{ metadata: string; value: string }>) => {
    dispatch(setAdditionalMetadata(data));
  });

  return (
    <>
      <Fade in={inventoryVisible}>
        <div className="inventory-wrapper-three-column">
          {/* Left Column - Equipment */}
          <div className="equipment-section">
            <EquipmentInventory />
          </div>

          {/* Center Column - Pockets */}
          <div className="center-section">
            <PocketsInventory />
          </div>

          {/* Right Column - Secondary Inventory */}
          <div className="right-section">
            <RightInventory />
          </div>

          <Tooltip />
          <InventoryContext />
        </div>
      </Fade>
      <InventoryHotbar />
    </>
  );
};

export default Inventory;
