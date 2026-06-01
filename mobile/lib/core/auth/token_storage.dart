import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

class TokenStorage {
  final FlutterSecureStorage _storage;
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  TokenStorage(this._storage);

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
  
  Future<String?> refreshToken() async {
    // This is a placeholder since Clerk handles refresh.
    // If needed, we can implement custom refresh logic here.
    return null;
  }
}
