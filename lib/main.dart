import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/auth/services/auth_service.dart';
import 'features/incidents/services/incident_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/incidents/screens/home_screen.dart';
import 'features/incidents/screens/map_screen.dart';
import 'features/incidents/screens/create_incident_screen.dart';
import 'features/incidents/screens/incident_details_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
        Get.put(AuthService());
        Get.put(IncidentService());
      }),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/map', page: () => const MapScreen()),
        GetPage(name: '/incident/create', page: () => const CreateIncidentScreen()),
        GetPage(name: '/incident/details', page: () => IncidentDetailsScreen()),
      ],
    );
  }
}

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();

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
                onPressed: () async {
                  bool authenticated = await authService.authenticateWithBiometrics();
                  if (authenticated) {
                    Get.off(() => const HomeScreen());
                  }
                },
                child: const Text('Login with Biometrics'),
              ),
              const SizedBox(height: 16),
              // TODO: Add email/password login form
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final IncidentService incidentService = Get.find<IncidentService>();
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
              Get.off(() => const AuthenticationScreen());
            },
          ),
        ],
      ),
      body: Obx(() => ListView.builder(
        itemCount: incidentService.incidents.length,
        itemBuilder: (context, index) {
          final incident = incidentService.incidents[index];
          return ListTile(
            title: Text(incident.title),
            subtitle: Text(incident.description),
            trailing: Text(incident.syncStatus),
            // TODO: Add incident details view
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const CreateIncidentScreen());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
