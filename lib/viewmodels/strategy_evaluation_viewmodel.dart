import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import '../models/strategy.dart';
import '../services/binance_service.dart';
import '../core/logger.dart';

class StrategyEvaluationViewModel extends ChangeNotifier {
  final BinanceService binanceService;

  // Binance Futures Standard VIP 0 Fees
  static const double makerFeeRate = 0.0002; // 0.02%
  static const double takerFeeRate = 0.0005; // 0.05%

  StrategyEvaluationViewModel({required this.binanceService});

  bool _isEvaluating = false;
  bool get isEvaluating => _isEvaluating;

  double _progress = 0.0;
  double get progress => _progress;

  int _totalTrades = 0;
  int get totalTrades => _totalTrades;

  int _profitableTrades = 0;
  int get profitableTrades => _profitableTrades;

  int _lossTrades = 0;
  int get lossTrades => _lossTrades;

  double _initialCapital = 0.0;
  double _currentBalance = 0.0;
  double _totalGrossProfitUsdt = 0.0;
  double _totalGrossLossUsdt = 0.0;
  double _totalFeesUsdt = 0.0;
  int _leverage = 1;

  double get initialCapital => _initialCapital;
  double get currentBalance => _currentBalance;
  double get totalGrossProfitUsdt => _totalGrossProfitUsdt;
  double get totalGrossLossUsdt => _totalGrossLossUsdt;
  double get totalFeesUsdt => _totalFeesUsdt;
  double get grossPnl => _totalGrossProfitUsdt + _totalGrossLossUsdt;
  double get totalEarnings => grossPnl - _totalFeesUsdt;
  int get leverage => _leverage;

  String? _error;
  String? get error => _error;

  EvaluationResult? _lastResult;
  EvaluationResult? get lastResult => _lastResult;

  void reset() {
    _isEvaluating = false;
    _progress = 0.0;
    _totalTrades = 0;
    _profitableTrades = 0;
    _lossTrades = 0;
    _initialCapital = 0.0;
    _currentBalance = 0.0;
    _totalGrossProfitUsdt = 0.0;
    _totalGrossLossUsdt = 0.0;
    _totalFeesUsdt = 0.0;
    _leverage = 1;
    _error = null;
    notifyListeners();
  }

  Future<void> evaluate(
    Strategy strategy,
    String symbol,
    String interval,
    double initialCapital,
    int leverage,
  ) async {
    reset();
    _isEvaluating = true;
    _initialCapital = initialCapital;
    _currentBalance = initialCapital;
    _leverage = leverage;
    notifyListeners();

    try {
      final klines = await binanceService.fetchKlines(
        symbol: symbol,
        interval: interval,
        limit: 500,
      );

      if (klines.length < 100) {
        throw Exception(
          'Not enough data to evaluate strategy (need at least 100 candles)',
        );
      }

      // Calculate indicators for all klines
      final List<MainIndicator> mainIndicators = [
        EMAIndicator(calcParams: [7, 25, 99]),
        BOLLIndicator(),
      ];
      final List<SecondaryIndicator> secondaryIndicators = [
        MACDIndicator(),
        RSIIndicator(),
      ];
      DataUtil.calculateIndicators(klines, mainIndicators, secondaryIndicators);

      String currentPosition = 'NONE'; // NONE, LONG, SHORT
      double entryPrice = 0.0;

      // Start from the 100th candle
      for (int i = 100; i < klines.length; i++) {
        _progress = (i - 100) / (klines.length - 100);
        notifyListeners();

        // Small delay to allow UI to update (stream-like progress)
        await Future.delayed(const Duration(milliseconds: 2));

        final subList = klines.sublist(0, i + 1);
        final currentCandle = klines[i];

        if (currentPosition == 'NONE') {
          // Check for Entry
          final longMet = _evaluatePhase(
            strategy.longEntry.conditions,
            subList,
          );
          final shortMet = _evaluatePhase(
            strategy.shortEntry.conditions,
            subList,
          );

          if (longMet) {
            currentPosition = 'LONG';
            entryPrice = currentCandle.close;
          } else if (shortMet) {
            currentPosition = 'SHORT';
            entryPrice = currentCandle.close;
          }
        } else if (currentPosition == 'LONG') {
          // Check for Exit or Protection
          bool exitMet = _evaluatePhase(strategy.longExit.conditions, subList);

          // Simulate Protection
          if (strategy.longEntry.useProtection) {
            final tpPrice =
                entryPrice * (1 + strategy.longEntry.takeProfit / 100);
            final slPrice =
                entryPrice * (1 - strategy.longEntry.stopLoss / 100);

            if (currentCandle.high >= tpPrice) {
              _closeTrade(
                entryPrice,
                tpPrice,
                'LONG',
                strategy.walletPercentage,
              );
              currentPosition = 'NONE';
              continue;
            } else if (currentCandle.low <= slPrice) {
              _closeTrade(
                entryPrice,
                slPrice,
                'LONG',
                strategy.walletPercentage,
              );
              currentPosition = 'NONE';
              continue;
            }
          }

          if (exitMet) {
            _closeTrade(
              entryPrice,
              currentCandle.close,
              'LONG',
              strategy.walletPercentage,
            );
            currentPosition = 'NONE';
          }
        } else if (currentPosition == 'SHORT') {
          // Check for Exit or Protection
          bool exitMet = _evaluatePhase(strategy.shortExit.conditions, subList);

          // Simulate Protection
          if (strategy.shortEntry.useProtection) {
            final tpPrice =
                entryPrice * (1 - strategy.shortEntry.takeProfit / 100);
            final slPrice =
                entryPrice * (1 + strategy.shortEntry.stopLoss / 100);

            if (currentCandle.low <= tpPrice) {
              _closeTrade(
                entryPrice,
                tpPrice,
                'SHORT',
                strategy.walletPercentage,
              );
              currentPosition = 'NONE';
              continue;
            } else if (currentCandle.high >= slPrice) {
              _closeTrade(
                entryPrice,
                slPrice,
                'SHORT',
                strategy.walletPercentage,
              );
              currentPosition = 'NONE';
              continue;
            }
          }

          if (exitMet) {
            _closeTrade(
              entryPrice,
              currentCandle.close,
              'SHORT',
              strategy.walletPercentage,
            );
            currentPosition = 'NONE';
          }
        }
      }

      _progress = 1.0;
      _lastResult = EvaluationResult(
        symbol: symbol,
        interval: interval,
        initialCapital: _initialCapital,
        leverage: _leverage,
        totalTrades: _totalTrades,
        profitableTrades: _profitableTrades,
        lossTrades: _lossTrades,
        grossProfit: _totalGrossProfitUsdt,
        grossLoss: _totalGrossLossUsdt,
        totalFees: _totalFeesUsdt,
        netEarnings: totalEarnings,
        rating: _calculateRating(),
      );
    } catch (e) {
      logger.e('Evaluation error: $e');
      _error = e.toString();
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  int _calculateRating() {
    if (_totalTrades == 0) return 0;

    final profitFactor = _totalGrossLossUsdt.abs() > 0
        ? _totalGrossProfitUsdt / _totalGrossLossUsdt.abs()
        : (_totalGrossProfitUsdt > 0 ? 5.0 : 0.0);

    final earningsPercent = (totalEarnings / _initialCapital) * 100;

    if (earningsPercent > 10 && profitFactor > 2.0) return 5;
    if (earningsPercent > 5 && profitFactor > 1.5) return 4;
    if (earningsPercent > 0 && profitFactor > 1.1) return 3;
    if (earningsPercent > -5) return 2;
    return 1;
  }

  void _closeTrade(
    double entry,
    double exit,
    String side,
    double walletPercentage,
  ) {
    _totalTrades++;

    // Position Size Calculation (Notional Value)
    final double marginUsed = _currentBalance * (walletPercentage / 100);
    final double notionalValueEntry = marginUsed * _leverage;

    // Fees on Entry (Assume Taker)
    final double entryFee = notionalValueEntry * takerFeeRate;
    _totalFeesUsdt += entryFee;
    _currentBalance -= entryFee;

    // Fees on Exit (Assume Taker)
    final double priceChangeFactor = side == 'LONG'
        ? (exit / entry)
        : (entry / exit);
    final double notionalValueExit = notionalValueEntry * priceChangeFactor;
    final double exitFee = notionalValueExit * takerFeeRate;
    _totalFeesUsdt += exitFee;
    _currentBalance -= exitFee;

    // PnL Calculation (Gross)
    final double priceChangePercent = side == 'LONG'
        ? (exit - entry) / entry
        : (entry - exit) / entry;

    final double grossPnlUsdt = priceChangePercent * marginUsed * _leverage;

    _currentBalance += grossPnlUsdt;

    if (grossPnlUsdt > 0) {
      _totalGrossProfitUsdt += grossPnlUsdt;
    } else {
      _totalGrossLossUsdt += grossPnlUsdt;
    }

    final double netPnlOfTrade = grossPnlUsdt - entryFee - exitFee;
    if (netPnlOfTrade > 0) {
      _profitableTrades++;
    } else {
      _lossTrades++;
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

    // In simulation, we always assume the candle is "closed" relative to the current index
    final KLineEntity activeData;
    if (condition.useLastClosedData) {
      activeData = data.length >= 2 ? data[data.length - 2] : data.last;
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

    return _checkOperator(condition.op, leftValue, rightValue, condition, data);
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
}
