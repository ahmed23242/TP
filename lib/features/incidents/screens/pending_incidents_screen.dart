import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/incident_controller.dart';
import '../widgets/incident_card.dart';
import '../models/incident.dart';
import '../../../core/network/connectivity_service.dart';
import '../services/sync_service.dart';

class PendingIncidentsScreen extends StatefulWidget {
  const PendingIncidentsScreen({super.key});

  @override
  State<PendingIncidentsScreen> createState() => _PendingIncidentsScreenState();
}

class _PendingIncidentsScreenState extends State<PendingIncidentsScreen> {
  final IncidentController _incidentController = Get.find<IncidentController>();
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  
  @override
  void initState() {
    super.initState();
    // Load incidents when the screen initializes
    Future.microtask(() {
      _incidentController.loadIncidents();
    });
  }
  
  // Get only pending (not synced) incidents, sorted by most recent date
  List<Incident> _getPendingIncidents() {
    return _incidentController.incidents
        .where((i) => i.syncStatus == 'pending')
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by most recent
  }
  
  void _syncPendingIncidents() {
    if (!_connectivityService.isConnected.value) {
      Get.snackbar(
        'Synchronisation impossible',
        'Vérifiez votre connexion internet',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Get SyncService and trigger manual sync
    try {
      final syncService = Get.find<SyncService>();
      syncService.manualSync();
      Get.snackbar(
        'Synchronisation',
        'Synchronisation des incidents en cours...',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de synchroniser: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents en attente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncPendingIncidents,
            tooltip: 'Synchroniser tous',
          ),
        ],
      ),
      body: Obx(() {
        if (_incidentController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final pendingIncidents = _getPendingIncidents();
        
        if (pendingIncidents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_done, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Tous les incidents sont synchronisés',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun incident en attente de synchronisation',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingIncidents.length,
          itemBuilder: (context, index) {
            final incident = pendingIncidents[index];
            return IncidentCard(
              incident: incident,
              onTap: () => Get.toNamed('/incident/details', arguments: incident),
            );
          },
        );
      }),
    );
  }
}
