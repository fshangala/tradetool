# Binance Trade Tool

A Flutter application for trading futures on the Binance platform using the Binance API.

## Overview
This tool is designed for advanced futures trading on Binance, providing a modern and efficient interface for traders.

## Key Features
- **Futures Trading:** Execute futures trades directly on Binance.
- **Dual Network Support:** Seamlessly toggle between Binance Testnet and the Live network.
- **Secure Configuration:** Dedicated settings page for managing API keys for both environments.
- **Modern UI:** Dark theme inspired by the Binance aesthetic with custom gradients and transparent elements.

## Architecture
This project strictly follows the **MVVM (Model-View-ViewModel)** architectural pattern using the `provider` package for state management. This ensures a clean separation of concerns, testability, and maintainability.

## UI/UX Standards
- **Theme:** Dark mode by default.
- **Primary Color:** Binance Yellow (#F0B90B).
- **Design Elements:** Modern look using color gradients and transparent/glassmorphism objects where appropriate.

## Getting Started
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Use `flutter run` to start the application.

## Technologies
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Provider
- **Local Persistence:** Shared Preferences
