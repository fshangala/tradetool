import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/strategy_viewmodel.dart';
import '../models/strategy.dart';
import 'strategy_edit_view.dart';

class StrategyListView extends StatelessWidget {
  const StrategyListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.blueGrey.withValues(alpha: 0.2),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Consumer<StrategyViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (viewModel.strategies.isEmpty) {
                      return const Center(
                        child: Text(
                          'No strategies found. Add one to get started.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.strategies.length,
                      itemBuilder: (context, index) {
                        final strategy = viewModel.strategies[index];
                        return _buildStrategyCard(context, strategy, viewModel);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF0B90B),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StrategyEditView(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Trading Strategies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(BuildContext context, Strategy strategy, StrategyViewModel viewModel) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StrategyEditView(strategy: strategy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strategy.name,
                    style: const TextStyle(
                      color: Color(0xFFF0B90B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, strategy, viewModel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPhaseSummary('Entry', strategy.entryPhase),
              const SizedBox(height: 4),
              _buildProtectionSummary(strategy.protectionPhase),
              const SizedBox(height: 4),
              _buildPhaseSummary('Exit', strategy.exitPhase),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseSummary(String title, StrategyPhase phase) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            phase.conditions.map((c) => _conditionToString(c)).join(', '),
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionSummary(ProtectionSettings protection) {
    return Row(
      children: [
        const Text(
          'Protection: ',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        Text(
          'TP: ${protection.takeProfitPercentage}% | SL: ${protection.stopLossPercentage}%',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  String _conditionToString(Condition c) {
    if (c.type == ConditionType.price) {
      return 'Price ${_opToString(c.op)} ${c.value}';
    } else {
      return '${c.indicatorName} ${_opToString(c.op)} ${c.value}';
    }
  }

  String _opToString(Operator op) {
    switch (op) {
      case Operator.greaterThan: return '>';
      case Operator.lessThan: return '<';
      case Operator.equal: return '==';
      case Operator.crossesAbove: return '↑';
      case Operator.crossesBelow: return '↓';
    }
  }

  void _confirmDelete(BuildContext context, Strategy strategy, StrategyViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Strategy', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${strategy.name}"?', 
          style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteStrategy(strategy.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
