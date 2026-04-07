import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/binance_service.dart';
import '../models/account_info.dart';
import '../models/account_config.dart';
import '../models/position_risk.dart';
import 'settings_viewmodel.dart';
import 'notification_viewmodel.dart';
import 'strategy_viewmodel.dart';
import '../models/strategy.dart';
import '../core/logger.dart';

class PositionIndicator extends MainIndicator<KLineEntity, MAStyle> {
  final List<double> entryPrices;

  PositionIndicator({required this.entryPrices})
      : super(
          name: 'POS',
          shortName: 'POS',
          indicatorStyle: const MAStyle(),
          calcParams: [],
        );

  @override
  void calc(List<KLineEntity> data) {}

  @override
  void drawChart(
    KLineEntity lastData,
    KLineEntity curData,
    double lastX,
    double curX,
    double Function(double) getLineY,
    Canvas canvas,
    KChartColors chartColors,
  ) {
    for (var price in entryPrices) {
      final y = getLineY(price);
      canvas.drawLine(
        Offset(lastX, y),
        Offset(curX, y),
        Paint()
          ..color = Colors.green.withValues(alpha: 0.7)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  TextSpan? drawFigure(KLineEntity data, int index, KChartColors chartColors) {
    return null;
  }

  @override
  (double, double) getMaxMinValue(KLineEntity data, double min, double max) {
    double newMin = min;
    double newMax = max;
    for (var price in entryPrices) {
      if (price < newMin) newMin = price;
      if (price > newMax) newMax = price;
    }
    return (newMin, newMax);
  }
}

class DashboardViewModel extends ChangeNotifier {
  final SettingsViewModel settingsViewModel;
  final NotificationViewModel notificationViewModel;
  final StrategyViewModel strategyViewModel;
  late BinanceService _binanceService;
  WebSocketChannel? _wsChannel;

  // Strategy Execution State
  final Map<String, String?> _activeStrategyIds = {}; // symbol -> strategyId
  final Map<String, String> _activeStrategyPhases = {}; // symbol -> phase (entry, protection, exit)
  
  String? getActiveStrategyId(String symbol) => _activeStrategyIds[symbol];
  String getActiveStrategyPhase(String symbol) => _activeStrategyPhases[symbol] ?? 'none';

  void setStrategyForSymbol(String symbol, String? strategyId) {
    if (isSymbolLocked(symbol)) return;
    _activeStrategyIds[symbol] = strategyId;
    if (strategyId != null) {
      _activeStrategyPhases[symbol] = 'entry';
    } else {
      _activeStrategyPhases.remove(symbol);
    }
    notifyListeners();
  }

  bool isSymbolLocked(String symbol) {
    // Locked if there's an active position AND a strategy was selected
    final hasPosition = _positions.any((p) => p.symbol == symbol);
    return hasPosition && _activeStrategyIds[symbol] != null;
  }

  List<KLineEntity> _datas = [];
  List<KLineEntity> get datas => _datas;

  String _currentInterval = '1m';
  String get currentInterval => _currentInterval;

  String _currentSymbol = 'BTCUSDT';
  String get currentSymbol => _currentSymbol;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isPositionsLoading = false;
  bool get isPositionsLoading => _isPositionsLoading;

  double _availableBalance = 0.0;
  double get availableBalance => _availableBalance;

  List<PositionRisk> _positions = [];
  List<PositionRisk> get positions => _positions;

  AccountInformation? _accountInfo;
  AccountInformation? get accountInfo => _accountInfo;

  AccountConfig? _accountConfig;
  AccountConfig? get accountConfig => _accountConfig;

  List<MainIndicator> _mainIndicators = [
    EMAIndicator(calcParams: [7, 25, 99]),
    BOLLIndicator(),
  ];
  final List<SecondaryIndicator> _secondaryIndicators = [
    MACDIndicator(),
    RSIIndicator(),
  ];

  List<MainIndicator> get mainIndicators => _mainIndicators;
  List<SecondaryIndicator> get secondaryIndicators => _secondaryIndicators;

  DashboardViewModel({
    required this.settingsViewModel,
    required this.notificationViewModel,
    required this.strategyViewModel,
  }) {
    _updateBinanceService();
    _init();

    settingsViewModel.addListener(_onSettingsChanged);
  }

  void _updateBinanceService() {
    _binanceService = BinanceService(
      isTestnet: settingsViewModel.isTestnet,
      apiKey: settingsViewModel.isTestnet
          ? settingsViewModel.testnetApiKey
          : settingsViewModel.liveApiKey,
      secretKey: settingsViewModel.isTestnet
          ? settingsViewModel.testnetSecretKey
          : settingsViewModel.liveSecretKey,
    );
  }

  void _onSettingsChanged() {
    _updateBinanceService();
    // Reset symbol if it's no longer in the selected list
    if (!settingsViewModel.selectedSymbols.contains(_currentSymbol)) {
      if (settingsViewModel.selectedSymbols.isNotEmpty) {
        _currentSymbol = settingsViewModel.selectedSymbols.first;
      }
    }
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    _datas = []; // Clear old data
    notifyListeners();

    await Future.wait([
      _fetchHistory(),
      _fetchAccountInfo(),
      _fetchPositions(),
    ]);
    _connectWebsocket();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchAccountInfo() async {
    final key = settingsViewModel.isTestnet
        ? settingsViewModel.testnetApiKey
        : settingsViewModel.liveApiKey;
    final secret = settingsViewModel.isTestnet
        ? settingsViewModel.testnetSecretKey
        : settingsViewModel.liveSecretKey;

    if (key.isEmpty || secret.isEmpty) {
      logger.i('API Keys not set, skipping account info fetch');
      _accountInfo = null;
      _accountConfig = null;
      _availableBalance = 0.0;
      return;
    }

    try {
      final results = await Future.wait([
        _binanceService.fetchAccountInformation(),
        _binanceService.fetchAccountConfig(),
      ]);
      
      _accountInfo = results[0] as AccountInformation;
      _accountConfig = results[1] as AccountConfig;
      
      _availableBalance = _accountInfo?.availableBalance ?? 0.0;
    } catch (e) {
      logger.e('Error fetching account info: $e');
      notificationViewModel.error('Failed to load account info: $e');
    }
  }

  Future<void> _fetchPositions() async {
    final key = settingsViewModel.isTestnet
        ? settingsViewModel.testnetApiKey
        : settingsViewModel.liveApiKey;
    final secret = settingsViewModel.isTestnet
        ? settingsViewModel.testnetSecretKey
        : settingsViewModel.liveSecretKey;

    if (key.isEmpty || secret.isEmpty) {
      _positions = [];
      return;
    }

    _isPositionsLoading = true;
    notifyListeners();

    try {
      final positionRisk = await _binanceService.fetchPositionRisk();
      _positions = positionRisk.where((p) => p.positionAmt != 0).toList();

      _updateChartIndicators();
    } catch (e) {
      logger.e('Error fetching positions: $e');
      notificationViewModel.error('Failed to load positions: $e');
    } finally {
      _isPositionsLoading = false;
      notifyListeners();
    }
  }

  void _updateChartIndicators() {
    final symbolPositions = _positions.where((p) => p.symbol == _currentSymbol).toList();
    final entryPrices = symbolPositions
        .map((p) => p.entryPrice)
        .where((price) => price > 0)
        .toList();

    _mainIndicators = [
      EMAIndicator(calcParams: [7, 25, 99]),
      BOLLIndicator(),
    ];

    if (entryPrices.isNotEmpty) {
      _mainIndicators.add(PositionIndicator(entryPrices: entryPrices));
      notifyListeners();
    }
  }

  Future<void> refreshPositions() async {
    await _fetchPositions();
  }

  Future<void> closePosition(PositionRisk position) async {
    final symbol = position.symbol;
    final amt = position.positionAmt;
    if (amt == 0) return;

    final side = amt > 0 ? 'SELL' : 'BUY';
    final quantity = amt.abs();
    final positionSide = position.positionSide;

    try {
      _isPositionsLoading = true;
      notifyListeners();

      final response = await _binanceService.placeOrder(
        symbol: symbol,
        side: side,
        type: 'MARKET',
        quantity: quantity,
        positionSide: positionSide,
      );

      logger.i('Position closed successfully: ${response.orderId}');
      notificationViewModel.success('Position closed for $symbol');
      
      await Future.wait([
        _fetchPositions(),
        _fetchAccountInfo(),
      ]);
    } catch (e) {
      logger.e('Error closing position: $e');
      notificationViewModel.error('Failed to close position: $e');
      _isPositionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final fetchedDatas = await _binanceService.fetchKlines(
        symbol: _currentSymbol,
        interval: _currentInterval,
      );
      _datas = fetchedDatas;
      DataUtil.calculateIndicators(
        _datas,
        _mainIndicators,
        _secondaryIndicators,
      );
    } catch (e) {
      logger.e('Error fetching history: $e');
      notificationViewModel.error('Failed to load chart data: $e');
    }
  }

  void _connectWebsocket() {
    _wsChannel?.sink.close();
    _wsChannel = _binanceService.establishKlineWebsocket(
      _currentSymbol,
      _currentInterval,
    );

    _wsChannel!.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['e'] == 'kline') {
        final k = data['k'];
        final newEntity = _binanceService.mapWsToKLineEntity(k);

        if (_datas.isNotEmpty && _datas.last.time == newEntity.time) {
          _datas[_datas.length - 1] = newEntity;
        } else {
          _datas.add(newEntity);
        }
        DataUtil.calculateIndicators(
          _datas,
          _mainIndicators,
          _secondaryIndicators,
        );

        // Run strategy evaluation
        _runStrategyEvaluation(_currentSymbol);

        notifyListeners();
      }
    });
  }

  void _runStrategyEvaluation(String symbol) {
    final strategyId = _activeStrategyIds[symbol];
    if (strategyId == null) return;

    final strategy = strategyViewModel.getStrategyById(strategyId);
    if (strategy == null) return;

    final phase = _activeStrategyPhases[symbol] ?? 'entry';

    if (phase == 'entry') {
      _processEntryPhase(symbol, strategy);
    } else if (phase == 'protection') {
      _processProtectionPhase(symbol, strategy);
    } else if (phase == 'exit') {
      _processExitPhase(symbol, strategy);
    }
  }

  Future<void> _processEntryPhase(String symbol, Strategy strategy) async {
    // Only entry if no position is open for this symbol
    final hasPosition = _positions.any((p) => p.symbol == symbol);
    if (hasPosition) {
      _activeStrategyPhases[symbol] = 'protection';
      return;
    }

    if (_evaluatePhase(strategy.entryPhase, _datas)) {
      logger.i('Entry conditions met for $symbol using ${strategy.name}');
      // For MVP, always Long. In a real app, Strategy should define side.
      await placeMarketOrder('BUY');
      _activeStrategyPhases[symbol] = 'protection';
      notifyListeners();
    }
  }

  Future<void> _processProtectionPhase(String symbol, Strategy strategy) async {
    final positions = _positions.where((p) => p.symbol == symbol).toList();
    if (positions.isEmpty) return;

    final position = positions.first;
    final entryPrice = position.entryPrice;
    if (entryPrice <= 0) return;

    final isLong = position.positionAmt > 0;
    final tpPercent = strategy.protectionPhase.takeProfitPercentage / 100;
    final slPercent = strategy.protectionPhase.stopLossPercentage / 100;

    final tpPrice = isLong ? entryPrice * (1 + tpPercent) : entryPrice * (1 - tpPercent);
    final slPrice = isLong ? entryPrice * (1 - slPercent) : entryPrice * (1 + slPercent);

    try {
      logger.i('Setting protection for $symbol: TP at $tpPrice, SL at $slPrice');
      
      // Place Take Profit Market order
      await _binanceService.placeOrder(
        symbol: symbol,
        side: isLong ? 'SELL' : 'BUY',
        type: 'TAKE_PROFIT_MARKET',
        stopPrice: double.parse(tpPrice.toStringAsFixed(2)),
        closePosition: true,
        workingType: 'MARK_PRICE',
        positionSide: position.positionSide,
      );

      // Place Stop Loss Market order
      await _binanceService.placeOrder(
        symbol: symbol,
        side: isLong ? 'SELL' : 'BUY',
        type: 'STOP_MARKET',
        stopPrice: double.parse(slPrice.toStringAsFixed(2)),
        closePosition: true,
        workingType: 'MARK_PRICE',
        positionSide: position.positionSide,
      );

      _activeStrategyPhases[symbol] = 'exit';
      notificationViewModel.success('Protection orders placed for $symbol');
      notifyListeners();
    } catch (e) {
      logger.e('Error placing protection orders: $e');
      // If protection fails, we still move to exit phase to monitor conditions
      _activeStrategyPhases[symbol] = 'exit';
    }
  }

  Future<void> _processExitPhase(String symbol, Strategy strategy) async {
    final positions = _positions.where((p) => p.symbol == symbol).toList();
    if (positions.isEmpty) {
      // Position closed (likely by TP/SL or manually)
      _activeStrategyIds.remove(symbol);
      _activeStrategyPhases.remove(symbol);
      notifyListeners();
      return;
    }

    if (_evaluatePhase(strategy.exitPhase, _datas)) {
      logger.i('Exit conditions met for $symbol using ${strategy.name}');
      await closePosition(positions.first);
      _activeStrategyIds.remove(symbol);
      _activeStrategyPhases.remove(symbol);
      notifyListeners();
    }
  }

  bool _evaluatePhase(StrategyPhase phase, List<KLineEntity> data) {
    if (phase.conditions.isEmpty) return false;
    
    // Always AND for now
    for (var condition in phase.conditions) {
      if (!_evaluateCondition(condition, data)) return false;
    }
    return true;
  }

  bool _evaluateCondition(Condition condition, List<KLineEntity> data) {
    if (data.isEmpty) return false;

    double actualValue;
    if (condition.type == ConditionType.price) {
      actualValue = data.last.close;
    } else {
      // Extract indicator value
      actualValue = _getIndicatorValue(condition.indicatorName!, data.last);
    }

    switch (condition.op) {
      case Operator.greaterThan:
        return actualValue > condition.value;
      case Operator.lessThan:
        return actualValue < condition.value;
      case Operator.equal:
        return actualValue == condition.value;
      case Operator.crossesAbove:
        if (data.length < 2) return false;
        final prevValue = condition.type == ConditionType.price 
            ? data[data.length - 2].close 
            : _getIndicatorValue(condition.indicatorName!, data[data.length - 2]);
        return prevValue <= condition.value && actualValue > condition.value;
      case Operator.crossesBelow:
        if (data.length < 2) return false;
        final prevValue = condition.type == ConditionType.price 
            ? data[data.length - 2].close 
            : _getIndicatorValue(condition.indicatorName!, data[data.length - 2]);
        return prevValue >= condition.value && actualValue < condition.value;
    }
  }

  double _getIndicatorValue(String name, KLineEntity entity) {
    switch (name) {
      case 'RSI':
        return entity.rsi ?? 50.0;
      case 'EMA7':
        return entity.maValueList?[0] ?? entity.close; // maValueList typically contains EMAs/MAs depending on setup
      case 'EMA25':
        return entity.maValueList?[1] ?? entity.close;
      case 'EMA99':
        return entity.maValueList?[2] ?? entity.close;
      default:
        return entity.close;
    }
  }

  Future<void> changeInterval(String interval) async {
    if (_currentInterval == interval) return;
    _currentInterval = interval;
    await _init();
  }

  Future<void> changeSymbol(String symbol) async {
    if (_currentSymbol == symbol) return;
    _currentSymbol = symbol;
    await _init();
  }

  Future<void> placeMarketOrder(String side) async {
    if (_datas.isEmpty) return;

    final currentPrice = _datas.last.close;
    final marginToUse = _availableBalance * 0.4;
    final quantity = marginToUse / currentPrice;

    // Simple rounding for quantity (e.g., BTCUSDT usually supports 3 decimals)
    // In a real app, we should fetch exchangeInfo for precision
    final formattedQuantity = double.parse(quantity.toStringAsFixed(3));

    if (formattedQuantity <= 0) {
      logger.w('Calculated quantity is too small: $formattedQuantity');
      notificationViewModel.error('Available margin too low for order');
      return;
    }

    try {
      final bool isHedgeMode = _accountConfig?.dualSidePosition ?? false;
      String? positionSide;
      if (isHedgeMode) {
        positionSide = side == 'BUY' ? 'LONG' : 'SHORT';
      } else {
        positionSide = 'BOTH';
      }

      final response = await _binanceService.placeOrder(
        symbol: _currentSymbol,
        side: side,
        type: 'MARKET',
        quantity: formattedQuantity,
        positionSide: positionSide,
      );
      logger.i('Order placed successfully: ${response.orderId}');
      notificationViewModel.success(
        '${side == 'BUY' ? 'Long' : 'Short'} order filled: $formattedQuantity $_currentSymbol',
      );
      await _fetchAccountInfo(); // Refresh positions and balance
      notifyListeners();
    } catch (e) {
      logger.e('Error placing order: $e');
      notificationViewModel.error('Failed to place order: $e');
    }
  }

  Future<void> refresh() async {
    await _init();
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    settingsViewModel.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
