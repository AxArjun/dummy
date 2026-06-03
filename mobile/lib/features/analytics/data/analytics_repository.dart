import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/analytics_models.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository(this._dio);

  Future<VehicleAnalyticsSummary> getVehicleAnalytics(String vehicleId, {int months = 12}) async {
    try {
      final response = await _dio.get(
        '/vehicles/$vehicleId/analytics',
        queryParameters: {'months': months},
      );
      if (response.statusCode == 200) {
        return VehicleAnalyticsSummary.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch analytics');
    } on DioException catch (e) {
      debugPrint('[AnalyticsRepository] getVehicleAnalytics error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch analytics');
    }
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(dioProvider));
});
