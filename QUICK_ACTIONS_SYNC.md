# Quick Actions Synchronization Guide

## ✅ Quick Actions System Overview

The EC Admin Ultimate uses a **unified quick actions system** that ensures all admin actions work consistently across all pages.

### Core Components

1. **`ui/lib/quick-actions-data.ts`** - Master list of ALL 60+ quick actions
2. **`ui/components/admin-quick-actions-modal.tsx`** - `executeQuickAction()` function (unified execution)
3. **`server/quick_actions.lua`** - Server-side action handlers
4. **`client/nui-quick-actions.lua`** - Client-side NUI bridge

---

## ✅ Quick Actions Available from Dashboard

The dashboard includes a **QuickActionsWidget** that displays the most common actions:

- **Self Actions**: Noclip, God Mode, Invisible, Heal, Stamina, etc.
- **Teleport Actions**: TPM, Bring, Goto, etc.
- **Player Actions**: Revive, Heal, Kick, Ban, Freeze, etc.
- **Vehicle Actions**: Spawn, Fix, Delete, etc.
- **Economy Actions**: Give Money, Give Item, etc.
- **World Actions**: Weather, Time, etc.
- **Server Actions**: Restart Resource, Announcement, etc.

### Accessing Quick Actions from Dashboard

1. **Quick Actions Widget** - Shows 12-16 most common actions directly on dashboard
2. **Quick Actions Center** - Click "View All" or use keyboard shortcut to open full panel (60+ actions)
3. **Command Palette** - Search and execute any quick action

---

## ✅ Synchronized Actions Across Pages

### Player Actions (Synced)

These actions work the same way from **any page**:

| Action | Quick Action ID | Available From |
|--------|----------------|----------------|
| Kick Player | `kick` | Players Page, Player Profile, Moderation Page, Quick Actions |
| Ban Player | `ban` | Players Page, Player Profile, Moderation Page, Quick Actions |
| Revive Player | `revive` | Players Page, Player Profile, Quick Actions |
| Heal Player | `heal_player` | Players Page, Player Profile, Quick Actions |
| Teleport to Player | `goto` | Players Page, Player Profile, Quick Actions |
| Bring Player | `bring` | Players Page, Player Profile, Quick Actions |
| Spectate Player | `spectate` | Players Page, Player Profile, Quick Actions |
| Freeze Player | `freeze` | Players Page, Player Profile, Quick Actions |
| Unfreeze Player | `unfreeze` | Players Page, Player Profile, Quick Actions |

### Vehicle Actions (Synced)

| Action | Quick Action ID | Available From |
|--------|----------------|----------------|
| Spawn Vehicle | `spawn_vehicle` | Vehicles Page, Dashboard, Quick Actions |
| Fix Vehicle | `fix_vehicle` | Vehicles Page, Player Profile, Quick Actions |
| Delete Vehicle | `delete_vehicle` | Vehicles Page, Player Profile, Quick Actions |
| Teleport to Vehicle | `tp_vehicle` | Vehicles Page, Quick Actions |

### Economy Actions (Synced)

| Action | Quick Action ID | Available From |
|--------|----------------|----------------|
| Give Money | `give_money` | Player Profile, Economy Tools, Quick Actions |
| Give Item | `give_item` | Player Profile, Inventory, Quick Actions |
| Remove Money | `remove_money` | Player Profile, Economy Tools, Quick Actions |
| Remove Item | `remove_item` | Player Profile, Inventory, Quick Actions |

---

## ✅ How Actions Are Synced

### 1. Unified Execution Function

All actions use `executeQuickAction()` from `admin-quick-actions-modal.tsx`:

```typescript
import { executeQuickAction } from './admin-quick-actions-modal';

// Execute any quick action
await executeQuickAction('kick', { playerId: 1, reason: 'Test' });
await executeQuickAction('revive', { playerId: 1 });
await executeQuickAction('spawn_vehicle', { vehicleName: 'adder' });
```

### 2. AdminActionModal Integration

The `AdminActionModal` component now uses quick actions internally:

- **Kick** → `executeQuickAction('kick', data)`
- **Ban** → `executeQuickAction('ban', data)`
- **Revive** → `executeQuickAction('revive', data)`
- **Teleport** → `executeQuickAction('goto'|'bring'|'tpm', data)`

### 3. Server-Side Handler

All actions route through `server/quick_actions.lua`:

```lua
lib.callback.register('ec_admin:quickAction', function(source, actionData)
    local action = actionData.action
    local data = actionData.data or {}
    
    -- Route to appropriate handler
    local handler = actionHandlers[action]
    return handler(source, data)
end)
```

---

## ✅ Pages with Quick Actions Integration

### ✅ Dashboard
- **QuickActionsWidget** - Shows 12-16 common actions
- **Quick Actions Center** - Full panel accessible via button or shortcut
- All actions work from dashboard

### ✅ Players Page
- Uses `AdminActionModal` for player actions
- All actions sync with quick actions system
- Bulk actions also use quick actions

### ✅ Player Profile
- Uses `AdminActionModal` for moderation actions
- Vehicle actions use quick actions
- Economy actions use quick actions
- All actions sync with dashboard

### ✅ Moderation Page
- Ban/Kick actions use quick actions
- Warning actions use quick actions
- All moderation actions sync

### ✅ Vehicles Page
- Vehicle spawn/delete/fix use quick actions
- All vehicle actions sync with dashboard

### ✅ Economy Tools Page
- Money/item actions use quick actions
- All economy actions sync

---

## ✅ Testing Quick Actions Sync

### Test Checklist

1. **Dashboard Quick Actions**
   - [ ] Quick actions widget displays on dashboard
   - [ ] Actions execute correctly from dashboard
   - [ ] Quick Actions Center opens from dashboard
   - [ ] All 60+ actions available in center

2. **Player Actions Sync**
   - [ ] Kick works from Players page
   - [ ] Kick works from Player Profile
   - [ ] Kick works from Moderation page
   - [ ] Kick works from Quick Actions
   - [ ] All kick actions use same system

3. **Teleport Actions Sync**
   - [ ] "Teleport to Player" works from Players page
   - [ ] "Teleport to Player" works from Player Profile
   - [ ] "Teleport to Player" works from Quick Actions
   - [ ] "Bring Player" works from all locations
   - [ ] "TPM" works from all locations

4. **Vehicle Actions Sync**
   - [ ] Spawn vehicle works from Vehicles page
   - [ ] Spawn vehicle works from Dashboard
   - [ ] Spawn vehicle works from Quick Actions
   - [ ] Fix/Delete vehicle works from all locations

5. **Economy Actions Sync**
   - [ ] Give money works from Player Profile
   - [ ] Give money works from Economy Tools
   - [ ] Give money works from Quick Actions
   - [ ] All money/item actions sync

---

## ✅ Benefits of Unified System

1. **Consistency** - Same action works the same way everywhere
2. **Maintainability** - One place to update action logic
3. **Reliability** - All actions go through same validation
4. **Logging** - All actions logged consistently
5. **Permissions** - All actions check permissions the same way

---

## ⚠️ Important Notes

1. **Always use `executeQuickAction()`** - Don't create custom action handlers
2. **Action IDs must match** - Use exact IDs from `quick-actions-data.ts`
3. **Data format** - Follow the data format expected by server handlers
4. **Error handling** - `executeQuickAction()` handles errors and shows toasts

---

**Last Updated:** [Current Date]  
**Status:** ✅ All actions synchronized
