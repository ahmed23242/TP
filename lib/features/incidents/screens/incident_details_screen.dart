import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
            // Afficher l'image depuis l'URL du serveur ou le chemin local
            if (incident.photoUrl != null && incident.photoUrl!.isNotEmpty)
              Image.network(
                incident.photoUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Si l'image du serveur ne peut pas être chargée, essayer le fichier local
                  if (incident.photoPath != null && incident.photoPath!.isNotEmpty) {
                    return Image.file(
                      File(incident.photoPath!),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    );
                  }
                  return Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              )
            else if (incident.photoPath != null && incident.photoPath!.isNotEmpty)
              // Si pas d'URL serveur, utiliser le fichier local
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
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(incident.latitude, incident.longitude),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                          userAgentPackageName: 'com.accidentsapp',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 40.0,
                              height: 40.0,
                              point: LatLng(incident.latitude, incident.longitude),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Afficher le lecteur audio si un fichier audio est disponible
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
                    // TODO: Implement voice note player with proper URL handling
                    ElevatedButton.icon(
                      onPressed: () {
                        // Utiliser le fichier local pour l'audio
                        final audioSource = incident.voiceNotePath;
                        
                        if (audioSource != null) {
                          // TODO: Implement audio player with the correct source
                          print('Playing audio from: $audioSource');
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play Voice Note'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  
                  // Afficher les médias supplémentaires s'il y en a
                  if (incident.additionalMedia.isNotEmpty) ...[  
                    const SizedBox(height: 24),
                    const Text(
                      'Additional Media',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: incident.additionalMedia.length,
                        itemBuilder: (context, index) {
                          final media = incident.additionalMedia[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                // Afficher le média en plein écran
                                // TODO: Implémenter l'affichage en plein écran
                              },
                              child: Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      media['media_type'] == 'image' 
                                          ? Icons.image 
                                          : media['media_type'] == 'video'
                                              ? Icons.videocam
                                              : Icons.insert_drive_file,
                                      size: 40,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      media['caption'] ?? 'Media ${index + 1}',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
