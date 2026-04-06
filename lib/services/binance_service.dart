import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

class BinanceService {
  static const String liveBaseUrl = 'https://fapi.binance.com';
  static const String testnetBaseUrl = 'https://demo-fapi.binance.com';
  static const String wsUrl = 'wss://fstream.binancefuture.com/ws';

  final bool isTestnet;

  BinanceService({required this.isTestnet});

  String get baseUrl => isTestnet ? testnetBaseUrl : liveBaseUrl;

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
