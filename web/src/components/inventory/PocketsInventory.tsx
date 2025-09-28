import React from 'react';
import InventorySlot from './InventorySlot';
import WeightBar from '../utils/WeightBar';
import { useAppSelector } from '../../store';
import { getTotalWeight } from '../../helpers';

const PocketsInventory: React.FC = () => {
  const leftInventory = useAppSelector((state) => state.inventory.leftInventory);
  const isBusy = useAppSelector((state) => state.inventory.isBusy);

  // Calculate weight using original ox_inventory method
  const weight = React.useMemo(
    () => (leftInventory?.maxWeight !== undefined ? Math.floor(getTotalWeight(leftInventory.items) * 1000) / 1000 : 0),
    [leftInventory?.maxWeight, leftInventory?.items]
  );

  // Get pocket items (first 10 slots for example)
  const getPocketSlots = () => {
    if (!leftInventory?.items) return [];

    const pocketSlots = [];
    for (let i = 1; i <= 10; i++) {
      const item = leftInventory.items.find((item) => item && item.slot === i);
      pocketSlots.push(item || { slot: i, name: '', count: 0 });
    }
    return pocketSlots;
  };

  // Get additional storage slots (bottom section)
  const getStorageSlots = () => {
    if (!leftInventory?.items) return [];

    const storageSlots = [];
    for (let i = 11; i <= 20; i++) {
      const item = leftInventory.items.find((item) => item && item.slot === i);
      storageSlots.push(item || { slot: i, name: '', count: 0 });
    }
    return storageSlots;
  };

  const pocketSlots = getPocketSlots();
  const storageSlots = getStorageSlots();

  return (
    <div className="pockets-inventory" style={{ pointerEvents: isBusy ? 'none' : 'auto' }}>
      <div className="pockets-header">
        <p>POCKETS</p>
        {leftInventory?.maxWeight && (
          <p>
            {weight / 1000}/{leftInventory.maxWeight / 1000}kg
          </p>
        )}
      </div>
      <WeightBar percent={leftInventory?.maxWeight ? (weight / leftInventory.maxWeight) * 100 : 0} />

      {/* Main pocket grid - 2 rows of 5 */}
      <div className="pockets-grid">
        {pocketSlots.map((item, index) => (
          <div key={`pocket-${index}`} className="pocket-slot">
            <InventorySlot
              item={item}
              inventoryType="player"
              inventoryGroups={leftInventory?.groups}
              inventoryId={leftInventory?.id || 'player'}
            />
          </div>
        ))}
      </div>

      {/* Additional storage sections */}
      <div className="storage-section">
        <div className="storage-row">
          <div className="storage-slots-container">
            {storageSlots.slice(0, 5).map((item, index) => (
              <div key={`storage-${index}`} className="storage-slot">
                <InventorySlot
                  item={item}
                  inventoryType="player"
                  inventoryGroups={leftInventory?.groups}
                  inventoryId={leftInventory?.id || 'player'}
                />
              </div>
            ))}
          </div>
          <div className="slots-counter">0 slots</div>
        </div>

        <div className="storage-row">
          <div className="storage-slots-container">
            {storageSlots.slice(5, 10).map((item, index) => (
              <div key={`storage2-${index}`} className="storage-slot">
                <InventorySlot
                  item={item}
                  inventoryType="player"
                  inventoryGroups={leftInventory?.groups}
                  inventoryId={leftInventory?.id || 'player'}
                />
              </div>
            ))}
          </div>
          <div className="slots-counter">0 slots</div>
        </div>
      </div>
    </div>
  );
};

export default PocketsInventory;
