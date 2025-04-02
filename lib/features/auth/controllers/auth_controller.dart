import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> userData = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final isAuth = await _authRepository.isAuthenticated();
    if (isAuth) {
      userData.value = await _authRepository.getUserData();
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
    }
  }

  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;
      await _authRepository.login(username, password);
      userData.value = await _authRepository.getUserData();
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

  Future<void> register(Map<String, dynamic> userData) async {
    try {
      isLoading.value = true;
      await _authRepository.register(userData);
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
    await _authRepository.logout();
    userData.value = null;
    Get.offAllNamed('/login');
  }

  bool get isAdmin => userData.value?['role'] == 'admin';
}
