import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String clerkId,
    required String email,
    String? displayName,
    String? avatarUrl,
    @Default(DistanceUnit.km) DistanceUnit distanceUnit,
    @Default(VolumeUnit.liters) VolumeUnit volumeUnit,
    @Default('INR') String currency,
    @Default('Asia/Kolkata') String timezone,
    required DateTime createdAt,
    
    // Profile-related settings merged
    @Default(true) bool darkMode,
    @Default(true) bool notifications,
    @Default(true) bool serviceAlerts,
    @Default(true) bool weeklyReports,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
