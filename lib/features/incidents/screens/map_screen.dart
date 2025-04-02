import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/incident_controller.dart';
import '../models/incident.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final IncidentController _incidentController = Get.find<IncidentController>();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    _markers.clear();
    for (var incident in _incidentController.incidents) {
      _markers.add(
        Marker(
          markerId: MarkerId(incident.id?.toString() ?? ''),
          position: LatLng(incident.latitude, incident.longitude),
          infoWindow: InfoWindow(
            title: incident.title,
            snippet: incident.description,
            onTap: () => _onMarkerTapped(incident),
          ),
        ),
      );
    }
    setState(() {});
  }

  void _onMarkerTapped(Incident incident) {
    Get.toNamed('/incident/details', arguments: incident);
  }

  void _fitBounds() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = lat < minLat ? lat : minLat;
      maxLat = lat > maxLat ? lat : maxLat;
      minLng = lng < minLng ? lng : minLng;
      maxLng = lng > maxLng ? lng : maxLng;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _incidentController.loadIncidents();
              _loadMarkers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitBounds,
          ),
        ],
      ),
      body: Obx(() {
        if (_incidentController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(0, 0),
            zoom: 2,
          ),
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
            _fitBounds();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: true,
          zoomControlsEnabled: true,
          compassEnabled: true,
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/incident/create'),
        child: const Icon(Icons.add_location),
      ),
    );
  }
}
