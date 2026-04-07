class OrderResponse {
  final String symbol;
  final int orderId;
  final String clientOrderId;
  final double price;
  final double origQty;
  final double executedQty;
  final double cumQuote;
  final String status;
  final String timeInForce;
  final String type;
  final String side;
  final String positionSide;
  final double stopPrice;
  final bool closePosition;
  final int updateTime;
  final String workingType;
  final bool priceProtect;
  final double avgPrice;

  OrderResponse({
    required this.symbol,
    required this.orderId,
    required this.clientOrderId,
    required this.price,
    required this.origQty,
    required this.executedQty,
    required this.cumQuote,
    required this.status,
    required this.timeInForce,
    required this.type,
    required this.side,
    required this.positionSide,
    required this.stopPrice,
    required this.closePosition,
    required this.updateTime,
    required this.workingType,
    required this.priceProtect,
    required this.avgPrice,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      symbol: json['symbol']?.toString() ?? '',
      orderId: int.tryParse(json['orderId']?.toString() ?? '0') ?? 0,
      clientOrderId: json['clientOrderId']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      origQty: double.tryParse(json['origQty']?.toString() ?? '0') ?? 0.0,
      executedQty: double.tryParse(json['executedQty']?.toString() ?? '0') ?? 0.0,
      cumQuote: double.tryParse(json['cumQuote']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '',
      timeInForce: json['timeInForce']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      side: json['side']?.toString() ?? '',
      positionSide: json['positionSide']?.toString() ?? 'BOTH',
      stopPrice: double.tryParse(json['stopPrice']?.toString() ?? '0') ?? 0.0,
      closePosition: json['closePosition'] as bool? ?? false,
      updateTime: int.tryParse(json['updateTime']?.toString() ?? '0') ?? 0,
      workingType: json['workingType']?.toString() ?? '',
      priceProtect: json['priceProtect'] as bool? ?? false,
      avgPrice: double.tryParse(json['avgPrice']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'orderId': orderId,
      'clientOrderId': clientOrderId,
      'price': price.toString(),
      'origQty': origQty.toString(),
      'executedQty': executedQty.toString(),
      'cumQuote': cumQuote.toString(),
      'status': status,
      'timeInForce': timeInForce,
      'type': type,
      'side': side,
      'positionSide': positionSide,
      'stopPrice': stopPrice.toString(),
      'closePosition': closePosition,
      'updateTime': updateTime,
      'workingType': workingType,
      'priceProtect': priceProtect,
      'avgPrice': avgPrice.toString(),
    };
  }
}
