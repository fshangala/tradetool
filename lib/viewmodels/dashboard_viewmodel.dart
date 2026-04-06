import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/binance_service.dart';
import 'settings_viewmodel.dart';
import 'notification_viewmodel.dart';
import '../core/logger.dart';

class DashboardViewModel extends ChangeNotifier {
  final SettingsViewModel settingsViewModel;
  final NotificationViewModel notificationViewModel;
  late BinanceService _binanceService;
  WebSocketChannel? _wsChannel;

  List<KLineEntity> _datas = [];
  List<KLineEntity> get datas => _datas;

  String _currentInterval = '1m';
  String get currentInterval => _currentInterval;

  final String _currentSymbol = 'BTCUSDT';
  String get currentSymbol => _currentSymbol;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  double _availableBalance = 0.0;
  double get availableBalance => _availableBalance;

  List<dynamic> _positions = [];
  List<dynamic> get positions => _positions;

  Map<String, dynamic>? _accountInfo;
  Map<String, dynamic>? get accountInfo => _accountInfo;

  final List<MainIndicator> _mainIndicators = [
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
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchHistory(),
      _fetchAccountInfo(),
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
      _availableBalance = 0.0;
      _positions = [];
      return;
    }

    try {
      final results = await Future.wait([
        _binanceService.fetchAccountInformation(),
        _binanceService.fetchAccountConfig(),
      ]);
      
      final accountInfoData = results[0];
      final accountConfigData = results[1];
      
      // Merge config into account info
      _accountInfo = {
        ...accountInfoData,
        ...accountConfigData,
      };
      
      _availableBalance = double.tryParse(accountInfoData['availableBalance']?.toString() ?? '0') ?? 0.0;
      _positions = (accountInfoData['positions'] as List<dynamic>)
          .where((p) {
            final amt = double.tryParse(p['positionAmt']?.toString() ?? '0') ?? 0.0;
            return amt != 0;
          })
          .toList();
    } catch (e) {
      logger.e('Error fetching account info: $e');
      notificationViewModel.error('Failed to load account info: $e');
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
      final bool isHedgeMode = _accountInfo?['dualSidePosition'] ?? false;
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
      logger.i('Order placed successfully: $response');
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
