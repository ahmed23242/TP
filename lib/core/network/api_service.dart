import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

class ApiService extends GetxController {
  // URL de base de l'API
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Pour l'émulateur Android
  // static const String baseUrl = 'http://localhost:8000/api'; // Pour le développement local
  // static const String baseUrl = 'https://votre-api-de-production.com/api'; // Pour la production
  
  final _storage = const FlutterSecureStorage();
  final RxBool isConnected = false.obs;
  
  // Points d'entrée de l'API
  static const String loginEndpoint = '$baseUrl/users/token/';
  static const String registerEndpoint = '$baseUrl/users/register/';
  static const String userProfileEndpoint = '$baseUrl/users/profile/';
  static const String incidentsEndpoint = '$baseUrl/incidents/';
  static const String tokenRefreshEndpoint = '$baseUrl/users/token/refresh/';
  
  @override
  void onInit() {
    super.onInit();
    _checkConnection();
  }
  
  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      isConnected.value = response.statusCode < 400;
      developer.log('API connection status: ${isConnected.value}');
    } catch (e) {
      isConnected.value = false;
      developer.log('API connection failed: $e');
    }
  }
  
  // Méthode pour obtenir les en-têtes d'authentification
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  // Méthode pour vérifier et rafraîchir le token si nécessaire
  Future<String?> _getValidToken() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;
      
      // Vérifier si le token est expiré (implémentation simplifiée)
      // Dans une application réelle, il faudrait décoder le JWT et vérifier la date d'expiration
      
      // Pour cet exemple, nous supposons juste que le token est valide
      return token;
    } catch (e) {
      developer.log('Error getting valid token: $e');
      return null;
    }
  }
  
  // Méthode pour se connecter
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await _checkConnection();
      if (!isConnected.value) {
        throw Exception('No internet connection');
      }
      
      final response = await http.post(
        Uri.parse(loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email, // Le backend utilise 'username' au lieu de 'email'
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Stocker le token de manière sécurisée
        await _storage.write(key: 'jwt_token', value: data['access']);
        await _storage.write(key: 'refresh_token', value: data['refresh']);
        
        // Retourner les données utilisateur
        return data['user'];
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      developer.log('API login error: $e');
      throw Exception('Login failed: $e');
    }
  }
  
  // Méthode pour s'inscrire
  Future<Map<String, dynamic>> register(String email, String password, String phone) async {
    try {
      await _checkConnection();
      if (!isConnected.value) {
        throw Exception('No internet connection');
      }
      
      final response = await http.post(
        Uri.parse(registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email, // Le backend utilise 'username' comme identifiant principal
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'user', // Rôle par défaut
        }),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      developer.log('API register error: $e');
      throw Exception('Registration failed: $e');
    }
  }
  
  // Méthode pour obtenir le profil utilisateur
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      await _checkConnection();
      if (!isConnected.value) {
        throw Exception('No internet connection');
      }
      
      final response = await http.get(
        Uri.parse(userProfileEndpoint),
        headers: await _getAuthHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user profile: ${response.body}');
      }
    } catch (e) {
      developer.log('API get user profile error: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  // Méthode pour envoyer un incident
  Future<Map<String, dynamic>> createIncident(Map<String, dynamic> incidentData) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      await _checkConnection();
      if (!isConnected.value) {
        throw Exception('No internet connection');
      }
      
      // Pour l'envoi de fichiers, il faudrait utiliser multipart/form-data
      // Mais pour simplifier, nous utiliserons juste application/json
      final response = await http.post(
        Uri.parse(incidentsEndpoint),
        headers: await _getAuthHeaders(),
        body: jsonEncode(incidentData),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create incident: ${response.body}');
      }
    } catch (e) {
      developer.log('API create incident error: $e');
      throw Exception('Failed to create incident: $e');
    }
  }
  
  // Méthode pour obtenir les incidents d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserIncidents() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      await _checkConnection();
      if (!isConnected.value) {
        throw Exception('No internet connection');
      }
      
      final response = await http.get(
        Uri.parse(incidentsEndpoint),
        headers: await _getAuthHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get user incidents: ${response.body}');
      }
    } catch (e) {
      developer.log('API get user incidents error: $e');
      throw Exception('Failed to get user incidents: $e');
    }
  }
  
  // Méthode pour synchroniser un incident
  Future<Map<String, dynamic>> syncIncident(Map<String, dynamic> incidentData) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      await _checkConnection();
      if (!isConnected.value) {
        throw Exception('No internet connection');
      }
      
      // Pour l'envoi de fichiers, il faudrait utiliser multipart/form-data
      // Mais pour simplifier, nous utiliserons juste application/json
      final response = await http.post(
        Uri.parse(incidentsEndpoint),
        headers: await _getAuthHeaders(),
        body: jsonEncode(incidentData),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to sync incident: ${response.body}');
      }
    } catch (e) {
      developer.log('API sync incident error: $e');
      throw Exception('Failed to sync incident: $e');
    }
  }
} 