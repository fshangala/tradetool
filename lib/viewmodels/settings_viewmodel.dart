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

  Future<void> setLiveApiKey(String value) async {
    _liveApiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLiveApiKey, value);
    notifyListeners();
  }

  Future<void> setLiveSecretKey(String value) async {
    _liveSecretKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLiveSecretKey, value);
    notifyListeners();
  }

  Future<void> setTestnetApiKey(String value) async {
    _testnetApiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyTestnetApiKey, value);
    notifyListeners();
  }

  Future<void> setTestnetSecretKey(String value) async {
    _testnetSecretKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyTestnetSecretKey, value);
    notifyListeners();
  }

  Future<void> setNetworkMode(bool isTestnet) async {
    _isTestnet = isTestnet;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsTestnet, isTestnet);
    notifyListeners();
  }
}
