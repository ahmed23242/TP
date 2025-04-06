import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database/database_helper.dart';
import '../models/incident.dart';
import 'dart:developer' as developer;

class IncidentService extends GetxController {
  final _db = DatabaseHelper.instance;
  final _imagePicker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  RxList<Incident> incidents = <Incident>[].obs;
  RxBool isRecording = false.obs;
  String? _currentRecordingPath;
  
  @override
  void onInit() {
    super.onInit();
    // Initialisation différée pour éviter de bloquer le thread principal
    Future.delayed(Duration.zero, () async {
      await _initRecorder();
    });
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      developer.log('Audio recorder initialized successfully');
    } catch (e) {
      developer.log('Error initializing audio recorder', error: e);
    }
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
      if (await Permission.microphone.request().isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        _currentRecordingPath = path.join(
          directory.path,
          'recording_${DateTime.now().millisecondsSinceEpoch}.aac',
        );
        
        await _recorder.startRecorder(
          toFile: _currentRecordingPath,
          codec: Codec.aacADTS,
        );
        
        isRecording.value = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopVoiceRecording() async {
    try {
      await _recorder.stopRecorder();
      isRecording.value = false;
      return _currentRecordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
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
      final incidents = await _db.getIncidentsByUserId(userId);
      this.incidents.value = incidents.map((map) => Incident.fromMap(map)).toList();
      return this.incidents;
    } catch (e, stackTrace) {
      developer.log('Error getting user incidents', error: e, stackTrace: stackTrace);
      rethrow;
      return [];
    }
  }

  Future<List<Incident>> getUnsyncedIncidents() async {
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
      // TODO: Implement API call to sync with server
      await _db.updateIncidentSyncStatus(incident.id, 'synced');
      developer.log('Incident synced: ${incident.id}');
    } catch (e, stackTrace) {
      developer.log('Error syncing incident', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Sync operations
  Future<void> syncPendingIncidents() async {
    try {
      final List<Map<String, dynamic>> unsyncedIncidents = 
          await _db.getUnsyncedIncidents();
          
      for (var incident in unsyncedIncidents) {
        // TODO: Implement API call to sync incident with backend
        // On successful sync:
        await _db.updateIncidentSyncStatus(incident['id'], 'synced');
      }
    } catch (e) {
      print('Error syncing incidents: $e');
    }
  }

  @override
  void onClose() {
    _recorder.closeRecorder();
    super.onClose();
  }
}
