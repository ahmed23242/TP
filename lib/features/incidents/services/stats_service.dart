import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../../core/database/database_helper.dart';

class StatsService extends GetxService {
  final _db = DatabaseHelper.instance;
  
  // Observable statistics
  final RxInt totalIncidents = 0.obs;
  final RxInt syncedIncidents = 0.obs;
  final RxInt pendingIncidents = 0.obs;
  final RxMap<String, int> incidentsByType = <String, int>{}.obs;
  final RxBool isLoading = false.obs;

  // Implement async initialization
  Future<StatsService> init() async {
    developer.log('Initializing StatsService');
    await refreshStats();
    developer.log('StatsService initialized');
    return this;
  }

  Future<void> refreshStats() async {
    try {
      isLoading.value = true;
      developer.log('Refreshing incident statistics');
      
      // Get user ID (using 1 as fallback for testing)
      final userId = 1; // Should get from auth service in real app
      
      // Get all incidents for user
      final incidents = await _db.getIncidentsByUserId(userId);
      totalIncidents.value = incidents.length;
      
      // Count synced vs pending incidents
      syncedIncidents.value = incidents.where((inc) => inc['sync_status'] == 'synced').length;
      pendingIncidents.value = incidents.where((inc) => inc['sync_status'] == 'pending').length;
      
      // Count incidents by type
      final typeMap = <String, int>{};
      for (var incident in incidents) {
        final type = incident['incident_type'] as String;
        typeMap[type] = (typeMap[type] ?? 0) + 1;
      }
      incidentsByType.value = typeMap;
      
      developer.log('Statistics refreshed: Total: ${totalIncidents.value}, '
          'Synced: ${syncedIncidents.value}, Pending: ${pendingIncidents.value}');
    } catch (e, stackTrace) {
      developer.log('Error refreshing statistics', error: e, stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }
  
  // Get incidents created in the last N days
  Future<int> getRecentIncidentsCount(int days) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final incidents = await _db.getIncidentsByUserId(1); // Use proper user ID
      
      return incidents.where((inc) {
        final createdAt = DateTime.parse(inc['created_at'] as String);
        return createdAt.isAfter(cutoffDate);
      }).length;
    } catch (e) {
      developer.log('Error getting recent incidents count', error: e);
      return 0;
    }
  }
  
  // Get completion rate (percentage of incidents that are synced)
  double getSyncCompletionRate() {
    if (totalIncidents.value == 0) return 0.0;
    return syncedIncidents.value / totalIncidents.value;
  }
} 