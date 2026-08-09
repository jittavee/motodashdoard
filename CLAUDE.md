# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Flutter app ("ECU Gauge" / api_tech_moto) that connects to a motorcycle ECU dongle over BLE and displays real-time gauges (RPM, speed, temps, AFR, etc.), with data logging, performance timing (0-100/201/402/1000m), smart alerts, and multiple dashboard themes. UI text is Thai-first (fallback locale `th_TH`); code comments are frequently in Thai too.

This repo is managed with FVM (Flutter Version Management) — `.fvmrc` pins Flutter `3.32.7`. Prefer `fvm flutter` over a bare `flutter` binary so the pinned SDK version is used.

## Common commands

```bash
fvm flutter pub get                 # install dependencies
fvm flutter run                     # run on connected device/emulator
fvm flutter analyze                 # static analysis (flutter_lints rules, see analysis_options.yaml)
fvm flutter test                    # run all tests
fvm flutter test test/controllers/ecu_data_controller_test.dart   # run a single test file
fvm flutter test --plain-name "should reject empty data"          # run a single test by name
fvm flutter build apk --release     # release APK build
```

Release / distribution helper scripts (interactive, run from repo root):
- `./bump_version.sh` — bumps the build number (and optionally version name) in `pubspec.yaml`.
- `./deploy_firebase.sh` — builds a release APK and uploads it to Firebase App Distribution (tester group). Requires the `firebase` CLI and prompts for release notes.

There is no separate lint-fix command; `flutter analyze` surfaces issues from `flutter_lints` as configured in [analysis_options.yaml](analysis_options.yaml).

## Architecture

### State management: GetX

Everything is wired through GetX (`get` package) — controllers, routes, dependency injection, and translations all go through `Get`.

- All top-level controllers/services are registered once in [lib/main.dart](lib/main.dart) via `Get.put(..., permanent: true)` before `runApp`, in a specific order: `PermissionService` (async) → `ThemeController` → `LanguageController` → `SettingsController` → `ECUDataController` → `BluetoothController` → `PerformanceTestController` → `GpsSpeedController`. Because they're permanent singletons, any screen/widget can reach them with `Get.find<XController>()`.
- Routing is declarative via `GetPage` in [lib/routes/app_pages.dart](lib/routes/app_pages.dart) with route names in [lib/routes/app_routes.dart](lib/routes/app_routes.dart); initial route is the splash screen.
- Reactive state uses `Rx`/`.obs` fields observed with `Obx(...)` in widgets (see `MyApp` in `main.dart` reacting to theme/locale changes).

### BLE data pipeline (the core data flow)

1. [lib/controllers/bluetooth_controller.dart](lib/controllers/bluetooth_controller.dart) scans/connects to the ECU dongle over `flutter_blue_plus`, targeting a fixed service/characteristic UUID pair (`targetServiceUuid` / `targetCharacteristicUuid`). It discovers services, subscribes to the notify characteristic, and decodes incoming bytes as UTF-8 strings.
2. The dongle streams one `KEY=VALUE` parameter per BLE notification (13 parameters per full cycle, ~15ms apart — see [ESP32_BLE_Data_Protocol.md](ESP32_BLE_Data_Protocol.md)). Valid keys: `TECHO, SPEED, WATER, AIR.T, MAP, TPS, BATT, IGNITI, INJECT, AFR, S.TRIM, L.TRIM, IACV`.
3. `BluetoothController` also intercepts special non-gauge messages before forwarding to the ECU controller: `EcuModel=N` (dongle ACKs an ECU model selection), `ECU=Connected|No_response|Connecting...` (dongle↔ECU link status), and echoes of commands the app itself sent (e.g. `model=N`), which are ignored.
4. On connect, the app always sends `model=0` (simulation) first, waits for that ACK, then re-sends the last-remembered `EcuModel` (persisted in `SharedPreferences`) — see `_waitingForSimulationAck` in `bluetooth_controller.dart`.
5. Valid parameter updates are forwarded via `Get.find<ECUDataController>().updateDataFromBluetooth(...)`, which validates/parses each `KEY=VALUE`, range-checks the value (see `_isValueInValidRange`), buffers it, and throttles UI updates to ~20fps (50ms) — with RPM (`TECHO`) further throttled to a 1000ms buffer window before merging into the general 50ms UI throttle. This exists to keep gauge animation smooth under high-frequency BLE notifications.
6. [lib/controllers/ecu_data_controller.dart](lib/controllers/ecu_data_controller.dart) also owns: alert threshold checks against live data (`_checkAlerts`, sound via `audioplayers`), optional per-second logging to SQLite, and a playback system (`isPlaybackMode`) that replays historical logs through the same `displayData` getter the dashboards read from — so dashboard widgets don't need to know whether they're showing live or replayed data.

### Persistence

[lib/services/database_helper.dart](lib/services/database_helper.dart) wraps `sqflite` with a singleton `DatabaseHelper.instance`. Three tables: `ecu_logs` (per-reading history), `alert_thresholds` (user-configured alert min/max per parameter), `performance_tests` (saved acceleration test results, including embedded ECU session stats added in schema v3). Schema changes go through `_upgradeDB` with additive `ALTER TABLE` migrations guarded by `PRAGMA table_info` checks — follow that pattern (never destructive) when adding columns.

### Dashboards and theming

Multiple interchangeable dashboard layouts live in `lib/views/screens/dashboard/` (`dashboard_1.dart` … `dashboard_5.dart`, plus `dashboard_4_1.dart`), each registered as its own route/template (`template1`..`template5` in `app_pages.dart`) and selected via [lib/views/screens/dashboard_template_screen.dart](lib/views/screens/dashboard_template_screen.dart). Visual themes (Classic/Sport/Digital) are defined in [lib/constants/app_themes.dart](lib/constants/app_themes.dart) and switched live via `ThemeController` — these are independent axes (dashboard layout choice vs. color theme). Gauge widgets (`views/widgets/*_gauge.dart`, `*_arc_gauge.dart`) are shared across dashboard templates and built on `syncfusion_flutter_gauges` / custom painters.

The app is locked to landscape orientation at startup (`SystemChrome.setPreferredOrientations` in `main.dart`).

### Translations (GetX i18n)

Thai/English strings live in [lib/translations/th_th.dart](lib/translations/th_th.dart) and [lib/translations/en_us.dart](lib/translations/en_us.dart), aggregated by `AppTranslations` in [lib/translations/app_translations.dart](lib/translations/app_translations.dart) and set on `GetMaterialApp`. Use the `'key'.tr` extension in widgets; `LanguageController` drives the active locale. See [TRANSLATION_GUIDE.md](TRANSLATION_GUIDE.md) for the full convention and [TROUBLESHOOTING_LANGUAGE.md](TROUBLESHOOTING_LANGUAGE.md) for known locale-switching pitfalls.

### Permissions

[lib/services/permission_service.dart](lib/services/permission_service.dart) is initialized first (async, before other controllers) since Bluetooth/GPS features depend on runtime permissions being resolved. Required platform permission declarations are in `android/app/src/main/AndroidManifest.xml` (Bluetooth scan/connect, location) and `ios/Runner/Info.plist` (Bluetooth + location usage descriptions).

## Testing notes

Controller tests (`test/controllers/*_test.dart`) instantiate controllers directly with `Get.testMode = true` and call `Get.reset()` in `tearDown` — follow this pattern for new controller tests rather than pumping a full widget tree. `ecu_data_controller_test.dart` is the reference example for validating the BLE parsing/range-checking behavior described above.
