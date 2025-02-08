import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.218.244:8000/api';

  // تسجيل حساب جديد
  static Future<Map<String, dynamic>> register({
    required String name,
    required String nickname,
    required String country,
    required String email,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/users/register');
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
    final url = Uri.parse('$baseUrl/users/login');
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
  final url = Uri.parse('$baseUrl/users/verify-token'); // Ensure correct path

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token', // Token in header
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['is_valid']; // Returns true if valid
  } else {
    return false; // Token is invalid
  }
}
 
  // دالة لجلب الدروس
  static Future<List<Map<String, dynamic>>> getLessons(int languageId, int chapterNumber, String token) async {
    try {
      final url = Uri.parse('$baseUrl/lessons/$languageId/$chapterNumber');
      final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    },);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load lessons: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load lessons: $e');
    }
  }

static Future<List<Map<String, dynamic>>> getCourses() async {
  final url = Uri.parse('$baseUrl/courses');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load courses: ${response.statusCode}');
  }
}
static Future<Map<String, dynamic>> getCourseById(int courseId) async {
  final url = Uri.parse('$baseUrl/courses/$courseId');  // ✅ Correct API endpoint
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // ✅ Parse JSON response
  } else {
    throw Exception('Failed to load course: ${response.statusCode}');
  }
}

static Future<List<Map<String, dynamic>>> getChaptersByCourseId(int courseId) async {
  final url = Uri.parse('$baseUrl/chapters/course/$courseId');  // ✅ New Endpoint
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load chapters: ${response.statusCode}');
  }
}

static Future<List<Map<String, dynamic>>> getChapters(int courseId) async {
  final url = Uri.parse('$baseUrl/chapters/$courseId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load chapters: ${response.statusCode}');
  }
}
static Future<List<Map<String, dynamic>>> getAllChapters() async {
  final url = Uri.parse('$baseUrl/chapters');  // ✅ No course_id in the URL
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load chapters: ${response.statusCode}');
  }
}







}
