class AlgoOrderResponse {
  final int algoId;
  final String clientAlgoId;
  final String algoType;
  final int code;
  final String msg;

  AlgoOrderResponse({
    required this.algoId,
    required this.clientAlgoId,
    required this.algoType,
    required this.code,
    required this.msg,
  });

  factory AlgoOrderResponse.fromJson(Map<String, dynamic> json) {
    return AlgoOrderResponse(
      algoId: int.tryParse(json['algoId']?.toString() ?? '0') ?? 0,
      clientAlgoId: json['clientAlgoId']?.toString() ?? '',
      algoType: json['algoType']?.toString() ?? '',
      code: int.tryParse(json['code']?.toString() ?? '0') ?? 0,
      msg: json['msg']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'algoId': algoId,
      'clientAlgoId': clientAlgoId,
      'algoType': algoType,
      'code': code,
      'msg': msg,
    };
  }
}
