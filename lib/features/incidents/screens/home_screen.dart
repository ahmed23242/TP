import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/incident_controller.dart';
import '../widgets/incident_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/network/connectivity_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incidentController = Get.find<IncidentController>();
    final authController = Get.find<AuthController>();
    final connectivityService = Get.find<ConnectivityService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urban Incidents'),
        actions: [
          Obx(() => Padding(
            padding: const EdgeInsets.all(8.0),
            child: connectivityService.isConnected.value
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
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser',
            onPressed: () => incidentController.syncIncidents(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cartes de menu principales
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    title: 'Signaler',
                    icon: Icons.add_alert,
                    color: Colors.orange,
                    onTap: () => Get.toNamed('/incident/create'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    title: 'Historique',
                    icon: Icons.history,
                    color: Colors.blue,
                    onTap: () => Get.toNamed('/incident/history'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    title: 'Carte',
                    icon: Icons.map,
                    color: Colors.green,
                    onTap: () => Get.toNamed('/map'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => _buildMenuCard(
                    title: 'Synchronisation',
                    icon: incidentController.isLoading.value 
                        ? Icons.sync
                        : Icons.sync_alt,
                    color: connectivityService.isConnected.value 
                        ? Colors.teal 
                        : Colors.grey,
                    onTap: connectivityService.isConnected.value
                        ? () => incidentController.syncIncidents()
                        : () => Get.snackbar(
                            'Hors ligne',
                            'Connexion internet requise pour synchroniser',
                            snackPosition: SnackPosition.BOTTOM,
                          ),
                  )),
                ),
              ],
            ),
          ),
          
          // Titre de la section incidents récents
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Incidents récents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed('/incident/history'),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
          ),
          
          // Liste des incidents récents
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => incidentController.loadIncidents(),
              child: Obx(() {
                if (incidentController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (incidentController.incidents.isEmpty) {
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

                // Afficher seulement les 5 incidents les plus récents
                final recentIncidents = incidentController.incidents.length > 5
                    ? incidentController.incidents.sublist(0, 5)
                    : incidentController.incidents;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: recentIncidents.length,
                  itemBuilder: (context, index) {
                    final incident = recentIncidents[index];
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/incident/create'),
        icon: const Icon(Icons.add),
        label: const Text('Signaler'),
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
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
