import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../models/incident.dart';
import '../controllers/incident_controller.dart';
import '../widgets/audio_recorder_widget.dart';
import '../services/location_service.dart';
import '../services/incident_service.dart';

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final IncidentController _incidentController;
  final _locationService = LocationService();
  final _imagePicker = ImagePicker();
  
  String? _photoPath;
  String? _voiceNotePath;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  String _selectedIncidentType = 'general';
  
  // Liste des types d'incidents
  final List<Map<String, String>> _incidentTypes = [
    {'value': 'general', 'label': 'General'},
    {'value': 'fire', 'label': 'Fire'},
    {'value': 'accident', 'label': 'Accident'},
    {'value': 'medical', 'label': 'Medical Emergency'},
    {'value': 'crime', 'label': 'Crime'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _initController();
    
    // S'assurer que le service d'incidents est bien initialisé
    try {
      Get.find<IncidentService>();
    } catch (e) {
      Get.put(IncidentService());
    }
  }

  void _initController() {
    try {
      _incidentController = Get.find<IncidentController>();
    } catch (e) {
      _incidentController = Get.put(IncidentController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to get location. Please enable location services.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        Get.snackbar(
          'Error',
          'Camera permission denied',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      
      if (pickedFile != null) {
        setState(() => _photoPath = pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture photo: $e');
    }
  }

  void _onRecordingComplete(String? path) {
    setState(() => _voiceNotePath = path);
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar('Error', 'Please fill all required fields');
      return;
    }

    if (_selectedLocation == null) {
      Get.snackbar('Error', 'Please get your current location first');
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Laisser l'UI se mettre à jour
      await Future.delayed(Duration.zero);
      
      try {
        await _incidentController.createIncident(
          title: _titleController.text,
          description: _descriptionController.text,
          photoPath: _photoPath,
          voiceNotePath: _voiceNotePath,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          incidentType: _selectedIncidentType,
        );
        
        Get.back();
        Get.snackbar(
          'Success',
          'Incident reported successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        if (e.toString().contains('User not authenticated')) {
          Get.snackbar(
            'Authentication Error',
            'Please log in again to report an incident',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () => Get.offAllNamed('/login'),
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to create incident: ${e.toString()}',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Incident Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedIncidentType,
                      items: _incidentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedIncidentType = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an incident type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.location_on),
                      label: Text(_selectedLocation != null
                          ? 'Location: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                          : 'Get Current Location'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_photoPath != null ? 'Photo Taken' : 'Take Photo'),
                    ),
                    if (_photoPath != null) ...[
                      const SizedBox(height: 8),
                      Image.file(
                        File(_photoPath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Voice Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    AudioRecorderWidget(
                      onRecordingComplete: _onRecordingComplete,
                      initialRecordingPath: _voiceNotePath,
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation!,
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('incident'),
                              position: _selectedLocation!,
                            ),
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitIncident,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Submit Report'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
