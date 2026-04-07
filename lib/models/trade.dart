class Trade {
  final bool buyer;
  final String commission;
  final String commissionAsset;
  final int id;
  final int orderId;
  final String price;
  final String qty;
  final String quoteQty;
  final String realizedPnl;
  final String side;
  final String positionSide;
  final String symbol;
  final int time;

  Trade({
    required this.buyer,
    required this.commission,
    required this.commissionAsset,
    required this.id,
    required this.orderId,
    required this.price,
    required this.qty,
    required this.quoteQty,
    required this.realizedPnl,
    required this.side,
    required this.positionSide,
    required this.symbol,
    required this.time,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      buyer: json['buyer'] as bool,
      commission: json['commission']?.toString() ?? '0',
      commissionAsset: json['commissionAsset']?.toString() ?? '',
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderId: int.tryParse(json['orderId']?.toString() ?? '0') ?? 0,
      price: json['price']?.toString() ?? '0',
      qty: json['qty']?.toString() ?? '0',
      quoteQty: json['quoteQty']?.toString() ?? '0',
      realizedPnl: json['realizedPnl']?.toString() ?? '0',
      side: json['side']?.toString() ?? '',
      positionSide: json['positionSide']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      time: int.tryParse(json['time']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buyer': buyer,
      'commission': commission,
      'commissionAsset': commissionAsset,
      'id': id,
      'orderId': orderId,
      'price': price,
      'qty': qty,
      'quoteQty': quoteQty,
      'realizedPnl': realizedPnl,
      'side': side,
      'positionSide': positionSide,
      'symbol': symbol,
      'time': time,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time);
}
