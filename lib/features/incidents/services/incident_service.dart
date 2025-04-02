import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database/database_helper.dart';
import '../models/incident.dart';

class IncidentService extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _imagePicker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  RxList<Incident> incidents = <Incident>[].obs;
  RxBool isRecording = false.obs;
  String? _currentRecordingPath;
  
  @override
  void onInit() {
    super.onInit();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
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
      final int id = await _dbHelper.insertIncident(incident.toMap());
      if (id != -1) {
        incidents.add(incident);
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating incident: $e');
      return false;
    }
  }

  Future<List<Incident>> getUserIncidents(int userId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.getUserIncidents(userId);
      incidents.value = maps.map((map) => Incident.fromMap(map)).toList();
      return incidents;
    } catch (e) {
      print('Error getting user incidents: $e');
      return [];
    }
  }

  // Sync operations
  Future<void> syncPendingIncidents() async {
    try {
      final List<Map<String, dynamic>> unsyncedIncidents = 
          await _dbHelper.getUnsyncedIncidents();
          
      for (var incident in unsyncedIncidents) {
        // TODO: Implement API call to sync incident with backend
        // On successful sync:
        await _dbHelper.markIncidentAsSynced(incident['id']);
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
