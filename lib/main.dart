import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/auth/services/auth_service.dart';
import 'features/incidents/services/incident_service.dart';
import 'features/incidents/controllers/incident_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/incidents/screens/home_screen.dart';
import 'features/incidents/screens/map_screen.dart';
import 'features/incidents/screens/create_incident_screen.dart';
import 'features/incidents/screens/incident_details_screen.dart';
import 'features/incidents/screens/incident_history_screen.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/incidents/services/location_service.dart';
import 'features/incidents/services/audio_service.dart';
import 'features/incidents/services/stats_service.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/api_service.dart';
import 'core/services/permission_service.dart';
import 'features/incidents/services/sync_service.dart';
import 'core/database/database_helper.dart';
import 'core/services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activation du mode test pour éviter les erreurs de navigation sans contexte
  Get.testMode = true;
  
  try {
    // Initialisation des services réseau
    final connectivityService = await Get.putAsync(() => ConnectivityService().init());
    final apiService = await Get.putAsync(() => ApiService(connectivityService: connectivityService).init());
    
    // Initialisation des services audio et localisation avant les incidents
    final audioService = await Get.putAsync(() => AudioService().init());
    final locationService = await Get.putAsync(() => LocationService().init());
    final navigationService = await Get.putAsync(() => NavigationService().init());
    
    // Initialisation des services d'authentification
    final authService = await Get.putAsync(() => AuthService(apiService: apiService).init());
    
    // Initialisation des services de gestion des incidents (après AudioService)
    Get.put(IncidentService(), permanent: true);
    
    // Initialisation du service de statistiques
    final statsService = await Get.putAsync(() => StatsService().init());
    
    // Initialisation du contrôleur d'authentification (après les services)
    final authController = AuthController();
    Get.put(authController, permanent: true);
    
    // Initialisation des services de synchronisation et de permissions
    Get.put(SyncService(), permanent: true);
    final permissionService = PermissionService();
    Get.put(permissionService, permanent: true);
  } catch (e) {
    print('Error during initialization: $e');
  }
  
  // Démarrer l'application
  runApp(const MyApp());
  
  // Vérifier les permissions après un court délai pour ne pas bloquer le démarrage
  Future.delayed(const Duration(seconds: 2), () {
    try {
      Get.find<PermissionService>().requestAllPermissions();
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urban Incidents',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      initialBinding: BindingsBuilder(() {
        // Note: les services principaux sont déjà enregistrés dans main()
        Get.lazyPut(() => IncidentController());
      }),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(
          name: '/home', 
          page: () => const HomeScreen(),
          binding: BindingsBuilder(() {
            Get.put(IncidentController());
          }),
        ),
        GetPage(
          name: '/map', 
          page: () => const MapScreen(),
          binding: BindingsBuilder(() {
            Get.put(IncidentController());
          }),
        ),
        GetPage(
          name: '/incident/create', 
          page: () => const CreateIncidentScreen(),
          binding: BindingsBuilder(() {
            Get.put(IncidentController());
          }),
        ),
        GetPage(
          name: '/incident/details', 
          page: () => IncidentDetailsScreen(),
          binding: BindingsBuilder(() {
            Get.put(IncidentController());
          }),
        ),
        GetPage(
          name: '/incident/history', 
          page: () => const IncidentHistoryScreen(),
          binding: BindingsBuilder(() {
            Get.put(IncidentController());
          }),
        ),
      ],
    );
  }
}

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Urban Incidents Reporter',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => authController.loginWithBiometrics(),
                child: const Text('Login with Biometrics'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.toNamed('/login'),
                child: const Text('Login with Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
