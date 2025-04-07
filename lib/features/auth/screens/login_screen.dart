import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const SizedBox(height: 30),
                
                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                      size: 80,
                        color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                      Text(
                      'Urban Incidents',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Signaler des incidents urbains',
                        style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                ),
                
                const SizedBox(height: 40),
                
                // Formulaire
                Obx(() => _authController.isRegistering.value 
                  ? _buildRegisterForm() 
                  : _buildLoginForm()),
                
                const SizedBox(height: 20),
                
                // Erreur
                Obx(() => _authController.errorMessage.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        _authController.errorMessage.value,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                            ),
                          )
                        : const SizedBox.shrink()),
                
                // Bouton de connexion/inscription
                Obx(() => CustomButton(
                  text: _authController.isRegistering.value ? 'S\'inscrire' : 'Se connecter',
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
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Séparateur
                Row(
                        children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('ou'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Bouton d'authentification biométrique
                FutureBuilder<bool>(
                  future: _authService.canUseBiometrics(),
                  builder: (context, snapshot) {
                    final canUseBiometrics = snapshot.data ?? false;
                    
                    if (!canUseBiometrics) {
                      return const SizedBox.shrink();
                    }
                    
                    return CustomButton(
                      text: 'Se connecter avec la biométrie',
                      icon: Icons.fingerprint,
                      isOutlined: true,
                      onPressed: () => _authController.loginWithBiometrics(),
                    );
                  },
                ),
              ],
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
          prefixIcon: Icons.email,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Mot de passe',
          controller: _authController.passwordController,
          isPassword: true,
          prefixIcon: Icons.lock,
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
          prefixIcon: Icons.email,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Mot de passe',
          controller: _authController.passwordController,
          isPassword: true,
          prefixIcon: Icons.lock,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Téléphone',
          controller: _authController.phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone,
        ),
      ],
    );
  }
}
