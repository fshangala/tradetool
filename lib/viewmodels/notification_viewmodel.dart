import 'package:flutter/material.dart';
import 'dart:async';

enum NotificationType { success, error, info }

class NotificationItem {
  final String id;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  NotificationItem({
    required this.id,
    required this.message,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationViewModel extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  void show(String message, {NotificationType type = NotificationType.info}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = NotificationItem(id: id, message: message, type: type);

    _notifications.add(item);
    notifyListeners();

    // Auto-dismiss after 5 seconds
    Timer(const Duration(seconds: 5), () {
      dismiss(id);
    });
  }

  void dismiss(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  void success(String message) => show(message, type: NotificationType.success);
  void error(String message) => show(message, type: NotificationType.error);
}
