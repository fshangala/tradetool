class SymbolModel {
  final String symbol;
  final int pricePrecision;
  final int quantityPrecision;
  final String status;
  final String contractType;

  SymbolModel({
    required this.symbol,
    required this.pricePrecision,
    required this.quantityPrecision,
    required this.status,
    required this.contractType,
  });

  factory SymbolModel.fromJson(Map<String, dynamic> json) {
    return SymbolModel(
      symbol: json['symbol'],
      pricePrecision: json['pricePrecision'],
      quantityPrecision: json['quantityPrecision'],
      status: json['status'],
      contractType: json['contractType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'pricePrecision': pricePrecision,
      'quantityPrecision': quantityPrecision,
      'status': status,
      'contractType': contractType,
    };
  }
}
