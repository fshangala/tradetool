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
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [const DashboardView(), const SettingsView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: BinanceTheme.darkBackground,
        selectedItemColor: BinanceTheme.yellow,
        unselectedItemColor: BinanceTheme.secondaryTextColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
