import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/animations/custom_animations.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with animated gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Animated background shapes
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPainter(),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    
                    // Logo and title section
                    Center(
                      child: Column(
                        children: [
                          // Animated logo container
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                // Inner ring
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                // Icon
                                Icon(
                                  Icons.security,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // App name with custom styling
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.8),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'SecureAlert',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Subtitle with custom styling
                          Text(
                            'Protection intelligente',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Form container with glass effect
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Form content
                          CustomAnimatedSwitcher(
                            child: Obx(() => _authController.isRegistering.value 
                              ? _buildRegisterForm() 
                              : _buildLoginForm()),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Error message
                          Obx(() => _authController.errorMessage.value.isNotEmpty
                            ? CustomAnimatedOpacity(
                                visible: true,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _authController.errorMessage.value,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                          
                          const SizedBox(height: 24),
                          
                          // Login/Register button
                          Obx(() => CustomButton(
                            text: _authController.isRegistering.value 
                              ? 'Créer un compte' 
                              : 'Se connecter',
                            onPressed: () => _authController.isRegistering.value 
                              ? _authController.register() 
                              : _authController.login(),
                            isLoading: _authController.isLoading.value,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            textColor: Colors.white,
                            prefixIcon: _authController.isRegistering.value ? Icons.person_add : Icons.login,
                          )),
                          
                          const SizedBox(height: 16),
                          
                          // Toggle login/register
                          TextButton(
                            onPressed: () => _authController.toggleRegistration(),
                            child: Text(
                              _authController.isRegistering.value 
                                ? 'Déjà un compte ? Se connecter' 
                                : 'Pas de compte ? S\'inscrire',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Biometric login
                    FutureBuilder<bool>(
                      future: _isBiometricLoginAvailable(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Column(
                            children: [
                              const Text(
                                'ou',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Authentification biométrique',
                                onPressed: () => _authController.tryBiometricLogin(),
                                backgroundColor: Colors.white.withOpacity(0.1),
                                textColor: Colors.white,
                                prefixIcon: Icons.fingerprint,
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoginForm() {
    return Column(
      children: [
        CustomTextField(
          label: 'Email',
          controller: _authController.emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Mot de passe',
          controller: _authController.passwordController,
          obscureText: true,
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRegisterForm() {
    return Column(
      children: [
        CustomTextField(
          label: 'Email',
          controller: _authController.emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Mot de passe',
          controller: _authController.passwordController,
          obscureText: true,
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Téléphone',
          controller: _authController.phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icon(
            Icons.phone_outlined,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Future<bool> _isBiometricLoginAvailable() async {
    final canUse = await _authService.canUseBiometrics();
    final isEnabled = await _authService.checkBiometricEnabled();
    return canUse && isEnabled;
  }
}

// Custom painter for background shapes
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw circles
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      size.width * 0.2,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.8),
      size.width * 0.3,
      paint,
    );

    // Draw rectangles
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.6,
        size.width * 0.2,
        size.width * 0.2,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.7,
        size.height * 0.1,
        size.width * 0.2,
        size.width * 0.2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
