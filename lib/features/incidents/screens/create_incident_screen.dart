import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
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
  
  // Media files storage
  final List<Map<String, dynamic>> _additionalMedia = [];
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;
  
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
    _videoPlayerController?.dispose();
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
  
  Future<void> _pickImage() async {
    try {
      final status = await Permission.photos.request();
      if (status != PermissionStatus.granted) {
        Get.snackbar(
          'Error',
          'Gallery permission denied',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _additionalMedia.add({
            'type': 'image',
            'path': pickedFile.path,
            'caption': 'Image ${_additionalMedia.length + 1}'
          });
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }
  
  Future<void> _recordVideo() async {
    try {
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();
      
      if (cameraStatus != PermissionStatus.granted || 
          microphoneStatus != PermissionStatus.granted) {
        Get.snackbar(
          'Error',
          'Camera and microphone permissions are required to record video',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );
      
      if (pickedFile != null) {
        setState(() {
          _additionalMedia.add({
            'type': 'video',
            'path': pickedFile.path,
            'caption': 'Video ${_additionalMedia.length + 1}'
          });
          
          // Initialize video player for preview
          _initializeVideoPlayer(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to record video: $e');
    }
  }
  
  Future<void> _pickVideo() async {
    try {
      final status = await Permission.photos.request();
      if (status != PermissionStatus.granted) {
        Get.snackbar(
          'Error',
          'Gallery permission denied',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (pickedFile != null) {
        setState(() {
          _additionalMedia.add({
            'type': 'video',
            'path': pickedFile.path,
            'caption': 'Video ${_additionalMedia.length + 1}'
          });
          
          // Initialize video player for preview
          _initializeVideoPlayer(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video: $e');
    }
  }
  
  Future<void> _initializeVideoPlayer(String videoPath) async {
    // Dispose previous controller if exists
    await _videoPlayerController?.dispose();
    
    // Create new controller
    _videoPlayerController = VideoPlayerController.file(File(videoPath));
    
    // Initialize and update UI when ready
    await _videoPlayerController!.initialize();
    setState(() {});
  }
  
  void _toggleVideoPlayback() {
    if (_videoPlayerController == null) return;
    
    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoPlayerController!.play();
        _isVideoPlaying = true;
      }
    });
  }
  
  void _removeMedia(int index) {
    setState(() {
      _additionalMedia.removeAt(index);
    });
  }
  
  void _updateMediaCaption(int index, String caption) {
    setState(() {
      _additionalMedia[index]['caption'] = caption;
    });
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
          additionalMedia: _additionalMedia,
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedLocation != null
                                ? 'Location: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                                : 'Add Location',
                              style: TextStyle(
                                fontWeight: _selectedLocation != null ? FontWeight.normal : FontWeight.bold,
                                color: _selectedLocation != null ? Colors.black87 : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          FloatingActionButton.small(
                            heroTag: 'getLocation',
                            onPressed: _getCurrentLocation,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.location_on, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _photoPath != null ? 'Main Photo:' : 'Add Main Photo:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        FloatingActionButton.small(
                          heroTag: 'takePhoto',
                          onPressed: _takePhoto,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ],
                    ),
                    if (_photoPath != null) ...[                      
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_photoPath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Additional Media:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            // Image picker button
                            FloatingActionButton.small(
                              heroTag: 'pickImage',
                              onPressed: _pickImage,
                              backgroundColor: Colors.green,
                              child: const Icon(Icons.photo_library, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            // Video recorder button
                            FloatingActionButton.small(
                              heroTag: 'recordVideo',
                              onPressed: _recordVideo,
                              backgroundColor: Colors.red,
                              child: const Icon(Icons.videocam, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            // Video picker button
                            FloatingActionButton.small(
                              heroTag: 'pickVideo',
                              onPressed: _pickVideo,
                              backgroundColor: Colors.purple,
                              child: const Icon(Icons.video_library, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    if (_additionalMedia.isNotEmpty) ...[                      
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Media (${_additionalMedia.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _additionalMedia.length,
                                itemBuilder: (context, index) {
                                  final media = _additionalMedia[index];
                                  return Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Media preview
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: media['type'] == 'image'
                                                ? Image.file(
                                                    File(media['path']),
                                                    fit: BoxFit.cover,
                                                  )
                                                : Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Container(
                                                        color: Colors.black,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      ),
                                                      const Icon(
                                                        Icons.play_circle_fill,
                                                        color: Colors.white,
                                                        size: 40,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        
                                        // Type indicator
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: media['type'] == 'image' ? Colors.green : Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  media['type'] == 'image' ? Icons.image : Icons.videocam,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  media['type'] == 'image' ? 'Image' : 'Video',
                                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        // Remove button
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => _removeMedia(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Voice Note:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    AudioRecorderWidget(
                      onRecordingComplete: _onRecordingComplete,
                      initialRecordingPath: _voiceNotePath,
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: _selectedLocation!,
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.accidentsapp',
                              tileProvider: NetworkTileProvider(),
                              maxZoom: 19,
                              tileSize: 256,
                              keepBuffer: 5,
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 40.0,
                                  height: 40.0,
                                  point: _selectedLocation!,
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
                    ],
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitIncident,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Submit Report',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
