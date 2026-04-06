import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:crypto/crypto.dart';

class BinanceService {
  static const String liveBaseUrl = 'https://fapi.binance.com';
  static const String testnetBaseUrl = 'https://demo-fapi.binance.com';
  static const String wsUrl = 'wss://fstream.binancefuture.com/ws';

  final bool isTestnet;
  final String? apiKey;
  final String? secretKey;

  BinanceService({
    required this.isTestnet,
    this.apiKey,
    this.secretKey,
  });

  String get baseUrl => isTestnet ? testnetBaseUrl : liveBaseUrl;

  String _generateSignature(String queryString) {
    if (secretKey == null) return '';
    final key = utf8.encode(secretKey!);
    final bytes = utf8.encode(queryString);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> fetchAccountInformation() async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String queryString = 'timestamp=$timestamp&recvWindow=60000';
    final String signature = _generateSignature(queryString);

    final response = await http.get(
      Uri.parse('$baseUrl/fapi/v3/account?$queryString&signature=$signature'),
      headers: {
        'X-MBX-APIKEY': apiKey!,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load account information: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchAccountConfig() async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String queryString = 'timestamp=$timestamp&recvWindow=60000';
    final String signature = _generateSignature(queryString);

    final response = await http.get(
      Uri.parse('$baseUrl/fapi/v1/accountConfig?$queryString&signature=$signature'),
      headers: {
        'X-MBX-APIKEY': apiKey!,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load account config: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchPositionRisk({String? symbol}) async {
    if (apiKey == null || secretKey == null) {
      throw Exception('API Key and Secret Key are required');
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String, String> params = {
      'timestamp': timestamp.toString(),
      'recvWindow': '60000',
    };
    if (symbol != null) params['symbol'] = symbol.toUpperCase();

    final String queryString = Uri(queryParameters: params).query;
    final String signature = _generateSignature(queryString);

    final response = await http.get(
      Uri.parse('$baseUrl/fapi/v3/positionRisk?$queryString&signature=$signature'),
      headers: {
        'X-MBX-APIKEY': apiKey!,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load position risk: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> placeOrder({
    required String symbol,
    required String side,
    required String type,
    double? quantity,
    double? price,
    String? timeInForce,
    String? positionSide,
    bool? reduceOnly,
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
      'recvWindow': '60000',
    };

    if (quantity != null) params['quantity'] = quantity.toString();
    if (price != null) params['price'] = price.toString();
    if (timeInForce != null) params['timeInForce'] = timeInForce;
    if (positionSide != null) params['positionSide'] = positionSide.toUpperCase();
    if (reduceOnly == true) params['reduceOnly'] = 'true';

    final String queryString = Uri(queryParameters: params).query;
    final String signature = _generateSignature(queryString);

    final response = await http.post(
      Uri.parse('$baseUrl/fapi/v1/order?$queryString&signature=$signature'),
      headers: {
        'X-MBX-APIKEY': apiKey!,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to place order: ${response.body}');
    }
  }

  Future<List<String>> fetchExchangeInfo() async {
    final response = await http.get(Uri.parse('$baseUrl/fapi/v1/exchangeInfo'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> symbols = data['symbols'];
      
      return symbols
          .where((s) => s['status'] == 'TRADING' && s['contractType'] == 'PERPETUAL' && s['symbol'].toString().endsWith('USDT'))
          .map((s) => s['symbol'].toString())
          .toList();
    } else {
      throw Exception('Failed to load exchange info: ${response.body}');
    }
  }

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

  WebSocketChannel establishKlineWebsocket(String symbol, String interval) {
    final channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/${symbol.toLowerCase()}@kline_$interval'),
    );
    return channel;
  }

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
}
