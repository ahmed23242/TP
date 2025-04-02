import 'package:local_auth/local_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:get/get.dart';
import '../../../core/database/database_helper.dart';

class AuthService extends GetxController {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  final RxBool isAuthenticated = false.obs;
  final RxString userRole = ''.obs;
  
  // JWT Authentication
  Future<bool> loginWithCredentials(String email, String password) async {
    try {
      // TODO: Implement API call to backend for JWT token
      // This is a placeholder for the actual API call
      String token = 'dummy_token';
      
      // Decode token to get user info
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      // Store user info in local database
      await _dbHelper.insertUser({
        'email': email,
        'role': decodedToken['role'],
        'token': token,
      });
      
      isAuthenticated.value = true;
      userRole.value = decodedToken['role'];
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  // Biometric Authentication
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      if (!canAuthenticateWithBiometrics) {
        return false;
      }

      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
          
      if (availableBiometrics.isEmpty) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      isAuthenticated.value = didAuthenticate;
      return didAuthenticate;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    isAuthenticated.value = false;
    userRole.value = '';
    // TODO: Implement cleanup of stored credentials
  }
  
  bool get isCitizen => userRole.value == 'citizen';
  bool get isAdmin => userRole.value == 'admin';
}
