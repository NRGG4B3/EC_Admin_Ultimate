export interface AdminProfile {
  admin_id: string;
  name: string;
  email: string;
  phone: string;
  location: string;
  role: string;
  joined_date: number;
  last_login: number;
  total_actions: number;
  players_managed: number;
  bans_issued: number;
  warnings_issued: number;
  resources_managed: number;
  uptime: number;
  trust_score: number;
  status: string;
  framework?: string;
}

export interface AdminPermission {
  name: string;
  granted: boolean;
  category: string;
}

export interface AdminRole {
  name: string;
  active: boolean;
}

export interface AdminActivity {
  id: number;
  admin_id: string;
  action: string;
  category: string;
  target_name?: string;
  timestamp: number;
  details: string;
}

export interface AdminAction {
  id: number;
  admin_id: string;
  action: string;
  category: string;
  target_name?: string;
  timestamp: number;
  details: string;
}

export interface AdminInfraction {
  id: number;
  reason: string;
  timestamp: number;
}

export interface AdminWarning {
  id: number;
  reason: string;
  timestamp: number;
}

export interface AdminBan {
  id: number;
  reason: string;
  timestamp: number;
}
