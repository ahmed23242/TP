import 'dart:async';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/api_service.dart';
import '../models/incident.dart';
import 'incident_service.dart';

class SyncService extends GetxController {
  final RxBool isSyncing = false.obs;
  late final Worker _connectivityWorker;
  
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  final IncidentService _incidentService = Get.find<IncidentService>();
  final ApiService _apiService = Get.find<ApiService>();
  
  @override
  void onInit() {
    super.onInit();
    _setupConnectivityListener();
    
    // Vérifier s'il y a des incidents à synchroniser au démarrage
    if (_connectivityService.isConnected.value) {
      syncPendingIncidents();
    }
  }
  
  @override
  void onClose() {
    _connectivityWorker.dispose();
    super.onClose();
  }
  
  // Configurer l'écouteur de connectivité
  void _setupConnectivityListener() {
    _connectivityWorker = ever(
      _connectivityService.connectivityChangedEvent, 
      (_) => _handleConnectivityChange()
    );
  }
  
  // Gérer les changements de connectivité
  Future<void> _handleConnectivityChange() async {
    if (_connectivityService.isConnected.value) {
      developer.log('Connection restored, starting sync...');
      await syncPendingIncidents();
    }
  }
  
  // Synchroniser les incidents en attente
  Future<void> syncPendingIncidents() async {
    if (isSyncing.value) {
      developer.log('Sync already in progress, skipping');
      return;
    }
    
    try {
      isSyncing.value = true;
      
      // Vérifier la connectivité avant de commencer
      final isConnected = await _connectivityService.checkConnectivity();
      if (!isConnected) {
        developer.log('No connection available, skipping sync');
        return;
      }
      
      // Récupérer les incidents non synchronisés
      final unsyncedIncidents = await _incidentService.getUnsyncedIncidents();
      developer.log('Found ${unsyncedIncidents.length} unsynced incidents');
      
      if (unsyncedIncidents.isEmpty) {
        return;
      }
      
      // Synchroniser chaque incident
      for (final incident in unsyncedIncidents) {
        try {
          await _syncIncident(incident);
        } catch (e) {
          developer.log('Error syncing incident ${incident.id}', error: e);
          // Continuer avec le prochain incident même si celui-ci échoue
        }
      }
      
      developer.log('Sync completed successfully');
    } catch (e) {
      developer.log('Error during sync', error: e);
    } finally {
      isSyncing.value = false;
    }
  }
  
  // Synchroniser un incident spécifique
  Future<void> _syncIncident(Incident incident) async {
    try {
      developer.log('Syncing incident: ${incident.id}');
      
      // Convertir l'incident en format approprié pour l'API
      final incidentData = {
        'title': incident.title,
        'description': incident.description,
        'latitude': incident.latitude,
        'longitude': incident.longitude,
        'incident_type': incident.incidentType,
        'created_at': incident.createdAt.toIso8601String(),
        // Les photos et enregistrements vocaux nécessiteraient un upload multipart
        // que nous simplifions ici
      };
      
      // Envoyer l'incident au serveur
      final response = await _apiService.syncIncident(incidentData);
      
      // Si la synchronisation réussit, mettre à jour l'état de l'incident local
      await _incidentService.updateIncidentSyncStatus(incident.id, 'synced');
      
      developer.log('Incident ${incident.id} synced successfully');
    } catch (e) {
      developer.log('Failed to sync incident ${incident.id}', error: e);
      throw e; // Propager l'erreur pour la gestion par l'appelant
    }
  }
  
  // Méthode publique pour déclencher manuellement la synchronisation
  Future<void> manualSync() async {
    developer.log('Manual sync requested');
    return syncPendingIncidents();
  }
} 