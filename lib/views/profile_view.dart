import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../core/theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final accountInfo = viewModel.accountInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.refresh,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: BinanceTheme.darkGradient),
        child: accountInfo == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 64,
                      color: BinanceTheme.secondaryTextColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No account information available',
                      style: TextStyle(color: BinanceTheme.secondaryTextColor),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your API keys in Settings',
                      style: TextStyle(color: BinanceTheme.secondaryTextColor),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                      child: const Text('Go to Settings'),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSummaryCard(accountInfo),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Assets'),
                  _buildAssetsList(accountInfo['assets'] as List<dynamic>),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Account Flags'),
                  _buildAccountFlags(accountInfo),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> accountInfo) {
    final totalWalletBalance = double.tryParse(accountInfo['totalWalletBalance']?.toString() ?? '0') ?? 0.0;
    final totalUnrealizedProfit = double.tryParse(accountInfo['totalUnrealizedProfit']?.toString() ?? '0') ?? 0.0;
    final totalMarginBalance = double.tryParse(accountInfo['totalMarginBalance']?.toString() ?? '0') ?? 0.0;
    final availableBalance = double.tryParse(accountInfo['availableBalance']?.toString() ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BinanceTheme.surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BinanceTheme.yellow.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total Wallet Balance',
            '\$${totalWalletBalance.toStringAsFixed(2)}',
            isBold: true,
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildSummaryRow(
            'Total Unrealized Profit',
            '\$${totalUnrealizedProfit.toStringAsFixed(2)}',
            valueColor: totalUnrealizedProfit >= 0
                ? BinanceTheme.green
                : BinanceTheme.red,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Total Margin Balance',
            '\$${totalMarginBalance.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Available Balance',
            '\$${availableBalance.toStringAsFixed(2)}',
            valueColor: BinanceTheme.yellow,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: BinanceTheme.secondaryTextColor),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: BinanceTheme.yellow,
        ),
      ),
    );
  }

  Widget _buildAssetsList(List<dynamic> assets) {
    final filteredAssets = assets
        .where((asset) {
          final balance = double.tryParse(asset['walletBalance']?.toString() ?? '0') ?? 0.0;
          return balance > 0;
        })
        .toList();

    if (filteredAssets.isEmpty) {
      return const Center(
        child: Text('No assets with balance found'),
      );
    }

    return Column(
      children: filteredAssets.map((asset) {
        final walletBalance = double.tryParse(asset['walletBalance']?.toString() ?? '0') ?? 0.0;
        final marginBalance = double.tryParse(asset['marginBalance']?.toString() ?? '0') ?? 0.0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BinanceTheme.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                asset['asset']?.toString() ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(walletBalance.toStringAsFixed(4)),
                  Text(
                    'Margin: ${marginBalance.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: BinanceTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountFlags(Map<String, dynamic> accountInfo) {
    final flags = {
      'Can Deposit': accountInfo['canDeposit'],
      'Can Trade': accountInfo['canTrade'],
      'Can Withdraw': accountInfo['canWithdraw'],
      'Multi-Assets Mode': accountInfo['multiAssetsMargin'],
      'Hedge Mode': accountInfo['dualSidePosition'],
    };

    final otherConfigs = {
      'Fee Tier': accountInfo['feeTier']?.toString() ?? '0',
      'Trade Group ID': accountInfo['tradeGroupId']?.toString() ?? '-1',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: flags.entries.map((entry) {
            final bool isTrue = entry.value == true;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isTrue
                    ? BinanceTheme.green.withValues(alpha: 0.1)
                    : BinanceTheme.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTrue
                      ? BinanceTheme.green.withValues(alpha: 0.5)
                      : BinanceTheme.red.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTrue ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: isTrue ? BinanceTheme.green : BinanceTheme.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: isTrue ? BinanceTheme.green : BinanceTheme.red,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          children: otherConfigs.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    color: BinanceTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  entry.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
