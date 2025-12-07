import {
  AdminProfile,
  AdminPermission,
  AdminRole,
  AdminActivity,
  AdminAction,
  AdminInfraction,
  AdminWarning,
  AdminBan
} from '../types/adminProfile';

// Fetch admin profile (live)
export async function fetchAdminProfile(adminId: string): Promise<AdminProfile> {
  const res = await fetch(`/api/admin/profile/${adminId}`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch admin profile');
  return res.json();
}

// Fetch admin permissions (live)
export async function fetchAdminPermissions(adminId: string): Promise<AdminPermission[]> {
  const res = await fetch(`/api/admin/profile/${adminId}/permissions`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch admin permissions');
  return res.json();
}

// Fetch admin roles (live)
export async function fetchAdminRoles(adminId: string): Promise<AdminRole[]> {
  const res = await fetch(`/api/admin/profile/${adminId}/roles`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch admin roles');
  return res.json();
}

// Fetch admin activity (live)
export async function fetchAdminActivity(adminId: string): Promise<AdminActivity[]> {
  const res = await fetch(`/api/admin/profile/${adminId}/activity`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch admin activity');
  return res.json();
}

// Fetch recent admin actions (live)
export async function fetchAdminActions(adminId: string): Promise<AdminAction[]> {
  const res = await fetch(`/api/admin/profile/${adminId}/actions`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch admin actions');
  return res.json();
}

// Fetch admin infractions (live)
export async function fetchAdminInfractions(adminId: string): Promise<AdminInfraction[]> {
  const res = await fetch(`/api/admin/profile/${adminId}/infractions`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch admin infractions');
  return res.json();
}

// Fetch admin warnings (live)
export async function fetchAdminWarnings(adminId: string): Promise<AdminWarning[]> {
  const res = await fetch(`/api/admin/profile/${adminId}/warnings`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch admin warnings');
  return res.json();
}

// Fetch admin bans (live)
export async function fetchAdminBans(adminId: string): Promise<AdminBan[]> {
  const res = await fetch(`/api/admin/profile/${adminId}/bans`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch admin bans');
  return res.json();
}
