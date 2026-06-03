// FuelIQ — Error Mapper
// Maps raw SDK/network exceptions to structured Failure types.

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:dio/dio.dart';

import 'failures.dart';

class ErrorMapper {
  const ErrorMapper._();

  static Failure map(Object error) {
    if (error is clerk.ClerkError) {
      return AuthFailure.fromClerkError(error);
    }
    if (error is DioException) {
      return _mapDioError(error);
    }
    if (error is Failure) {
      return error;
    }
    return AuthFailure(error.toString());
  }

  static Failure _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError) {
      return NetworkFailure.offline;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure.timeout;
    }
    final status = error.response?.statusCode;
    if (status != null && status >= 500) {
      return NetworkFailure.serverError;
    }
    if (status == 401) {
      return SessionFailure.expired;
    }
    return NetworkFailure(error.message ?? 'Network error. Please try again.');
  }
}
