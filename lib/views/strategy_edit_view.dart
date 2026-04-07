import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/strategy.dart';
import '../viewmodels/strategy_viewmodel.dart';

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
  late List<Condition> _entryConditions;
  late List<Condition> _exitConditions;
  late double _walletPercentage;
  late double _takeProfit;
  late double _stopLoss;

  @override
  void initState() {
    super.initState();
    final s = widget.strategy;
    _id = s?.id ?? const Uuid().v4();
    _nameController = TextEditingController(text: s?.name ?? '');
    _entryConditions = List.from(s?.entryPhase.conditions ?? []);
    _exitConditions = List.from(s?.exitPhase.conditions ?? []);
    _walletPercentage = s?.walletPercentage ?? 40.0;
    _takeProfit = s?.protectionPhase.takeProfitPercentage ?? 1.0;
    _stopLoss = s?.protectionPhase.stopLossPercentage ?? 1.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_entryConditions.isEmpty || _exitConditions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Both Entry and Exit phases must have at least one condition.')),
        );
        return;
      }

      final strategy = Strategy(
        id: _id,
        name: _nameController.text,
        walletPercentage: _walletPercentage,
        entryPhase: StrategyPhase(conditions: _entryConditions),
        protectionPhase: ProtectionSettings(
          takeProfitPercentage: _takeProfit,
          stopLossPercentage: _stopLoss,
        ),
        exitPhase: StrategyPhase(conditions: _exitConditions),
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
            icon: const Icon(Icons.check, color: Color(0xFFF0B90B)),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 24),
            _buildPhaseSection('Entry Phase (Buy/Long)', _entryConditions),
            const SizedBox(height: 24),
            _buildProtectionSection(),
            const SizedBox(height: 24),
            _buildPhaseSection('Exit Phase (Sell/Close)', _exitConditions),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFF0B90B),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhaseSection(String title, List<Condition> conditions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        ...conditions.asMap().entries.map((entry) {
          final index = entry.key;
          final condition = entry.value;
          return Card(
            color: Colors.white.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                _conditionToString(condition),
                style: const TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                onPressed: () => setState(() => conditions.removeAt(index)),
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => _showAddConditionDialog(conditions),
          icon: const Icon(Icons.add, color: Color(0xFFF0B90B)),
          label: const Text('Add Condition', style: TextStyle(color: Color(0xFFF0B90B))),
        ),
      ],
    );
  }

  Widget _buildProtectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Protection Settings'),
        Row(
          children: [
            Expanded(
              child: _buildNumberInput(
                'Take Profit (%)',
                _takeProfit,
                (val) => setState(() => _takeProfit = val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberInput(
                'Stop Loss (%)',
                _stopLoss,
                (val) => setState(() => _stopLoss = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberInput(String label, double value, Function(double) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
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
    return '$leftSide $opStr $rightSide';
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

  void _showAddConditionDialog(List<Condition> conditions) {
    ConditionType selectedType = ConditionType.indicator;
    String selectedIndicator = 'RSI';
    Operator selectedOp = Operator.lessThan;
    
    // Comparison target state
    bool isComparingWithIndicator = false;
    String targetIndicator = 'EMA25';
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
                const Text('Source', style: TextStyle(color: Color(0xFFF0B90B), fontSize: 12)),
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
                    items: ['RSI', 'EMA7', 'EMA25', 'EMA99'].map((name) {
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedIndicator = val!),
                  ),
                const SizedBox(height: 16),
                const Text('Operator', style: TextStyle(color: Color(0xFFF0B90B), fontSize: 12)),
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
                    const Text('Compare with', style: TextStyle(color: Color(0xFFF0B90B), fontSize: 12)),
                    Row(
                      children: [
                        const Text('Value', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Switch(
                          value: isComparingWithIndicator,
                          activeThumbColor: const Color(0xFFF0B90B),
                          activeTrackColor: const Color(0xFFF0B90B).withValues(alpha: 0.5),
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
                    items: ['RSI', 'EMA7', 'EMA25', 'EMA99'].map((name) {
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
                    targetType: isComparingWithIndicator ? ConditionType.indicator : ConditionType.price, // value is just a constant
                    targetIndicatorName: isComparingWithIndicator ? targetIndicator : null,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: Color(0xFFF0B90B))),
            ),
          ],
        ),
      ),
    );
  }
}
