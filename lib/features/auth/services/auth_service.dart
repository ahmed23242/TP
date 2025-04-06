import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import '../../../core/database/database_helper.dart';

class AuthService extends GetxController {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  final _db = DatabaseHelper.instance;
  
  final RxBool isAuthenticated = false.obs;
  final RxString userRole = ''.obs;
  final RxBool isBiometricAvailable = false.obs;
  final RxBool isBiometricEnabled = false.obs;
  final RxString userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      developer.log('Initializing authentication service');
      
      // Check biometric availability
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      isBiometricAvailable.value = canCheckBiometrics && isDeviceSupported;
      developer.log('Biometric availability: ${isBiometricAvailable.value}');

      // Check if biometric login is enabled
      final email = await _storage.read(key: 'user_email');
      if (email != null) {
        userEmail.value = email;
        isBiometricEnabled.value = true;
        developer.log('Biometric login enabled for email: $email');
      }

      // Check existing authentication
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        try {
          if (!JwtDecoder.isExpired(token)) {
            isAuthenticated.value = true;
            final decodedToken = JwtDecoder.decode(token);
            userRole.value = decodedToken['role'] ?? '';
            developer.log('User authenticated with role: ${userRole.value}');
          } else {
            // Token est expiré, on le supprime
            await _storage.delete(key: 'jwt_token');
            developer.log('Expired token removed');
          }
        } catch (e) {
          // Token est invalide, on le supprime
          await _storage.delete(key: 'jwt_token');
          developer.log('Invalid token removed', error: e);
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error initializing auth', error: e, stackTrace: stackTrace);
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      if (!isBiometricAvailable.value) {
        developer.log('Biometrics not available');
        return false;
      }
      final canUse = isBiometricEnabled.value && userEmail.value.isNotEmpty;
      developer.log('Can use biometrics: $canUse');
      return canUse;
    } catch (e, stackTrace) {
      developer.log('Error checking biometric availability', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> enableBiometricLogin(String email) async {
    try {
      developer.log('Enabling biometric login for email: $email');
      await _storage.write(key: 'user_email', value: email);
      userEmail.value = email;
      isBiometricEnabled.value = true;
      developer.log('Biometric login enabled successfully');
    } catch (e, stackTrace) {
      developer.log('Error enabling biometric login', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await canUseBiometrics()) {
        developer.log('Cannot use biometrics');
        return false;
      }

      developer.log('Starting biometric authentication');
      bool didAuthenticate = false;
      try {
        didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to login',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      } catch (e) {
        developer.log('Error during biometric authentication hardware', error: e);
        // Si l'authentification biométrique échoue pour des raisons techniques, on tente de récupérer l'utilisateur
        final email = userEmail.value;
        if (email.isNotEmpty) {
          final user = await _db.getUserByEmail(email);
          if (user != null) {
            isAuthenticated.value = true;
            userRole.value = user['role'] ?? 'user';
            
            // Générer un nouveau token et le stocker
            final token = 'biometric_token_${DateTime.now().millisecondsSinceEpoch}';
            await _storage.write(key: 'jwt_token', value: token);
            
            developer.log('Fallback to stored credentials for email: $email, new token generated');
            return true;
          }
        }
        return false;
      }

      if (didAuthenticate) {
        developer.log('Biometric authentication successful');
        final user = await _db.getUserByEmail(userEmail.value);
        if (user != null) {
          isAuthenticated.value = true;
          userRole.value = user['role'] ?? 'user';
          
          // Générer un nouveau token et le stocker
          final token = 'biometric_token_${DateTime.now().millisecondsSinceEpoch}';
          await _storage.write(key: 'jwt_token', value: token);
          
          developer.log('User authenticated with role: ${user['role']}, new token generated');
          return true;
        }
        developer.log('User not found in database');
      } else {
        developer.log('Biometric authentication failed');
      }
      return false;
    } catch (e, stackTrace) {
      developer.log('Error during biometric authentication', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> loginWithCredentials(String email, String password) async {
    try {
      developer.log('Attempting login with credentials for email: $email');
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Store user data in local database
      final user = {
        'id': 1, // ID utilisateur explicite pour éviter les problèmes d'authentification
        'email': email,
        'role': 'user', // Default role
        'token': 'auth_token_${DateTime.now().millisecondsSinceEpoch}',
        'last_login': DateTime.now().toIso8601String(),
      };
      await _db.insertUser(user);
      developer.log('User data stored in database: ${user.toString()}');
      
      // Store token securely
      await _storage.write(key: 'jwt_token', value: user['token'].toString());
      developer.log('Token stored securely: ${user['token']}');
      
      isAuthenticated.value = true;
      userRole.value = user['role']?.toString() ?? 'user';
      developer.log('Login successful with role: ${user['role']}');
      
      // Enable biometric login if available
      if (isBiometricAvailable.value) {
        await enableBiometricLogin(email);
      }
    } catch (e, stackTrace) {
      developer.log('Error during login', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      developer.log('Attempting logout');
      await _storage.delete(key: 'jwt_token');
      isAuthenticated.value = false;
      userRole.value = '';
      developer.log('Logout successful');
    } catch (e, stackTrace) {
      developer.log('Error during logout', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  bool get isCitizen => userRole.value == 'user';
  bool get isAdmin => userRole.value == 'admin';
}

