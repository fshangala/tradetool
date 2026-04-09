import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:collection/collection.dart';
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
  final Map<String, String> _activeStrategyPhases =
      {}; // symbol -> phase (entry, exit)
  final Map<String, String?> _failedActions =
      {}; // symbol -> failedActionName ('entry', 'protection', 'exit')
  final Map<String, bool> _workingSymbols = {}; // symbol -> working

  String? getActiveStrategyId(String symbol) => _activeStrategyIds[symbol];
  String getActiveStrategyPhase(String symbol) =>
      _activeStrategyPhases[symbol] ?? 'none';
  String? getFailedAction(String symbol) => _failedActions[symbol];
  bool isWorking(String symbol) => _workingSymbols[symbol] ?? false;

  void setStrategyForSymbol(String symbol, String? strategyId) {
    _activeStrategyIds[symbol] = strategyId;
    if (strategyId != null) {
      final hasPosition = _positions.any((p) => p.symbol == symbol);
      _activeStrategyPhases[symbol] = hasPosition ? 'exit' : 'entry';
    } else {
      _activeStrategyPhases.remove(symbol);
      _workingSymbols.remove(symbol);
    }
    _failedActions.remove(symbol);
    _updateWakelock();
    notifyListeners();
  }

  void _updateWakelock() {
    final bool anyActive = _activeStrategyIds.values.any((id) => id != null);
    WakelockPlus.toggle(enable: anyActive);
    if (anyActive) {
      logger.i('Wakelock enabled: automated strategy is running');
    } else {
      logger.i('Wakelock disabled: no automated strategies running');
    }
  }

  bool isSymbolLocked(String symbol) {
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
    if (!settingsViewModel.selectedSymbols.contains(_currentSymbol)) {
      if (settingsViewModel.selectedSymbols.isNotEmpty) {
        _currentSymbol = settingsViewModel.selectedSymbols.first;
      }
    }
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    _datas = [];
    notifyListeners();

    await Future.wait([
      _fetchHistory(),
      _fetchAccountInfo(),
      _fetchPositions(),
    ]);
    _connectWebsocket();
    _updateWakelock();

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
    final symbolPositions = _positions
        .where((p) => p.symbol == _currentSymbol)
        .toList();
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
    }

    // Re-calculate indicators since _mainIndicators has changed
    if (_datas.isNotEmpty) {
      DataUtil.calculateIndicators(
        _datas,
        _mainIndicators,
        _secondaryIndicators,
      );
    }
    notifyListeners();
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

      await Future.wait([_fetchPositions(), _fetchAccountInfo()]);
    } catch (e) {
      logger.e('Error closing position: $e');
      notificationViewModel.error('Failed to close position: $e');
      _isPositionsLoading = false;
      notifyListeners();
      rethrow;
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

  bool _candleClosed = false;

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
        _candleClosed = k['x']; // true if the candle is closed otherwise false

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

        _runStrategyEvaluation(_currentSymbol);
        logger.d(
          'WebSocket update for $_currentSymbol: price=${newEntity.close}',
        );

        notifyListeners();
      }
    });
  }

  void _runStrategyEvaluation(String symbol) {
    if (_failedActions[symbol] != null || isWorking(symbol)) return;

    final strategyId = _activeStrategyIds[symbol];
    if (strategyId == null) return;

    final strategy = strategyViewModel.getStrategyById(strategyId);
    if (strategy == null) {
      logger.w('Strategy $strategyId not found for $symbol');
      return;
    }

    final phase = _activeStrategyPhases[symbol] ?? 'entry';
    logger.d(
      'Evaluating strategy ${strategy.name} for $symbol (Phase: $phase)',
    );

    if (phase == 'entry') {
      _processEntryPhase(symbol, strategy);
    } else if (phase == 'exit') {
      _processExitPhase(symbol, strategy);
    }
  }

  Future<void> _processEntryPhase(String symbol, Strategy strategy) async {
    final hasPosition = _positions.any((p) => p.symbol == symbol);
    if (hasPosition) {
      logger.d('Already have position for $symbol, moving to exit phase');
      _activeStrategyPhases[symbol] = 'exit';
      notifyListeners();
      return;
    }

    final longMet = _evaluatePhase(strategy.longEntry.conditions, _datas);
    final shortMet = _evaluatePhase(strategy.shortEntry.conditions, _datas);

    logger.d('Entry evaluation for $symbol: Long=$longMet, Short=$shortMet');

    if (longMet) {
      await _executeEntry(symbol, strategy, 'BUY', strategy.longEntry);
    } else if (shortMet) {
      await _executeEntry(symbol, strategy, 'SELL', strategy.shortEntry);
    }
  }

  Future<void> _executeEntry(
    String symbol,
    Strategy strategy,
    String side,
    EntrySettings entry,
  ) async {
    logger.i('$side entry conditions met for $symbol using ${strategy.name}');
    try {
      _workingSymbols[symbol] = true;
      notifyListeners();

      await placeMarketOrder(side, percent: strategy.walletPercentage / 100);
      _activeStrategyPhases[symbol] = 'exit';

      if (entry.useProtection) {
        await _placeProtectionOrdersForSymbol(
          symbol,
          entry.takeProfit,
          entry.stopLoss,
        );
      }
      notifyListeners();
    } catch (e) {
      logger.e('Entry execution failed: $e');
      _failedActions[symbol] = 'entry';
      notifyListeners();
    } finally {
      _workingSymbols[symbol] = false;
      notifyListeners();
    }
  }

  Future<void> _placeProtectionOrdersForSymbol(
    String symbol,
    double tpPercent,
    double slPercent,
  ) async {
    PositionRisk? position;

    try {
      _workingSymbols[symbol] = true;
      notifyListeners();

      // Retry finding position up to 3 times with 1s delay
      for (int i = 0; i < 3; i++) {
        await _fetchPositions();
        position = _positions.firstWhereOrNull((p) => p.symbol == symbol);
        if (position != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }

      if (position == null) {
        logger.e('Could not find position for $symbol to set protection');
        _failedActions[symbol] = 'protection';
        notifyListeners();
        return;
      }

      final entryPrice = position.entryPrice;
      if (entryPrice <= 0) return;

      final isLong = position.positionAmt > 0;
      final tpPrice = isLong
          ? entryPrice * (1 + tpPercent / 100)
          : entryPrice * (1 - tpPercent / 100);
      final slPrice = isLong
          ? entryPrice * (1 - slPercent / 100)
          : entryPrice * (1 + slPercent / 100);

      logger.i(
        'Setting protection for $symbol: TP at $tpPrice, SL at $slPrice',
      );

      final symbolInfo = settingsViewModel.getSymbolInfo(symbol);

      await _binanceService.placeAlgoOrder(
        symbol: symbol,
        side: isLong ? 'SELL' : 'BUY',
        type: 'TAKE_PROFIT_MARKET',
        triggerPrice: double.parse(
          tpPrice.toStringAsFixed(symbolInfo?.pricePrecision ?? 2),
        ),
        closePosition: true,
        workingType: 'MARK_PRICE',
        positionSide: position.positionSide,
      );

      await _binanceService.placeAlgoOrder(
        symbol: symbol,
        side: isLong ? 'SELL' : 'BUY',
        type: 'STOP_MARKET',
        triggerPrice: double.parse(
          slPrice.toStringAsFixed(symbolInfo?.pricePrecision ?? 2),
        ),
        closePosition: true,
        workingType: 'MARK_PRICE',
        positionSide: position.positionSide,
      );

      notificationViewModel.success('Protection orders placed for $symbol');
    } catch (e) {
      logger.e('Error placing protection orders: $e');
      notificationViewModel.error('Failed to place protection orders: $e');
      _failedActions[symbol] = 'protection';
      notifyListeners();
    } finally {
      _workingSymbols[symbol] = false;
      notifyListeners();
    }
  }

  Future<void> _processExitPhase(String symbol, Strategy strategy) async {
    final position = _positions.firstWhereOrNull((p) => p.symbol == symbol);
    if (position == null) {
      // Position was closed elsewhere (e.g. manually)
      _activeStrategyPhases[symbol] = 'entry';
      _failedActions.remove(symbol);
      notifyListeners();
      return;
    }

    final isLong = position.positionAmt > 0;
    final exitConditions = isLong
        ? strategy.longExit.conditions
        : strategy.shortExit.conditions;

    if (_evaluatePhase(exitConditions, _datas)) {
      logger.i(
        '${isLong ? "Long" : "Short"} exit conditions met for $symbol using ${strategy.name}',
      );
      try {
        _workingSymbols[symbol] = true;
        notifyListeners();

        await closePosition(position);
        _activeStrategyPhases[symbol] = 'entry';
        _failedActions.remove(symbol);
        notifyListeners();
      } catch (e) {
        logger.e('Exit execution failed: $e');
        _failedActions[symbol] = 'exit';
        notifyListeners();
      } finally {
        _workingSymbols[symbol] = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryAction(String symbol) async {
    final failedAction = _failedActions[symbol];
    if (failedAction == null || isWorking(symbol)) return;

    final strategyId = _activeStrategyIds[symbol];
    if (strategyId == null) return;

    final strategy = strategyViewModel.getStrategyById(strategyId);
    if (strategy == null) return;

    _failedActions.remove(symbol);
    notifyListeners();

    try {
      _workingSymbols[symbol] = true;
      notifyListeners();

      if (failedAction == 'entry') {
        _runStrategyEvaluation(symbol);
      } else if (failedAction == 'protection') {
        final position = _positions.firstWhereOrNull((p) => p.symbol == symbol);
        if (position != null) {
          final isLong = position.positionAmt > 0;
          final entry = isLong ? strategy.longEntry : strategy.shortEntry;
          await _placeProtectionOrdersForSymbol(
            symbol,
            entry.takeProfit,
            entry.stopLoss,
          );
        } else {
          await _placeProtectionOrdersForSymbol(
            symbol,
            strategy.longEntry.takeProfit,
            strategy.longEntry.stopLoss,
          );
        }
      } else if (failedAction == 'exit') {
        final position = _positions.firstWhereOrNull((p) => p.symbol == symbol);
        if (position != null) {
          await closePosition(position);
          _activeStrategyIds.remove(symbol);
          _activeStrategyPhases.remove(symbol);
          _updateWakelock();
        }
      }
      notifyListeners();
    } catch (e) {
      // Failed action will be reset in the methods if it fails again
    } finally {
      _workingSymbols[symbol] = false;
      notifyListeners();
    }
  }

  bool _evaluatePhase(List<Condition> conditions, List<KLineEntity> data) {
    if (conditions.isEmpty) return false;
    for (var condition in conditions) {
      if (!_evaluateCondition(condition, data)) return false;
    }
    return true;
  }

  bool _evaluateCondition(Condition condition, List<KLineEntity> data) {
    if (data.isEmpty) return false;

    // Determine the data point to use for evaluation
    final KLineEntity activeData;
    if (condition.useLastClosedData) {
      if (_candleClosed) {
        activeData = data.last;
      } else {
        activeData = data.length >= 2 ? data[data.length - 2] : data.last;
      }
    } else {
      activeData = data.last;
    }

    double leftValue;
    if (condition.type == ConditionType.price) {
      leftValue = activeData.close;
    } else {
      leftValue = _getIndicatorValue(condition.indicatorName!, activeData);
    }

    double rightValue;
    if (condition.targetType == ConditionType.indicator) {
      rightValue = _getIndicatorValue(
        condition.targetIndicatorName!,
        activeData,
      );
    } else {
      rightValue = condition.value;
    }

    final met = _checkOperator(
      condition.op,
      leftValue,
      rightValue,
      condition,
      data,
    );

    logger.d(
      'Condition: ${condition.type.name} ${condition.indicatorName ?? ""} ${condition.op.name} ${condition.targetIndicatorName ?? condition.value} (LastClosed: ${condition.useLastClosedData}) | Left: $leftValue, Right: $rightValue | Result: $met',
    );

    return met;
  }

  bool _checkOperator(
    Operator op,
    double left,
    double right,
    Condition condition,
    List<KLineEntity> data,
  ) {
    switch (op) {
      case Operator.greaterThan:
        return left > right;
      case Operator.lessThan:
        return left < right;
      case Operator.equal:
        return left == right;
      case Operator.crossesAbove:
        if (data.length < 2) return false;
        final prevData = data[data.length - 2];
        final prevLeft = condition.type == ConditionType.price
            ? prevData.close
            : _getIndicatorValue(condition.indicatorName!, prevData);
        final prevRight = condition.targetIndicatorName != null
            ? _getIndicatorValue(condition.targetIndicatorName!, prevData)
            : condition.value;
        return prevLeft <= prevRight && left > right;
      case Operator.crossesBelow:
        if (data.length < 2) return false;
        final prevData = data[data.length - 2];
        final prevLeft = condition.type == ConditionType.price
            ? prevData.close
            : _getIndicatorValue(condition.indicatorName!, prevData);
        final prevRight = condition.targetIndicatorName != null
            ? _getIndicatorValue(condition.targetIndicatorName!, prevData)
            : condition.value;
        return prevLeft >= prevRight && left < right;
    }
  }

  double _getIndicatorValue(String name, KLineEntity entity) {
    switch (name) {
      case 'RSI':
        return entity.rsi ?? 50.0;
      case 'EMA7':
        final val =
            entity.emaValueList != null && entity.emaValueList!.isNotEmpty
            ? entity.emaValueList![0]
            : null;
        if (val == null || val == 0) return entity.close;
        return val;
      case 'EMA25':
        final val =
            entity.emaValueList != null && entity.emaValueList!.length > 1
            ? entity.emaValueList![1]
            : null;
        if (val == null || val == 0) return entity.close;
        return val;
      case 'EMA99':
        final val =
            entity.emaValueList != null && entity.emaValueList!.length > 2
            ? entity.emaValueList![2]
            : null;
        if (val == null || val == 0) return entity.close;
        return val;
      case 'UP':
        return entity.boll?.up ?? entity.close;
      case 'MB':
        return entity.boll?.mid ?? entity.close;
      case 'DN':
        return entity.boll?.dn ?? entity.close;
      case 'MACD':
        return entity.macd ?? 0.0;
      case 'DIF':
        return entity.dif ?? 0.0;
      case 'DEA':
        return entity.dea ?? 0.0;
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

  Future<void> placeMarketOrder(String side, {double percent = 0.4}) async {
    if (_datas.isEmpty) return;

    final currentPrice = _datas.last.close;
    final marginToUse = _availableBalance * percent;
    final quantity = marginToUse / currentPrice;

    final symbolInfo = settingsViewModel.getSymbolInfo(_currentSymbol);
    final formattedQuantity = double.parse(
      quantity.toStringAsFixed(symbolInfo?.quantityPrecision ?? 3),
    );

    if (formattedQuantity <= 0) {
      logger.w('Calculated quantity is too small: $formattedQuantity');
      notificationViewModel.error('Available margin too low for order');
      throw Exception('Insufficient margin');
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
      await _fetchAccountInfo();
      await _fetchPositions();
      notifyListeners();
    } catch (e) {
      logger.e('Error placing order: $e');
      notificationViewModel.error('Failed to place order: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _init();
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    settingsViewModel.removeListener(_onSettingsChanged);
    WakelockPlus.disable();
    super.dispose();
  }
}
