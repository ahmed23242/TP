import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/incident_controller.dart';
import '../widgets/incident_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/network/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/stats_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IncidentController _incidentController = Get.find<IncidentController>();
  final AuthController _authController = Get.find<AuthController>();
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  final SyncService _syncService = Get.find<SyncService>();
  final StatsService _statsService = Get.find<StatsService>();
  
  @override
  void initState() {
    super.initState();
    _incidentController.loadIncidents();
    
    // Refresh statistics when screen loads
    _statsService.refreshStats();
    
    // Vérifier si nous avons une connexion pour synchoniser automatiquement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_connectivityService.isConnected.value) {
        _syncService.syncPendingIncidents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urban Incidents'),
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
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser',
            onPressed: () => _syncService.manualSync(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => _authController.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Overview
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(() {
                  if (_statsService.isLoading.value) {
                    return const Center(
                      heightFactor: 1,
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => _statsService.refreshStats(),
                            tooltip: 'Refresh Stats',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Stats cards
                      Row(
                        children: [
                          _buildStatCard(
                            'Total',
                            _statsService.totalIncidents.value.toString(),
                            Icons.assessment,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Synced',
                            _statsService.syncedIncidents.value.toString(),
                            Icons.cloud_done,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Pending',
                            _statsService.pendingIncidents.value.toString(),
                            Icons.cloud_upload,
                            Colors.orange,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Progress indicator for sync status
                      if (_statsService.totalIncidents.value > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Sync Progress'),
                                  Text(
                                    '${(_statsService.getSyncCompletionRate() * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _statsService.getSyncCompletionRate(),
                                  backgroundColor: Colors.grey.shade200,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
          
          // Titre de la section incidents récents
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Incidents récents',
                  style: TextStyle(
                    fontSize: 16,
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
          
          // Liste des incidents
          Expanded(
            child: Obx(() {
              if (_incidentController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final incidents = _incidentController.incidents;
              if (incidents.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Aucun incident signalé',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Utilisez le bouton + pour signaler un incident',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              
              // Limiter à 5 incidents les plus récents
              final recentIncidents = incidents.length > 5 
                  ? incidents.sublist(0, 5) 
                  : incidents;
              
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/incident/create'),
        icon: const Icon(Icons.add),
        label: const Text('Signaler'),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
