import { PlayerProfile, PlayerInventoryItem, PlayerVehicle, PlayerProperty, PlayerTransaction, PlayerActivity, PlayerWarning, PlayerBan, PlayerNote, PlayerPerformance, PlayerMoneyChart } from '../types/playerProfile';

export async function fetchPlayerProfile(playerId: number): Promise<PlayerProfile> {
  const res = await fetch(`/api/players/profile/${playerId}`);
  return res.json();
}

export async function fetchPlayerInventory(playerId: number): Promise<PlayerInventoryItem[]> {
  const res = await fetch(`/api/players/${playerId}/inventory`);
  return res.json();
}

export async function fetchPlayerVehicles(playerId: number): Promise<PlayerVehicle[]> {
  const res = await fetch(`/api/players/${playerId}/vehicles`);
  return res.json();
}

export async function fetchPlayerProperties(playerId: number): Promise<PlayerProperty[]> {
  const res = await fetch(`/api/players/${playerId}/properties`);
  return res.json();
}

export async function fetchPlayerTransactions(playerId: number): Promise<PlayerTransaction[]> {
  const res = await fetch(`/api/players/${playerId}/transactions`);
  return res.json();
}

export async function fetchPlayerActivity(playerId: number): Promise<PlayerActivity[]> {
  const res = await fetch(`/api/players/${playerId}/activity`);
  return res.json();
}

export async function fetchPlayerWarnings(playerId: number): Promise<PlayerWarning[]> {
  const res = await fetch(`/api/players/${playerId}/warnings`);
  return res.json();
}

export async function fetchPlayerBans(playerId: number): Promise<PlayerBan[]> {
  const res = await fetch(`/api/players/${playerId}/bans`);
  return res.json();
}

export async function fetchPlayerNotes(playerId: number): Promise<PlayerNote[]> {
  const res = await fetch(`/api/players/${playerId}/notes`);
  return res.json();
}

export async function fetchPlayerPerformance(playerId: number): Promise<PlayerPerformance[]> {
  const res = await fetch(`/api/players/${playerId}/performance`);
  return res.json();
}

export async function fetchPlayerMoneyChart(playerId: number): Promise<PlayerMoneyChart[]> {
  const res = await fetch(`/api/players/${playerId}/money-chart`);
  return res.json();
}
