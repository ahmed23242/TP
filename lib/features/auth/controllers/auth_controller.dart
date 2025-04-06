import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import 'dart:developer' as developer;

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final AuthService _authService = Get.find<AuthService>();
  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> userData = Rx<Map<String, dynamic>?>(null);
  final RxBool isCheckingAuth = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    if (isCheckingAuth.value) return;
    isCheckingAuth.value = true;
    
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        userData.value = await _authRepository.getUserData();
        Get.offAllNamed('/home');
      } else {
        // Check for biometric authentication possibility
        final canUseBiometric = await _authService.canUseBiometrics();
        if (canUseBiometric) {
          final success = await _authService.authenticateWithBiometrics();
          if (success) {
            userData.value = await _authRepository.getUserData();
            Get.offAllNamed('/home');
            return;
          }
        }
        if (Get.currentRoute != '/login') {
          Get.offAllNamed('/login');
        }
      }
    } finally {
      isCheckingAuth.value = false;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;
      await _authRepository.login(username, password);
      userData.value = await _authRepository.getUserData();
      
      // Enable biometric login for next time if available
      if (_authService.isBiometricAvailable.value) {
        await _authService.enableBiometricLogin(username);
      }
      
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to login. Please check your credentials.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithBiometrics() async {
    try {
      isLoading.value = true;
      final success = await _authService.authenticateWithBiometrics();
      if (success) {
        // Tenter de récupérer les données utilisateur du token
        userData.value = await _authRepository.getUserData();
        
        // Si les données ne sont pas disponibles via le token, créer des données utilisateur de base
        if (userData.value == null) {
          final email = _authService.userEmail.value;
          userData.value = {
            'id': 1, // ID utilisateur par défaut
            'email': email,
            'role': _authService.userRole.value
          };
          developer.log('Created basic user data for biometric auth: ${userData.value}');
        }
        
        Get.offAllNamed('/home');
      } else {
        Get.snackbar(
          'Error',
          'Biometric authentication failed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      developer.log('Error during biometric login', error: e);
      Get.snackbar(
        'Error',
        'Failed to login with biometrics: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String phone) async {
    try {
      isLoading.value = true;
      await _authRepository.register(email, password, phone);
      Get.snackbar(
        'Success',
        'Registration successful! Please login.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to register. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authRepository.logout();
      userData.value = null;
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool get isAdmin => userData.value?['role'] == 'admin';
}
