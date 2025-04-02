import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // For Android Emulator
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to request if it exists
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              try {
                final response = await _dio.post(
                  '$baseUrl/users/token/refresh/',
                  data: {'refresh': refreshToken},
                );
                
                final newToken = response.data['access'];
                await _storage.write(key: 'access_token', value: newToken);
                
                // Retry the original request
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final clonedRequest = await _dio.request(
                  error.requestOptions.path,
                  options: Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  ),
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                
                return handler.resolve(clonedRequest);
              } catch (e) {
                // Refresh token failed, user needs to login again
                await _storage.deleteAll();
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Authentication
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/users/token/',
        data: {'username': username, 'password': password},
      );
      
      await _storage.write(key: 'access_token', value: response.data['access']);
      await _storage.write(key: 'refresh_token', value: response.data['refresh']);
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(
        '$baseUrl/users/register/',
        data: userData,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Incidents
  Future<List<Map<String, dynamic>>> getIncidents() async {
    try {
      final response = await _dio.get('$baseUrl/incidents/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createIncident(Map<String, dynamic> incidentData) async {
    try {
      final formData = FormData.fromMap(incidentData);
      
      if (incidentData['photo'] != null) {
        formData.files.add(
          MapEntry(
            'photo',
            await MultipartFile.fromFile(incidentData['photo']),
          ),
        );
      }
      
      if (incidentData['voice_note'] != null) {
        formData.files.add(
          MapEntry(
            'voice_note',
            await MultipartFile.fromFile(incidentData['voice_note']),
          ),
        );
      }
      
      final response = await _dio.post(
        '$baseUrl/incidents/',
        data: formData,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncOfflineIncidents(List<Map<String, dynamic>> incidents) async {
    for (var incident in incidents) {
      try {
        await createIncident(incident);
      } catch (e) {
        print('Error syncing incident: $e');
        // Continue with next incident even if one fails
        continue;
      }
    }
  }
}
