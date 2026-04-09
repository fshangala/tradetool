import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:collection/collection.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/position_risk.dart';
import 'widgets/notification_overlay.dart';
import '../core/theme.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${viewModel.currentSymbol} - ${viewModel.currentInterval}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.refresh,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: BinanceTheme.surfaceColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: BinanceTheme.darkGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icon.png',
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.show_chart,
                        color: BinanceTheme.yellow,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TradeTool',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () => Navigator.pop(context),
              selected: true,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.psychology,
              label: 'Strategies',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/strategies');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.history,
              label: 'Trade History',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/trades');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const Divider(color: Colors.white12),
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: BinanceTheme.darkGradient,
            ),
            child: Column(
              children: [
                _buildSelectors(viewModel),
                _buildStrategySelector(viewModel),
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: BinanceTheme.yellow,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: viewModel.refresh,
                          color: BinanceTheme.yellow,
                          child: ListView(
                            children: [
                              _buildChart(viewModel),
                              _buildRetryButton(context, viewModel),
                              _buildPositions(context, viewModel),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const NotificationOverlay(),
        ],
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context, DashboardViewModel viewModel) {
    final failedAction = viewModel.getFailedAction(viewModel.currentSymbol);
    if (failedAction == null) return const SizedBox.shrink();

    final isWorking = viewModel.isWorking(viewModel.currentSymbol);

    String label = 'Retry Action';
    if (isWorking) {
      label = 'Working...';
    } else {
      if (failedAction == 'entry') label = 'Retry Entry';
      if (failedAction == 'protection') label = 'Retry Protection';
      if (failedAction == 'exit') label = 'Retry Close';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: isWorking
            ? null
            : () => viewModel.retryAction(viewModel.currentSymbol),
        icon: isWorking
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black54,
                ),
              )
            : const Icon(Icons.replay),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: BinanceTheme.yellow,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildSelectors(DashboardViewModel viewModel) {
    final intervals = [
      '1m',
      '3m',
      '5m',
      '15m',
      '30m',
      '1h',
      '2h',
      '4h',
      '6h',
      '8h',
      '12h',
      '1d',
      '3d',
      '1w',
      '1M',
    ];
    final symbols = viewModel.settingsViewModel.selectedSymbols;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdownContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: viewModel.currentSymbol,
                  dropdownColor: BinanceTheme.surfaceColor,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: BinanceTheme.yellow,
                  ),
                  items: symbols.map((symbol) {
                    return DropdownMenuItem(
                      value: symbol,
                      child: Text(
                        symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) viewModel.changeSymbol(value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: viewModel.currentInterval,
                  dropdownColor: BinanceTheme.surfaceColor,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.timer,
                    color: BinanceTheme.yellow,
                    size: 18,
                  ),
                  items: intervals.map((interval) {
                    return DropdownMenuItem(
                      value: interval,
                      child: Text(
                        interval,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) viewModel.changeInterval(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BinanceTheme.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BinanceTheme.yellow.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _buildStrategySelector(DashboardViewModel viewModel) {
    final strategies = viewModel.strategyViewModel.strategies;
    final activeId = viewModel.getActiveStrategyId(viewModel.currentSymbol);
    final activePhase = viewModel.getActiveStrategyPhase(
      viewModel.currentSymbol,
    );
    final isWorking = viewModel.isWorking(viewModel.currentSymbol);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdownContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: activeId,
                  dropdownColor: BinanceTheme.surfaceColor,
                  isExpanded: true,
                  hint: const Text(
                    'Select Strategy',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  disabledHint: Text(
                    strategies
                            .firstWhereOrNull((s) => s.id == activeId)
                            ?.name ??
                        'Active Strategy',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  icon: const Icon(
                    Icons.psychology,
                    color: BinanceTheme.yellow,
                    size: 18,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'Manual Trading (Auto Off)',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                    ...strategies.map((strategy) {
                      return DropdownMenuItem<String?>(
                        value: strategy.id,
                        child: Text(
                          strategy.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: isWorking
                      ? null
                      : (value) {
                          viewModel.setStrategyForSymbol(
                            viewModel.currentSymbol,
                            value,
                          );
                        },
                ),
              ),
            ),
          ),
          if (activeId != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: (isWorking ? BinanceTheme.yellow : BinanceTheme.yellow)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BinanceTheme.yellow.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  if (isWorking)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: BinanceTheme.yellow,
                      ),
                    )
                  else
                    const Icon(
                      Icons.auto_mode,
                      color: BinanceTheme.yellow,
                      size: 14,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    isWorking ? 'WORKING' : activePhase.toUpperCase(),
                    style: const TextStyle(
                      color: BinanceTheme.yellow,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(DashboardViewModel viewModel) {
    return Container(
      height: 450,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: BinanceTheme.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BinanceTheme.yellow.withValues(alpha: 0.1)),
      ),
      child: KChartWidget(
        viewModel.datas,
        KChartStyle(),
        KChartColors(),
        detailBuilder: (entity) => const SizedBox.shrink(),
        isTrendLine: false,
        isLine: false,
        mainIndicators: viewModel.mainIndicators,
        secondaryIndicators: viewModel.secondaryIndicators,
        volHidden: true,
        fixedLength: 2,
      ),
    );
  }

  Widget _buildPositions(BuildContext context, DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Open Positions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BinanceTheme.yellow,
                ),
              ),
              if (viewModel.isPositionsLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BinanceTheme.yellow,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: BinanceTheme.yellow,
                  ),
                  onPressed: viewModel.refreshPositions,
                ),
            ],
          ),
        ),
        if (viewModel.positions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No open positions',
                style: TextStyle(color: BinanceTheme.secondaryTextColor),
              ),
            ),
          )
        else
          ...viewModel.positions.map((position) {
            final amt = position.positionAmt;
            final entryPrice = position.entryPrice;
            final markPrice = position.markPrice;
            final pnl = position.unRealizedProfit;
            final isLong = position.isLong;
            final symbol = position.symbol;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BinanceTheme.surfaceColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLong
                      ? BinanceTheme.green.withValues(alpha: 0.2)
                      : BinanceTheme.red.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            symbol,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isLong
                                  ? BinanceTheme.green.withValues(alpha: 0.2)
                                  : BinanceTheme.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isLong ? 'LONG' : 'SHORT',
                              style: TextStyle(
                                color: isLong
                                    ? BinanceTheme.green
                                    : BinanceTheme.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)} USDT',
                        style: TextStyle(
                          color: pnl >= 0
                              ? BinanceTheme.green
                              : BinanceTheme.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPosDetail('Size', '${amt.abs()}'),
                      _buildPosDetail('Entry', entryPrice.toStringAsFixed(2)),
                      _buildPosDetail('Mark', markPrice.toStringAsFixed(2)),
                      ElevatedButton(
                        onPressed: () => _showCloseConfirmation(
                          context,
                          viewModel,
                          position,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BinanceTheme.red.withValues(
                            alpha: 0.2,
                          ),
                          foregroundColor: BinanceTheme.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          minimumSize: const Size(60, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showCloseConfirmation(
    BuildContext context,
    DashboardViewModel viewModel,
    PositionRisk position,
  ) {
    final symbol = position.symbol;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BinanceTheme.surfaceColor,
        title: const Text(
          'Confirm Close Position',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to close your position for $symbol at market price?',
          style: const TextStyle(color: BinanceTheme.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.closePosition(position);
              Navigator.pop(context);
            },
            child: const Text(
              'Close Position',
              style: TextStyle(
                color: BinanceTheme.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: BinanceTheme.secondaryTextColor,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? BinanceTheme.yellow : BinanceTheme.secondaryTextColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? BinanceTheme.yellow : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
