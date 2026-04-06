import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/binance_service.dart';
import 'settings_viewmodel.dart';
import '../core/logger.dart';

class DashboardViewModel extends ChangeNotifier {
  final SettingsViewModel settingsViewModel;
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

  DashboardViewModel({required this.settingsViewModel}) {
    _binanceService = BinanceService(isTestnet: settingsViewModel.isTestnet);
    _init();

    settingsViewModel.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    _binanceService = BinanceService(isTestnet: settingsViewModel.isTestnet);
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _fetchHistory();
    _connectWebsocket();

    _isLoading = false;
    notifyListeners();
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
