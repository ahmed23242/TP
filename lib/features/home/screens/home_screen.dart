import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../incidents/controllers/incident_controller.dart';
import '../../incidents/widgets/incident_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/network/connectivity_service.dart';
import '../../incidents/widgets/stats_overview_widget.dart';
import '../../incidents/widgets/user_stats_widget.dart';
import '../../incidents/services/stats_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IncidentController _incidentController = Get.find<IncidentController>();
  final AuthController _authController = Get.find<AuthController>();
  late final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  late final StatsService _statsService = Get.find<StatsService>();
  
  // Toggle between user-focused stats and sync-focused stats
  final RxBool _showUserStats = true.obs;
  
  @override
  void initState() {
    super.initState();
    _incidentController.loadIncidents();
    
    // Refresh statistics when screen loads
    _statsService.refreshStats();
    _statsService.fetchUserDashboardStats();
    
    // Verify if we need to prompt for biometric activation
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
    Get.dialog(
      AlertDialog(
        title: const Text('Activer l\'authentification biométrique?'),
        content: const Text(
          'Voulez-vous activer l\'authentification biométrique pour '
          'une connexion plus rapide et sécurisée à l\'avenir?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _authController.cancelBiometricEnabling();
              Get.back();
            },
            child: const Text('Non, merci'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await _authController.enableBiometricAuthentication();
              if (success) {
                Get.snackbar(
                  'Succès',
                  'Authentification biométrique activée!',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
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
            onPressed: () {
              _incidentController.loadIncidents();
              _statsService.refreshStats();
              _statsService.fetchUserDashboardStats();
            },
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
        onRefresh: () async {
          await _incidentController.loadIncidents();
          await _statsService.refreshAllStats();
        },
        child: Obx(() {
          if (_incidentController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(12),
                    children: [
              _buildStatsSection(),
              const SizedBox(height: 16),
              _buildQuickActionsBar(),
                      const SizedBox(height: 16),
              if (_incidentController.incidents.isEmpty)
                _buildEmptyState()
              else
                ..._buildIncidentsList(),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/incident/create'),
        tooltip: 'Signaler un incident',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: Icon(Icons.swap_horiz),
              label: Text('Toggle View'),
              onPressed: () => _toggleStatsView(),
            ),
          ],
        ),
        SizedBox(height: 8),
        Obx(() => _showUserStats.value
          ? UserStatsWidget()
          : StatsOverviewWidget(isCompact: true)
        ),
      ],
    );
  }
  
  // Toggle between different stats views
  void _toggleStatsView() {
    _showUserStats.value = !_showUserStats.value;
    
    // Refresh the appropriate stats when toggling
    if (_showUserStats.value) {
      _statsService.refreshUserDashboardStats();
    } else {
      _statsService.refreshStats();
      _statsService.fetchRemoteStats();
    }
  }
  
  Widget _buildQuickActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.add_circle,
            label: 'Signaler',
            color: Colors.blue,
            onTap: () => Get.toNamed('/incident/create'),
          ),
          _buildActionButton(
            icon: Icons.history,
            label: 'Historique',
            color: Colors.purple,
            onTap: () => Get.toNamed('/incidents'),
          ),
          _buildActionButton(
            icon: Icons.sync,
            label: 'Synchroniser',
            color: Colors.green,
            onTap: () => _incidentController.syncIncidents(),
          ),
          _buildActionButton(
            icon: Icons.map,
            label: 'Carte',
            color: Colors.orange,
            onTap: () => Get.toNamed('/map'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              ),
            ],
          ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun incident signalé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilisez le bouton ci-dessus pour signaler un incident',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildIncidentsList() {
    return _incidentController.incidents.map((incident) => 
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: IncidentCard(
          incident: incident,
          onTap: () => Get.toNamed(
            '/incident/details',
            arguments: incident,
          ),
        ),
      )
    ).toList();
  }
} 