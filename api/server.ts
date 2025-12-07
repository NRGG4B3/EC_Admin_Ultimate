import { ServerInfo } from '../types/server';

export async function fetchServerInfo(): Promise<ServerInfo> {
  // Replace with real API call
  const res = await fetch('/api/server/info');
  return res.json();
}
