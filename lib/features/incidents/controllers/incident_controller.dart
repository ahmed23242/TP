import 'package:accidentsapp/features/auth/services/auth_service.dart';
import 'package:accidentsapp/features/incidents/models/incident.dart';
import 'package:accidentsapp/features/incidents/services/incident_service.dart';
import 'package:accidentsapp/features/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;

class IncidentController extends GetxController {
  final IncidentService _incidentService = Get.find<IncidentService>();
  
  final RxList<Incident> incidents = <Incident>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filterStatus = 'all'.obs;
  final RxString filterType = 'all'.obs;
  final RxString sortBy = 'date'.obs;
  
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
      final authService = Get.find<AuthService>();
      final userId = authService.currentUserId.value;
      
      if (userId == null) {
        developer.log('User ID not found, unable to load incidents');
        // Ne pas utiliser Get.snackbar pendant le build d'un widget
        // Get.snackbar('Erreur', 'Identifiant utilisateur non trouvé');
        isLoading.value = false;
        return;
      }
      
      final loadedIncidents = await _incidentService.getUserIncidents(userId);
      
      // S'assurer qu'il n'y a pas de doublons (par ID)
      final Map<int, Incident> uniqueIncidents = {};
      for (var incident in loadedIncidents) {
        uniqueIncidents[incident.id] = incident;
      }
      
      incidents.value = uniqueIncidents.values.toList();
      developer.log('Loaded ${incidents.value.length} incidents');
    } catch (e) {
      developer.log('Error loading incidents', error: e);
      // Ne pas utiliser Get.snackbar pendant le build d'un widget
      // Get.snackbar('Erreur', 'Impossible de charger les incidents');
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
      
      // Générer un ID unique basé sur le timestamp
      final incidentId = DateTime.now().millisecondsSinceEpoch;
      
      // Vérifier si un incident similaire existe déjà (dans les 2 dernières secondes)
      final duplicateCheck = incidents.any((inc) => 
        (incidentId - inc.id).abs() < 2000 && // Créé dans les 2 dernières secondes
        inc.title == title &&
        inc.latitude == latitude &&
        inc.longitude == longitude
      );
      
      if (duplicateCheck) {
        developer.log('Duplicate incident detected, ignoring');
        return;
      }
      
      // Créer l'incident avec l'ID utilisateur récupéré ou la valeur par défaut
      final incident = Incident(
        id: incidentId,
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
