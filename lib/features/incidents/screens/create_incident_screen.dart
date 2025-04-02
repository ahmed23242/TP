import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/incident.dart';
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
  final _incidentService = Get.find<IncidentService>();
  
  String? _photoPath;
  String? _voiceNotePath;
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      final position = await _incidentService.getCurrentLocation();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to get location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photoPath = await _incidentService.captureImage();
      if (photoPath != null) {
        setState(() => _photoPath = photoPath);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture photo: $e');
    }
  }

  Future<void> _handleVoiceRecording() async {
    if (_incidentService.isRecording.value) {
      final String? path = await _incidentService.stopVoiceRecording();
      if (path != null) {
        setState(() {
          _voiceNotePath = path;
        });
      }
    } else {
      final bool started = await _incidentService.startVoiceRecording();
      if (!started) {
        Get.snackbar(
          'Error',
          'Failed to start recording. Please check microphone permissions.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      Get.snackbar('Error', 'Please fill all required fields and select location');
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      final incident = Incident(
        title: _titleController.text,
        description: _descriptionController.text,
        photoPath: _photoPath,
        voiceNotePath: _voiceNotePath,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        createdAt: DateTime.now(),
        userId: 1, // TODO: Get actual user ID
      );

      final success = await _incidentService.createIncident(incident);
      if (success) {
        Get.back();
        Get.snackbar('Success', 'Incident reported successfully');
      } else {
        Get.snackbar('Error', 'Failed to create incident');
      }
    } finally {
      setState(() => _isLoading = false);
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
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(() {
                            final isRecording = _incidentService.isRecording.value;
                            return ElevatedButton.icon(
                              onPressed: _handleVoiceRecording,
                              icon: Icon(isRecording ? Icons.stop : Icons.mic),
                              label: Text(isRecording ? 'Stop' : 'Record'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isRecording ? Colors.red : null,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_photoPath != null) ...[
                      Image.file(
                        File(_photoPath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Get Current Location'),
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
                      onPressed: _submitIncident,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Submit Report'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
