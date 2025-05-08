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
import '../../../core/widgets/common_widgets.dart';

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> with SingleTickerProviderStateMixin {
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
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Step tracking
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Liste des types d'incidents avec icônes
  final List<Map<String, dynamic>> _incidentTypes = [
    {'value': 'general', 'label': 'General', 'icon': Icons.warning_amber_rounded},
    {'value': 'fire', 'label': 'Fire', 'icon': Icons.local_fire_department},
    {'value': 'accident', 'label': 'Accident', 'icon': Icons.car_crash},
    {'value': 'medical', 'label': 'Medical Emergency', 'icon': Icons.medical_services},
    {'value': 'crime', 'label': 'Crime', 'icon': Icons.gavel},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _incidentController = Get.find<IncidentController>();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
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
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom app bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nouvel Incident',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentStep--;
                              _animationController.reset();
                              _animationController.forward();
                            });
                          },
                          child: const Text('Précédent'),
                        ),
                    ],
                  ),
                ),
                
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_totalSteps, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Step content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildTypeSelectionStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildMediaStep();
      case 3:
        return _buildLocationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTypeSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type d\'incident',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez le type d\'incident que vous souhaitez signaler',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _incidentTypes.length,
          itemBuilder: (context, index) {
            final type = _incidentTypes[index];
            final isSelected = _selectedIncidentType == type['value'];
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIncidentType = type['value'];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type['icon'],
                      size: 32,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type['label'],
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep++;
                _animationController.reset();
                _animationController.forward();
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Suivant'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails de l\'incident',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Décrivez l\'incident en détail pour aider les intervenants',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Donnez un titre court et descriptif',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez l\'incident en détail',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Précédent'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _currentStep++;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Suivant'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Médias',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez des photos et vidéos pour illustrer l\'incident',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        
        // Main photo
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photo principale',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_photoPath != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_photoPath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _photoPath = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: _takePhoto,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.none,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajouter une photo',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Additional media
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Médias additionnels',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        tooltip: 'Ajouter une image',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      IconButton(
                        onPressed: _recordVideo,
                        icon: const Icon(Icons.videocam),
                        tooltip: 'Enregistrer une vidéo',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      IconButton(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.video_library),
                        tooltip: 'Choisir une vidéo',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_additionalMedia.isNotEmpty) ...[
                const SizedBox(height: 16),
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
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: media['type'] == 'image'
                                  ? Image.file(
                                      File(media['path']),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Container(
                                      color: Colors.black,
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _additionalMedia.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(4),
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
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Précédent'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep++;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Suivant'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirmez l\'emplacement de l\'incident',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        
        // Map
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedLocation != null)
                SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 80,
                              height: 80,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _titleController.text.isNotEmpty
                                          ? _titleController.text
                                          : 'Incident',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 40,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.none,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Obtenir ma position'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                    _animationController.reset();
                    _animationController.forward();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Précédent'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedLocation != null ? _submitIncident : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Soumettre'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
