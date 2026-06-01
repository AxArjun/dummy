import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType notificationType,
    required String title,
    required String body,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    required bool isRead,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}
