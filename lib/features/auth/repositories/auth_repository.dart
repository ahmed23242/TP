import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiClient.login(username, password);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      await _apiClient.register(userData);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return false;
      
      bool hasExpired = JwtDecoder.isExpired(token);
      return !hasExpired;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }
}
