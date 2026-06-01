// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'garage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$garageNotifierHash() => r'garage_notifier_hash';
String _$vehicleByIdHash() => r'vehicle_by_id_hash';

/// See also [GarageNotifier].
@ProviderFor(GarageNotifier)
final garageNotifierProvider =
    AutoDisposeNotifierProvider<GarageNotifier, GarageState>.internal(
  GarageNotifier.new,
  name: r'garageNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$garageNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GarageNotifier = AutoDisposeNotifier<GarageState>;

/// See also [vehicleById].
@ProviderFor(vehicleById)
const vehicleByIdProvider = VehicleByIdFamily();

class VehicleByIdFamily extends Family<Vehicle?> {
  const VehicleByIdFamily();

  VehicleByIdProvider call(String vehicleId) {
    return VehicleByIdProvider(vehicleId);
  }

  @override
  VehicleByIdProvider getProviderOverride(
    covariant VehicleByIdProvider provider,
  ) {
    return call(provider.vehicleId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'vehicleByIdProvider';
}

class VehicleByIdProvider extends AutoDisposeProvider<Vehicle?> {
  VehicleByIdProvider(String vehicleId)
      : this._internal(
          (ref) => vehicleById(ref as VehicleByIdRef, vehicleId),
          from: vehicleByIdProvider,
          name: r'vehicleByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vehicleByIdHash,
          dependencies: VehicleByIdFamily._dependencies,
          allTransitiveDependencies:
              VehicleByIdFamily._allTransitiveDependencies,
          vehicleId: vehicleId,
        );

  VehicleByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.vehicleId,
  }) : super.internal();

  final String vehicleId;

  @override
  Override overrideWithValue(Vehicle? value) {
    return $ProviderOverride(
      origin: this,
      override: $ValueProvider<Vehicle?>(value),
    );
  }

  @override
  (String,) get argument {
    return (vehicleId,);
  }

  @override
  AutoDisposeProviderElement<Vehicle?> createElement() {
    return _VehicleByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleByIdProvider && other.vehicleId == vehicleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, vehicleId.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin VehicleByIdRef on AutoDisposeProviderRef<Vehicle?> {
  String get vehicleId;
}

class _VehicleByIdProviderElement extends AutoDisposeProviderElement<Vehicle?>
    with VehicleByIdRef {
  _VehicleByIdProviderElement(super.provider);

  @override
  String get vehicleId => (origin as VehicleByIdProvider).vehicleId;
}

class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
