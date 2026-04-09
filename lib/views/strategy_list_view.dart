import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/strategy_viewmodel.dart';
import '../models/strategy.dart';
import 'strategy_edit_view.dart';
import '../core/theme.dart';

class StrategyListView extends StatelessWidget {
  const StrategyListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(gradient: BinanceTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Consumer<StrategyViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator(color: BinanceTheme.yellow));
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
        backgroundColor: BinanceTheme.yellow,
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
          const Spacer(),
          Consumer<StrategyViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: viewModel.isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: BinanceTheme.yellow, strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: BinanceTheme.yellow),
                onPressed: viewModel.isLoading ? null : () => viewModel.refresh(),
              );
            },
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strategy.name,
                          style: const TextStyle(
                            color: BinanceTheme.yellow,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (strategy.lastResult != null)
                          Row(
                            children: [
                              _buildRatingStars(strategy.lastResult!.rating),
                              const SizedBox(width: 8),
                              Text(
                                'Success: ${((strategy.lastResult!.profitableTrades / (strategy.lastResult!.totalTrades > 0 ? strategy.lastResult!.totalTrades : 1)) * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'No evaluation yet',
                            style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, strategy, viewModel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (strategy.longEntry.conditions.isNotEmpty) ...[
                _buildPhaseSummary('Long Entry', strategy.longEntry.conditions),
                _buildProtectionSummary(strategy.longEntry),
                const SizedBox(height: 8),
              ],
              if (strategy.shortEntry.conditions.isNotEmpty) ...[
                _buildPhaseSummary('Short Entry', strategy.shortEntry.conditions),
                _buildProtectionSummary(strategy.shortEntry),
                const SizedBox(height: 8),
              ],
              _buildPhaseSummary('Long Exit', strategy.longExit.conditions),
              _buildPhaseSummary('Short Exit', strategy.shortExit.conditions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseSummary(String title, List<Condition> conditions) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Expanded(
          child: Text(
            conditions.isEmpty ? 'None' : conditions.map((c) => _conditionToString(c)).join(', '),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionSummary(EntrySettings entry) {
    if (!entry.useProtection) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Text(
        'Protection: TP ${entry.takeProfit}% | SL ${entry.stopLoss}%',
        style: const TextStyle(color: BinanceTheme.yellow, fontSize: 10),
      ),
    );
  }

  String _conditionToString(Condition c) {
    final opStr = _opToString(c.op);
    String leftSide = c.type == ConditionType.price ? 'Price' : c.indicatorName!;
    String rightSide = c.targetIndicatorName ?? c.value.toString();
    return '$leftSide $opStr $rightSide';
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

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: BinanceTheme.yellow,
          size: 12,
        );
      }),
    );
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
