import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:learn_programming/data/datasources/values.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.8:8000/api';

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
  Future<List<Map<String, dynamic>>> fetchQuizzesByLesson(int lessonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/by-lesson/$lessonId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load quizzes');
    }
  }
Future<void> submitQuizAnswers(int quizId, Map<int, int> selectedAnswers, String token) async {
  final List<Map<String, dynamic>> answers = selectedAnswers.entries
      .map((entry) => {
            "question_id": entry.key,
            "selected_option": entry.value,
          })
      .toList();

  final response = await http.post(
    Uri.parse('$baseUrl/quizzes/$quizId/submit'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({"answers": answers}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to submit quiz.');
  }
}
static Future<http.Response> submitQuiz(
    int quizId, List<Map<String, dynamic>> answers, String token) async {
  final url = Uri.parse('$baseUrl/quizzes/$quizId/submit');
  return await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({"answers": answers}),
  );
}

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
 Future<List<Map<String, dynamic>>> fetchLessons(int chapterNumber) async {
  final response = await http.get(
    Uri.parse('$baseUrl/lessons/chapter/$chapterNumber'),
    headers: {'Content-Type': 'application/json'},
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  } else {
    throw Exception('Failed to load lessons');
  }
}

 Future<Map<String, dynamic>> fetchLesson(int lessonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lessons/details/$lessonId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load lesson');
    }
  }

  
  // دالة لجلب الدروس
  static Future<List<Map<String, dynamic>>> getLessons(int languageId, int chapterNumber, String token) async {
    try {
      final url = Uri.parse('$baseUrl/lessons/$chapterNumber');
      final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    },);
      current_chapter_Id = chapterNumber;
      current_course_Id = languageId;
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
