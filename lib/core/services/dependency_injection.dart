import 'package:get/get.dart';
import 'dart:developer' as developer;

import 'local_storage_service.dart';
import 'api_service.dart';

class DependencyInjection {
  static Future<void> init() async {
    developer.log('Initializing dependencies');
    
    // Initialize LocalStorageService
    await Get.putAsync<LocalStorageService>(() async {
      final service = LocalStorageService();
      return await service.init();
    });
    
    // Initialize ApiService
    await Get.putAsync<ApiService>(() async {
      final service = ApiService();
      return await service.init();
    });
    
    developer.log('All dependencies initialized');
  }
} 