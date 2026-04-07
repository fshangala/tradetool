import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../viewmodels/trades_viewmodel.dart';
import '../models/trade.dart';
import '../core/theme.dart';

class TradesView extends StatelessWidget {
  const TradesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Trade History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TradesViewModel>().fetchTrades(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Consumer<TradesViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.trades.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: BinanceTheme.yellow));
            }

            if (viewModel.trades.isEmpty) {
              return const Center(
                child: Text(
                  'No trades found',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, bottom: 20),
              itemCount: viewModel.trades.length,
              itemBuilder: (context, index) {
                final trade = viewModel.trades[index];
                return _TradeListTile(trade: trade);
              },
            );
          },
        ),
      ),
    );
  }
}

class _TradeListTile extends StatelessWidget {
  final Trade trade;

  const _TradeListTile({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.side == 'BUY';
    final color = isBuy ? Colors.greenAccent : Colors.redAccent;
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              trade.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                trade.side,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            Text(
              '${trade.realizedPnl} USDT',
              style: TextStyle(
                color: double.parse(trade.realizedPnl) >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Price: ${trade.price}', style: const TextStyle(color: Colors.white70)),
                Text('Qty: ${trade.qty}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeFormat.format(trade.dateTime),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        onTap: () => _showTradeDetails(context, trade),
      ),
    );
  }

  void _showTradeDetails(BuildContext context, Trade trade) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Trade Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: BinanceTheme.yellow,
                ),
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'Symbol', value: trade.symbol),
              _DetailRow(label: 'Side', value: trade.side, valueColor: trade.side == 'BUY' ? Colors.green : Colors.red),
              _DetailRow(label: 'Position Side', value: trade.positionSide),
              _DetailRow(label: 'Price', value: '${trade.price} USDT'),
              _DetailRow(label: 'Quantity', value: trade.qty),
              _DetailRow(label: 'Quote Quantity', value: '${trade.quoteQty} USDT'),
              _DetailRow(label: 'Commission', value: '${trade.commission} ${trade.commissionAsset}'),
              _DetailRow(
                label: 'Realized PnL',
                value: '${trade.realizedPnl} USDT',
                valueColor: double.parse(trade.realizedPnl) >= 0 ? Colors.green : Colors.red,
              ),
              _DetailRow(label: 'Trade ID', value: trade.id.toString()),
              _DetailRow(label: 'Order ID', value: trade.orderId.toString()),
              _DetailRow(label: 'Time', value: DateFormat('yyyy-MM-dd HH:mm:ss').format(trade.dateTime)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BinanceTheme.yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleAfter(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedRectangleAfter extends OutlinedBorder {
  final BorderRadiusGeometry borderRadius;

  const RoundedRectangleAfter({
    this.borderRadius = BorderRadius.zero,
    super.side,
  });

  @override
  OutlinedBorder copyWith({BorderSide? side, BorderRadiusGeometry? borderRadius}) {
    return RoundedRectangleAfter(
      borderRadius: borderRadius ?? this.borderRadius,
      side: side ?? this.side,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {ui.TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {ui.TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  void paint(Canvas canvas, Rect rect, {ui.TextDirection? textDirection}) {
    if (rect.isEmpty) return;
    final RRect outer = borderRadius.resolve(textDirection).toRRect(rect);
    canvas.drawRRect(outer, side.toPaint());
  }

  @override
  ShapeBorder scale(double t) {
    return RoundedRectangleAfter(
      borderRadius: borderRadius * t,
      side: side.scale(t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is RoundedRectangleAfter && other.side == side && other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(side, borderRadius);
}
