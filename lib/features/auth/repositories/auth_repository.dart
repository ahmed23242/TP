import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:accidentsapp/features/auth/services/auth_service.dart';
import '../../../core/database/database_helper.dart';
import 'dart:developer' as developer;

class AuthRepository {
  final _authService = Get.find<AuthService>();
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      developer.log('Attempting login with credentials for email: $email');
      await _authService.loginWithCredentials(email, password);
      developer.log('Login successful');
      return true;
    } catch (e, stackTrace) {
      developer.log('Login failed', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> register(String email, String password, String phone) async {
    try {
      developer.log('Attempting registration for email: $email');
      // For now, we'll just login the user after registration
      await _authService.loginWithCredentials(email, password);
      developer.log('Registration successful');
      return true;
    } catch (e, stackTrace) {
      developer.log('Registration failed', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        developer.log('No token found');
        return false;
      }
      
      try {
        if (JwtDecoder.isExpired(token)) {
          developer.log('Token expired');
          await logout();
          return false;
        }
      } catch (e) {
        developer.log('Invalid token format', error: e);
        await logout();
        return false;
      }
      
      developer.log('User is authenticated');
      return true;
    } catch (e, stackTrace) {
      developer.log('Authentication check failed', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      developer.log('User logged out successfully');
    } catch (e, stackTrace) {
      developer.log('Logout failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      developer.log('Token retrieved: ${token != null ? 'exists' : 'null'}');
      return token;
    } catch (e, stackTrace) {
      developer.log('Failed to get token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      // D'abord, essayer de récupérer les données du token
      final token = await getToken();
      if (token != null) {
        try {
          final userData = JwtDecoder.decode(token);
          developer.log('User data retrieved from token: ${userData.toString()}');
          
          // Ajouter un ID utilisateur par défaut si manquant
          if (!userData.containsKey('id')) {
            userData['id'] = 1;
          }
          
          return userData;
        } catch (e) {
          developer.log('Failed to decode token, will try database', error: e);
          // Continuer à essayer avec la base de données
        }
      }
      
      // Si pas de token ou décodage échoué, essayer de récupérer depuis la base de données
      final email = _authService.userEmail.value;
      if (email.isNotEmpty) {
        // Utiliser direct DatabaseHelper qui est accessible
        final db = DatabaseHelper.instance;
        final user = await db.getUserByEmail(email);
        if (user != null) {
          developer.log('User data retrieved from database: ${user.toString()}');
          
          // Ajouter un ID utilisateur par défaut si manquant
          if (!user.containsKey('id')) {
            user['id'] = 1;
          }
          
          return user;
        }
      }
      
      // En dernier recours, créer des données utilisateur de base
      if (_authService.isAuthenticated.value) {
        final fallbackData = {
          'id': 1,
          'email': email,
          'role': _authService.userRole.value
        };
        developer.log('Created fallback user data: ${fallbackData.toString()}');
        return fallbackData;
      }
      
      developer.log('No user data found');
      return null;
    } catch (e, stackTrace) {
      developer.log('Failed to get user data', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
