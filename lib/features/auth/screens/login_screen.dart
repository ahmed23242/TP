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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo et titre
                  CustomAnimatedSwitcher(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'SecureAlert',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sécurité urbaine intelligente',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Formulaire
                  CustomAnimatedSwitcher(
                    child: Obx(() => _authController.isRegistering.value 
                      ? _buildRegisterForm() 
                      : _buildLoginForm()),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Message d'erreur
                  Obx(() => _authController.errorMessage.value.isNotEmpty
                    ? CustomAnimatedOpacity(
                        visible: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _authController.errorMessage.value,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton de connexion/inscription
                  Obx(() => CustomButton(
                    text: _authController.isRegistering.value ? 'Créer un compte' : 'Se connecter',
                    isLoading: _authController.isLoading.value,
                    onPressed: () => _authController.isRegistering.value 
                      ? _authController.register() 
                      : _authController.login(),
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Bouton de changement connexion/inscription
                  TextButton(
                    onPressed: () => _authController.toggleRegistration(),
                    child: Text(
                      _authController.isRegistering.value 
                        ? 'Déjà un compte ? Se connecter' 
                        : 'Pas de compte ? S\'inscrire',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Séparateur
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Bouton d'authentification biométrique
                  FutureBuilder<bool>(
                    future: _isBiometricLoginAvailable(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data == true) {
                        return CustomButton(
                          text: 'Se connecter avec la biométrie',
                          onPressed: () => _authController.tryBiometricLogin(),
                          backgroundColor: Colors.green.shade700,
                          prefixIcon: Icons.fingerprint,
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
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Mot de passe',
          controller: _authController.passwordController,
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
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
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Mot de passe',
          controller: _authController.passwordController,
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Téléphone',
          controller: _authController.phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
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
