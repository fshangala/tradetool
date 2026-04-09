import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:crypto/crypto.dart';
import '../models/trade.dart';
import '../models/account_info.dart';
import '../models/account_config.dart';
import '../models/position_risk.dart';
import '../models/order_response.dart';
import '../models/algo_order_response.dart';
import '../models/symbol_model.dart';

/// Service class to interact with the Binance Futures API.
class BinanceService {
  static const String liveBaseUrl = 'https://fapi.binance.com';
  static const String testnetBaseUrl = 'https://demo-fapi.binance.com';
  static const String wsUrl = 'wss://fstream.binancefuture.com/ws';
  static const int recvWindow = 30000;

  final bool isTestnet;
  final String? apiKey;
  final String? secretKey;

  BinanceService({required this.isTestnet, this.apiKey, this.secretKey});

  /// Returns the base URL based on the environment (Live or Testnet).
  String get baseUrl => isTestnet ? testnetBaseUrl : liveBaseUrl;

  /// Generates an HMAC SHA256 signature for authenticated requests.
  String _generateSignature(String queryString) {
    if (secretKey == null) return '';
    final key = utf8.encode(secretKey!);
    final bytes = utf8.encode(queryString);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Fetches account information including balances and assets.
  ///
  /// Throws an [Exception] if API keys are missing or the request fails.
  Future<AccountInformation> fetchAccountInformation() async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String queryString = 'timestamp=$timestamp&recvWindow=$recvWindow';
    final String signature = _generateSignature(queryString);

    final response = await http.get(
      Uri.parse('$baseUrl/fapi/v3/account?$queryString&signature=$signature'),
      headers: {'X-MBX-APIKEY': apiKey!},
    );

    if (response.statusCode == 200) {
      return AccountInformation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load account information: ${response.body}');
    }
  }

  /// Fetches account configuration settings like position mode (Hedge/One-way).
  ///
  /// Throws an [Exception] if API keys are missing or the request fails.
  Future<AccountConfig> fetchAccountConfig() async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String queryString = 'timestamp=$timestamp&recvWindow=$recvWindow';
    final String signature = _generateSignature(queryString);

    final response = await http.get(
      Uri.parse(
        '$baseUrl/fapi/v1/accountConfig?$queryString&signature=$signature',
      ),
      headers: {'X-MBX-APIKEY': apiKey!},
    );

    if (response.statusCode == 200) {
      return AccountConfig.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load account config: ${response.body}');
    }
  }

  /// Fetches risk information for open positions.
  ///
  /// [symbol] Optional symbol to filter positions.
  /// Throws an [Exception] if API keys are missing or the request fails.
  Future<List<PositionRisk>> fetchPositionRisk({String? symbol}) async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String, String> params = {
      'timestamp': timestamp.toString(),
      'recvWindow': '$recvWindow',
    };
    if (symbol != null) params['symbol'] = symbol.toUpperCase();

    final String queryString = Uri(queryParameters: params).query;
    final String signature = _generateSignature(queryString);

    final response = await http.get(
      Uri.parse(
        '$baseUrl/fapi/v3/positionRisk?$queryString&signature=$signature',
      ),
      headers: {'X-MBX-APIKEY': apiKey!},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => PositionRisk.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load position risk: ${response.body}');
    }
  }

  /// Places a new order on the Binance Futures exchange.
  ///
  /// [symbol] The trading pair (e.g., BTCUSDT).
  /// [side] 'BUY' or 'SELL'.
  /// [type] Order type (e.g., 'MARKET', 'LIMIT').
  /// [quantity] Order quantity.
  /// [price] Order price (required for LIMIT orders).
  /// [timeInForce] GTC, IOC, FOK (for LIMIT orders).
  /// [positionSide] 'BOTH' for One-way Mode, 'LONG' or 'SHORT' for Hedge Mode.
  /// [reduceOnly] Set to true if the order is intended to only reduce an existing position.
  /// [stopPrice] Used with STOP/STOP_MARKET/TAKE_PROFIT/TAKE_PROFIT_MARKET orders.
  /// [closePosition] A value of true with STOP_MARKET or TAKE_PROFIT_MARKET will close the position.
  /// [workingType] stopPrice triggered by: "MARK_PRICE", "CONTRACT_PRICE". Default "CONTRACT_PRICE".
  Future<OrderResponse> placeOrder({
    required String symbol,
    required String side,
    required String type,
    double? quantity,
    double? price,
    double? stopPrice,
    String? timeInForce,
    String? positionSide,
    bool? reduceOnly,
    bool? closePosition,
    String? workingType,
  }) async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String, String> params = {
      'symbol': symbol.toUpperCase(),
      'side': side.toUpperCase(),
      'type': type.toUpperCase(),
      'timestamp': timestamp.toString(),
      'recvWindow': '$recvWindow',
    };

    if (quantity != null) params['quantity'] = quantity.toString();
    if (price != null) params['price'] = price.toString();
    if (stopPrice != null) params['stopPrice'] = stopPrice.toString();
    if (timeInForce != null) params['timeInForce'] = timeInForce;
    if (positionSide != null) {
      params['positionSide'] = positionSide.toUpperCase();
    }
    if (reduceOnly == true) params['reduceOnly'] = 'true';
    if (closePosition == true) params['closePosition'] = 'true';
    if (workingType != null) params['workingType'] = workingType.toUpperCase();

    final String queryString = Uri(queryParameters: params).query;
    final String signature = _generateSignature(queryString);

    final response = await http.post(
      Uri.parse('$baseUrl/fapi/v1/order?$queryString&signature=$signature'),
      headers: {'X-MBX-APIKEY': apiKey!},
    );

    if (response.statusCode == 200) {
      return OrderResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to place order: ${response.body}');
    }
  }

  /// Fetches a list of available trading symbols from the exchange.
  ///
  /// Filters for symbols that are TRADING, PERPETUAL, and end with USDT.
  Future<List<SymbolModel>> fetchExchangeInfo() async {
    final response = await http.get(Uri.parse('$baseUrl/fapi/v1/exchangeInfo'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> symbols = data['symbols'];

      return symbols
          .where(
            (s) =>
                s['status'] == 'TRADING' &&
                s['contractType'] == 'PERPETUAL' &&
                s['symbol'].toString().endsWith('USDT'),
          )
          .map((s) => SymbolModel.fromJson(s))
          .toList();
    } else {
      throw Exception('Failed to load exchange info: ${response.body}');
    }
  }

  /// Fetches historical candlestick data (K-lines) for a symbol.
  ///
  /// [symbol] The trading pair.
  /// [interval] Time interval (e.g., '1m', '15m', '1h').
  /// [limit] Number of bars to fetch (max 1500, default 500).
  Future<List<KLineEntity>> fetchKlines({
    required String symbol,
    required String interval,
    int limit = 500,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/fapi/v1/klines?symbol=${symbol.toUpperCase()}&interval=$interval&limit=$limit',
      ),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => _mapToKLineEntity(item)).toList();
    } else {
      throw Exception('Failed to load klines: ${response.body}');
    }
  }

  /// Establishes a WebSocket connection for real-time K-line updates.
  WebSocketChannel establishKlineWebsocket(String symbol, String interval) {
    final channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/${symbol.toLowerCase()}@kline_$interval'),
    );
    return channel;
  }

  /// Maps a raw K-line list from the REST API to a [KLineEntity].
  KLineEntity _mapToKLineEntity(List<dynamic> item) {
    return KLineEntity.fromCustom(
      open: double.parse(item[1].toString()),
      high: double.parse(item[2].toString()),
      low: double.parse(item[3].toString()),
      close: double.parse(item[4].toString()),
      vol: double.parse(item[5].toString()),
      amount: double.parse(item[7].toString()), // Quote asset volume
      time: int.parse(item[0].toString()),
    );
  }

  /// Maps a raw K-line map from the WebSocket stream to a [KLineEntity].
  KLineEntity mapWsToKLineEntity(Map<String, dynamic> k) {
    return KLineEntity.fromCustom(
      open: double.parse(k['o'].toString()),
      high: double.parse(k['h'].toString()),
      low: double.parse(k['l'].toString()),
      close: double.parse(k['c'].toString()),
      vol: double.parse(k['v'].toString()),
      amount: double.parse(k['q'].toString()),
      time: int.parse(k['t'].toString()),
    );
  }

  /// Fetches the authenticated user's trade history.
  ///
  /// [symbol] Optional symbol to filter trades.
  Future<List<Trade>> fetchUserTrades({String? symbol}) async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String, String> params = {
      'timestamp': timestamp.toString(),
      'recvWindow': '$recvWindow',
    };
    if (symbol != null) params['symbol'] = symbol.toUpperCase();

    final String queryString = Uri(queryParameters: params).query;
    final String signature = _generateSignature(queryString);

    final response = await http.get(
      Uri.parse(
        '$baseUrl/fapi/v1/userTrades?$queryString&signature=$signature',
      ),
      headers: {'X-MBX-APIKEY': apiKey!},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Trade.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load user trades: ${response.body}');
    }
  }

  /// Places a new algo order (conditional order) using the Algo Service.
  ///
  /// [symbol] The trading pair.
  /// [side] 'BUY' or 'SELL'.
  /// [type] 'STOP_MARKET', 'TAKE_PROFIT_MARKET', 'TRAILING_STOP_MARKET', etc.
  /// [quantity] Order quantity.
  /// [triggerPrice] The price that triggers the order.
  /// [price] Execution price for limit algo orders.
  /// [positionSide] 'BOTH', 'LONG', or 'SHORT'.
  /// [closePosition] Set to true to close the entire position.
  /// [reduceOnly] Set to true to only reduce position.
  /// [workingType] 'MARK_PRICE' or 'CONTRACT_PRICE'.
  /// [priceProtect] 'TRUE' or 'FALSE'.
  /// [callbackRate] Callback rate for trailing stop (0.1 to 5).
  /// [activatePrice] Activation price for trailing stop.
  Future<AlgoOrderResponse> placeAlgoOrder({
    required String symbol,
    required String side,
    required String type,
    double? quantity,
    double? triggerPrice,
    double? price,
    String? positionSide,
    bool? closePosition,
    bool? reduceOnly,
    String? workingType,
    String? priceProtect,
    double? callbackRate,
    double? activatePrice,
  }) async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String, String> params = {
      'algoType': 'CONDITIONAL',
      'symbol': symbol.toUpperCase(),
      'side': side.toUpperCase(),
      'type': type.toUpperCase(),
      'timestamp': timestamp.toString(),
      'recvWindow': '$recvWindow',
    };

    if (quantity != null) params['quantity'] = quantity.toString();
    if (triggerPrice != null) params['triggerPrice'] = triggerPrice.toString();
    if (price != null) params['price'] = price.toString();
    if (positionSide != null) {
      params['positionSide'] = positionSide.toUpperCase();
    }
    if (closePosition == true) params['closePosition'] = 'true';
    if (reduceOnly == true) params['reduceOnly'] = 'true';
    if (workingType != null) params['workingType'] = workingType.toUpperCase();
    if (priceProtect != null) {
      params['priceProtect'] = priceProtect.toUpperCase();
    }
    if (callbackRate != null) params['callbackRate'] = callbackRate.toString();
    if (activatePrice != null) {
      params['activatePrice'] = activatePrice.toString();
    }

    final String queryString = Uri(queryParameters: params).query;
    final String signature = _generateSignature(queryString);

    final response = await http.post(
      Uri.parse('$baseUrl/fapi/v1/algoOrder?$queryString&signature=$signature'),
      headers: {'X-MBX-APIKEY': apiKey!},
    );

    if (response.statusCode == 200) {
      return AlgoOrderResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to place algo order: ${response.body}');
    }
  }
}
