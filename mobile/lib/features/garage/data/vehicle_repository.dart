import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared/models/models.dart';
import '../../../../core/network/dio_client.dart';

class VehicleRepository {
  final Dio _dio;

  VehicleRepository(this._dio);

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _dio.get('/vehicles');
      if (response.statusCode == 200) {
        final dataNode = response.data['data'];
        final List<dynamic> data = (dataNode is List) ? dataNode : (dataNode['items'] ?? []);
        return data.map((json) => Vehicle.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[VehicleRepository] getVehicles error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch vehicles');
    }
  }

  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    try {
      final response = await _dio.post(
        '/vehicles',
        data: vehicle.toJson()
          ..remove('id')
          ..remove('created_at')
          ..remove('total_distance_km')
          ..remove('total_fuel_cost')
          ..remove('avg_efficiency_lper100km')
          ..remove('current_odometer')
          ..remove('photo_url')
          ..remove('is_archived'),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Vehicle.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to add vehicle');
    } on DioException catch (e) {
      debugPrint('[VehicleRepository] addVehicle error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to add vehicle');
    }
  }

  Future<Vehicle> updateVehicle(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        '/vehicles/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return Vehicle.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to update vehicle');
    } on DioException catch (e) {
      debugPrint('[VehicleRepository] updateVehicle error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to update vehicle');
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      final response = await _dio.delete('/vehicles/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete vehicle');
      }
    } on DioException catch (e) {
      debugPrint('[VehicleRepository] deleteVehicle error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to delete vehicle');
    }
  }
}

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(ref.watch(dioProvider));
});
