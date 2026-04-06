# Binance Trade Tool

A modern Flutter application for trading USDS-Margined futures on the Binance platform, supporting both Live and Testnet environments.

## Overview
This tool provides a streamlined, high-performance interface for futures traders, featuring real-time data, secure authentication, and a modern "glassmorphism" aesthetic.

## Key Features
- **Real-time Charting:** Live K-line (candlestick) charts with technical indicators (EMA, BOLL, MACD, RSI) and WebSocket updates.
- **Position Chart Integration:** Visualize open position entry prices directly on the K-line chart.
- **One-Click Trading:** Execute Long or Short market orders using a pre-configured percentage of available margin (default 40%).
- **Instant Position Exit:** Quick "Close Position" button to exit trades at market price with a single confirmation.
- **Independent Position Tracking:** Real-time monitoring of open positions, entry prices, mark prices, and unrealized PnL, with dedicated refresh controls.
- **Dual Network Support:** Toggle between Binance Testnet and Live network with independent API key management.
- **Detailed Account Profile:** Comprehensive view of wallet balances, asset breakdown, and account configuration flags (Position Mode, Multi-Assets Mode, etc.).
- **Smart Notifications:** Non-intrusive, auto-dismissing notifications for order confirmations and API errors.
- **Secure Authentication:** All private requests are signed with HMAC SHA256 as required by Binance API.

## Architecture
This project follows the **MVVM (Model-View-ViewModel)** architectural pattern using the `provider` package. This ensures a clean separation between UI components and business logic, promoting maintainability and stability.

## UI/UX Standards
- **Dark Mode:** Optimized for low-light environments and a premium trading experience.
- **Aesthetic:** Modern "glassmorphism" design using semi-transparent surfaces, gradients, and subtle blurs.
- **Responsiveness:** Designed to handle real-time data updates smoothly without UI lag.

## Getting Started
1. Clone the repository.
2. Ensure you have Flutter SDK installed (^3.9.2).
3. Run `flutter pub get` to install dependencies.
4. Add your Binance API keys in the **Settings** page (Testnet keys recommended for initial testing).
5. Use `flutter run` to start the application.

## Technologies
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Provider
- **Local Persistence:** Shared Preferences
- **Charting:** k_chart_plus
- **Security:** crypto (HMAC SHA256)
- **Networking:** http, web_socket_channel
