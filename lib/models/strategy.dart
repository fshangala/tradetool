import 'package:uuid/uuid.dart';
enum ConditionType { price, indicator }

enum Operator { greaterThan, lessThan, equal, crossesAbove, crossesBelow }

class Condition {
  final ConditionType type;
  final String? indicatorName; // RSI, EMA7, EMA25, EMA99, etc.
  final List<dynamic>? params;
  final Operator op;
  final double value;
  final ConditionType targetType;
  final String? targetIndicatorName;
  final bool useLastClosedData;

  Condition({
    required this.type,
    this.indicatorName,
    this.params,
    required this.op,
    required this.value,
    this.targetType = ConditionType.price,
    this.targetIndicatorName,
    this.useLastClosedData = false,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      type: ConditionType.values.firstWhere((e) => e.name == json['type']),
      indicatorName: json['indicatorName'],
      params: json['params'],
      op: Operator.values.firstWhere((e) => e.name == json['op']),
      value: (json['value'] as num).toDouble(),
      targetType: json['targetType'] != null
          ? ConditionType.values.firstWhere((e) => e.name == json['targetType'])
          : ConditionType.price,
      targetIndicatorName: json['targetIndicatorName'],
      useLastClosedData: json['useLastClosedData'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'indicatorName': indicatorName,
      'params': params,
      'op': op.name,
      'value': value,
      'targetType': targetType.name,
      'targetIndicatorName': targetIndicatorName,
      'useLastClosedData': useLastClosedData,
    };
  }
}

class ConditionGroup {
  final String id;
  final List<Condition> conditions;
  final String operator; // 'AND' or 'OR'

  ConditionGroup({
    required this.id,
    required this.conditions,
    this.operator = 'AND',
  });

  factory ConditionGroup.fromJson(Map<String, dynamic> json) {
    return ConditionGroup(
      id: json['id'] ?? const Uuid().v4(),
      conditions: (json['conditions'] as List)
          .map((c) => Condition.fromJson(c))
          .toList(),
      operator: json['operator'] ?? 'AND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'operator': operator,
    };
  }

  ConditionGroup copyWith({
    String? id,
    List<Condition>? conditions,
    String? operator,
  }) {
    return ConditionGroup(
      id: id ?? this.id,
      conditions: conditions ?? this.conditions,
      operator: operator ?? this.operator,
    );
  }
}

class StrategyPhase {
  final List<ConditionGroup> groups;
  final String operator; // Outer operator: 'AND' or 'OR'

  StrategyPhase({required this.groups, this.operator = 'AND'});

  factory StrategyPhase.fromJson(Map<String, dynamic> json) {
    // Migration logic for legacy single condition list
    if (json.containsKey('conditions')) {
      final conditions = (json['conditions'] as List)
          .map((c) => Condition.fromJson(c))
          .toList();
      return StrategyPhase(
        groups: [
          ConditionGroup(
            id: const Uuid().v4(),
            conditions: conditions,
            operator: json['logicOperator'] ?? 'AND',
          ),
        ],
        operator: 'AND',
      );
    }

    return StrategyPhase(
      groups: (json['groups'] as List)
          .map((g) => ConditionGroup.fromJson(g))
          .toList(),
      operator: json['operator'] ?? 'AND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groups': groups.map((g) => g.toJson()).toList(),
      'operator': operator,
    };
  }
}

class EntrySettings {
  final List<ConditionGroup> groups;
  final bool useProtection;
  final double takeProfit;
  final double stopLoss;
  final String operator; // Outer operator: 'AND' or 'OR'

  EntrySettings({
    required this.groups,
    this.useProtection = false,
    this.takeProfit = 1.0,
    this.stopLoss = 1.0,
    this.operator = 'AND',
  });

  factory EntrySettings.fromJson(Map<String, dynamic> json) {
    // Migration logic for legacy single condition list
    if (json.containsKey('conditions')) {
      final conditions = (json['conditions'] as List)
          .map((c) => Condition.fromJson(c))
          .toList();
      return EntrySettings(
        groups: [
          ConditionGroup(
            id: const Uuid().v4(),
            conditions: conditions,
            operator: 'AND',
          ),
        ],
        useProtection: json['useProtection'] ?? false,
        takeProfit: (json['takeProfit'] as num?)?.toDouble() ?? 1.0,
        stopLoss: (json['stopLoss'] as num?)?.toDouble() ?? 1.0,
        operator: 'AND',
      );
    }

    return EntrySettings(
      groups: (json['groups'] as List)
          .map((g) => ConditionGroup.fromJson(g))
          .toList(),
      useProtection: json['useProtection'] ?? false,
      takeProfit: (json['takeProfit'] as num?)?.toDouble() ?? 1.0,
      stopLoss: (json['stopLoss'] as num?)?.toDouble() ?? 1.0,
      operator: json['operator'] ?? 'AND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groups': groups.map((g) => g.toJson()).toList(),
      'useProtection': useProtection,
      'takeProfit': takeProfit,
      'stopLoss': stopLoss,
      'operator': operator,
    };
  }
}

class SimulatedCandle {
  final double open;
  final double high;
  final double low;
  final double close;
  final double vol;
  final double? rsi;
  final double? ema7;
  final double? ema25;
  final double? ema99;
  final double? bollUp;
  final double? bollMid;
  final double? bollDn;
  final double? macd;
  final double? dif;
  final double? dea;
  final int time;

  SimulatedCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.vol,
    this.rsi,
    this.ema7,
    this.ema25,
    this.ema99,
    this.bollUp,
    this.bollMid,
    this.bollDn,
    this.macd,
    this.dif,
    this.dea,
    required this.time,
  });

  factory SimulatedCandle.fromJson(Map<String, dynamic> json) {
    return SimulatedCandle(
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      vol: (json['vol'] as num).toDouble(),
      rsi: (json['rsi'] as num?)?.toDouble(),
      ema7: (json['ema7'] as num?)?.toDouble(),
      ema25: (json['ema25'] as num?)?.toDouble(),
      ema99: (json['ema99'] as num?)?.toDouble(),
      bollUp: (json['bollUp'] as num?)?.toDouble(),
      bollMid: (json['bollMid'] as num?)?.toDouble(),
      bollDn: (json['bollDn'] as num?)?.toDouble(),
      macd: (json['macd'] as num?)?.toDouble(),
      dif: (json['dif'] as num?)?.toDouble(),
      dea: (json['dea'] as num?)?.toDouble(),
      time: json['time'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'vol': vol,
      'rsi': rsi,
      'ema7': ema7,
      'ema25': ema25,
      'ema99': ema99,
      'bollUp': bollUp,
      'bollMid': bollMid,
      'bollDn': bollDn,
      'macd': macd,
      'dif': dif,
      'dea': dea,
      'time': time,
    };
  }
}

class SimulatedTrade {
  final String side;
  final double entryPrice;
  final double exitPrice;
  final double netPnl;
  final SimulatedCandle entryCandle;
  final SimulatedCandle exitCandle;

  SimulatedTrade({
    required this.side,
    required this.entryPrice,
    required this.exitPrice,
    required this.netPnl,
    required this.entryCandle,
    required this.exitCandle,
  });

  factory SimulatedTrade.fromJson(Map<String, dynamic> json) {
    return SimulatedTrade(
      side: json['side'],
      entryPrice: (json['entryPrice'] as num).toDouble(),
      exitPrice: (json['exitPrice'] as num).toDouble(),
      netPnl: (json['netPnl'] as num).toDouble(),
      entryCandle: SimulatedCandle.fromJson(json['entryCandle']),
      exitCandle: SimulatedCandle.fromJson(json['exitCandle']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'side': side,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'netPnl': netPnl,
      'entryCandle': entryCandle.toJson(),
      'exitCandle': exitCandle.toJson(),
    };
  }
}

class EvaluationResult {
  final String symbol;
  final String interval;
  final double initialCapital;
  final int leverage;
  final int totalTrades;
  final int profitableTrades;
  final int lossTrades;
  final double grossProfit;
  final double grossLoss;
  final double totalFees;
  final double netEarnings;
  final int rating; // 0-5 stars
  final List<SimulatedTrade> trades;

  EvaluationResult({
    required this.symbol,
    required this.interval,
    required this.initialCapital,
    required this.leverage,
    required this.totalTrades,
    required this.profitableTrades,
    required this.lossTrades,
    required this.grossProfit,
    required this.grossLoss,
    required this.totalFees,
    required this.netEarnings,
    required this.rating,
    this.trades = const [],
  });

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      symbol: json['symbol'],
      interval: json['interval'],
      initialCapital: (json['initialCapital'] as num).toDouble(),
      leverage: json['leverage'],
      totalTrades: json['totalTrades'],
      profitableTrades: json['profitableTrades'],
      lossTrades: json['lossTrades'],
      grossProfit: (json['grossProfit'] as num).toDouble(),
      grossLoss: (json['grossLoss'] as num).toDouble(),
      totalFees: (json['totalFees'] as num).toDouble(),
      netEarnings: (json['netEarnings'] as num).toDouble(),
      rating: json['rating'],
      trades: (json['trades'] as List?)
              ?.map((t) => SimulatedTrade.fromJson(t))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'interval': interval,
      'initialCapital': initialCapital,
      'leverage': leverage,
      'totalTrades': totalTrades,
      'profitableTrades': profitableTrades,
      'lossTrades': lossTrades,
      'grossProfit': grossProfit,
      'grossLoss': grossLoss,
      'totalFees': totalFees,
      'netEarnings': netEarnings,
      'rating': rating,
      'trades': trades.map((t) => t.toJson()).toList(),
    };
  }
}

class Strategy {
  final String id;
  final String name;
  final double walletPercentage;
  final EntrySettings longEntry;
  final EntrySettings shortEntry;
  final StrategyPhase longExit;
  final StrategyPhase shortExit;
  final EvaluationResult? lastResult;

  Strategy({
    required this.id,
    required this.name,
    this.walletPercentage = 40.0,
    required this.longEntry,
    required this.shortEntry,
    required this.longExit,
    required this.shortExit,
    this.lastResult,
  });

  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      id: json['id'],
      name: json['name'],
      walletPercentage: (json['walletPercentage'] as num?)?.toDouble() ?? 40.0,
      longEntry: EntrySettings.fromJson(json['longEntry']),
      shortEntry: EntrySettings.fromJson(json['shortEntry']),
      longExit: StrategyPhase.fromJson(json['longExit']),
      shortExit: StrategyPhase.fromJson(json['shortExit']),
      lastResult: json['lastResult'] != null
          ? EvaluationResult.fromJson(json['lastResult'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'walletPercentage': walletPercentage,
      'longEntry': longEntry.toJson(),
      'shortEntry': shortEntry.toJson(),
      'longExit': longExit.toJson(),
      'shortExit': shortExit.toJson(),
      'lastResult': lastResult?.toJson(),
    };
  }

  Strategy copyWith({
    String? name,
    double? walletPercentage,
    EntrySettings? longEntry,
    EntrySettings? shortEntry,
    StrategyPhase? longExit,
    StrategyPhase? shortExit,
    EvaluationResult? lastResult,
  }) {
    return Strategy(
      id: id,
      name: name ?? this.name,
      walletPercentage: walletPercentage ?? this.walletPercentage,
      longEntry: longEntry ?? this.longEntry,
      shortEntry: shortEntry ?? this.shortEntry,
      longExit: longExit ?? this.longExit,
      shortExit: shortExit ?? this.shortExit,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}
