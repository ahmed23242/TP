import 'dart:async';
import 'package:get/get.dart';
import '../network/connectivity_service.dart';
import '../../features/incidents/services/incident_service.dart';
import 'dart:developer' as developer;

class SyncService extends GetxService {
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  late IncidentService _incidentService;
  late Timer _syncTimer;
  final RxBool isSyncing = false.obs;

  // Augmenter la fréquence des tentatives de synchronisation
  final int _syncIntervalSeconds = 30; // Toutes les 30 secondes
  
  // Etat pour savoir si la dernière tentative a échoué
  final RxBool lastSyncFailed = false.obs;
  
  // Compteur de tentatives échouées consécutives
  int _failedAttempts = 0;
  
  // Nombre maximal de tentatives échouées avant d'augmenter l'intervalle
  final int _maxFailedAttempts = 3;

  @override
  void onInit() {
    super.onInit();
    _incidentService = Get.find<IncidentService>();
    
    // Écouter les changements de connectivité
    _connectivityService.isConnected.listen((isConnected) {
      if (isConnected) {
        developer.log('Network reconnected - triggering sync');
        _syncData();
      }
    });
    
    // Démarrer la synchronisation périodique
    _startPeriodicSync();
    
    // Tentative de synchronisation initiale
    _syncData();
  }

  // Démarrer la synchronisation périodique
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      Duration(seconds: _syncIntervalSeconds), 
      (_) => _syncData()
    );
  }

  // Synchroniser les données
  Future<void> _syncData() async {
    // Si une synchronisation est déjà en cours, ne pas en démarrer une autre
    if (isSyncing.value) return;
    
    // Si l'appareil n'est pas connecté, ne pas tenter de synchroniser
    if (!_connectivityService.isConnected.value) {
      developer.log('Device not connected, skipping sync');
      return;
    }
    
    isSyncing.value = true;
    developer.log('Starting to sync pending incidents');
    
    try {
      // Récupérer les incidents non synchronisés
      final unsyncedIncidents = await _incidentService.getUnsyncedIncidents();
      
      if (unsyncedIncidents.isEmpty) {
        developer.log('No pending incidents to sync');
        isSyncing.value = false;
        lastSyncFailed.value = false;
        _failedAttempts = 0;
        return;
      }
      
      developer.log('Found ${unsyncedIncidents.length} unsynced incidents');
      
      // Pour chaque incident non synchronisé, tenter de le synchroniser
      for (final incident in unsyncedIncidents) {
        try {
          await _incidentService.syncIncident(incident);
          developer.log('Incident synced: ${incident.id}');
        } catch (e) {
          developer.log('Error syncing incident ${incident.id}', error: e);
          lastSyncFailed.value = true;
          _failedAttempts++;
        }
      }
      
      // Vérifier si la synchronisation a réussi
      final remainingUnsyncedIncidents = await _incidentService.getUnsyncedIncidents();
      if (remainingUnsyncedIncidents.isEmpty) {
        developer.log('All incidents synced successfully');
        lastSyncFailed.value = false;
        _failedAttempts = 0;
      }
      
    } catch (e) {
      developer.log('Sync error', error: e);
      lastSyncFailed.value = true;
      _failedAttempts++;
      
      // Si trop de tentatives échouées, augmenter l'intervalle temporairement
      if (_failedAttempts >= _maxFailedAttempts) {
        _adjustSyncInterval();
      }
    } finally {
      isSyncing.value = false;
    }
  }
  
  // Méthode pour ajuster l'intervalle de synchronisation
  void _adjustSyncInterval() {
    // Annuler le timer actuel
    _syncTimer.cancel();
    
    // Créer un nouveau timer avec un intervalle plus long
    int adjustedInterval = _syncIntervalSeconds * (_failedAttempts - _maxFailedAttempts + 2);
    // Limiter l'intervalle maximum (5 minutes)
    adjustedInterval = adjustedInterval > 300 ? 300 : adjustedInterval;
    
    developer.log('Adjusting sync interval to $adjustedInterval seconds due to repeated failures');
    
    _syncTimer = Timer.periodic(
      Duration(seconds: adjustedInterval), 
      (_) => _syncData()
    );
    
    // Planifier le retour à l'intervalle normal après un certain temps
    Timer(Duration(minutes: 10), () {
      if (_failedAttempts >= _maxFailedAttempts) {
        _syncTimer.cancel();
        _startPeriodicSync();
        developer.log('Restoring normal sync interval');
      }
    });
  }
  
  // Force une synchronisation manuelle
  Future<void> forceSyncNow() async {
    await _syncData();
  }

  @override
  void onClose() {
    _syncTimer.cancel();
    super.onClose();
  }
} 