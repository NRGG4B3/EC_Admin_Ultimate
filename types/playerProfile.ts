export interface PlayerProfile {
  id: number;
  name: string;
  status: string;
  location: string;
  coords: { x: number; y: number; z: number };
  health: number;
  armor: number;
  job: string;
  jobGrade: string;
  gang: string;
  money: { cash: number; bank: number; crypto: number; blackMoney: number };
  steamId: string;
  license: string;
  discord: string;
  discordId: string;
  ip: string;
  hwid: string;
  phoneNumber: string;
  nationality: string;
  birthDate: string;
  gender: string;
  hunger: number;
  thirst: number;
  stress: number;
  isDead: boolean;
  citizenId: string;
  metadata: Record<string, any>;
}

export interface PlayerInventoryItem {
  id: number;
  name: string;
  quantity: number;
  type: string;
  weight: number;
  useable: boolean;
  description: string;
  slot: number;
  metadata: Record<string, any>;
}

export interface PlayerVehicle {
  id: number;
  model: string;
  plate: string;
  location: string;
  stored: boolean;
  mileage: number;
  fuel: number;
  engine: number;
  body: number;
  value: number;
  impounded: boolean;
  impoundReason: string | null;
  mods: Record<string, any>;
  color: { primary: string; secondary: string };
  owner: string;
}

export interface PlayerProperty {
  id: number;
  type: string;
  address: string;
  owned: boolean;
  garage: number;
  price: number;
  keys: string[];
  locked: boolean;
  hasStash: boolean;
  hasWardrobe: boolean;
  tier: string;
  coords: { x: number; y: number; z: number };
}

export interface PlayerTransaction {
  id: number;
  type: string;
  amount: number;
  balance: number;
  from: string;
  to: string;
  timestamp: string;
  details: string;
}

export interface PlayerActivity {
  id: number;
  action: string;
  timestamp: string;
  type: string;
  details: string;
  admin: string | null;
}

export interface PlayerWarning {
  id: number;
  reason: string;
  issuedBy: string;
  date: string;
  active: boolean;
  expires: string;
}

export interface PlayerBan {
  id: number;
  reason: string;
  issuedBy: string;
  date: string;
  active: boolean;
  expires: string;
}

export interface PlayerNote {
  id: number;
  note: string;
  createdBy: string;
  date: string;
}

export interface PlayerPerformance {
  day: string;
  playtime: number;
  arrests: number;
  deaths: number;
}

export interface PlayerMoneyChart {
  day: string;
  cash: number;
  bank: number;
}
