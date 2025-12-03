# NRG API Suite - Host APIs

## Overview

This directory contains **7 production APIs** that run on the NRG Host server:

1. **Global Ban API** - Cross-server ban synchronization
2. **Server Registry API** - Customer server management
3. **Analytics API** - Aggregated server analytics
4. **Player Tracking API** - Global player database
5. **Resource Hub API** - Resource distribution
6. **License Validation API** - License management
7. **Emergency Control API** - Remote server control

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    NRG HOST SERVER                       │
│  (Runs all 7 APIs + Master Gateway)                     │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │
            ┌─────────────┼─────────────┐
            │             │             │
            ▼             ▼             ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │  Customer   │ │  Customer   │ │  Customer   │
    │  Server 1   │ │  Server 2   │ │  Server 3   │
    └─────────────┘ └─────────────┘ └─────────────┘
```

---

## API Endpoints

### 1. Global Ban API (`/api/bans/*`)

**Purpose**: Synchronize bans across all customer servers

**Endpoints**:
- `POST /api/bans/add` - Add global ban
- `GET /api/bans/check/:identifier` - Check if player banned
- `GET /api/bans/list` - List all bans
- `DELETE /api/bans/remove/:id` - Remove ban
- `POST /api/bans/sync` - Sync bans to customer server

---

### 2. Server Registry API (`/api/registry/*`)

**Purpose**: Manage customer server connections

**Endpoints**:
- `POST /api/registry/register` - Register customer server
- `POST /api/registry/heartbeat` - Server heartbeat
- `GET /api/registry/list` - List all servers
- `GET /api/registry/stats/:server_id` - Server statistics
- `DELETE /api/registry/unregister/:server_id` - Unregister server

---

### 3. Analytics API (`/api/analytics/*`)

**Purpose**: Aggregated analytics across all servers

**Endpoints**:
- `GET /api/analytics/overview` - Global overview
- `GET /api/analytics/players` - Player statistics
- `GET /api/analytics/economy` - Economy stats
- `GET /api/analytics/performance` - Performance metrics
- `POST /api/analytics/report` - Submit analytics report

---

### 4. Player Tracking API (`/api/players/*`)

**Purpose**: Global player database

**Endpoints**:
- `GET /api/players/:identifier` - Get player data
- `POST /api/players/track` - Track player session
- `GET /api/players/search` - Search players
- `GET /api/players/history/:identifier` - Player history
- `POST /api/players/flag` - Flag suspicious player

---

### 5. Resource Hub API (`/api/resources/*`)

**Purpose**: Distribute approved resources

**Endpoints**:
- `GET /api/resources/list` - List available resources
- `GET /api/resources/download/:id` - Download resource
- `POST /api/resources/upload` - Upload resource (admin)
- `GET /api/resources/updates` - Check for updates

---

### 6. License Validation API (`/api/license/*`)

**Purpose**: Validate customer licenses

**Endpoints**:
- `POST /api/license/validate` - Validate license key
- `GET /api/license/info/:key` - License information
- `POST /api/license/activate` - Activate license
- `POST /api/license/deactivate` - Deactivate license

---

### 7. Emergency Control API (`/api/emergency/*`)

**Purpose**: Emergency remote server control

**Endpoints**:
- `POST /api/emergency/shutdown/:server_id` - Emergency shutdown
- `POST /api/emergency/broadcast` - Broadcast message
- `POST /api/emergency/rollback/:server_id` - Rollback database
- `GET /api/emergency/status/:server_id` - Emergency status

---

## Authentication

All APIs use **JWT token authentication**:

```http
Authorization: Bearer <jwt_token>
X-Server-ID: <customer_server_id>
X-API-Key: <api_key>
```

---

## Rate Limiting

- **Customer servers**: 1000 req/min
- **Admin endpoints**: 100 req/min
- **Public endpoints**: 60 req/min

---

## Database Schema

See `/host/database/schema.sql` for complete schema.

---

## Setup

See `/host/SETUP.md` for installation instructions.
