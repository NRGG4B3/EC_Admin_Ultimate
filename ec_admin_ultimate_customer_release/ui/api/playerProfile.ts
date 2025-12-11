// EC Admin Ultimate - Player Profile API
// TypeScript API wrapper for player profile NUI calls

import { fetchNui } from '../components/nui-bridge';
import {
  PlayerProfile,
  PlayerInventoryItem,
  PlayerVehicle,
  PlayerProperty,
  PlayerTransaction,
  PlayerActivity,
  PlayerWarning,
  PlayerBan,
  PlayerNote,
  PlayerPerformance,
  PlayerMoneyChart
} from '../../types/playerProfile';

export async function fetchPlayerProfile(playerId: number): Promise<PlayerProfile> {
  const response = await fetchNui<{ success: boolean; profile: PlayerProfile }>('getPlayerProfile', { playerId });
  if (!response || !response.success || !response.profile) {
    throw new Error('Failed to fetch player profile');
  }
  return response.profile;
}

export async function fetchPlayerInventory(playerId: number): Promise<PlayerInventoryItem[]> {
  const response = await fetchNui<{ success: boolean; inventory: PlayerInventoryItem[] }>('getPlayerInventory', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.inventory || [];
}

export async function fetchPlayerVehicles(playerId: number): Promise<PlayerVehicle[]> {
  const response = await fetchNui<{ success: boolean; vehicles: PlayerVehicle[] }>('getPlayerVehicles', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.vehicles || [];
}

export async function fetchPlayerProperties(playerId: number): Promise<PlayerProperty[]> {
  const response = await fetchNui<{ success: boolean; properties: PlayerProperty[] }>('getPlayerProperties', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.properties || [];
}

export async function fetchPlayerTransactions(playerId: number): Promise<PlayerTransaction[]> {
  const response = await fetchNui<{ success: boolean; transactions: PlayerTransaction[] }>('getPlayerTransactions', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.transactions || [];
}

export async function fetchPlayerActivity(playerId: number): Promise<PlayerActivity[]> {
  const response = await fetchNui<{ success: boolean; activity: PlayerActivity[] }>('getPlayerActivity', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.activity || [];
}

export async function fetchPlayerWarnings(playerId: number): Promise<PlayerWarning[]> {
  const response = await fetchNui<{ success: boolean; warnings: PlayerWarning[] }>('getPlayerWarnings', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.warnings || [];
}

export async function fetchPlayerBans(playerId: number): Promise<PlayerBan[]> {
  const response = await fetchNui<{ success: boolean; bans: PlayerBan[] }>('getPlayerBans', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.bans || [];
}

export async function fetchPlayerNotes(playerId: number): Promise<PlayerNote[]> {
  const response = await fetchNui<{ success: boolean; notes: PlayerNote[] }>('getPlayerNotes', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.notes || [];
}

export async function fetchPlayerPerformance(playerId: number): Promise<PlayerPerformance[]> {
  const response = await fetchNui<{ success: boolean; performance: PlayerPerformance[] }>('getPlayerPerformance', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.performance || [];
}

export async function fetchPlayerMoneyChart(playerId: number): Promise<PlayerMoneyChart[]> {
  const response = await fetchNui<{ success: boolean; moneyChart: PlayerMoneyChart[] }>('getPlayerMoneyChart', { playerId });
  if (!response || !response.success) {
    return [];
  }
  return response.moneyChart || [];
}

