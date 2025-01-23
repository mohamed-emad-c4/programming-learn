import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.32:8000';

  // تسجيل حساب جديد
  static Future<Map<String, dynamic>> register({
    required String name,
    required String nickname,
    required String country,
    required String email,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'nickname': nickname,
        'country': country,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 422) {
      throw Exception('Validation Error: ${response.body}');
    } else {
      throw Exception('Failed to register: ${response.statusCode}');
    }
  }

  // تسجيل الدخول
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'password',
        'username': username,
        'password': password,
        'scope': '',
        'client_id': '',
        'client_secret': '',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // يعيد الـ token كـ Map
    } else if (response.statusCode == 422) {
      throw Exception('Validation Error: ${response.body}');
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }

// lib/data/datasources/api_service.dart
// lib/data/datasources/api_service.dart
static Future<bool> verifyToken(String token) async {
  final url = Uri.parse('$baseUrl/verify-token'); // Replace with your endpoint
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return true; // Token is valid
  } else {
    return false; // Token is invalid
  }
}
}
