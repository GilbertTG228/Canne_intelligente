# AGENTS.md

## Developer Commands
- **Dependencies**: `flutter pub get`
- **Analysis**: `flutter analyze`
- **Run**: `flutter run --dart-define=API_URL=https://your-server`
- **Routing Override**: `flutter run --dart-define=ROUTING_URL=...`

## Architecture & Patterns
- **State Management**: Provider + ChangeNotifier.
- **Data Flow**: `Service` (API/Local) $\rightarrow$ `Controller` (Provider) $\rightarrow$ `Screen/Widget`.
- **Offline Mode**: SQLite cache via `cache_service`. If API fails, app displays cached data with an offline banner.
- **Polling**: API is polled every 10s (no WebSockets).
- **Map/Routing**: `flutter_map` (OpenStreetMap) and OSRM pedestrian routing.

## Infrastructure Quirks
- **Android**: 
    - `minSdk = 23`.
    - Requires `isCoreLibraryDesugaringEnabled = true` for `flutter_local_notifications`.
    - Local test servers require `android:usesCleartextTraffic="true"` in `AndroidManifest.xml`.
- **Firebase**: Push notifications require `google-services.json` in `android/app/`. App remains functional without it.
- **Inactivity Logic**: Calculated client-side based on the age of the last received position.

## Key Implementation Details
- **Trips**: Reconstructed on the client; a gap > 10 min between positions starts a new trip.
- **Local Storage**: Home address and display names are stored locally on the device.
- **Consent**: Managed via `POST /api/consentements` and stored locally.
