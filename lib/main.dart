import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'viewmodels/trades_viewmodel.dart';
import 'views/settings_view.dart';
import 'views/dashboard_view.dart';
import 'views/profile_view.dart';
import 'views/trades_view.dart';

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
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProxyProvider2<SettingsViewModel, NotificationViewModel, DashboardViewModel>(
          create: (context) => DashboardViewModel(
            settingsViewModel: context.read<SettingsViewModel>(),
            notificationViewModel: context.read<NotificationViewModel>(),
          ),
          update: (context, settings, notification, previous) =>
              previous ??
              DashboardViewModel(
                settingsViewModel: settings,
                notificationViewModel: notification,
              ),
        ),
        ChangeNotifierProxyProvider2<SettingsViewModel, NotificationViewModel, TradesViewModel>(
          create: (context) => TradesViewModel(
            settingsViewModel: context.read<SettingsViewModel>(),
            notificationViewModel: context.read<NotificationViewModel>(),
          ),
          update: (context, settings, notification, previous) =>
              previous ??
              TradesViewModel(
                settingsViewModel: settings,
                notificationViewModel: notification,
              ),
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
          '/profile': (context) => const ProfileView(),
          '/trades': (context) => const TradesView(),
        },
      ),
    );
  }
}
