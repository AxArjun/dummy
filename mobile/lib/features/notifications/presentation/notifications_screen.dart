// FuelIQ — Notifications Screen
// App alerts and service reminders

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/models.dart';

// ─── Mock notifications provider ──────────────────────────────────────────────

final _mockNotifications = [
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

final notificationsStateProvider = StateNotifierProvider<NotificationsNotifier,
    List<AppNotification>>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(_mockNotifications);

  void markRead(String notificationId) {
    state = state.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }
      return n;
    }).toList();
  }

  void markAllRead() {
    state = state
        .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
  }

  void delete(String notificationId) {
    state = state.where((n) => n.id != notificationId).toList();
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);
  static const Color _success = Color(0xFF4CAF50);
  static const Color _warning = Color(0xFFFF9800);
  static const Color _danger = Color(0xFFF44336);

  IconData _notifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.serviceReminder:
        return Icons.build_circle_outlined;
      case NotificationType.serviceOverdue:
        return Icons.warning_amber_rounded;
      case NotificationType.weeklySummary:
        return Icons.bar_chart_rounded;
      case NotificationType.monthlyReport:
        return Icons.receipt_long_rounded;
      case NotificationType.anomalyAlert:
        return Icons.notification_important_outlined;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  Color _notifColor(NotificationType type) {
    switch (type) {
      case NotificationType.serviceReminder:
        return _warning;
      case NotificationType.serviceOverdue:
        return _danger;
      case NotificationType.weeklySummary:
        return _gold;
      case NotificationType.monthlyReport:
        return const Color(0xFF2196F3);
      case NotificationType.anomalyAlert:
        return _danger;
      case NotificationType.system:
        return _textSub;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsStateProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B0B0B),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => ref
                  .read(notificationsStateProvider.notifier)
                  .markAllRead(),
              child: const Text(
                'Mark All Read',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _gold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationCard(
                  notification: notif,
                  icon: _notifIcon(notif.notificationType),
                  color: _notifColor(notif.notificationType),
                  timeAgo: _timeAgo(notif.createdAt),
                  onTap: () => ref
                      .read(notificationsStateProvider.notifier)
                      .markRead(notif.id),
                  onDismiss: () => ref
                      .read(notificationsStateProvider.notifier)
                      .delete(notif.id),
                )
                    .animate()
                    .fadeIn(
                        delay: Duration(milliseconds: 60 * index),
                        duration: 400.ms)
                    .slideX(begin: 0.05, end: 0);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _card,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: _gold, size: 44),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 24),
            const Text(
              'All caught up',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            const Text(
              'No new notifications.\nWe\'ll alert you about service reminders\nand fuel insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: _textSub,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 350.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.color,
    required this.timeAgo,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final IconData icon;
  final Color color;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFF44336), size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? _card
                : _card.withBlue(_card.blue + 5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? _border
                  : color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8, top: 3),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: notification.isRead
                            ? _textSub
                            : _textPrimary.withOpacity(0.8),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: _textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
