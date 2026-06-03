// FuelIQ — Dio HTTP Client + Interceptors (Production)
// Fixed: AuthInterceptor now uses Firebase ID tokens via Riverpod Ref.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1', // Android emulator → localhost
);
const _kConnectTimeout = Duration(seconds: 15);
const _kReceiveTimeout = Duration(seconds: 30);

/// Provider for the main Dio instance.
/// AuthInterceptor receives a token-getter closure backed by the Firebase session.
final dioProvider = Provider<Dio>((ref) {
  return _buildDio(
    getToken: (bool forceRefresh) async {
      final user = ref.read(currentUserProvider);
      return await user?.getIdToken(forceRefresh);
    },
  );
});

Dio _buildDio({required Future<String?> Function(bool forceRefresh) getToken}) {
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
    AuthInterceptor(getToken, dio),
    RetryInterceptor(dio),
    ErrorInterceptor(),
    if (!kReleaseMode) LoggingInterceptor(),
  ]);

  return dio;
}

// ─── Auth Interceptor ─────────────────────────────────────────────────────────

/// Attaches the Firebase session JWT to every outbound request.
/// On 401, retrieves a fresh token and retries once.
class AuthInterceptor extends Interceptor {
  final Future<String?> Function(bool forceRefresh) _getToken;
  final Dio _dio;

  AuthInterceptor(this._getToken, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Allow individual requests to opt out of auth
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    // Fetch the live Firebase session token (cached internally by Firebase until expiry)
    final token = await _getToken(false);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Inject request ID for backend tracing / log correlation
    options.headers['X-Request-ID'] = _generateRequestId();

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && err.requestOptions.extra['_retry'] != true) {
      // Session may have expired between requests. Force refresh token from Firebase.
      try {
        final newToken = await _getToken(true);
        if (newToken != null) {
          final options = err.requestOptions;
          options.extra['_retry'] = true;
          options.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (_) {
        // Fresh token fetch failed — session is truly expired.
        // Router will redirect to /login via AuthUnauthenticated state.
      }
    }
    handler.next(err);
  }

  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36);
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
    final shouldRetry = _shouldRetry(err) && retryCount < _maxRetries;

    if (shouldRetry) {
      await Future.delayed(_retryDelay * (retryCount + 1));
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
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
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

// ─── Logging Interceptor (Dev Only) ───────────────────────────────────────────

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
        '✗ ${err.response?.statusCode} ${err.requestOptions.uri}: ${err.message}');
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
        code: firstError['code'] as String? ?? 'UNKNOWN',
        message: firstError['message'] as String? ?? 'An error occurred',
        statusCode: statusCode,
        field: firstError['field'] as String?,
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
