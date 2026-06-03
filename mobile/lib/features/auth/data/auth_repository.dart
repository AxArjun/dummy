// FuelIQ — Auth Repository (Production)
// Syncs Clerk user identity with the FuelIQ backend (PostgreSQL via FastAPI).
// Called after successful Clerk authentication to create/update the app user.

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ─── Models ────────────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String clerkUserId;
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
      clerkUserId: json['clerk_user_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory AppUser.fromClerkUser(clerk.User user) {
    // emailAddresses is List<EmailAddress>? in clerk_auth 0.0.14-beta
    final emailList = user.emailAddresses;
    String email = '';
    if (emailList != null && emailList.isNotEmpty) {
      email = emailList.first.emailAddress ?? '';
    }

    final nameParts = <String>[];
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      nameParts.add(user.firstName!);
    }
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      nameParts.add(user.lastName!);
    }

    return AppUser(
      id: user.id,
      clerkUserId: user.id,
      email: email,
      name: nameParts.isEmpty ? null : nameParts.join(' '),
      avatarUrl: user.imageUrl,
      createdAt: DateTime.now(), // clerk.User.createdAt type varies by version
    );
  }
}

// ─── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  final Dio _dio;

  const AuthRepository(this._dio);

  /// Creates or updates the app user in our backend after Clerk auth succeeds.
  /// This is a "upsert" — safe to call on every sign-in.
  Future<AppUser?> syncUser(clerk.User clerkUser) async {
    try {
      final emailList = clerkUser.emailAddresses;
      String email = '';
      if (emailList != null && emailList.isNotEmpty) {
        email = emailList.first.emailAddress ?? '';
      }

      final nameParts = <String>[];
      if (clerkUser.firstName != null && clerkUser.firstName!.isNotEmpty) {
        nameParts.add(clerkUser.firstName!);
      }
      if (clerkUser.lastName != null && clerkUser.lastName!.isNotEmpty) {
        nameParts.add(clerkUser.lastName!);
      }

      final response = await _dio.post(
        '/auth/sync',
        data: {
          'clerk_user_id': clerkUser.id,
          'email': email,
          'name': nameParts.join(' ').trim(),
          'avatar_url': clerkUser.imageUrl,
        },
        options: Options(extra: {'skipAuth': false}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AppUser.fromJson(response.data as Map<String, dynamic>);
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
      final response = await _dio.get('/auth/profile');
      if (response.statusCode == 200) {
        return AppUser.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[AuthRepository] getProfile error: ${e.message}');
      return null;
    }
  }

  /// Deletes the current user's account from our backend.
  Future<bool> deleteAccount() async {
    try {
      final response = await _dio.delete('/auth/account');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      debugPrint('[AuthRepository] deleteAccount error: ${e.message}');
      throw Exception('Failed to delete account: ${e.message}');
    }
  }
}
