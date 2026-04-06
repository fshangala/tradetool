import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import '../viewmodels/dashboard_viewmodel.dart';
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: BinanceTheme.darkGradient),
        child: Column(
          children: [
            _buildIntervalSelector(viewModel),
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
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSelector(DashboardViewModel viewModel) {
    final intervals = ['1m', '5m', '15m', '1h', '4h', '1d'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: intervals.map((interval) {
          final isSelected = viewModel.currentInterval == interval;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(interval),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) viewModel.changeInterval(interval);
              },
              selectedColor: BinanceTheme.yellow,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
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
}
