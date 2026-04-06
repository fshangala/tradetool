import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class SettingsViewModel extends ChangeNotifier {
  String _liveApiKey = '';
  String _liveSecretKey = '';
  String _testnetApiKey = '';
  String _testnetSecretKey = '';
  bool _isTestnet = true;

  String get liveApiKey => _liveApiKey;
  String get liveSecretKey => _liveSecretKey;
  String get testnetApiKey => _testnetApiKey;
  String get testnetSecretKey => _testnetSecretKey;
  bool get isTestnet => _isTestnet;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _liveApiKey = prefs.getString(AppConstants.keyLiveApiKey) ?? '';
    _liveSecretKey = prefs.getString(AppConstants.keyLiveSecretKey) ?? '';
    _testnetApiKey = prefs.getString(AppConstants.keyTestnetApiKey) ?? '';
    _testnetSecretKey = prefs.getString(AppConstants.keyTestnetSecretKey) ?? '';
    _isTestnet = prefs.getBool(AppConstants.keyIsTestnet) ?? true;
    notifyListeners();
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
