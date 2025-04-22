import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database/database_helper.dart';
import '../models/incident.dart';
import 'dart:developer' as developer;
import '../../../core/network/connectivity_service.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/network/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'audio_service.dart';
import 'package:flutter/material.dart';

class IncidentService extends GetxController {
  final _db = DatabaseHelper.instance;
  final _imagePicker = ImagePicker();
  late final AudioService _audioService;
  late final ConnectivityService _connectivityService;
  
  RxList<Incident> incidents = <Incident>[].obs;
  RxBool isRecording = false.obs;
  String? _currentRecordingPath;
  final RxBool isSyncing = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize services safely
    _initializeServices();
    
    // Set up periodic sync
    _setupPeriodicSync();
  }
  
  void _initializeServices() {
    try {
      // Try to find existing services
      _audioService = Get.find<AudioService>();
      developer.log('AudioService found successfully');
    } catch (e) {
      // Create a new instance if not found
      _audioService = Get.put(AudioService());
      developer.log('AudioService created anew');
    }
    
    try {
      _connectivityService = Get.find<ConnectivityService>();
      developer.log('ConnectivityService found successfully');
    } catch (e) {
      _connectivityService = Get.put(ConnectivityService());
      developer.log('ConnectivityService created anew');
    }
  }

  void _setupPeriodicSync() {
    // Sync every 15 minutes if there are pending incidents
    ever(_connectivityService.isConnected, (isConnected) {
      if (isConnected) {
        syncPendingIncidents();
      }
    });
    
    // Also set up a timer to check periodically
    Timer.periodic(const Duration(minutes: 15), (_) async {
      if (_connectivityService.isConnected.value) {
        await syncPendingIncidents();
      }
    });
  }

  // Location handling
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  // Image capture
  Future<String?> captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      return image?.path;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  // Voice recording
  Future<bool> startVoiceRecording() async {
    try {
      final success = await _audioService.startRecording();
      if (success) {
        isRecording.value = true;
      }
      return success;
    } catch (e) {
      developer.log('Error starting recording', error: e);
      return false;
    }
  }

  Future<String?> stopVoiceRecording() async {
    try {
      if (!isRecording.value) return null;
      
      final path = await _audioService.stopRecording();
      isRecording.value = false;
      _currentRecordingPath = path;
      return path;
    } catch (e) {
      developer.log('Error stopping recording', error: e);
      return null;
    }
  }

  // Incident CRUD operations
  Future<bool> createIncident(Incident incident) async {
    try {
      await _db.insertIncident(incident.toMap());
      developer.log('Incident created: ${incident.id}');
      incidents.add(incident);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error creating incident', error: e, stackTrace: stackTrace);
      rethrow;
      return false;
    }
  }

  Future<List<Incident>> getUserIncidents(int userId) async {
    try {
      developer.log('Getting incidents for user $userId');
      final dbIncidents = await _db.getIncidentsByUserId(userId);
      
      // Convert to Incident objects
      final incidentsList = dbIncidents.map((map) => Incident.fromMap(map)).toList();
      
      // Update the observable list
      incidents.value = incidentsList;
      
      return incidentsList;
    } catch (e) {
      developer.log('Error getting user incidents', error: e);
      return [];
    }
  }
  
  // Get only pending (not synced) incidents
  Future<List<Incident>> getPendingIncidents() async {
    try {
      // Get the current user ID
      final storage = const FlutterSecureStorage();
      final userIdStr = await storage.read(key: 'user_id');
      final userId = userIdStr != null ? int.parse(userIdStr) : 0;
      
      if (userId <= 0) {
        developer.log('No valid user ID found for getting pending incidents');
        return [];
      }
      
      developer.log('Getting pending incidents for user $userId');
      final dbIncidents = await _db.getIncidentsByUserId(userId);
      
      // Filter to only include pending incidents
      final pendingIncidents = dbIncidents
          .where((map) => map['sync_status'] == 'pending')
          .map((map) => Incident.fromMap(map))
          .toList();
      
      developer.log('Found ${pendingIncidents.length} pending incidents');
      return pendingIncidents;
    } catch (e) {
      developer.log('Error getting pending incidents', error: e);
      return [];
    }
  }
  
  // Get unsynced incidents (alias for getPendingIncidents for compatibility)
  Future<List<Incident>> getUnsyncedIncidents() async {
    return getPendingIncidents();
  }

  Future<List<Incident>> getUnsyncedIncidentsFromDB() async {
    try {
      final incidents = await _db.getUnsyncedIncidents();
      return incidents.map((map) => Incident.fromMap(map)).toList();
    } catch (e, stackTrace) {
      developer.log('Error getting unsynced incidents', error: e, stackTrace: stackTrace);
      rethrow;
      return [];
    }
  }

  Future<void> syncIncident(Incident incident) async {
    try {
      developer.log('Starting to sync incident with server: ${incident.id}');
      
      // Get the API service
      final apiService = Get.find<ApiService>();
      
      // First check if we have a token
      final token = await apiService.getStoredToken();
      if (token == null) {
        developer.log('Cannot sync incident: No authentication token available');
        
        // Show dialog to prompt re-login
        Get.snackbar(
          'Authentication Required',
          'Please log in again to upload your incident reports',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
          mainButton: TextButton(
            child: Text('Login'),
            onPressed: () => Get.offAllNamed('/login'),
          ),
        );
        
        throw Exception('Not authenticated - token missing');
      }
      
      // Prepare incident data for the API
      final Map<String, dynamic> incidentData = {
        'title': incident.title,
        'description': incident.description,
        'latitude': incident.latitude,
        'longitude': incident.longitude,
        'incident_type': incident.incidentType,
        'created_at': incident.createdAt.toIso8601String(),
        'user': incident.userId,
        'status': 'pending',
        'sync_status': 'pending',
        'photo_path': incident.photoPath,
        'voice_note_path': incident.voiceNotePath,
      };
      
      // Call the API to sync the incident
      developer.log('Sending incident to server: $incidentData');
      final response = await apiService.syncIncident(incidentData);
      
      if (response != null) {
        // Update local status to synced
      await _db.updateIncidentSyncStatus(incident.id, 'synced');
        developer.log('Incident synced successfully: ${incident.id}');
      } else {
        developer.log('Failed to sync incident: ${incident.id}');
      }
    } catch (e, stackTrace) {
      developer.log('Error syncing incident', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Sync operations
  Future<void> syncPendingIncidents() async {
    // Skip if already syncing
    if (isSyncing.value) {
      developer.log('Sync already in progress, skipping');
      return;
    }
    
    try {
      isSyncing.value = true;
      developer.log('-------- STARTING SYNC PROCESS --------');
      developer.log('Attempting to sync pending incidents to backend');
      
      // Check for internet connectivity
      final bool isConnected = await _connectivityService.checkConnectivity();
      developer.log('Internet connection status: $isConnected');
      
      if (!isConnected) {
        developer.log('No internet connection, sync aborted');
        isSyncing.value = false;
        return;
      }
      
      // Get unsynced incidents
      developer.log('Fetching unsynced incidents from local database');
      final List<Map<String, dynamic>> unsyncedIncidents = 
          await _db.getUnsyncedIncidents();
      
      if (unsyncedIncidents.isEmpty) {
        developer.log('No pending incidents to sync');
        isSyncing.value = false;
        return;
      }
      
      developer.log('Found ${unsyncedIncidents.length} incidents to sync');
      
      // Get API service for sending data
      developer.log('Getting API service for syncing');
      final apiService = Get.find<ApiService>();
      
      // Check for authentication token
      developer.log('Checking for authentication token');
      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token == null) {
        developer.log('Syncing incidents failed: No authentication token found');
        isSyncing.value = false;
        return;
      }
      developer.log('Authentication token found, continuing with sync');
      
      int successCount = 0;
      int failCount = 0;
      
      // Process each unsynced incident
      for (var incidentMap in unsyncedIncidents) {
        try {
          final incident = Incident.fromMap(incidentMap);
          
          developer.log('Processing incident ID: ${incident.id} for sync');
          developer.log('Incident details: title=${incident.title}, type=${incident.incidentType}, userId=${incident.userId}');
          
          // Prepare data for API in proper format
          final Map<String, dynamic> incidentData = {
            'title': incident.title,
            'description': incident.description,
            'latitude': incident.latitude,
            'longitude': incident.longitude,
            'incident_type': incident.incidentType,
            'created_at': incident.createdAt.toIso8601String(),
            'photo_path': incident.photoPath,
            'voice_note_path': incident.voiceNotePath,
            'status': 'pending',
            'sync_status': 'pending',
            'user': incident.userId, // Make sure to include the user ID
          };
          
          developer.log('Syncing incident ${incident.id} to backend');
          
          // Call API to sync incident
          final response = await apiService.syncIncident(incidentData);
          
          if (response != null) {
            // Update local status to synced
            developer.log('Successfully synced incident ${incident.id} to backend, updating local status');
            await _db.updateIncidentSyncStatus(incident.id, 'synced');
            developer.log('Incident ${incident.id} successfully synced');
            successCount++;
          } else {
            developer.log('Failed to sync incident ${incident.id}: null response from API');
            failCount++;
          }
        } catch (e) {
          developer.log('Error syncing incident: $e');
          failCount++;
        }
      }
      
      developer.log('Sync completed - Success: $successCount, Failed: $failCount');
      
      // Update the incidents list if any were successfully synced
      if (successCount > 0) {
        // Reload incidents to reflect new sync status
        developer.log('Reloading incidents list after successful sync');
        final currentUserId = await const FlutterSecureStorage().read(key: 'user_id');
        if (currentUserId != null) {
          developer.log('Reloading incidents for user ID: $currentUserId');
          await getUserIncidents(int.parse(currentUserId));
        } else {
          developer.log('Cannot reload incidents: user ID not found');
        }
      }
      
      developer.log('-------- SYNC PROCESS COMPLETED --------');
    } catch (e, stackTrace) {
      developer.log('Error during sync process', error: e, stackTrace: stackTrace);
    } finally {
      isSyncing.value = false;
    }
  }

  // Mettre à jour le statut de synchronisation d'un incident
  Future<void> updateIncidentSyncStatus(int incidentId, String syncStatus) async {
    try {
      await _db.updateIncidentSyncStatus(incidentId, syncStatus);
      
      // Update the incident in the list if it exists
      final index = incidents.indexWhere((inc) => inc.id == incidentId);
      if (index != -1) {
        final incident = incidents[index];
        final updatedIncident = Incident(
          id: incident.id,
          title: incident.title,
          description: incident.description,
          photoPath: incident.photoPath,
          photoUrl: incident.photoUrl,
          voiceNotePath: incident.voiceNotePath,
          latitude: incident.latitude,
          longitude: incident.longitude,
          createdAt: incident.createdAt,
          status: incident.status,
          incidentType: incident.incidentType,
          syncStatus: syncStatus,
          userId: incident.userId,
        );
        incidents[index] = updatedIncident;
        incidents.refresh();
      }
      
      developer.log('Updated sync status for incident $incidentId to $syncStatus');
    } catch (e, stackTrace) {
      developer.log('Error updating incident sync status', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
