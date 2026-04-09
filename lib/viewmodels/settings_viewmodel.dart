import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../services/binance_service.dart';
import '../models/symbol_model.dart';
import 'notification_viewmodel.dart';

class SettingsViewModel extends ChangeNotifier {
  final NotificationViewModel notificationViewModel;
  String _liveApiKey = '';
  String _liveSecretKey = '';
  String _testnetApiKey = '';
  String _testnetSecretKey = '';
  bool _isTestnet = true;
  List<String> _selectedSymbols = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT'];
  List<SymbolModel> _allSymbols = [];
  Map<String, SymbolModel> _symbolInfoMap = {};
  bool _isSymbolsLoading = false;

  String get liveApiKey => _liveApiKey;
  String get liveSecretKey => _liveSecretKey;
  String get testnetApiKey => _testnetApiKey;
  String get testnetSecretKey => _testnetSecretKey;
  bool get isTestnet => _isTestnet;
  List<String> get selectedSymbols => _selectedSymbols;
  List<SymbolModel> get allSymbols => _allSymbols;
  bool get isSymbolsLoading => _isSymbolsLoading;

  SettingsViewModel({required this.notificationViewModel}) {
    _loadSettings();
  }

  SymbolModel? getSymbolInfo(String symbol) => _symbolInfoMap[symbol];

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _liveApiKey = prefs.getString(AppConstants.keyLiveApiKey) ?? '';
    _liveSecretKey = prefs.getString(AppConstants.keyLiveSecretKey) ?? '';
    _testnetApiKey = prefs.getString(AppConstants.keyTestnetApiKey) ?? '';
    _testnetSecretKey = prefs.getString(AppConstants.keyTestnetSecretKey) ?? '';
    _isTestnet = prefs.getBool(AppConstants.keyIsTestnet) ?? true;
    _selectedSymbols = prefs.getStringList('custom_symbols') ?? ['BTCUSDT', 'ETHUSDT', 'BNBUSDT'];
    
    // Initial fetch to populate map for default symbols
    await fetchAllAvailableSymbols();
    
    notifyListeners();
  }

  Future<void> fetchAllAvailableSymbols() async {
    _isSymbolsLoading = true;
    notifyListeners();
    try {
      final service = BinanceService(isTestnet: _isTestnet);
      _allSymbols = await service.fetchExchangeInfo();
      _symbolInfoMap = {for (var s in _allSymbols) s.symbol: s};
    } catch (e) {
      debugPrint('Error fetching symbols: $e');
      notificationViewModel.error('Failed to fetch symbols: $e');
    } finally {
      _isSymbolsLoading = false;
      notifyListeners();
    }
  }

  void addSymbol(String symbol) {
    if (!_selectedSymbols.contains(symbol)) {
      _selectedSymbols.add(symbol);
      _saveSymbols();
      notifyListeners();
    }
  }

  void removeSymbol(String symbol) {
    if (_selectedSymbols.contains(symbol)) {
      _selectedSymbols.remove(symbol);
      _saveSymbols();
      notifyListeners();
    }
  }

  Future<void> _saveSymbols() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_symbols', _selectedSymbols);
  }

  void setLiveApiKey(String value) {
    _liveApiKey = value;
    notifyListeners();
  }

  void setLiveSecretKey(String value) {
    _liveSecretKey = value;
    notifyListeners();
  }

  void setTestnetApiKey(String value) {
    _testnetApiKey = value;
    notifyListeners();
  }

  void setTestnetSecretKey(String value) {
    _testnetSecretKey = value;
    notifyListeners();
  }

  void setNetworkMode(bool isTestnet) {
    _isTestnet = isTestnet;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLiveApiKey, _liveApiKey);
    await prefs.setString(AppConstants.keyLiveSecretKey, _liveSecretKey);
    await prefs.setString(AppConstants.keyTestnetApiKey, _testnetApiKey);
    await prefs.setString(AppConstants.keyTestnetSecretKey, _testnetSecretKey);
    await prefs.setBool(AppConstants.keyIsTestnet, _isTestnet);
    notifyListeners();
  }
}
