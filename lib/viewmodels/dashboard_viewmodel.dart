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
  late BinanceService _binanceService;
  WebSocketChannel? _wsChannel;

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
        notifyListeners();
      }
    });
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
