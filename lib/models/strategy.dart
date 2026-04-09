enum ConditionType { price, indicator }

enum Operator {
  greaterThan,
  lessThan,
  equal,
  crossesAbove,
  crossesBelow,
}

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

class StrategyPhase {
  final List<Condition> conditions;
  final String logicOperator;

  StrategyPhase({
    required this.conditions,
    this.logicOperator = 'AND',
  });

  factory StrategyPhase.fromJson(Map<String, dynamic> json) {
    return StrategyPhase(
      conditions: (json['conditions'] as List)
          .map((c) => Condition.fromJson(c))
          .toList(),
      logicOperator: json['logicOperator'] ?? 'AND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'logicOperator': logicOperator,
    };
  }
}

class EntrySettings {
  final List<Condition> conditions;
  final bool useProtection;
  final double takeProfit;
  final double stopLoss;

  EntrySettings({
    required this.conditions,
    this.useProtection = false,
    this.takeProfit = 1.0,
    this.stopLoss = 1.0,
  });

  factory EntrySettings.fromJson(Map<String, dynamic> json) {
    return EntrySettings(
      conditions: (json['conditions'] as List)
          .map((c) => Condition.fromJson(c))
          .toList(),
      useProtection: json['useProtection'] ?? false,
      takeProfit: (json['takeProfit'] as num?)?.toDouble() ?? 1.0,
      stopLoss: (json['stopLoss'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'useProtection': useProtection,
      'takeProfit': takeProfit,
      'stopLoss': stopLoss,
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
