import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'service_record.freezed.dart';
part 'service_record.g.dart';

@freezed
class ServiceRecord with _$ServiceRecord {
  const factory ServiceRecord({
    required String id,
    required String vehicleId,
    required ServiceType serviceType,
    required DateTime serviceDate,
    double? odometerReading,
    double? cost,
    required String currency,
    String? shopName,
    String? description,
    List<Map<String, String>>? partsReplaced,
    String? receiptUrl,
    required DateTime createdAt,
  }) = _ServiceRecord;

  factory ServiceRecord.fromJson(Map<String, dynamic> json) => _$ServiceRecordFromJson(json);
}
