import { Player, Item } from '../types/inventory';

// Fetch all players
export async function fetchPlayers(): Promise<Player[]> {
  const res = await fetch('/api/inventory/players', { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch players');
  return res.json();
}

// Fetch items for a player
export async function fetchPlayerItems(playerId: string): Promise<Item[]> {
  const res = await fetch(`/api/inventory/player/${playerId}/items`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch player items');
  return res.json();
}
