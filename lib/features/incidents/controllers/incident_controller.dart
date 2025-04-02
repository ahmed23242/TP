import 'package:get/get.dart';
import '../models/incident.dart';
import '../repositories/incident_repository.dart';

class IncidentController extends GetxController {
  final IncidentRepository _repository = IncidentRepository();
  final RxBool isLoading = false.obs;
  final RxList<Incident> incidents = <Incident>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadIncidents();
  }

  Future<void> loadIncidents() async {
    try {
      isLoading.value = true;
      final loadedIncidents = await _repository.getIncidents();
      incidents.value = loadedIncidents;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load incidents: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createIncident(Incident incident) async {
    try {
      isLoading.value = true;
      final success = await _repository.createIncident(incident);
      if (success) {
        await loadIncidents(); // Reload the list after creating
      }
      return success;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create incident: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncOfflineIncidents() async {
    try {
      await _repository.syncOfflineIncidents();
      await loadIncidents(); // Reload after sync
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sync incidents: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
