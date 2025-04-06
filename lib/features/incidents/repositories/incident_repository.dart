import 'package:get/get.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_client.dart';
import '../models/incident.dart';

class IncidentRepository {
  final ApiClient _apiClient = ApiClient();
  final _db = DatabaseHelper.instance;
  final RxBool isSyncing = false.obs;

  Future<List<Incident>> getIncidents() async {
    try {
      final incidents = await _apiClient.getIncidents();
      return incidents.map((data) => Incident.fromMap(data)).toList();
    } catch (e) {
      // If API fails, return local incidents
      final localIncidents = await _db.getIncidentsByUserId(1); // TODO: Get actual user ID
      return localIncidents.map((data) => Incident.fromMap(data)).toList();
    }
  }

  Future<bool> createIncident(Incident incident) async {
    try {
      // Try to create incident online
      final response = await _apiClient.createIncident(incident.toMap());
      return true;
    } catch (e) {
      // If offline, save locally
      await _db.insertIncident(incident.toMap());
      return true;
    }
  }

  Future<void> syncOfflineIncidents() async {
    if (isSyncing.value) return;
    
    try {
      isSyncing.value = true;
      final unsyncedIncidents = await _db.getUnsyncedIncidents();
      
      if (unsyncedIncidents.isEmpty) return;
      
      await _apiClient.syncOfflineIncidents(unsyncedIncidents);
      
      // Mark all synced incidents
      for (var incident in unsyncedIncidents) {
        await _db.updateIncidentSyncStatus(incident['id'], 'synced');
      }
    } finally {
      isSyncing.value = false;
    }
  }
}
