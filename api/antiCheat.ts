import { AntiCheatLog, AntiCheatDetection, AntiCheatChartData } from '../types/antiCheat.ts';

// Fetch all anti-cheat logs (live data)
export async function fetchAntiCheatLogs(): Promise<AntiCheatLog[]> {
  const res = await fetch('/api/anticheat/logs', { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch anti-cheat logs');
  return res.json();
}

// Fetch anti-cheat detections (for charts/graphs)
export async function fetchAntiCheatDetections(): Promise<AntiCheatDetection[]> {
  const res = await fetch('/api/anticheat/detections', { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch anti-cheat detections');
  return res.json();
}

// Fetch anti-cheat chart data (live)
export async function fetchAntiCheatChartData(): Promise<AntiCheatChartData> {
  const res = await fetch('/api/anticheat/chart', { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch anti-cheat chart data');
  return res.json();
}

// Fetch recent anti-cheat flags (live)
export async function fetchRecentAntiCheatFlags(): Promise<AntiCheatLog[]> {
  const res = await fetch('/api/anticheat/recent-flags', { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch recent anti-cheat flags');
  return res.json();
}

// Toggle anti-cheat actions (live)
export async function toggleAntiCheatAction(action: string): Promise<void> {
  const res = await fetch(`/api/anticheat/toggle/${action}`, { method: 'POST' });
  if (!res.ok) throw new Error('Failed to toggle anti-cheat action');
}
