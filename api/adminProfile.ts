// Fetch all admin profile data in one call (live)
export async function fetchAdminProfileFull(adminId: string): Promise<any> {
  // Use NUI callback for FiveM or fallback to REST if in web mode
  if ((window as any).GetParentResourceName) {
    return new Promise((resolve, reject) => {
      (window as any).fetchNui('adminProfile:getFullProfile', { adminId })
        .then((resp: any) => {
          if (resp && resp.success) resolve(resp.data);
          else reject(resp?.message || 'Failed to fetch admin profile');
        })
        .catch(reject);
    });
  } else {
    // Fallback: fetch each section in parallel (for web dev/testing)
    const [profile, permissions, roles, activity, actions, infractions, warnings, bans] = await Promise.all([
      fetchAdminProfile(adminId),
      fetchAdminPermissions(adminId),
      fetchAdminRoles(adminId),
      fetchAdminActivity(adminId),
      fetchAdminActions(adminId),
      fetchAdminInfractions(adminId),
      fetchAdminWarnings(adminId),
      fetchAdminBans(adminId)
    ]);
    return { profile, permissions, roles, activity, actions, infractions, warnings, bans };
  }
}
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
