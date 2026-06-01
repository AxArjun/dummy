import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';
import '../../data/notification_repository.dart';

final notificationsStateProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(() {
  return NotificationsNotifier();
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    return ref.read(notificationRepositoryProvider).getNotifications();
  }

  void markRead(String notificationId) {
    if (!state.hasValue) return;
    
    final current = state.valueOrNull ?? [];
    final updated = current.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }
      return n;
    }).toList();
    
    state = AsyncData(updated);
  }

  void markAllRead() {
    if (!state.hasValue) return;
    
    final current = state.valueOrNull ?? [];
    final updated = current
        .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
        
    state = AsyncData(updated);
  }

  void delete(String notificationId) {
    if (!state.hasValue) return;
    
    final current = state.valueOrNull ?? [];
    final updated = current.where((n) => n.id != notificationId).toList();
    
    state = AsyncData(updated);
  }
}
