# Local VPN Test Server

This directory contains everything needed to test the VPN app locally — both
a **mock mode** (no server needed) and a **real local OpenVPN server** via Docker.

---

## Option A — Mock Mode (no network, instant setup)

The fastest way to test all UI states.  No server, no Docker, no certs needed.

### Setup

Open [`lib/utilities/vpn_service.dart`](../lib/utilities/vpn_service.dart) and
make sure the flag is set to `true`:

```dart
const bool kLocalTestMode = true;
```

### Run

```
flutter run
```

Tap **Connect** and the app will cycle through:

| Time | Stage shown |
|------|-------------|
| 0 s  | Connecting… |
| 1.2 s | Authenticating… |
| 2.8 s | Connected ✓ |

Download / upload stats tick every second with simulated traffic.
Tap **Disconnect** to cycle back through Disconnecting → Not Connected.

---

## Option B — Real Local OpenVPN Server (Docker)

Use this when you want a genuine TLS handshake and a real kernel VPN tunnel.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with the
  WSL 2 backend **running**
- Android Emulator (the emulator routes `10.0.2.2` to your Windows host
  automatically — no extra port forwarding needed)

### One-time Setup

Open PowerShell **inside** this directory and run:

```powershell
cd local_test_server
.\setup.ps1
```

The script will:
1. Generate a full PKI (CA + server certificate) inside the Docker container
2. Create a `local-test` client certificate
3. Export a complete `.ovpn` client profile → `local-test.ovpn`
4. Overwrite all `assets/vpn_configs/*.ovpn` with that profile pointing at `10.0.2.2:1194`
5. Start the OpenVPN server in the background (`docker-compose up -d`)

> ⚠️  The PKI generation step takes about 60 seconds on first run.

### Connect the Flutter App

1. In `vpn_service.dart` flip the flag:
   ```dart
   const bool kLocalTestMode = false;
   ```
2. Run the app on the **Android Emulator**:
   ```
   flutter run
   ```
3. Tap **Connect** — a real OpenVPN tunnel to your local server will be
   established.

### Stop the Server

```powershell
.\teardown.ps1
```

You'll be asked whether to keep or wipe the PKI data.  Keeping it means you
can restart the server with a simple `docker-compose up -d` without re-running
setup.

---

## File Reference

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Defines the `kylemanna/openvpn` container on UDP 1194 |
| `setup.ps1` | Full one-shot setup: PKI → client cert → export → start server |
| `teardown.ps1` | Stop server + optional PKI wipe |
| `data/` | PKI data volume (created by setup.ps1, gitignored) |
| `local-test.ovpn` | Exported client profile (created by setup.ps1, gitignored) |

---

## Switching Between Modes

| What you want | `kLocalTestMode` | Server running? |
|---------------|:--------------:|:---------------:|
| UI / animation testing | `true` | ❌ Not needed |
| Real tunnel testing | `false` | ✅ Yes (setup.ps1) |
| Production | `false` | ✅ Real server |

---

## Troubleshooting

**`Docker Desktop is not running`**  
Start Docker Desktop and wait for the whale icon to show "Docker Desktop is running" in the system tray.

**`Connection error` in the app after setup**  
Check the container logs:
```powershell
docker logs vpn_local_test
```

**Physical device instead of emulator**  
`10.0.2.2` only works in the Android Emulator. For a physical device on the
same Wi-Fi, find your PC's local IP (`ipconfig`) and use that instead of
`10.0.2.2` in the `.ovpn` files. You may also need to open UDP 1194 in
Windows Firewall.
