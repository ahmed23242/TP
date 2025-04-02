import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/incident_controller.dart';
import '../widgets/incident_card.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incidentController = Get.put(IncidentController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urban Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Get.toNamed('/map'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => incidentController.loadIncidents(),
        child: Obx(() {
          if (incidentController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (incidentController.incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No incidents reported yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => incidentController.loadIncidents(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: incidentController.incidents.length,
            itemBuilder: (context, index) {
              final incident = incidentController.incidents[index];
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/incident/create'),
        icon: const Icon(Icons.add),
        label: const Text('Report Incident'),
      ),
    );
  }
}
