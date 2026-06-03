import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/network/dio_client.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository(ref.watch(dioProvider)));

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['items'] ?? response.data['data'];
        return data.map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[NotificationRepository] getNotifications error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch notifications');
    }
  }
}
