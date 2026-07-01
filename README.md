# Field Asset Tracker

> An offline-first mobile field data collection app built with Flutter — empowering engineers and surveyors to record asset data reliably, with or without network connectivity.

---

## Features

- **Offline-first architecture** — Full functionality without internet. Data is cached locally in Hive and synced automatically when the network returns.
- **Real-time network monitoring** — Animated slide-down banners alert the user when the device goes offline or reconnects.
- **Automated background sync** — Detects network restoration and pushes all pending local records to the backend automatically.
- **Modern professional UI** — Card-based interface with category chips, formatted coordinate displays, and live sync status indicators.
- **Robust conflict resolution** — Smart client-wins upsert logic ensures data is never duplicated or lost during interrupted syncs.

---

## Technology Stack

| Layer | Library |
|---|---|
| Frontend framework | Flutter |
| State management | `flutter_riverpod` |
| Local database | `hive_flutter` |
| Networking | `dio` |
| Network detection | `connectivity_plus` |
| Mock backend (dev) | `json-server` |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js and npm](https://nodejs.org/) (for the local mock backend)

### 1. Install JSON Server

```bash
npm install -g json-server
```

### 2. Start the mock backend

From your project root:

```bash
json-server --watch db.json
```

> **⚠️ Physical device / emulator note**
> Devices and Android emulators cannot route to `localhost`. Bind the server to your local network IP instead:
>
> ```bash
> json-server --watch db.json --host 0.0.0.0 --port 3000
> ```
>
> Then update `_baseUrl` in `lib/data/datasources/remote_data_source.dart` to your machine's IPv4 address — e.g. `http://192.168.1.5:3000/assets`.

### 3. Run the Flutter app

```bash
flutter pub get
flutter run
```

Chrome is recommended for testing network throttling on web.

---

## Synchronization & Error Handling

Field networks are inherently unstable. The app handles this through a resilient background-friendly flow:

1. **Local cache first** — New assets are written immediately to Hive and marked `pendingSync`. The UI updates instantly; the user is never blocked.
2. **Network interception** — `DioException` blocks catch timeouts, 500 errors, and 404s during transmission.
3. **Graceful failures** — API errors are caught and suppressed from the UI. The asset stays tagged `pendingSync` in Hive.
4. **Auto-recovery** — The app listens to the device's network stream. The moment connectivity transitions from offline to online, an automatic sync sweep retries all pending uploads.

---

## Conflict Resolution

A common problem in offline-first apps: if the server saves an asset but the network drops before returning a success response, the app assumes the upload failed. On the next sync attempt, pushing the same asset would cause a duplicate key error.

The app solves this with a **check-then-act (client-wins upsert)** strategy:

```
Before pushing any pending asset:

  GET /assets/{id}
  │
  ├── 404 Not Found ──→ No conflict. POST to create the record.
  │
  └── 200 OK ─────────→ Conflict detected. PUT to overwrite the server
                         record with the client's latest version.
                         Field worker's edits always win.
```

When a conflict is resolved, a globally registered `ScaffoldMessengerKey` triggers a snackbar notifying the user that the server data was successfully overwritten.

---

## Project Structure

```
lib/
├── data/
│   ├── datasources/       # Dio API calls and JSON Server integration
│   └── models/            # Hive adapters and Data Transfer Objects
├── domain/
│   └── entities/          # Core business objects (AssetEntity)
├── presentation/
│   ├── providers/         # Riverpod state management
│   ├── screens/           # AssetListScreen, AddAssetScreen
│   └── widgets/           # Reusable UI components (NetworkBanner)
└── main.dart              # App entry point and global messenger key
```