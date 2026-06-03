// FuelIQ — Auth Repository (Production)
// Syncs Firebase user identity with the FuelIQ backend (PostgreSQL via FastAPI).
// Called after successful Firebase authentication to create/update the app user.

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

// ─── Models ────────────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String clerkUserId; // Historically named clerk_id, now holds firebase_uid
  final String email;
  final String? name;
  final String? avatarUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.clerkUserId,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      clerkUserId: json['clerk_id'] as String,
      email: json['email'] as String,
      name: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  final Dio _dio;

  const AuthRepository(this._dio);

  /// Creates or updates the app user in our backend after Firebase auth succeeds.
  /// This is a "upsert" — safe to call on every sign-in.
  Future<AppUser?> syncUser(firebase.User firebaseUser) async {
    try {
      final response = await _dio.post(
        '/auth/sync-user',
        data: {
          'firebase_uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'display_name': firebaseUser.displayName,
          'avatar_url': firebaseUser.photoURL,
        },
        options: Options(extra: {'skipAuth': false}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AppUser.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[AuthRepository] syncUser DioException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[AuthRepository] syncUser error: $e');
      return null;
    }
  }

  /// Fetches the current user's profile from our backend.
  Future<AppUser?> getProfile() async {
    try {
      final response = await _dio.get('/users/me');
      if (response.statusCode == 200) {
        return AppUser.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[AuthRepository] getProfile error: ${e.message}');
      return null;
    }
  }

  /// Logs the user out from the backend to invalidate cache
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      debugPrint('[AuthRepository] logout error: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
