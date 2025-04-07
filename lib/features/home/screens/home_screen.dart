import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../incidents/controllers/incident_controller.dart';
import '../../incidents/widgets/incident_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/network/connectivity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IncidentController _incidentController = Get.find<IncidentController>();
  final AuthController _authController = Get.find<AuthController>();
  late final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  
  @override
  void initState() {
    super.initState();
    _incidentController.loadIncidents();
    
    // Vérifier si nous devons demander l'activation de la biométrie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricPrompt();
    });
  }
  
  void _checkBiometricPrompt() {
    if (_authController.shouldAskForBiometric.value) {
      _showBiometricEnableDialog();
    }
  }
  
  void _showBiometricEnableDialog() {
    if (Get.isDialogOpen ?? false) {
      return; // Éviter d'ouvrir plusieurs dialogues
    }
    
    // Utiliser Get.dialog au lieu de showDialog pour une meilleure gestion avec GetX
    Get.dialog(
      AlertDialog(
        title: const Text('Activer la biométrie'),
        content: const SingleChildScrollView(
          child: Text(
            'Souhaitez-vous activer la connexion par empreinte digitale ou reconnaissance faciale pour faciliter vos futures connexions?'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _authController.cancelBiometricEnabling();
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _authController.enableBiometricAuthentication();
            },
            child: const Text('Activer'),
          ),
        ],
      ),
      barrierDismissible: false,
      name: 'biometricPromptHome',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents urbains'),
        actions: [
          // Indicateur de connectivité
          Obx(() => Padding(
            padding: const EdgeInsets.all(8.0),
            child: _connectivityService.isConnected.value
              ? const Icon(Icons.wifi, color: Colors.green)
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.red),
                    Container(
                      width: 20,
                      height: 2,
                      color: Colors.red,
                      transform: Matrix4.rotationZ(0.785398), // 45 degrés en radians
                    ),
                  ],
                ),
          )),
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
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
                ),
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

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Réduire le padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32, // Réduire la taille de l'icône
                color: color,
              ),
              const SizedBox(height: 4), // Réduire l'espace
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13, // Réduire la taille de la police
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 