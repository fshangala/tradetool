# Binance Trade Tool

A modern Flutter application for trading USDS-Margined futures on the Binance platform, supporting both Live and Testnet environments.

## Overview
This tool provides a streamlined, high-performance interface for futures traders, featuring real-time data, secure authentication, and a modern "glassmorphism" aesthetic.

## Key Features
- **Real-time Charting:** Live K-line (candlestick) charts with technical indicators (EMA, BOLL, MACD, RSI) and WebSocket updates.
- **Position Chart Integration:** Visualize open position entry prices directly on the K-line chart.
- **Dynamic Pair Selection:** Quickly switch between symbols using a dashboard dropdown, synced with your personalized settings.
- **Advanced Interval Support:** Choose from 15 timeframes ranging from 1 minute to 1 month.
- **Automated Trading Strategies:** Create and manage custom strategies with sophisticated entry and exit logic.
    - **Dual-Side Support:** Define independent conditions for Long and Short entries/exits within the same strategy.
    - **Integrated Protection:** Configure Take Profit and Stop Loss directly in the entry settings for immediate placement upon order fill.
    - **Dynamic Comparisons:** Compare price or indicators against other indicators (e.g., "Close > EMA25").
    - **Customizable Wallet Usage:** Allocate 1-80% of available wallet balance per strategy.
- **Dashboard Automation:** Optimized for hands-free trading with automated strategy execution and a "Retry" mechanism for failed API actions.
- **Algo Order Service:** Utilizes Binance's specialized Algo Order API for reliable automated protection.
- **Instant Position Exit:** Quick "Close Position" button to exit trades at market price with a single confirmation.
- **Trade History & Analytics:** Comprehensive history of your trades with detailed breakdowns of price, quantity, commission, and realized PnL.
- **Personalized Symbol List:** Manage your own trading pairs list in Settings; fetch all available perpetual pairs and save your favorites.
- **Independent Position Tracking:** Real-time monitoring of open positions, entry prices, mark prices, and unrealized PnL, with dedicated refresh controls.
- **Dual Network Support:** Toggle between Binance Testnet and Live network with independent API key management.
- **Detailed Account Profile:** Comprehensive view of wallet balances, asset breakdown, and account configuration flags (Position Mode, Multi-Assets Mode, etc.).
- **Smart Notifications:** Non-intrusive, auto-dismissing notifications for order confirmations and API errors.
- **Wakelock Support:** Keeps the device screen on while automated strategies are actively running.
- **Secure Authentication:** All private requests are signed with HMAC SHA256 as required by Binance API.

## Architecture
This project follows the **MVVM (Model-View-ViewModel)** architectural pattern using the `provider` package. 

- **Models:** Structured Dart classes (`AccountInformation`, `PositionRisk`, `Trade`, `Strategy`, etc.) provide a single source of truth for all API data, ensuring type safety and robust parsing.
- **ViewModels:** `ChangeNotifier` classes that handle business logic, state management, and interaction with the `BinanceService`.
- **Views:** Declarative UI components built with Flutter, focusing solely on rendering state and handling user input.
- **Services:** `BinanceService` provides an authenticated, documented interface to the Binance Futures API.

This separation ensures a clean codebase, promoting maintainability and high stability for real-time trading data.

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
- **Device Support:** wakelock_plus
