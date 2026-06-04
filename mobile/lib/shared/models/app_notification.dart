import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,

    @JsonKey(name: 'notification_type')
    required NotificationType notificationType,

    required String title,
    required String body,

    Map<String, dynamic>? metadata,

    @JsonKey(name: 'action_url')
    String? actionUrl,

    @JsonKey(name: 'is_read')
    required bool isRead,

    @JsonKey(name: 'read_at')
    DateTime? readAt,

    @JsonKey(name: 'created_at')
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$AppNotificationFromJson(json);
}