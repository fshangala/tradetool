import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'views/settings_view.dart';

void main() {
  runApp(const BinanceTradeApp());
}

class BinanceTradeApp extends StatelessWidget {
  const BinanceTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: MaterialApp(
        title: 'Binance Trade Tool',
        theme: BinanceTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const SettingsView(),
      ),
    );
  }
}
