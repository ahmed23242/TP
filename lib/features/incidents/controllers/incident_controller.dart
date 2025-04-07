import 'package:get/get.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import '../../auth/controllers/auth_controller.dart';
import 'dart:developer' as developer;

class IncidentController extends GetxController {
  final _incidentService = IncidentService();
  final incidents = <Incident>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Execution différée pour éviter de bloquer le thread principal
    Future.delayed(Duration.zero, () async {
      await loadIncidents();
    });
  }

  Future<void> loadIncidents() async {
    try {
      isLoading.value = true;
      AuthController? authController;
      try {
        authController = Get.find<AuthController>();
      } catch (e) {
        developer.log('AuthController not found, skipping incident loading', error: e);
        return;
      }
      
      final userId = authController.userData.value?['id'];
      if (userId != null) {
        final userIncidents = await _incidentService.getUserIncidents(userId);
        incidents.assignAll(userIncidents);
        developer.log('Loaded ${incidents.length} incidents');
      } else {
        developer.log('User ID not found, unable to load incidents');
      }
    } catch (e, stackTrace) {
      developer.log('Error loading incidents', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'Failed to load incidents',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createIncident({
    required String title,
    required String description,
    String? photoPath,
    String? voiceNotePath,
    required double latitude,
    required double longitude,
    String incidentType = 'general',
  }) async {
    try {
      isLoading.value = true;
      
      // Vérifier si l'AuthController est disponible
      AuthController? authController;
      int userId = 1; // Valeur par défaut si aucun ID n'est trouvé
      
      try {
        authController = Get.find<AuthController>();
        // Récupérer l'ID de l'utilisateur ou utiliser la valeur par défaut
        userId = authController.userData.value?['id'] ?? 1;
      } catch (e) {
        developer.log('AuthController not found, using default user ID', error: e);
      }
      
      // Créer l'incident avec l'ID utilisateur récupéré ou la valeur par défaut
      final incident = Incident(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        description: description,
        photoPath: photoPath,
        voiceNotePath: voiceNotePath,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
        incidentType: incidentType,
        syncStatus: 'pending',
        userId: userId,
      );

      // Enregistrer l'incident et l'ajouter à la liste
      await _incidentService.createIncident(incident);
      incidents.add(incident);
      developer.log('Created new incident: ${incident.id}');
    } catch (e, stackTrace) {
      developer.log('Error creating incident', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncIncidents() async {
    try {
      isLoading.value = true;
      final unsyncedIncidents = await _incidentService.getUnsyncedIncidents();
      developer.log('Found ${unsyncedIncidents.length} unsynced incidents');

      for (final incident in unsyncedIncidents) {
        try {
          await _incidentService.syncIncident(incident);
          developer.log('Synced incident: ${incident.id}');
        } catch (e) {
          developer.log('Error syncing incident ${incident.id}', error: e);
        }
      }

      await loadIncidents();
    } catch (e, stackTrace) {
      developer.log('Error syncing incidents', error: e, stackTrace: stackTrace);
      Get.snackbar(
        'Error',
        'Failed to sync incidents',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
