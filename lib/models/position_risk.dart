class PositionRisk {
  final double entryPrice;
  final String marginType;
  final bool isAutoAddMargin;
  final double isolatedMargin;
  final int leverage;
  final double liquidationPrice;
  final double markPrice;
  final double maxNotionalValue;
  final double positionAmt;
  final double notional;
  final double isolatedWallet;
  final String symbol;
  final double unRealizedProfit;
  final String positionSide;
  final int updateTime;

  PositionRisk({
    required this.entryPrice,
    required this.marginType,
    required this.isAutoAddMargin,
    required this.isolatedMargin,
    required this.leverage,
    required this.liquidationPrice,
    required this.markPrice,
    required this.maxNotionalValue,
    required this.positionAmt,
    required this.notional,
    required this.isolatedWallet,
    required this.symbol,
    required this.unRealizedProfit,
    required this.positionSide,
    required this.updateTime,
  });

  factory PositionRisk.fromJson(Map<String, dynamic> json) {
    return PositionRisk(
      entryPrice: double.tryParse(json['entryPrice']?.toString() ?? '0') ?? 0.0,
      marginType: json['marginType']?.toString() ?? '',
      isAutoAddMargin:
          (json['isAutoAddMargin']?.toString() ?? 'false').toLowerCase() ==
          'true',
      isolatedMargin:
          double.tryParse(json['isolatedMargin']?.toString() ?? '0') ?? 0.0,
      leverage: int.tryParse(json['leverage']?.toString() ?? '0') ?? 0,
      liquidationPrice:
          double.tryParse(json['liquidationPrice']?.toString() ?? '0') ?? 0.0,
      markPrice: double.tryParse(json['markPrice']?.toString() ?? '0') ?? 0.0,
      maxNotionalValue:
          double.tryParse(json['maxNotionalValue']?.toString() ?? '0') ?? 0.0,
      positionAmt:
          double.tryParse(json['positionAmt']?.toString() ?? '0') ?? 0.0,
      notional: double.tryParse(json['notional']?.toString() ?? '0') ?? 0.0,
      isolatedWallet:
          double.tryParse(json['isolatedWallet']?.toString() ?? '0') ?? 0.0,
      symbol: json['symbol']?.toString() ?? '',
      unRealizedProfit:
          double.tryParse(json['unRealizedProfit']?.toString() ?? '0') ?? 0.0,
      positionSide: json['positionSide']?.toString() ?? 'BOTH',
      updateTime: int.tryParse(json['updateTime']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryPrice': entryPrice.toString(),
      'marginType': marginType,
      'isAutoAddMargin': isAutoAddMargin.toString(),
      'isolatedMargin': isolatedMargin.toString(),
      'leverage': leverage.toString(),
      'liquidationPrice': liquidationPrice.toString(),
      'markPrice': markPrice.toString(),
      'maxNotionalValue': maxNotionalValue.toString(),
      'positionAmt': positionAmt.toString(),
      'notional': notional.toString(),
      'isolatedWallet': isolatedWallet.toString(),
      'symbol': symbol,
      'unRealizedProfit': unRealizedProfit.toString(),
      'positionSide': positionSide,
      'updateTime': updateTime,
    };
  }

  bool get isLong => positionAmt > 0;
  bool get isShort => positionAmt < 0;
}
