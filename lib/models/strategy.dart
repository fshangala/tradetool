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

  Condition({
    required this.type,
    this.indicatorName,
    this.params,
    required this.op,
    required this.value,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      type: ConditionType.values.firstWhere((e) => e.name == json['type']),
      indicatorName: json['indicatorName'],
      params: json['params'],
      op: Operator.values.firstWhere((e) => e.name == json['op']),
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'indicatorName': indicatorName,
      'params': params,
      'op': op.name,
      'value': value,
    };
  }
}

class StrategyPhase {
  final List<Condition> conditions;
  final String logicOperator; // Always 'AND' for now

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

class ProtectionSettings {
  final double takeProfitPercentage;
  final double stopLossPercentage;

  ProtectionSettings({
    required this.takeProfitPercentage,
    required this.stopLossPercentage,
  });

  factory ProtectionSettings.fromJson(Map<String, dynamic> json) {
    return ProtectionSettings(
      takeProfitPercentage: (json['takeProfitPercentage'] as num).toDouble(),
      stopLossPercentage: (json['stopLossPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'takeProfitPercentage': takeProfitPercentage,
      'stopLossPercentage': stopLossPercentage,
    };
  }
}

class Strategy {
  final String id;
  final String name;
  final StrategyPhase entryPhase;
  final ProtectionSettings protectionPhase;
  final StrategyPhase exitPhase;

  Strategy({
    required this.id,
    required this.name,
    required this.entryPhase,
    required this.protectionPhase,
    required this.exitPhase,
  });

  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      id: json['id'],
      name: json['name'],
      entryPhase: StrategyPhase.fromJson(json['entryPhase']),
      protectionPhase: ProtectionSettings.fromJson(json['protectionPhase']),
      exitPhase: StrategyPhase.fromJson(json['exitPhase']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'entryPhase': entryPhase.toJson(),
      'protectionPhase': protectionPhase.toJson(),
      'exitPhase': exitPhase.toJson(),
    };
  }
}
