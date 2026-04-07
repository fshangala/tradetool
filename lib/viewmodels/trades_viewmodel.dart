import 'package:flutter/material.dart';
import '../services/binance_service.dart';
import '../models/trade.dart';
import 'settings_viewmodel.dart';
import 'notification_viewmodel.dart';
import '../core/logger.dart';

class TradesViewModel extends ChangeNotifier {
  final SettingsViewModel settingsViewModel;
  final NotificationViewModel notificationViewModel;
  late BinanceService _binanceService;

  List<Trade> _trades = [];
  List<Trade> get trades => _trades;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TradesViewModel({
    required this.settingsViewModel,
    required this.notificationViewModel,
  }) {
    _updateBinanceService();
    settingsViewModel.addListener(_onSettingsChanged);
    fetchTrades();
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
    fetchTrades();
  }

  Future<void> fetchTrades() async {
    final key = settingsViewModel.isTestnet
        ? settingsViewModel.testnetApiKey
        : settingsViewModel.liveApiKey;
    final secret = settingsViewModel.isTestnet
        ? settingsViewModel.testnetSecretKey
        : settingsViewModel.liveSecretKey;

    if (key.isEmpty || secret.isEmpty) {
      _trades = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _trades = await _binanceService.fetchUserTrades();
      // Sort trades by time descending (newest first)
      _trades.sort((a, b) => b.time.compareTo(a.time));
    } catch (e) {
      logger.e('Error fetching trades: $e');
      notificationViewModel.error('Failed to load trades: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    settingsViewModel.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
