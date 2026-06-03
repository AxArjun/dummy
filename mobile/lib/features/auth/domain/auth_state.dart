import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// Represents the exhaustive authentication states of the application.
@freezed
class AuthState with _$AuthState {
  const factory AuthState.loading() = _Loading;
  
  const factory AuthState.unauthenticated() = _Unauthenticated;
  
  /// Authenticated but email has not been verified yet.
  const factory AuthState.emailNotVerified() = _EmailNotVerified;
  
  /// Fully authenticated and verified.
  const factory AuthState.authenticated() = _Authenticated;
  
  /// An error occurred during an auth operation.
  const factory AuthState.error(String message) = _Error;
}
