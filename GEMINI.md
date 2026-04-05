# Project Context: tradetool

## Project Overview
`tradetool` is a Flutter application based on the standard Flutter counter template. It is designed to run on multiple platforms, including Android, iOS, Linux, macOS, Web, and Windows.

- **Primary Technologies:** Flutter, Dart (SDK ^3.9.2).
- **Key Dependencies:** `cupertino_icons`.
- **Architecture:** Standard Flutter widget-based architecture with `setState` for local state management.

## Building and Running
The following commands can be used to develop and build the project:

- **Run in Debug Mode:** `flutter run`
- **Run Tests:** `flutter test`
- **Static Analysis:** `flutter analyze`
- **Build for Windows:** `flutter build windows` (and similarly for other platforms like `apk`, `ios`, `web`).
- **Update Dependencies:** `flutter pub get`

## Development Conventions
- **Linting:** The project follows the recommended Flutter lints defined in `package:flutter_lints/flutter.yaml`.
- **UI:** Uses Material Design 3 (implied by `ColorScheme.fromSeed` in `main.dart`).
- **Formatting:** Adheres to the standard Dart formatting rules (`dart format`).
- **Testing:** Widget tests are located in the `test/` directory.

## Key Files
- `lib/main.dart`: The main entry point of the application, containing the `MyApp` and `MyHomePage` widgets.
- `pubspec.yaml`: Defines project dependencies, assets, and versioning.
- `analysis_options.yaml`: Configures the Dart analyzer and linter rules.
- `test/widget_test.dart`: Contains smoke tests for the UI.
