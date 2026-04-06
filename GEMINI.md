# Project Context: Binance Trade Tool

## Project Overview
`tradetool` is a Flutter application for trading futures on the Binance platform. It utilizes the Binance API for live and testnet environments.

- **Primary Technologies:** Flutter, Dart (SDK ^3.9.2).
- **Core Dependencies:** `provider`, `shared_preferences`, `cupertino_icons`, `http`, `k_chart_plus`, `web_socket_channel`, `logger`.
- **Architecture:** Strictly follow **MVVM (Model-View-ViewModel)** using the `provider` package.

## UI & Design Standards
- **Theme Mode:** Always use **Dark Mode**.
- **Primary Color:** Binance Yellow (`#F0B90B`).
- **Aesthetic:** Modern design with gradients and transparent/glassmorphism objects.
- **Material Design:** Follow Material 3 guidelines while incorporating the custom theme.
- **Navigation:** Use named routes. Initial route is `/` (Dashboard), and `/settings` for the settings page.

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
- **Navigation:** Refactored to a route-based flow. Removed the bottom navigation bar in favor of an `AppBar` action button for settings.
- **Settings Page:** Implemented UI for API keys (API Key, Secret Key) for both Live and Testnet, including network toggle and persistence.
- **Dashboard:** Implemented live K-line chart with real-time WebSocket updates and EMA indicators (7, 25, 99) rendered directly on the chart.
- **Logging:** Integrated `logger` package and replaced `debugPrint` with structured logging.

## Planned Features
- **Trading Operations:** Implement Open/Close position functionality (Market/Limit orders).
- **Position Tracking:** Real-time monitoring of open positions, PnL, and margin.
- **Account Balance:** Display available balance for the selected network.

## Key Files
- `lib/main.dart`: Entry point with route configuration and top-level providers.
- `lib/core/logger.dart`: Global logger configuration.
- `lib/services/binance_service.dart`: Core logic for Binance API and WebSockets.
- `lib/viewmodels/`: MVVM ViewModels for state management.
- `lib/views/`: UI implementation following the glassmorphism aesthetic.
- `pubspec.yaml`: Dependencies and project metadata.
- `README.md`: High-level project documentation.
