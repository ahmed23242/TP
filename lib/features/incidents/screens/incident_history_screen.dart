import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/incident_controller.dart';
import '../widgets/incident_card.dart';
import '../models/incident.dart';
import '../../../core/network/connectivity_service.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  final IncidentController _incidentController = Get.find<IncidentController>();
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  
  // Filtres
  final RxString _statusFilter = 'all'.obs;
  final RxString _typeFilter = 'all'.obs;
  final RxString _sortOption = 'date_desc'.obs;
  
  @override
  void initState() {
    super.initState();
    // Utiliser Future.microtask ou Future.delayed pour éviter
    // d'appeler loadIncidents pendant le build
    Future.microtask(() {
      _incidentController.loadIncidents();
    });
  }
  
  List<Incident> _getFilteredIncidents() {
    List<Incident> filteredList = List.from(_incidentController.incidents);
    
    // Filtrer par statut
    if (_statusFilter.value != 'all') {
      filteredList = filteredList.where((i) => i.status == _statusFilter.value).toList();
    }
    
    // Filtrer par type
    if (_typeFilter.value != 'all') {
      filteredList = filteredList.where((i) => i.incidentType == _typeFilter.value).toList();
    }
    
    // Trier
    switch (_sortOption.value) {
      case 'date_asc':
        filteredList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'date_desc':
        filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'status':
        filteredList.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'type':
        filteredList.sort((a, b) => a.incidentType.compareTo(b.incidentType));
        break;
    }
    
    return filteredList;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des incidents'),
        actions: [
          Obx(() => _connectivityService.isConnected.value
            ? const Icon(Icons.wifi, color: Colors.green)
            : const Icon(Icons.wifi_off, color: Colors.red)
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser',
            onPressed: () async {
              await _incidentController.syncIncidents();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronisation terminée')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _incidentController.loadIncidents(),
        child: Obx(() {
          if (_incidentController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final incidents = _getFilteredIncidents();
          
          if (incidents.isEmpty) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun incident trouvé',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _incidentController.loadIncidents(),
                        child: const Text('Actualiser'),
                      ),
                      TextButton(
                        onPressed: () => Get.toNamed('/incident/create'),
                        child: const Text('Signaler un incident'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return IncidentCard(
                incident: incident,
                onTap: () => Get.toNamed(
                  '/incident/details',
                  arguments: incident,
                ),
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/incident/create'),
        icon: const Icon(Icons.add),
        label: const Text('Signaler'),
      ),
    );
  }
  
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet à la feuille de défilement de prendre plus d'espace
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16, 
                right: 16,
                top: 16
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrer les incidents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Statut
                  const Text('Statut:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Obx(() => Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _statusFilter.value == 'all',
                        onSelected: (selected) => _statusFilter.value = 'all',
                      ),
                      FilterChip(
                        label: const Text('En attente'),
                        selected: _statusFilter.value == 'pending',
                        onSelected: (selected) => _statusFilter.value = 'pending',
                      ),
                      FilterChip(
                        label: const Text('En cours'),
                        selected: _statusFilter.value == 'in_progress',
                        onSelected: (selected) => _statusFilter.value = 'in_progress',
                      ),
                      FilterChip(
                        label: const Text('Terminé'),
                        selected: _statusFilter.value == 'completed',
                        onSelected: (selected) => _statusFilter.value = 'completed',
                      ),
                    ],
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Type
                  const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Obx(() => Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _typeFilter.value == 'all',
                        onSelected: (selected) => _typeFilter.value = 'all',
                      ),
                      FilterChip(
                        label: const Text('Général'),
                        selected: _typeFilter.value == 'general',
                        onSelected: (selected) => _typeFilter.value = 'general',
                      ),
                      FilterChip(
                        label: const Text('Accident'),
                        selected: _typeFilter.value == 'accident',
                        onSelected: (selected) => _typeFilter.value = 'accident',
                      ),
                      FilterChip(
                        label: const Text('Incendie'),
                        selected: _typeFilter.value == 'fire',
                        onSelected: (selected) => _typeFilter.value = 'fire',
                      ),
                      FilterChip(
                        label: const Text('Danger'),
                        selected: _typeFilter.value == 'danger',
                        onSelected: (selected) => _typeFilter.value = 'danger',
                      ),
                    ],
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Tri
                  const Text('Tri:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Obx(() => Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Date ↓'),
                        selected: _sortOption.value == 'date_desc',
                        onSelected: (selected) => _sortOption.value = 'date_desc',
                      ),
                      ChoiceChip(
                        label: const Text('Date ↑'),
                        selected: _sortOption.value == 'date_asc',
                        onSelected: (selected) => _sortOption.value = 'date_asc',
                      ),
                      ChoiceChip(
                        label: const Text('Statut'),
                        selected: _sortOption.value == 'status',
                        onSelected: (selected) => _sortOption.value = 'status',
                      ),
                      ChoiceChip(
                        label: const Text('Type'),
                        selected: _sortOption.value == 'type',
                        onSelected: (selected) => _sortOption.value = 'type',
                      ),
                    ],
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _statusFilter.value = 'all';
                          _typeFilter.value = 'all';
                          _sortOption.value = 'date_desc';
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Appliquer'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 