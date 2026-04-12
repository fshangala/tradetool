# Project Context: Binance Trade Tool

## Project Overview
`tradetool` is a Flutter application for trading futures on the Binance platform. It utilizes the Binance API for live and testnet environments.

- **Primary Technologies:** Flutter, Dart (SDK ^3.9.2).
- **Core Dependencies:** `provider`, `shared_preferences`, `cupertino_icons`, `http`, `k_chart_plus`, `web_socket_channel`, `logger`, `crypto`, `intl`, `wakelock_plus`, `uuid`.
- **Architecture:** Strictly follow **MVVM (Model-View-ViewModel)** using the `provider` package.

## UI & Design Standards
- **Theme Mode:** Always use **Dark Mode**.
- **Primary Color:** Binance Yellow (`#F0B90B`).
- **Aesthetic:** Modern design with gradients and transparent/glassmorphism objects.
- **Material Design:** Follow Material 3 guidelines while incorporating the custom theme.
- **Navigation:** Use named routes. `/` (Dashboard), `/settings` (Settings), `/profile` (Profile), and `/trades` (Trades).

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
- **Dashboard:** Implemented live K-line chart with real-time WebSocket updates and real-time open positions tracking.
- **Profile Page:** Displays comprehensive account information including total balances, unrealized PnL, available margin, assets list, and account configuration flags.
- **Notifications:** Integrated a non-intrusive, auto-dismissing notification system for order status and API errors.
- **Security:** Implemented HMAC SHA256 signing for authenticated API requests.
- **Robustness:** Added safe data parsing and null safety checks across all components to prevent crashes from malformed API responses.
- **Independent Positions Management:** Implemented independent fetching of open positions using the `/fapi/v3/positionRisk` endpoint.
- **Dashboard Enhancements:** Added a dedicated refresh button for positions, integrated open position entry prices into the candlestick chart, and implemented dual dropdown selectors for customizable symbols and 15+ time intervals.
- **Trading Operations:** Implemented "Close Position" functionality for instant market exit.
- **Customizable Pair Management:** Added a settings section to fetch, select, and persist a personalized list of trading pairs using `SharedPreferences`.
- **Trade History:** Implemented a dedicated trade history page fetching data from `/fapi/v1/userTrades`, with detailed modal views for each transaction and dashboard integration.
- **Type-safe Data Modeling:** Created structured Dart models (`AccountInformation`, `AccountConfig`, `PositionRisk`, `OrderResponse`, `Trade`, `Strategy`, `EntrySettings`) for all Binance API responses to provide a single source of truth and improve type safety.
- **Service Refactoring:** Refactored `BinanceService` to use these structured models and added comprehensive DartDoc documentation for all methods.
- **Automated Trading Strategies:** Implemented a sophisticated dual-side strategy engine.
    - **Separate Long/Short Conditions:** Define independent entry and exit conditions for Long and Short positions within the same strategy.
    - **Integrated Protection:** Move Take Profit and Stop Loss settings directly into the entry phase for immediate placement upon order fill.
    - **Expanded Indicators:** Full support for **RSI**, **EMA** (7, 25, 99), **Bollinger Bands** (UP, MB, DN), and **MACD** (Histogram, DIF, DEA) in conditions.
    - **Accurate EMA Logic:** Utilizes `EMAIndicator` with `emaValueList` for precise EMA7, EMA25, and EMA99 evaluation.
    - **Dynamic Comparisons:** Support for comparing price or indicators against other indicators (e.g., "Price < DN" or "DIF > DEA").
    - **Customizable Wallet Usage:** Specify 1-80% of available wallet balance for each strategy entry.
    - **Symbol Metadata & Precision:** Implemented `SymbolModel` to store exchange-provided `quantityPrecision` and `pricePrecision`.
    - **Dynamic Precision Handling:** Orders (Market and Protection) now dynamically use the correct precision for quantities and trigger prices based on the trading pair's metadata, replacing hardcoded defaults.
    - **Enhanced Pair Management:** Improved symbol selection UI with search filtering and precision information visibility.
    - **Navigation Drawer:** Implemented a navigation drawer on the Dashboard to declutter the AppBar and centralize access to Strategies, History, Profile, and Settings.
    - **Historical Comparisons:** Added `useLastClosedData` flag to conditions, allowing evaluation using price and indicator values from the last closed candle (regardless of the current candle's live movement).
    - **RSI Reversion Strategy:** Seeded a default "RSI Reversion" strategy utilizing closed-candle data (Entry: RSI < 30 / > 70, Exit: RSI 50).
- **Condition Groups & Nested Logic:** Introduced a powerful two-level logical hierarchy for strategy triggers.
    - **Grouped Conditions:** Support for multiple `ConditionGroup` objects per phase, each with its own internal **AND/OR** operator.
    - **Phase-Level Operators:** Combine multiple groups using a secondary phase-level **AND/OR** operator (e.g., `(A OR B) AND (C OR D)`).
    - **Backward Compatibility:** Robust migration layer in data models to wrap legacy single-list conditions into groups.
    - **Strategy Auto Continue:** Added an `autoContinue` toggle to each strategy. If disabled, the strategy automatically deselects itself from the pair after an exit, returning the user to manual mode.
    - **Signed Input Support:** Updated numeric fields in UI to allow negative values, enabling comparisons against negative indicator levels (e.g., MACD Histogram < -10.0).
    - **Advanced Lookback Conditions:** Implemented support for "ANY" or "ALL" evaluations over a specified range of candles (e.g., "RSI > 70 on ANY of last 5 candles").
- **Algo Order Support:** Integrated Binance's specialized Algo Order Service (`/fapi/v1/algoOrder`) for automated protection orders.
- **Dashboard Refinement:** Removed manual trade buttons to focus on automated execution; added a dynamic **Retry** button for failed strategy actions (Entry, Protection, or Exit).
- **Strategy Evaluation (Backtesting):** Implemented a comprehensive backtesting engine with realistic simulation.
    - **Historical Data:** Fetches and processes 500 candles for analysis, starting after 100 candles to allow indicator stabilization.
    - **Financial Simulation:** Accounts for Binance Futures VIP 0 fees (Maker 0.02%, Taker 0.05%) and supports 1x, 5x, 10x, and 20x leverage.
    - **Performance Metrics:** Tracks Gross Profit, Gross Loss, Total Fees, and calculates Net Earnings (PnL - Fees).
    - **Streaming Progress:** Asynchronous evaluation with a real-time progress bar for a smooth UI experience.
    - **Evaluation Persistence:** Automatically saves the latest evaluation results, input parameters, and a performance-based **5-star rating** to each strategy.
    - **Detailed Backtesting History:** Captures full entry/exit candle data (OHLCV + indicators) for every simulated trade, with side-by-side visual comparison UI in the strategy list.
    - **Enhanced Strategy List:** Displays star ratings and success rates (`profitableTrades / totalTrades`) directly on the main strategy list for at-a-glance performance monitoring.
- **Evaluation Performance & Visualization:** Optimized the strategy backtesting workflow for speed and clarity.
    - **K-line Caching:** Implemented a caching mechanism in `StrategyEvaluationViewModel` to store candlestick data by symbol and interval, making repeated evaluations near-instant.
    - **On-Demand Data Refresh:** Added a "Fetch New Data" button in the evaluation modal, allowing users to choose between using cached data or fetching the latest market data.
    - **Integrated Strategy Chart:** Added a high-performance `KChartWidget` directly to the Strategy Edit screen. It appears below the evaluation button when a result is available, showing the price action and technical indicators.
    - **Trade Timeline Visualization:** Developed a custom `TimelineIndicator` to plot simulated trades directly on the K-line chart.
    - **Color-Coded Triggers:** Visualizes entry and exit points with specific colors: Green for Long entries, Red for Short entries, and Blue for all trade exits (Long or Short).

## Planned Features
- **Enhanced Orders:** Support for Limit orders, Stop Loss, and Take Profit.

## Key Files
- `lib/main.dart`: Entry point with route configuration and top-level providers.
- `lib/core/logger.dart`: Global logger configuration.
- `lib/services/binance_service.dart`: Core logic for Binance API, WebSockets, and HMAC signing.
- `lib/viewmodels/`: MVVM ViewModels for state management (Dashboard, Settings, Notification, Strategy).
- `lib/views/`: UI implementation following the glassmorphism aesthetic.
- `pubspec.yaml`: Dependencies and project metadata.
- `README.md`: High-level project documentation.
