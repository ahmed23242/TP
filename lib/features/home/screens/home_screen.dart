import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../incidents/controllers/incident_controller.dart';
import '../../incidents/widgets/incident_card.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final IncidentController _incidentController = Get.find<IncidentController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    // Observer pour afficher la boîte de dialogue de demande d'activation de la biométrie
    // après la première connexion ou inscription
    ever(_authController.shouldAskForBiometric, (shouldAsk) {
      if (shouldAsk) {
        _showBiometricPrompt(context);
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents urbains'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _incidentController.loadIncidents(),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: const Text('Mon profil'),
                onTap: () => Get.toNamed('/profile'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: const Text('Déconnexion'),
                onTap: () => _authController.logout(),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _incidentController.loadIncidents(),
        child: Obx(() {
          if (_incidentController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_incidentController.incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun incident signalé',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.toNamed('/incident/create'),
                    child: const Text('Signaler un incident'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _incidentController.incidents.length,
            itemBuilder: (context, index) {
              final incident = _incidentController.incidents[index];
              return IncidentCard(
                incident: incident,
                onTap: () => Get.toNamed(
                  '/incident/details',
                  arguments: incident,
                ),
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/incident/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Méthode pour afficher la boîte de dialogue demandant l'activation de la biométrie
  void _showBiometricPrompt(BuildContext context) {
    // On utilise Future.delayed pour éviter les problèmes de build context
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Activer l\'authentification biométrique'),
          content: const Text(
            'Voulez-vous utiliser votre empreinte digitale ou reconnaissance faciale '
            'pour vous connecter plus rapidement à l\'avenir?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _authController.cancelBiometricEnabling();
              },
              child: const Text('Non, merci'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authController.enableBiometricAuthentication();
              },
              child: const Text('Activer'),
            ),
          ],
        ),
      );
    });
  }
} 