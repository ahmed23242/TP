import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import '../../../core/database/database_helper.dart';
import 'package:flutter/services.dart';

class AuthService extends GetxController {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  final _db = DatabaseHelper.instance;
  
  final RxBool isAuthenticated = false.obs;
  final RxString userRole = ''.obs;
  final RxBool isBiometricAvailable = false.obs;
  final RxBool isBiometricEnabled = false.obs;
  final RxString userEmail = ''.obs;
  final RxBool isLoggedIn = false.obs;
  final Rx<int?> currentUserId = Rx<int?>(null);

  // Liste d'utilisateurs valides pour démonstration
  final List<Map<String, dynamic>> _validUsers = [
    {
      'id': 1,
      'email': 'user@example.com',
      'password': 'password123',
      'role': 'user',
    },
    {
      'id': 2,
      'email': 'admin@example.com',
      'password': 'admin123',
      'role': 'admin',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
    checkLoginStatus();
  }

  Future<void> _initializeAuth() async {
    try {
      developer.log('Initializing authentication service');
      
      // Check biometric availability with more detailed logging
      try {
        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        
        isBiometricAvailable.value = canCheckBiometrics && isDeviceSupported && availableBiometrics.isNotEmpty;
        
        // Vérifier si la biométrie est activée pour un compte
        final biometricEnabled = await _storage.read(key: 'biometric_enabled');
        isBiometricEnabled.value = biometricEnabled == 'true';
        
        developer.log('Biometric availability details:');
        developer.log('- Can check biometrics: $canCheckBiometrics');
        developer.log('- Device supported: $isDeviceSupported');
        developer.log('- Available biometrics: $availableBiometrics');
        developer.log('- Biometric enabled for account: ${isBiometricEnabled.value}');
        developer.log('- Final availability status: ${isBiometricAvailable.value}');
      } catch (e) {
        developer.log('Error checking biometrics during initialization', error: e);
        isBiometricAvailable.value = false;
      }

      // Check if biometric login is enabled
      final email = await _storage.read(key: 'user_email');
      if (email != null) {
        userEmail.value = email;
        developer.log('Email found for biometric login: $email');
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

  Future<void> checkLoginStatus() async {
    try {
      final userIdStr = await _storage.read(key: 'user_id');
      if (userIdStr != null) {
        final userId = int.parse(userIdStr);
        currentUserId.value = userId;
        isLoggedIn.value = true;
      }
    } catch (e) {
      developer.log('Error checking login status', error: e);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user != null && user['password'] == password) {
        await _storage.write(key: 'user_id', value: user['id'].toString());
        await _storage.write(key: 'user_email', value: email);
        userEmail.value = email;
        currentUserId.value = user['id'];
        isLoggedIn.value = true;
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error during login', error: e);
      return false;
    }
  }

  Future<bool> register(String email, String password, String phone) async {
    try {
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        return false; // User already exists
      }

      final userId = await _db.insertUser({
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'user',
        'token': 'auth_token_${DateTime.now().millisecondsSinceEpoch}',
        'last_login': DateTime.now().toIso8601String(),
      });

      if (userId > 0) {
        await _storage.write(key: 'user_id', value: userId.toString());
        currentUserId.value = userId;
        isLoggedIn.value = true;
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error during registration', error: e);
      return false;
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      // 1. Vérifier si le matériel est disponible
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      developer.log('Biometric hardware check - Can check: $canCheckBiometrics, Device supported: $isDeviceSupported');
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        developer.log('Hardware does not support biometrics');
        return false;
      }
      
      // 2. Vérifier les types de biométrie disponibles
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      developer.log('Available biometrics: $availableBiometrics');
      
      if (availableBiometrics.isEmpty) {
        developer.log('No biometrics enrolled on device');
        return false;
      }
      
      // Si nous arrivons ici, le matériel et au moins un type de biométrie sont disponibles
      // 3. Vérifier si l'utilisateur a déjà activé l'authentification biométrique
      final bioEnabled = isBiometricEnabled.value;
      final hasEmail = userEmail.value.isNotEmpty;
      
      developer.log('Biometric status - Enabled in app: $bioEnabled, Has email: $hasEmail');
      
      // Pour faciliter les tests en développement, considérons que la biométrie est utilisable 
      // si le matériel le supporte, même si l'utilisateur n'a pas encore activé la fonctionnalité
      final canUse = availableBiometrics.isNotEmpty;
      
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
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canCheckBiometrics || await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        developer.log('Device does not support biometric authentication');
        return false;
      }
      
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        developer.log('No biometrics enrolled on this device');
        return false;
      }
      
      // Vérifier si la biométrie a été activée pour un compte
      final biometricEnabled = await _storage.read(key: 'biometric_enabled');
      if (biometricEnabled != 'true') {
        developer.log('Biometric login not enabled for any account');
        return false;
      }
      
      developer.log('Available biometrics: $availableBiometrics');
      
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à l\'application',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (didAuthenticate) {
        // Récupérer l'ID et l'email associés à la biométrie
        final userIdStr = await _storage.read(key: 'biometric_user_id');
        final email = await _storage.read(key: 'biometric_user_email');
        
        if (userIdStr != null && email != null) {
          final userId = int.parse(userIdStr);
          
          // Mettre à jour les informations de connexion
          currentUserId.value = userId;
          userEmail.value = email;
          isLoggedIn.value = true;
          
          // Charger les données de l'utilisateur depuis la base de données
          final userData = await _db.getUserByEmail(email);
          if (userData != null) {
            userRole.value = userData['role'] as String? ?? 'user';
          }
          
          developer.log('Biometric authentication successful for user $email (ID: $userId)');
          return true;
        } else {
          developer.log('Biometric authentication successful but user data not found');
          return false;
        }
      }
      
      return false;
    } on PlatformException catch (e) {
      developer.log('Error during biometric authentication', error: e);
      return false;
    }
  }

  Future<void> loginWithCredentials(String email, String password) async {
    try {
      developer.log('Attempting login with credentials for email: $email');
      
      // 1. D'abord, vérifier dans la liste des utilisateurs prédéfinis
      final validUser = _validUsers.firstWhereOrNull(
        (user) => user['email'] == email && user['password'] == password
      );
      
      // 2. Si l'utilisateur est trouvé dans la liste prédéfinie
      if (validUser != null) {
        developer.log('User found in predefined list');
        
        // Simulate API call delay
        await Future.delayed(const Duration(seconds: 1));
        
        // Store user data in local database (or update if already exists)
        final user = {
          'id': validUser['id'], 
          'email': validUser['email'],
          'role': validUser['role'],
          'token': 'auth_token_${DateTime.now().millisecondsSinceEpoch}',
          'last_login': DateTime.now().toIso8601String(),
        };
        await _db.insertUser(user);
        developer.log('User data stored/updated in database: ${user.toString()}');
        
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
        
        return;
      }
      
      // 3. Si pas dans la liste prédéfinie, vérifier dans la base de données locale
      final dbUser = await _db.getUserByEmail(email);
      if (dbUser != null) {
        developer.log('User found in database, but passwords cannot be verified (stored hashed)');
        
        // Note: Dans une application réelle, les mots de passe seraient stockés
        // sous forme de hash et vérifiés de manière sécurisée.
        // Comme cette application est une démo, on lève une exception pour simplifier.
        
        // Si on voulait vérifier le mot de passe hashé (dans une vraie app):
        // final storedHash = dbUser['password_hash'];
        // final isValid = await _passwordHasher.verify(password, storedHash);
        // if (isValid) { ... }
      }
      
      // Si l'utilisateur n'est pas trouvé ou le mot de passe est incorrect
      throw Exception('Identifiants invalides');
      
    } catch (e, stackTrace) {
      developer.log('Error during login', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      developer.log('Attempting logout');
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'user_id');
      isAuthenticated.value = false;
      userRole.value = '';
      currentUserId.value = null;
      developer.log('Logout successful');
    } catch (e, stackTrace) {
      developer.log('Error during logout', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  bool get isCitizen => userRole.value == 'user';
  bool get isAdmin => userRole.value == 'admin';

  // Méthode publique pour obtenir des informations détaillées sur la biométrie
  Future<Map<String, dynamic>> getBiometricDetails() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return {
        'canCheckBiometrics': canCheckBiometrics,
        'isDeviceSupported': isDeviceSupported,
        'availableBiometrics': availableBiometrics,
        'isBiometricEnabled': isBiometricEnabled.value,
        'userEmail': userEmail.value,
      };
    } catch (e) {
      developer.log('Error getting biometric details', error: e);
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Méthode pour tester l'authentification biométrique sans effectuer de connexion
  Future<bool> testBiometricAuthentication() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        return false;
      }
      
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to test biometric functionality',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      developer.log('Error testing biometric authentication', error: e);
      return false;
    }
  }

  // Nouvelle méthode pour associer un compte avec la biométrie
  Future<bool> associateBiometricWithAccount() async {
    try {
      // Vérifier si la biométrie est disponible sur l'appareil
      if (!await canUseBiometrics()) {
        developer.log('Biometric authentication not available on this device');
        return false;
      }
      
      // Demander une authentification biométrique pour confirmer l'identité
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour activer la connexion par biométrie',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (didAuthenticate) {
        // L'utilisateur s'est authentifié avec la biométrie, activer la fonctionnalité
        final userId = currentUserId.value;
        final email = userEmail.value;
        
        if (userId == null || email.isEmpty) {
          developer.log('No user logged in to associate with biometrics');
          return false;
        }
        
        // Stocker les informations nécessaires pour les futures authentifications biométriques
        await _storage.write(key: 'biometric_enabled', value: 'true');
        await _storage.write(key: 'biometric_user_id', value: userId.toString());
        await _storage.write(key: 'biometric_user_email', value: email);
        
        isBiometricEnabled.value = true;
        
        developer.log('Successfully associated biometrics with user: $email (ID: $userId)');
        return true;
      } else {
        developer.log('User cancelled biometric authentication for association');
        return false;
      }
    } catch (e) {
      developer.log('Error associating biometrics with account', error: e);
      return false;
    }
  }

  // Méthode pour vérifier si la biométrie est activée
  Future<bool> checkBiometricEnabled() async {
    try {
      final biometricEnabled = await _storage.read(key: 'biometric_enabled');
      return biometricEnabled == 'true';
    } catch (e) {
      developer.log('Error checking if biometric is enabled', error: e);
      return false;
    }
  }
}

