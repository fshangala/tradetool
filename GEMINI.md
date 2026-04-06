# Project Context: Binance Trade Tool

## Project Overview
`tradetool` is a Flutter application for trading futures on the Binance platform. It utilizes the Binance API for live and testnet environments.

- **Primary Technologies:** Flutter, Dart (SDK ^3.9.2).
- **Core Dependencies:** `provider`, `shared_preferences`, `cupertino_icons`, `http`, `k_chart_plus`, `web_socket_channel`, `logger`, `crypto`.
- **Architecture:** Strictly follow **MVVM (Model-View-ViewModel)** using the `provider` package.

## UI & Design Standards
- **Theme Mode:** Always use **Dark Mode**.
- **Primary Color:** Binance Yellow (`#F0B90B`).
- **Aesthetic:** Modern design with gradients and transparent/glassmorphism objects.
- **Material Design:** Follow Material 3 guidelines while incorporating the custom theme.
- **Navigation:** Use named routes. `/` (Dashboard), `/settings` (Settings), and `/profile` (Profile).

## Development Conventions
- **State Management:** Use `ChangeNotifier` classes as ViewModels and provide them using `ChangeNotifierProvider`.
- **Logic Separation:** Views should only handle UI. Business logic must reside in ViewModels. Models handle data structures and repository/API calls.
- **Persistence:** Use `shared_preferences` for storing API keys (Testnet and Live) and the network toggle state.
- **Linting:** Follow standard Flutter lints. No warnings or errors should be present in the codebase.
- **Charting:** Using `k_chart_plus` (v1.0.4+). Technical indicators must be calculated using `DataUtil.calculateIndicators` before rendering.
- **Logging:** Use the global `logger` instance from `lib/core/logger.dart` instead of `debugPrint` or `print`.

## Building and Running
- **Debug:** `flutter run`
- **Tests:** `flutter test`
- **Analysis:** `flutter analyze`
- **Dependencies:** `flutter pub get`
- **Formatting:** `dart format .`
- **Shell Commands:** Avoid using the `&&` operator in shell commands (e.g., in PowerShell). Use the `;` operator to chain multiple commands or run them sequentially.

## Current Status
- **Navigation:** Implemented route-based flow with Dashboard, Settings, and Profile views.
- **Settings Page:** Implemented UI for API keys (API Key, Secret Key) for both Live and Testnet, including network toggle and persistence.
- **Dashboard:** Implemented live K-line chart with real-time WebSocket updates, Long/Short trading buttons (40% margin), and real-time open positions tracking.
- **Profile Page:** Displays comprehensive account information including total balances, unrealized PnL, available margin, assets list, and account configuration flags.
- **Notifications:** Integrated a non-intrusive, auto-dismissing notification system for order status and API errors.
- **Security:** Implemented HMAC SHA256 signing for authenticated API requests.
- **Robustness:** Added safe data parsing and null safety checks across all components to prevent crashes from malformed API responses.

## Planned Features
- **Trading Operations:** Implement Close position functionality.
- **Enhanced Orders:** Support for Limit orders, Stop Loss, and Take Profit.
- **Historical Data:** View trade history and transaction logs.

## Key Files
- `lib/main.dart`: Entry point with route configuration and top-level providers.
- `lib/core/logger.dart`: Global logger configuration.
- `lib/services/binance_service.dart`: Core logic for Binance API, WebSockets, and HMAC signing.
- `lib/viewmodels/`: MVVM ViewModels for state management (Dashboard, Settings, Notification).
- `lib/views/`: UI implementation following the glassmorphism aesthetic.
- `pubspec.yaml`: Dependencies and project metadata.
- `README.md`: High-level project documentation.
