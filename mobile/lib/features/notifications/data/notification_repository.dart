import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

class NotificationRepository {
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      AppNotification(
        id: 'n001',
        notificationType: NotificationType.serviceReminder,
        title: 'Oil Change Due',
        body:
            'Your BMW 3 Series is due for an oil change. Last service was 5,000 km ago.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n002',
        notificationType: NotificationType.weeklySummary,
        title: 'Weekly Fuel Summary',
        body:
            'You spent ₹4,845 on fuel this week across 512 km. Efficiency: 8.9 L/100km.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: 'n003',
        notificationType: NotificationType.anomalyAlert,
        title: 'Efficiency Drop Detected',
        body:
            'Your fuel efficiency dropped by 15% in the last fill-up. Consider checking tyre pressure.',
        isRead: true,
        readAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      AppNotification(
        id: 'n004',
        notificationType: NotificationType.monthlyReport,
        title: 'May 2026 Report Ready',
        body:
            'Your monthly report for May 2026 is ready. Total spend: ₹12,442 across 3 fill-ups.',
        isRead: true,
        readAt: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      AppNotification(
        id: 'n005',
        notificationType: NotificationType.system,
        title: 'Welcome to FuelIQ',
        body:
            'Start tracking your vehicle\'s fuel consumption to get personalized insights.',
        isRead: true,
        readAt: DateTime.now().subtract(const Duration(days: 7)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
}
