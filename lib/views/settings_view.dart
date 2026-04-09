import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../core/theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _testnetApiKeyController =
      TextEditingController();
  final TextEditingController _testnetSecretKeyController =
      TextEditingController();
  final TextEditingController _liveApiKeyController = TextEditingController();
  final TextEditingController _liveSecretKeyController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<SettingsViewModel>();
    _testnetApiKeyController.text = viewModel.testnetApiKey;
    _testnetSecretKeyController.text = viewModel.testnetSecretKey;
    _liveApiKeyController.text = viewModel.liveApiKey;
    _liveSecretKeyController.text = viewModel.liveSecretKey;
  }

  @override
  void dispose() {
    _testnetApiKeyController.dispose();
    _testnetSecretKeyController.dispose();
    _liveApiKeyController.dispose();
    _liveSecretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(gradient: BinanceTheme.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNetworkToggle(viewModel),
              const SizedBox(height: 24),
              _buildSectionTitle('Testnet API Configuration'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Testnet API Key',
                      controller: _testnetApiKeyController,
                      onChanged: viewModel.setTestnetApiKey,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Testnet Secret Key',
                      controller: _testnetSecretKeyController,
                      onChanged: viewModel.setTestnetSecretKey,
                      isPassword: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Live API Configuration'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Live API Key',
                      controller: _liveApiKeyController,
                      onChanged: viewModel.setLiveApiKey,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Live Secret Key',
                      controller: _liveSecretKeyController,
                      onChanged: viewModel.setLiveSecretKey,
                      isPassword: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Pair Management'),
              const SizedBox(height: 12),
              _buildSymbolManagement(context, viewModel),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await viewModel.saveSettings();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BinanceTheme.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: BinanceTheme.yellow,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNetworkToggle(SettingsViewModel viewModel) {
    return _buildSettingsCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Network Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                viewModel.isTestnet
                    ? 'Testnet Enabled'
                    : 'Live Network Enabled',
                style: const TextStyle(color: BinanceTheme.secondaryTextColor),
              ),
            ],
          ),
          Switch(
            value: viewModel.isTestnet,
            onChanged: viewModel.setNetworkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BinanceTheme.surfaceColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BinanceTheme.yellow.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSymbolManagement(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Trading Pairs',
          style: TextStyle(
            color: BinanceTheme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: viewModel.selectedSymbols.map((symbol) {
            return Chip(
              label: Text(symbol),
              backgroundColor: BinanceTheme.yellow.withValues(alpha: 0.2),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              deleteIcon: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
              onDeleted: () => viewModel.removeSymbol(symbol),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showAddSymbolDialog(context, viewModel),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Trading Pair'),
          style: ElevatedButton.styleFrom(
            backgroundColor: BinanceTheme.surfaceColor,
            foregroundColor: BinanceTheme.yellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSymbolDialog(BuildContext context, SettingsViewModel viewModel) {
    viewModel.fetchAllAvailableSymbols();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                final filteredSymbols = viewModel.allSymbols
                    .where((s) => s.symbol.contains(searchQuery.toUpperCase()))
                    .toList();

                return AlertDialog(
                  backgroundColor: BinanceTheme.surfaceColor,
                  title: const Text(
                    'Add Trading Pair',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: viewModel.isSymbolsLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: BinanceTheme.yellow,
                            ),
                          )
                        : Column(
                            children: [
                              TextField(
                                onChanged: (value) =>
                                    setDialogState(() => searchQuery = value),
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Search symbols (e.g. BTC)',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredSymbols.length,
                                  itemBuilder: (context, index) {
                                    final symbolModel = filteredSymbols[index];
                                    final symbol = symbolModel.symbol;
                                    final isSelected = viewModel.selectedSymbols
                                        .contains(symbol);
                                    return ListTile(
                                      title: Text(
                                        symbol,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Prec: Q:${symbolModel.quantityPrecision} P:${symbolModel.pricePrecision}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: BinanceTheme.yellow,
                                            )
                                          : const Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.grey,
                                            ),
                                      onTap: () {
                                        if (isSelected) {
                                          viewModel.removeSymbol(symbol);
                                        } else {
                                          viewModel.addSymbol(symbol);
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: BinanceTheme.yellow),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: BinanceTheme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          obscureText: isPassword,
          style: const TextStyle(color: BinanceTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
