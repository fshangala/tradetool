# Project Context: Binance Trade Tool

## Project Overview
`tradetool` is a Flutter application for trading futures on the Binance platform. It utilizes the Binance API for live and testnet environments.

- **Primary Technologies:** Flutter, Dart (SDK ^3.9.2).
- **Core Dependencies:** `provider`, `shared_preferences`, `cupertino_icons`.
- **Architecture:** Strictly follow **MVVM (Model-View-ViewModel)** using the `provider` package.

## UI & Design Standards
- **Theme Mode:** Always use **Dark Mode**.
- **Primary Color:** Binance Yellow (`#F0B90B`).
- **Aesthetic:** Modern design with gradients and transparent/glassmorphism objects.
- **Material Design:** Follow Material 3 guidelines while incorporating the custom theme.

## Development Conventions
- **State Management:** Use `ChangeNotifier` classes as ViewModels and provide them using `ChangeNotifierProvider`.
- **Logic Separation:** Views should only handle UI. Business logic must reside in ViewModels. Models handle data structures and repository/API calls.
- **Persistence:** Use `shared_preferences` for storing API keys (Testnet and Live) and the network toggle state.
- **Linting:** Follow standard Flutter lints.

## Building and Running
- **Debug:** `flutter run`
- **Tests:** `flutter test`
- **Analysis:** `flutter analyze`
- **Dependencies:** `flutter pub get`

## Planned Features
- **Settings Page:** UI for API keys (API Key, Secret Key) for both Live and Testnet, plus a toggle to switch networks.
- **Binance API Integration:** For futures trading.

## Key Files
- `lib/main.dart`: Entry point with theme configuration and top-level providers.
- `pubspec.yaml`: Dependencies and project metadata.
- `README.md`: High-level project documentation.
