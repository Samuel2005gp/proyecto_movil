import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  // GET request
  static Future<http.Response> get(String endpoint) async {
    final token = await StorageService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      _handleUnauthorized(response);
      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // POST request
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await StorageService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      _handleUnauthorized(response);
      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // PUT request
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final token = await StorageService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      _handleUnauthorized(response);
      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // PATCH request
  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final token = await StorageService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      _handleUnauthorized(response);
      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final token = await StorageService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.delete(url, headers: headers);
      _handleUnauthorized(response);
      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Manejar respuestas 401 (no autorizado)
  static void _handleUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      StorageService.clearAll();
      throw UnauthorizedException('Sesión expirada. Por favor inicia sesión nuevamente.');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => message;
}
