import React, { useEffect, useState } from 'react';
import { fetchPlayers, fetchPlayerItems } from '../api/inventory';
import { Player, Item } from '../types/inventory';

const InventoryManagement: React.FC = () => {
  const [players, setPlayers] = useState<Player[]>([]);
  const [selectedPlayer, setSelectedPlayer] = useState<Player | null>(null);
  const [items, setItems] = useState<Item[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchPlayers().then(setPlayers).catch(() => setError('Failed to load players'));
  }, []);

  useEffect(() => {
    if (selectedPlayer) {
      fetchPlayerItems(selectedPlayer.id)
        .then(setItems)
        .catch(() => setError('Failed to load items'));
    }
  }, [selectedPlayer]);

  return (
    <div>
      <h1>Inventory Management</h1>
      {error && <div className="error">{error}</div>}
      <div>
        <h2>Players</h2>
        <ul>
          {players.map(player => (
            <li key={player.id} onClick={() => setSelectedPlayer(player)}>
              {player.name}
            </li>
          ))}
        </ul>
      </div>
      {selectedPlayer && (
        <div>
          <h2>Items for {selectedPlayer.name}</h2>
          <ul>
            {items.map(item => (
              <li key={item.id}>{item.name}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default InventoryManagement;