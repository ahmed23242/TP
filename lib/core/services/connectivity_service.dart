import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = false.obs;
  
  Future<ConnectivityService> init() async {
    developer.log('Initializing ConnectivityService');
    
    // Check initial connectivity status
    final connectivityResults = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResults);
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
    
    developer.log('ConnectivityService initialized. Current status: ${isConnected.value ? 'Connected' : 'Disconnected'}');
    return this;
  }

  @override
  void onInit() {
    super.onInit();
    // Initialization moved to init() method
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If any connectivity result is not 'none', then we consider the device connected
    isConnected.value = results.any((result) => result != ConnectivityResult.none);
    developer.log('Connection status updated: ${isConnected.value ? 'Connected' : 'Disconnected'}');
  }

  Future<bool> checkConnectivity() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResults);
    return isConnected.value;
  }
} 