// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fuel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fuelNotifierHash() => r'fuel_notifier_hash';
String _$fuelLogsHash() => r'fuel_logs_hash';

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

/// See also [FuelNotifier].
@ProviderFor(FuelNotifier)
const fuelNotifierProvider = FuelNotifierFamily();

class FuelNotifierFamily extends Family<FuelState> {
  const FuelNotifierFamily();

  FuelNotifierProvider call(String vehicleId) {
    return FuelNotifierProvider(vehicleId);
  }

  @override
  FuelNotifierProvider getProviderOverride(
    covariant FuelNotifierProvider provider,
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
  String? get name => r'fuelNotifierProvider';
}

class FuelNotifierProvider
    extends AutoDisposeNotifierProviderImpl<FuelNotifier, FuelState> {
  FuelNotifierProvider(String vehicleId)
      : this._internal(
          () => FuelNotifier()..vehicleId = vehicleId,
          from: fuelNotifierProvider,
          name: r'fuelNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fuelNotifierHash,
          dependencies: FuelNotifierFamily._dependencies,
          allTransitiveDependencies:
              FuelNotifierFamily._allTransitiveDependencies,
          vehicleId: vehicleId,
        );

  FuelNotifierProvider._internal(
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
  FuelState runNotifierBuild(
    covariant FuelNotifier notifier,
  ) {
    return notifier.build(vehicleId);
  }

  @override
  Override overrideWithValue(FuelState value) {
    return $ProviderOverride(
      origin: this,
      override: $ValueProvider<FuelState>(value),
    );
  }

  @override
  (String,) get argument {
    return (vehicleId,);
  }

  @override
  AutoDisposeNotifierProviderElement<FuelNotifier, FuelState>
      createElement() {
    return _FuelNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FuelNotifierProvider && other.vehicleId == vehicleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, vehicleId.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin FuelNotifierRef
    on AutoDisposeNotifierProviderRef<FuelState> {
  String get vehicleId;
}

class _FuelNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<FuelNotifier, FuelState>
    with FuelNotifierRef {
  _FuelNotifierProviderElement(super.provider);

  @override
  String get vehicleId => (origin as FuelNotifierProvider).vehicleId;
}

/// See also [fuelLogs].
@ProviderFor(fuelLogs)
const fuelLogsProvider = FuelLogsFamily();

class FuelLogsFamily extends Family<List<FuelLog>> {
  const FuelLogsFamily();

  FuelLogsProvider call(String vehicleId) {
    return FuelLogsProvider(vehicleId);
  }

  @override
  FuelLogsProvider getProviderOverride(
    covariant FuelLogsProvider provider,
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
  String? get name => r'fuelLogsProvider';
}

class FuelLogsProvider extends AutoDisposeProvider<List<FuelLog>> {
  FuelLogsProvider(String vehicleId)
      : this._internal(
          (ref) => fuelLogs(ref as FuelLogsRef, vehicleId),
          from: fuelLogsProvider,
          name: r'fuelLogsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fuelLogsHash,
          dependencies: FuelLogsFamily._dependencies,
          allTransitiveDependencies:
              FuelLogsFamily._allTransitiveDependencies,
          vehicleId: vehicleId,
        );

  FuelLogsProvider._internal(
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
  Override overrideWithValue(List<FuelLog> value) {
    return $ProviderOverride(
      origin: this,
      override: $ValueProvider<List<FuelLog>>(value),
    );
  }

  @override
  (String,) get argument {
    return (vehicleId,);
  }

  @override
  AutoDisposeProviderElement<List<FuelLog>> createElement() {
    return _FuelLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FuelLogsProvider && other.vehicleId == vehicleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, vehicleId.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin FuelLogsRef on AutoDisposeProviderRef<List<FuelLog>> {
  String get vehicleId;
}

class _FuelLogsProviderElement
    extends AutoDisposeProviderElement<List<FuelLog>>
    with FuelLogsRef {
  _FuelLogsProviderElement(super.provider);

  @override
  String get vehicleId => (origin as FuelLogsProvider).vehicleId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
