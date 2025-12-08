/**
 * EC Admin Ultimate - Player Profile Types
 * Type definitions for player profile data structures
 */

export interface PlayerInventoryItem {
  id: number;
  name: string;
  label: string;
  quantity: number;
  weight: number;
  type: string;
  slot?: number;
  metadata?: any;
  image?: string;
}

export interface PlayerVehicle {
  id: number;
  model: string;
  plate: string;
  owner: string;
  mileage: number;
  fuel: number;
  engine: number;
  body: number;
  value: number;
  impounded: boolean;
  stored: boolean;
  location: string;
  mods: {
    engine: number;
    transmission: number;
    brakes: number;
    turbo: boolean;
  };
  color: {
    primary: string;
    secondary: string;
  };
  impoundReason?: string;
}

export interface PlayerProperty {
  id: number;
  name: string;
  type: string;
  address: string;
  value: number;
  owned: boolean;
  keys: string[];
  locked: boolean;
  interior?: string;
  furniture?: any[];
}

export interface PlayerTransaction {
  id: number;
  type: 'deposit' | 'withdrawal' | 'transfer' | 'purchase' | 'sale' | 'payment';
  amount: number;
  balance: number;
  description: string;
  timestamp: number;
  from?: string;
  to?: string;
}

export interface PlayerActivity {
  id: number;
  type: string;
  action: string;
  details: string;
  timestamp: number;
  location?: string;
}

export interface PlayerWarning {
  id: number;
  reason: string;
  issuedBy: string;
  issuedAt: number;
  expiresAt?: number;
  active: boolean;
}

export interface PlayerBan {
  id: number;
  reason: string;
  bannedBy: string;
  bannedAt: number;
  expiresAt?: number;
  isPermanent: boolean;
  active: boolean;
}

export interface PlayerNote {
  id: number;
  note: string;
  createdBy: string;
  createdAt: number;
  updatedAt?: number;
  category?: string;
}

export interface PlayerPerformance {
  id: number;
  metric: string;
  value: number;
  timestamp: number;
  category?: string;
}

export interface PlayerMoneyChart {
  date: string;
  cash: number;
  bank: number;
  total: number;
}
