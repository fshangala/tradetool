import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/strategy.dart';

class StrategyViewModel extends ChangeNotifier {
  List<Strategy> _strategies = [];
  bool _isLoading = false;

  List<Strategy> get strategies => _strategies;
  bool get isLoading => _isLoading;

  StrategyViewModel() {
    _loadStrategies();
  }

  Future<void> refresh() async {
    await _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? strategiesJson = prefs.getStringList(
        'trading_strategies',
      );

      if (strategiesJson != null) {
        _strategies = strategiesJson
            .map((s) => Strategy.fromJson(jsonDecode(s)))
            .toList();
      } else {
        // Add a default sample strategy if none exist
        _strategies = [_createDefaultStrategy()];
        await _saveStrategies();
      }
    } catch (e) {
      debugPrint('Error loading strategies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Strategy _createDefaultStrategy() {
    return Strategy(
      id: const Uuid().v4(),
      name: 'RSI Reversion',
      walletPercentage: 40.0,
      longEntry: EntrySettings(
        conditions: [
          Condition(
            type: ConditionType.indicator,
            indicatorName: 'RSI',
            op: Operator.lessThan,
            value: 30,
            useLastClosedData: true,
          ),
        ],
        useProtection: true,
        takeProfit: 2.0,
        stopLoss: 1.0,
      ),
      shortEntry: EntrySettings(
        conditions: [
          Condition(
            type: ConditionType.indicator,
            indicatorName: 'RSI',
            op: Operator.greaterThan,
            value: 70,
            useLastClosedData: true,
          ),
        ],
        useProtection: true,
        takeProfit: 2.0,
        stopLoss: 1.0,
      ),
      longExit: StrategyPhase(
        conditions: [
          Condition(
            type: ConditionType.indicator,
            indicatorName: 'RSI',
            op: Operator.greaterThan,
            value: 50,
            useLastClosedData: true,
          ),
        ],
      ),
      shortExit: StrategyPhase(
        conditions: [
          Condition(
            type: ConditionType.indicator,
            indicatorName: 'RSI',
            op: Operator.lessThan,
            value: 50,
            useLastClosedData: true,
          ),
        ],
      ),
    );
  }

  Future<void> _saveStrategies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> strategiesJson = _strategies
          .map((s) => jsonEncode(s.toJson()))
          .toList();
      await prefs.setStringList('trading_strategies', strategiesJson);
    } catch (e) {
      debugPrint('Error saving strategies: $e');
    }
  }

  Future<void> addStrategy(Strategy strategy) async {
    _strategies.add(strategy);
    await _saveStrategies();
    notifyListeners();
  }

  Future<void> updateStrategy(Strategy strategy) async {
    final index = _strategies.indexWhere((s) => s.id == strategy.id);
    if (index != -1) {
      _strategies[index] = strategy;
      await _saveStrategies();
      notifyListeners();
    }
  }

  Future<void> deleteStrategy(String id) async {
    _strategies.removeWhere((s) => s.id == id);
    await _saveStrategies();
    notifyListeners();
  }

  Strategy? getStrategyById(String id) {
    try {
      return _strategies.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
