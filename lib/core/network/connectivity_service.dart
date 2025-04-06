import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _initConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      developer.log('Error checking connectivity', error: e);
      isConnected.value = false;
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Si n'importe quelle connexion est active, considérer comme connecté
    final bool hasConnection = results.any((result) => 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.ethernet);
    
    isConnected.value = hasConnection;
    
    if (hasConnection) {
      developer.log('Connected to the internet: ${results.map((r) => r.name).join(', ')}');
    } else {
      developer.log('Not connected to the internet: ${results.map((r) => r.name).join(', ')}');
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return isConnected.value;
    } catch (e) {
      developer.log('Error checking connectivity', error: e);
      isConnected.value = false;
      return false;
    }
  }
} 