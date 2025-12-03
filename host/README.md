## Web access and IP privacy

Goal: Make the admin UI accessible from a browser while never exposing the raw VPS IP (45.144.225.227) to customers.

Recommended setup:

1) Bind the Node server to 0.0.0.0 for local interface access, but serve externally only via a reverse proxy.
- Edit `host/node-server/.env` (or copy `.env.example`) and set:
  - `BIND=0.0.0.0`
  - `PORT=3000`
  - `HOST_SECRET=YOUR_HOST_SHARED_SECRET_HERE_CHANGE_THIS`
  - `HOST_DOMAIN=api.ecbetasolutions.com`

2) Reverse proxy with HTTPS and DNS
- Point DNS for `api.ecbetasolutions.com` (and optionally `admin.ecbetasolutions.com`) to the VPS.
- Configure Apache/Nginx to proxy external requests to `http://127.0.0.1:3000` and terminate TLS.
- Keep `.htaccess` protections on XAMPP htdocs to prevent default page exposure.

3) Firewall rules
- Inbound allow TCP 3000-3019 (already scripted) if you want direct access from FiveM or internal services.
- Prefer proxying public access via 443/HTTPS only; avoid exposing 3000-3019 to the public internet when possible.

4) Authentication
- All protected APIs enforce `X-Host-Secret` header (see `index.js`).
- Add a web login/session for browser UI (JWT/cookie) before allowing admin actions.
- Optional: IP allow list for high-sensitivity endpoints (global bans, emergency control).

5) UI serving
- The Node server serves `ui/dist` directly; the reverse proxy should route `/` to that static content.
- Protected admin pages should call backend APIs with both session auth and `X-Host-Secret`.

6) Don’t leak the VPS IP
- Use only domain names in links, docs, and UI.
- Set `MASTER_GATEWAY_URL` to `https://api.ecbetasolutions.com` in `.env` if you enable HTTPS proxy.
- Avoid printing raw IP in status banners when `HOST_DOMAIN` is set.

Checklist to complete:
- [ ] `.env` configured with `BIND=0.0.0.0`, secrets set, domains set.
- [ ] Reverse proxy (Apache/Nginx) pointing domain → local 3000, with HTTPS.
- [ ] Windows Firewall rule present or ports closed if using proxy-only.
- [ ] UI loads over domain, admin actions succeed with secret + session.

# NRG HOST API Server

⚠️ **FOR NRG INTERNAL USE ONLY** - Do not distribute to customers!

> **Note for Customers**: This folder contains NRG's internal hosting infrastructure. **You do NOT need this!** EC_Admin_Ultimate works perfectly without it. The resource automatically detects if the Host API is available and gracefully falls back to Lua-only mode if not. You can safely ignore this entire folder. ✅

---

## Quick Setup

```batch
cd EC_admin_ultimate/host
setup.bat
```

This will:
1. Install dependencies
2. Generate .host-secret
3. Start the HOST API server

---

## Server Details

- **Port:** 3000 (localhost only)
- **Bind:** 127.0.0.1 (no external access)
- **APIs:** All 20 NRG APIs integrated
- **Language:** JavaScript (Node.js)

---

## Commands

- `setup.bat` - Install and start server
- `stop.bat` - Stop server
- `restart.bat` - Restart server

---

## Requirements

- Node.js 18+ (https://nodejs.org/)
- 2GB RAM minimum

---

## Verify

After running setup.bat, server should be online:

```
http://127.0.0.1:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "...",
  "uptime": 123
}
```

---

## Auto-Configuration

Server auto-configures on first run:
- Generates `.env` from `.env.example`
- Creates database tables
- Sets up HOST_SECRET
- Configures all 20 APIs

---

## APIs Included

All accessed via the main server on port 3000:

1. `/api/host/*` - HOST management (requires secret)
2. `/api/players/*` - Player data
3. `/api/bans/*` - Global bans
4. `/api/metrics/*` - Server metrics
5. + 16 more...

---

## Troubleshooting

**Server won't start:**
- Check Node.js: `node --version`
- Reinstall: `npm install`

**Port conflict:**
- Change PORT in `.env`
- Default: 3000

**Database errors:**
- Check MySQL is running
- Verify credentials in `.env`

---

**Support:** NRG Internal Discord #dev-support
