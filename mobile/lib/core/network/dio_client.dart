// FuelIQ — Dio HTTP Client + Interceptors
// Production network layer with token refresh, retry, and logging

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/token_storage.dart';

const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1', // Android emulator → localhost
);
const _kConnectTimeout = Duration(seconds: 15);
const _kReceiveTimeout = Duration(seconds: 30);

/// Provider for the main Dio instance
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  return _buildDio(tokenStorage);
});

Dio _buildDio(TokenStorage tokenStorage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: _kConnectTimeout,
      receiveTimeout: _kReceiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '1.0.0',
        'X-Platform': 'android',
      },
    ),
  );

  // Add interceptors (order matters — outermost first)
  dio.interceptors.addAll([
    AuthInterceptor(tokenStorage, dio),
    RetryInterceptor(dio),
    ErrorInterceptor(),
    if (const bool.fromEnvironment('dart.vm.product') == false)
      LoggingInterceptor(),
  ]);

  return dio;
}

// ─── Auth Interceptor ─────────────────────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;

  AuthInterceptor(this._tokenStorage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Inject request ID for tracing
    options.headers['X-Request-ID'] = _generateRequestId();
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired — attempt refresh via Clerk
      try {
        final newToken = await _tokenStorage.refreshToken();
        if (newToken != null) {
          // Retry the original request
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh failed — force re-login
        await _tokenStorage.clearTokens();
      }
    }
    handler.next(err);
  }

  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// ─── Retry Interceptor ────────────────────────────────────────────────────────

class RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    // Only retry on network errors or 5xx (not client errors)
    final shouldRetry = _shouldRetry(err) && retryCount < _maxRetries;

    if (shouldRetry) {
      await Future.delayed(_retryDelay * (retryCount + 1)); // Exponential backoff

      err.requestOptions.extra['retryCount'] = retryCount + 1;

      try {
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}

// ─── Error Interceptor ────────────────────────────────────────────────────────

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiError = ApiException.fromDioError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiError,
      ),
    );
  }
}

// ─── Logging Interceptor (Dev Only) ──────────────────────────────────────────

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrintSynchronously('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrintSynchronously('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrintSynchronously('✗ ${err.response?.statusCode} ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}

// ─── API Exception ────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final String? field;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.field,
  });

  factory ApiException.fromDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    
    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        code: 'NETWORK_ERROR',
        message: 'No internet connection. Please check your network.',
      );
    }
    
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        code: 'TIMEOUT',
        message: 'Request timed out. Please try again.',
      );
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['errors'] is List) {
      final firstError = (data['errors'] as List).first;
      return ApiException(
        code: firstError['code'] ?? 'UNKNOWN',
        message: firstError['message'] ?? 'An error occurred',
        statusCode: statusCode,
        field: firstError['field'],
      );
    }

    return ApiException(
      code: 'HTTP_$statusCode',
      message: _defaultMessage(statusCode),
      statusCode: statusCode,
    );
  }

  static String _defaultMessage(int? code) {
    return switch (code) {
      400 => 'Invalid request',
      401 => 'Authentication required',
      403 => 'Access denied',
      404 => 'Resource not found',
      409 => 'Conflict — resource already exists',
      422 => 'Validation failed',
      429 => 'Too many requests. Please slow down.',
      500 => 'Server error. Please try again.',
      _ => 'Something went wrong',
    };
  }

  @override
  String toString() => 'ApiException($code): $message';
}

void debugPrintSynchronously(String message) {
  // ignore: avoid_print
  print(message);
}
