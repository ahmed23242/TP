import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/incident_controller.dart';
import '../models/incident.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final IncidentController _incidentController = Get.find<IncidentController>();
  final LocationService _locationService = Get.find<LocationService>();
  
  final Completer<GoogleMapController> _mapController = Completer();
  final Map<String, Marker> _markers = {};
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 2,
  );
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  Future<void> _initializeMap() async {
    try {
      // Obtenir la position actuelle
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 13,
        );
      }
      
      // Charger les incidents si nécessaire
      if (_incidentController.incidents.isEmpty) {
        await _incidentController.loadIncidents();
      }
      
      // Ajouter les marqueurs
      _updateMarkers();
      
      // Forcer une mise à jour de l'UI
      if (mounted) setState(() {});
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'obtenir votre position actuelle',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void _updateMarkers() {
    _markers.clear();
    
    // Ajouter un marqueur pour chaque incident
    for (final incident in _incidentController.incidents) {
      final marker = Marker(
        markerId: MarkerId('incident_${incident.id}'),
        position: LatLng(incident.latitude, incident.longitude),
        infoWindow: InfoWindow(
          title: incident.title,
          snippet: incident.description.length > 50
              ? '${incident.description.substring(0, 50)}...'
              : incident.description,
          onTap: () => Get.toNamed('/incident/details', arguments: incident),
        ),
        icon: _getMarkerIcon(incident),
      );
      
      _markers['incident_${incident.id}'] = marker;
    }
  }
  
  BitmapDescriptor _getMarkerIcon(Incident incident) {
    // Par défaut, utiliser le marqueur rouge standard
    return BitmapDescriptor.defaultMarkerWithHue(
      _getMarkerHue(incident.incidentType),
    );
  }
  
  double _getMarkerHue(String incidentType) {
    switch (incidentType.toLowerCase()) {
      case 'fire':
        return BitmapDescriptor.hueRed;
      case 'accident':
        return BitmapDescriptor.hueOrange;
      case 'danger':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }
  
  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    _updateMarkers();
    
    // Animer vers la position initiale
    if (_initialCameraPosition.target.latitude != 0) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(_initialCameraPosition),
      );
    } else if (_incidentController.incidents.isNotEmpty) {
      // S'il n'y a pas de position initiale mais qu'il y a des incidents, centrer sur le premier
      final incident = _incidentController.incidents.first;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(incident.latitude, incident.longitude),
          13,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () async {
              await _incidentController.loadIncidents();
              _updateMarkers();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Ma position',
            onPressed: () async {
              try {
                final position = await _locationService.getCurrentLocation();
                if (position != null) {
                  final GoogleMapController controller = await _mapController.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(position.latitude, position.longitude),
                      15,
                    ),
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Erreur',
                  'Impossible d\'obtenir votre position actuelle',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        _updateMarkers();
        
        return GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          onMapCreated: _onMapCreated,
          markers: Set<Marker>.of(_markers.values),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/incident/create'),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Signaler'),
      ),
    );
  }
}
