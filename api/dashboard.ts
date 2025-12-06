import { DashboardStats, QuickAction, EconomyStats, AdminCategory } from '../types/dashboard';

export async function fetchDashboardStats(): Promise<DashboardStats> {
  const res = await fetch('/api/dashboard/stats');
  return res.json();
}
export async function fetchQuickActions(): Promise<QuickAction[]> {
  const res = await fetch('/api/dashboard/quick-actions');
  return res.json();
}
export async function fetchEconomyStats(): Promise<EconomyStats> {
  const res = await fetch('/api/dashboard/economy');
  return res.json();
}
export async function fetchAdminCategories(): Promise<AdminCategory[]> {
  const res = await fetch('/api/dashboard/admin-categories');
  return res.json();
}
// ...repeat for other api files...
