import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../core/theme.dart';

class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();
    final notifications = viewModel.notifications;

    if (notifications.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      right: 20,
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: notifications.reversed.map((item) {
            return _NotificationTile(
              key: ValueKey(item.id),
              item: item,
              onDismiss: () => viewModel.dismiss(item.id),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onDismiss;

  const _NotificationTile({
    super.key,
    required this.item,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;

    switch (item.type) {
      case NotificationType.success:
        iconColor = BinanceTheme.green;
        icon = Icons.check_circle_outline;
        break;
      case NotificationType.error:
        iconColor = BinanceTheme.red;
        icon = Icons.error_outline;
        break;
      case NotificationType.info:
        iconColor = BinanceTheme.yellow;
        icon = Icons.info_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BinanceTheme.surfaceColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(
                    Icons.close,
                    color: BinanceTheme.secondaryTextColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
