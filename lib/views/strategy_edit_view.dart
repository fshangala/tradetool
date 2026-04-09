import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/strategy.dart';
import '../viewmodels/strategy_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/strategy_evaluation_viewmodel.dart';
import '../core/theme.dart';

class StrategyEditView extends StatefulWidget {
  final Strategy? strategy;

  const StrategyEditView({super.key, this.strategy});

  @override
  State<StrategyEditView> createState() => _StrategyEditViewState();
}

class _StrategyEditViewState extends State<StrategyEditView> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  late TextEditingController _nameController;
  late double _walletPercentage;

  // Long Entry Settings
  late List<Condition> _longEntryConditions;
  late bool _longUseProtection;
  late double _longTP;
  late double _longSL;

  // Short Entry Settings
  late List<Condition> _shortEntryConditions;
  late bool _shortUseProtection;
  late double _shortTP;
  late double _shortSL;

  // Exit Phases
  late List<Condition> _longExitConditions;
  late List<Condition> _shortExitConditions;

  @override
  void initState() {
    super.initState();
    final s = widget.strategy;
    _id = s?.id ?? const Uuid().v4();
    _nameController = TextEditingController(text: s?.name ?? '');
    _walletPercentage = s?.walletPercentage ?? 40.0;

    // Long Entry
    _longEntryConditions = List.from(s?.longEntry.conditions ?? []);
    _longUseProtection = s?.longEntry.useProtection ?? false;
    _longTP = s?.longEntry.takeProfit ?? 1.0;
    _longSL = s?.longEntry.stopLoss ?? 1.0;

    // Short Entry
    _shortEntryConditions = List.from(s?.shortEntry.conditions ?? []);
    _shortUseProtection = s?.shortEntry.useProtection ?? false;
    _shortTP = s?.shortEntry.takeProfit ?? 1.0;
    _shortSL = s?.shortEntry.stopLoss ?? 1.0;

    // Exits
    _longExitConditions = List.from(s?.longExit.conditions ?? []);
    _shortExitConditions = List.from(s?.shortExit.conditions ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_longEntryConditions.isEmpty && _shortEntryConditions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one entry phase (Long or Short) must have conditions.')),
        );
        return;
      }

      final strategy = Strategy(
        id: _id,
        name: _nameController.text,
        walletPercentage: _walletPercentage,
        longEntry: EntrySettings(
          conditions: _longEntryConditions,
          useProtection: _longUseProtection,
          takeProfit: _longTP,
          stopLoss: _longSL,
        ),
        shortEntry: EntrySettings(
          conditions: _shortEntryConditions,
          useProtection: _shortUseProtection,
          takeProfit: _shortTP,
          stopLoss: _shortSL,
        ),
        longExit: StrategyPhase(conditions: _longExitConditions),
        shortExit: StrategyPhase(conditions: _shortExitConditions),
      );

      final viewModel = Provider.of<StrategyViewModel>(context, listen: false);
      if (widget.strategy == null) {
        viewModel.addStrategy(strategy);
      } else {
        viewModel.updateStrategy(strategy);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.strategy == null ? 'New Strategy' : 'Edit Strategy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: BinanceTheme.yellow),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGeneralSection(),
            if (widget.strategy?.lastResult != null) ...[
              const SizedBox(height: 16),
              _buildLastEvaluationSection(widget.strategy!.lastResult!),
            ],
            const SizedBox(height: 24),
            _buildEntrySection('LONG ENTRY', _longEntryConditions, _longUseProtection, _longTP, _longSL, 
              (val) => setState(() => _longUseProtection = val),
              (val) => setState(() => _longTP = val),
              (val) => setState(() => _longSL = val)),
            const SizedBox(height: 16),
            _buildEntrySection('SHORT ENTRY', _shortEntryConditions, _shortUseProtection, _shortTP, _shortSL,
              (val) => setState(() => _shortUseProtection = val),
              (val) => setState(() => _shortTP = val),
              (val) => setState(() => _shortSL = val)),
            const SizedBox(height: 16),
            _buildExitSection('LONG EXIT', _longExitConditions),
            const SizedBox(height: 16),
            _buildExitSection('SHORT EXIT', _shortExitConditions),
            const SizedBox(height: 32),
            _buildEvaluateButton(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildLastEvaluationSection(EvaluationResult result) {
    return Card(
      color: BinanceTheme.yellow.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Latest Evaluation'),
                _buildRatingStars(result.rating),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${result.symbol} • ${result.interval} • ${result.leverage}x • ${result.initialCapital.toStringAsFixed(0)} USDT',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSimpleMetric('Net Earnings', '${result.netEarnings >= 0 ? '+' : ''}${result.netEarnings.toStringAsFixed(2)}', 
                    result.netEarnings >= 0 ? Colors.greenAccent : Colors.redAccent),
                _buildSimpleMetric('Success Rate', '${((result.profitableTrades / (result.totalTrades > 0 ? result.totalTrades : 1)) * 100).toStringAsFixed(1)}%', Colors.white),
                _buildSimpleMetric('Trades', result.totalTrades.toString(), Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: BinanceTheme.yellow,
          size: 16,
        );
      }),
    );
  }

  Widget _buildEvaluateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showEvaluationModal(context),
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('Evaluate Strategy'),
        style: ElevatedButton.styleFrom(
          backgroundColor: BinanceTheme.yellow.withValues(alpha: 0.1),
          foregroundColor: BinanceTheme.yellow,
          side: const BorderSide(color: BinanceTheme.yellow),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('General Info'),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Strategy Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _walletPercentage.toString(),
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Wallet Percentage for Entry (%)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                helperText: 'Max 80%',
                helperStyle: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              onChanged: (val) {
                final doubleValue = double.tryParse(val);
                if (doubleValue != null) _walletPercentage = doubleValue;
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final val = double.tryParse(value);
                if (val == null) return 'Invalid number';
                if (val <= 0 || val > 80) return 'Must be between 1 and 80';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrySection(String title, List<Condition> conditions, bool useProtection, double tp, double sl, 
      Function(bool) onProtectionChanged, Function(double) onTPChanged, Function(double) onSLChanged) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title),
            _buildConditionsList(conditions),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            Row(
              children: [
                const Text('Auto Protection (TP/SL)', style: TextStyle(color: Colors.white, fontSize: 14)),
                const Spacer(),
                Switch(
                  value: useProtection,
                  onChanged: onProtectionChanged,
                  activeThumbColor: BinanceTheme.yellow,
                ),
              ],
            ),
            if (useProtection)
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInput('Take Profit (%)', tp, onTPChanged),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberInput('Stop Loss (%)', sl, onSLChanged),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExitSection(String title, List<Condition> conditions) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title),
            _buildConditionsList(conditions),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsList(List<Condition> conditions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...conditions.asMap().entries.map((entry) {
          final index = entry.key;
          final condition = entry.value;
          return Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              title: Text(
                _conditionToString(condition),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                onPressed: () => setState(() => conditions.removeAt(index)),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showAddConditionDialog(conditions),
          icon: const Icon(Icons.add, color: BinanceTheme.yellow, size: 16),
          label: const Text('Add Condition', style: TextStyle(color: BinanceTheme.yellow, fontSize: 12)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: BinanceTheme.yellow,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNumberInput(String label, double value, Function(double) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
      ),
      onChanged: (val) {
        final doubleValue = double.tryParse(val);
        if (doubleValue != null) onChanged(doubleValue);
      },
    );
  }

  String _conditionToString(Condition c) {
    final opStr = _opToSymbol(c.op);
    String leftSide = c.type == ConditionType.price ? 'Price' : c.indicatorName!;
    String rightSide = c.targetIndicatorName ?? c.value.toString();
    String suffix = c.useLastClosedData ? ' [Last]' : '';
    return '$leftSide $opStr $rightSide$suffix';
  }

  String _opToSymbol(Operator op) {
    switch (op) {
      case Operator.greaterThan: return '>';
      case Operator.lessThan: return '<';
      case Operator.equal: return '==';
      case Operator.crossesAbove: return '↑';
      case Operator.crossesBelow: return '↓';
    }
  }

  void _showEvaluationModal(BuildContext context) {
    final settings = context.read<SettingsViewModel>();
    String selectedSymbol = settings.selectedSymbols.isNotEmpty ? settings.selectedSymbols.first : 'BTCUSDT';
    String selectedInterval = '1h';
    int selectedLeverage = 10;
    final intervals = ['1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '6h', '8h', '12h', '1d', '3d', '1w', '1M'];
    final leverages = [1, 5, 10, 20];
    final capitalController = TextEditingController(text: '1000');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Consumer<StrategyEvaluationViewModel>(
            builder: (context, evalViewModel, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Strategy Evaluation',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () {
                          evalViewModel.reset();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildModalDropdown(
                                  'Symbol',
                                  selectedSymbol,
                                  settings.selectedSymbols,
                                  (val) => setModalState(() => selectedSymbol = val!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildModalDropdown(
                                  'Interval',
                                  selectedInterval,
                                  intervals,
                                  (val) => setModalState(() => selectedInterval = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Initial Capital (USDT)', style: TextStyle(color: BinanceTheme.yellow, fontSize: 11)),
                                    TextField(
                                      controller: capitalController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildModalDropdown(
                                  'Leverage',
                                  '${selectedLeverage}x',
                                  leverages.map((l) => '${l}x').toList(),
                                  (val) => setModalState(() => selectedLeverage = int.parse(val!.replaceAll('x', ''))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (evalViewModel.isEvaluating || evalViewModel.progress > 0) ...[
                            const Text('Progress', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: evalViewModel.progress,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(BinanceTheme.yellow),
                            ),
                            const SizedBox(height: 24),
                            _buildResultGrid(evalViewModel),
                          ],
                          if (evalViewModel.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                evalViewModel.error!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: evalViewModel.isEvaluating
                          ? null
                          : () {
                              final strategy = Strategy(
                                id: _id,
                                name: _nameController.text,
                                walletPercentage: _walletPercentage,
                                longEntry: EntrySettings(
                                  conditions: _longEntryConditions,
                                  useProtection: _longUseProtection,
                                  takeProfit: _longTP,
                                  stopLoss: _longSL,
                                ),
                                shortEntry: EntrySettings(
                                  conditions: _shortEntryConditions,
                                  useProtection: _shortUseProtection,
                                  takeProfit: _shortTP,
                                  stopLoss: _shortSL,
                                ),
                                longExit: StrategyPhase(conditions: _longExitConditions),
                                shortExit: StrategyPhase(conditions: _shortExitConditions),
                              );
                              final capital = double.tryParse(capitalController.text) ?? 1000.0;
                              evalViewModel.evaluate(strategy, selectedSymbol, selectedInterval, capital, selectedLeverage).then((_) {
                                if (context.mounted && evalViewModel.lastResult != null && evalViewModel.error == null) {
                                  final updatedStrategy = strategy.copyWith(lastResult: evalViewModel.lastResult);
                                  Provider.of<StrategyViewModel>(context, listen: false).updateStrategy(updatedStrategy);
                                }
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BinanceTheme.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.white10,
                      ),
                      child: Text(evalViewModel.isEvaluating ? 'Evaluating...' : 'Start Evaluation'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModalDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: BinanceTheme.yellow, fontSize: 11)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.grey[850],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          underline: Container(height: 1, color: Colors.white24),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResultGrid(StrategyEvaluationViewModel viewModel) {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildResultItem('Total Trades', viewModel.totalTrades.toString(), Colors.white),
            _buildResultItem('Profitable', viewModel.profitableTrades.toString(), Colors.greenAccent),
            _buildResultItem('Losses', viewModel.lossTrades.toString(), Colors.redAccent),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildResultItem('Gross Profit', '+${viewModel.totalGrossProfitUsdt.toStringAsFixed(2)}', Colors.greenAccent),
            _buildResultItem('Gross Loss', viewModel.totalGrossLossUsdt.toStringAsFixed(2), Colors.redAccent),
            _buildResultItem('Total Fees', '-${viewModel.totalFeesUsdt.toStringAsFixed(2)}', Colors.orangeAccent),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const SizedBox.shrink(),
            _buildResultItem('Net Earnings', viewModel.totalEarnings.toStringAsFixed(2), viewModel.totalEarnings >= 0 ? Colors.greenAccent : Colors.redAccent, isBold: true),
            const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value, Color color, {bool isBold = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value, 
              style: TextStyle(
                color: color, 
                fontSize: 14, 
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal
              )
            ),
          ),
        ],
      ),
    );
  }

  void _showAddConditionDialog(List<Condition> conditions) {
    ConditionType selectedType = ConditionType.indicator;
    String selectedIndicator = 'RSI';
    Operator selectedOp = Operator.lessThan;
    bool isComparingWithIndicator = false;
    String targetIndicator = 'EMA25';
    bool useLastClosedData = false;
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Add Condition', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Source', style: TextStyle(color: BinanceTheme.yellow, fontSize: 12)),
                DropdownButton<ConditionType>(
                  value: selectedType,
                  dropdownColor: Colors.grey[850],
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: ConditionType.values.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                if (selectedType == ConditionType.indicator)
                  DropdownButton<String>(
                    value: selectedIndicator,
                    dropdownColor: Colors.grey[850],
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: ['RSI', 'EMA7', 'EMA25', 'EMA99', 'UP', 'MB', 'DN', 'MACD', 'DIF', 'DEA'].map((name) {
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedIndicator = val!),
                  ),
                const SizedBox(height: 16),
                const Text('Operator', style: TextStyle(color: BinanceTheme.yellow, fontSize: 12)),
                DropdownButton<Operator>(
                  value: selectedOp,
                  dropdownColor: Colors.grey[850],
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: Operator.values.map((op) {
                    return DropdownMenuItem(value: op, child: Text(op.name.toUpperCase()));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedOp = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Compare with', style: TextStyle(color: BinanceTheme.yellow, fontSize: 12)),
                    Row(
                      children: [
                        const Text('Value', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Switch(
                          value: isComparingWithIndicator,
                          activeThumbColor: BinanceTheme.yellow,
                          activeTrackColor: BinanceTheme.yellow.withValues(alpha: 0.5),
                          onChanged: (val) => setDialogState(() => isComparingWithIndicator = val),
                        ),
                        const Text('Indicator', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                if (isComparingWithIndicator)
                  DropdownButton<String>(
                    value: targetIndicator,
                    dropdownColor: Colors.grey[850],
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: ['RSI', 'EMA7', 'EMA25', 'EMA99', 'UP', 'MB', 'DN', 'MACD', 'DIF', 'DEA'].map((name) {
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => targetIndicator = val!),
                  )
                else
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Constant Value',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Use Last Closed Candle', style: TextStyle(color: BinanceTheme.yellow, fontSize: 12)),
                    const Spacer(),
                    Switch(
                      value: useLastClosedData,
                      activeThumbColor: BinanceTheme.yellow,
                      activeTrackColor: BinanceTheme.yellow.withValues(alpha: 0.5),
                      onChanged: (val) => setDialogState(() => useLastClosedData = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                double value = 0;
                if (!isComparingWithIndicator) {
                  final parsed = double.tryParse(valueController.text);
                  if (parsed == null) return;
                  value = parsed;
                }

                setState(() {
                  conditions.add(Condition(
                    type: selectedType,
                    indicatorName: selectedType == ConditionType.indicator ? selectedIndicator : null,
                    op: selectedOp,
                    value: value,
                    targetType: isComparingWithIndicator ? ConditionType.indicator : ConditionType.price,
                    targetIndicatorName: isComparingWithIndicator ? targetIndicator : null,
                    useLastClosedData: useLastClosedData,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: BinanceTheme.yellow)),
            ),
          ],
        ),
      ),
    );
  }
}
