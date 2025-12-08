/**
 * Admin Profile API
 * Wrapper functions for admin profile NUI callbacks
 */

declare global {
  interface Window {
    fetchNui: (eventName: string, data?: any) => Promise<any>;
  }
}

/**
 * Fetch full admin profile data
 */
export async function fetchAdminProfileFull(adminId: string): Promise<{
  profile: any;
  permissions: any[];
  roles: any[];
  activity: any[];
  actions: any[];
  infractions: any[];
  warnings: any[];
  bans: any[];
}> {
  if (!window.fetchNui) {
    throw new Error('NUI bridge not available');
  }

  const response = await window.fetchNui('getAdminProfileFull', { adminId });
  
  if (!response || !response.success) {
    throw new Error(response?.error || 'Failed to fetch admin profile');
  }

  return {
    profile: response.profile,
    permissions: response.permissions || [],
    roles: response.roles || [],
    activity: response.activity || [],
    actions: response.actions || [],
    infractions: response.infractions || [],
    warnings: response.warnings || [],
    bans: response.bans || []
  };
}

