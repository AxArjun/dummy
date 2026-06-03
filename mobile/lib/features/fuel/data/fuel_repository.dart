import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/network/dio_client.dart';

class FuelRepository {
  final Dio _dio;

  FuelRepository(this._dio);

  Future<List<FuelLog>> getLogs(String vehicleId) async {
    try {
      final response = await _dio.get('/vehicles/$vehicleId/fuel-logs');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['items'] ?? response.data['data'];
        return data.map((json) => FuelLog.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[FuelRepository] getLogs error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch fuel logs');
    }
  }

  Future<FuelLog> addLog(FuelLog log) async {
    try {
      final response = await _dio.post(
        '/vehicles/${log.vehicleId}/fuel-logs',
        data: {
          'odometer_reading': log.odometerReading,
          'volume_liters': log.volumeLiters,
          'price_per_liter': log.pricePerLiter,
          'is_full_tank': log.isFullTank,
          'station_name': log.stationName,
          'logged_via': log.loggedVia,
          'filled_at': log.filledAt.toIso8601String(),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return FuelLog.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to add fuel log');
    } on DioException catch (e) {
      debugPrint('[FuelRepository] addLog error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to add fuel log');
    }
  }
}

final fuelRepositoryProvider = Provider<FuelRepository>((ref) {
  return FuelRepository(ref.watch(dioProvider));
});
