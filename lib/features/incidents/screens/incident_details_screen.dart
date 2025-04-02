import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/incident.dart';
import '../../auth/controllers/auth_controller.dart';
import "package:timeago/timeago.dart" as timeago;

class IncidentDetailsScreen extends StatelessWidget {
  final Incident incident = Get.arguments;
  final AuthController authController = Get.find<AuthController>();

  IncidentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (authController.isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                // TODO: Implement admin actions
                switch (value) {
                  case 'update_status':
                    _showUpdateStatusDialog(context);
                    break;
                  case 'assign':
                    _showAssignDialog(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'update_status',
                  child: Text('Update Status'),
                ),
                const PopupMenuItem(
                  value: 'assign',
                  child: Text('Assign Responder'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incident.photoPath != null)
              Image.file(
                File(incident.photoPath!),
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(incident.syncStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          incident.syncStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    incident.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(
                        'Reported ${timeago.format(incident.createdAt)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(incident.latitude, incident.longitude),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('incident'),
                          position: LatLng(incident.latitude, incident.longitude),
                        ),
                      },
                    ),
                  ),
                  if (incident.voiceNotePath != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Voice Note',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // TODO: Implement voice note player
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Play voice note
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play Voice Note'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context) {
    // TODO: Implement status update dialog
  }

  void _showAssignDialog(BuildContext context) {
    // TODO: Implement responder assignment dialog
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
