import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'views/settings_view.dart';
import 'views/dashboard_view.dart';

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
        ChangeNotifierProxyProvider<SettingsViewModel, DashboardViewModel>(
          create: (context) => DashboardViewModel(
            settingsViewModel: context.read<SettingsViewModel>(),
          ),
          update: (context, settings, previous) =>
              previous ?? DashboardViewModel(settingsViewModel: settings),
        ),
      ],
      child: MaterialApp(
        title: 'Binance Trade Tool',
        theme: BinanceTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardView(),
          '/settings': (context) => const SettingsView(),
        },
      ),
    );
  }
}
