import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:learn_programming/data/datasources/values.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/problem_model.dart';
import '../models/tag.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.9:8000/api';

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
        'username': nickname,
        // 'country': country,
        'email': email,
        'password': password,
        'role': "student",
      }),
    );
    dev.log('Error: ${response.body}');
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
    dev.log('username: $username');
    dev.log('password: $password');
    final url = Uri.parse('$baseUrl/users/login');
    dev.log('Login URL: $url');

    try {
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

      dev.log('Login response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        dev.log('Login error response: ${response.body}');
      }

      final body = jsonDecode(response.body);
      dev.log('tokeeeeeeen: ${body['access_token']}');
      token = body['access_token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token_access', token);

      if (response.statusCode == 200) {
        // dev.log('Login successful: ${response.body}');
        return jsonDecode(response.body); // يعيد الـ token كـ Map
      } else if (response.statusCode == 422) {
        throw Exception('Validation Error: ${response.body}');
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('Login exception: $e');
      throw Exception('فشل في تسجيل الدخول: $e');
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

  Future<void> submitQuizAnswers(
      int quizId, Map<int, int> selectedAnswers, String token) async {
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

  Future<Map<String, dynamic>> submitQuiz(
      {required int quizId,
      required List<Map<String, dynamic>> answers,
      String? token}) async {
    final url = Uri.parse('$baseUrl/quizzes/$quizId/submit');
    try {
      dev.log('Submitting quiz to $url');

      // Ensure each answer has correct format
      final validatedAnswers = answers
          .map((answer) => {
                "question_id": answer["question_id"],
                "selected_option": answer["selected_option"],
              })
          .toList();

      dev.log('Formatted answers: $validatedAnswers');

      final headers = {
        'Content-Type': 'application/json',
      };

      // Add token if available
      if (token != null && token.isNotEmpty) {
        dev.log('Using token for submission: $token');
        headers['Authorization'] = 'Bearer $token';
      } else {
        dev.log('No token available for submission');
      }

      // Build the correct JSON structure
      final requestBody = jsonEncode({"answers": validatedAnswers});

      dev.log('Request body: $requestBody');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );

      dev.log('Quiz submission response code: ${response.statusCode}');
      dev.log('Quiz submission response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Quiz submitted successfully',
          'data': jsonResponse,
          'submission_token': jsonResponse['token'] ?? token,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to submit quiz: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e, stackTrace) {
      dev.log('Error submitting quiz: $e');
      dev.log(stackTrace.toString());
      return {
        'success': false,
        'message': 'Exception occurred: $e',
      };
    }
  }

  // Deprecated method - keeping for backward compatibility
  @Deprecated('Use instance method submitQuiz instead')
  static Future<http.Response> submitQuizStatic(
      int quizId, List<Map<String, dynamic>> answers, String token) async {
    dev.log('Warning: Using deprecated static submitQuiz method');
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

  Future<List<Map<String, dynamic>>> getData(
      String endpoint, String token) async {
    dev.log(
        'ApiService.getData: Requesting $endpoint with token ${token.substring(0, min(10, token.length))}...');
    try {
      // Special case for quiz results - send user_id if available
      if (endpoint.contains('/quizzes') && endpoint.contains('/results')) {
        return await _getQuizResults(endpoint, token);
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dev.log(
          'ApiService.getData: Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> resultList = jsonDecode(response.body);
        return resultList.map((item) => item as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401) {
        dev.log('ApiService.getData: Authentication failed (401 Unauthorized)');
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 403) {
        dev.log('ApiService.getData: Access forbidden (403 Forbidden)');
        throw Exception(
            'Access denied. You may need different permissions for this operation.');
      } else if (response.statusCode == 404) {
        dev.log('ApiService.getData: Resource not found (404 Not Found)');
        throw Exception('The requested resource was not found.');
      } else {
        dev.log(
            'ApiService.getData: Request failed with status: ${response.statusCode}');
        dev.log('ApiService.getData: Response body: ${response.body}');
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('ApiService.getData: Exception occurred: $e');
      rethrow; // Rethrow to let the caller handle it
    }
  }

  /// Special handler for quiz results that tries different API approach
  Future<List<Map<String, dynamic>>> _getQuizResults(
      String endpoint, String token) async {
    dev.log('ApiService: Using specialized quiz results handler for $endpoint');
    try {
      // Extract quiz ID from endpoint
      final quizIdStr =
          endpoint.split('/').where((part) => part.isNotEmpty).toList()[1];
      final quizId = int.tryParse(quizIdStr);

      if (quizId == null) {
        throw Exception('Invalid quiz ID in endpoint: $endpoint');
      }

      // First try the direct endpoint
      final directUrl = Uri.parse('${ApiService.baseUrl}$endpoint');
      dev.log('ApiService: Trying direct quiz results URL: $directUrl');

      final response = await http.get(
        directUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // If successful, return the results
      if (response.statusCode == 200) {
        final List<dynamic> resultList = jsonDecode(response.body);
        return resultList.map((item) => item as Map<String, dynamic>).toList();
      }

      // If we got a permission error (403), try the student-specific endpoint
      if (response.statusCode == 403) {
        dev.log(
            'ApiService: Permission denied on direct endpoint, trying student-specific endpoint');

        // Try alternative endpoint format for student role
        final alternativeUrl =
            Uri.parse('${ApiService.baseUrl}/quizzes/$quizId/my-results');
        dev.log('ApiService: Trying alternative URL: $alternativeUrl');

        final altResponse = await http.get(
          alternativeUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (altResponse.statusCode == 200) {
          final List<dynamic> resultList = jsonDecode(altResponse.body);
          return resultList
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          dev.log(
              'ApiService: Alternative endpoint also failed with status ${altResponse.statusCode}');
          throw _handleErrorResponse(altResponse);
        }
      } else {
        // For non-403 errors on the first try
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      dev.log('ApiService: Error fetching quiz results: $e');
      rethrow;
    }
  }

  /// Helper to create appropriate exception based on response
  Exception _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    String message;

    try {
      // Try to parse error message from response body
      final errorBody = jsonDecode(response.body);
      message = errorBody['message'] ?? errorBody['error'] ?? 'Unknown error';
    } catch (_) {
      // If unable to parse, use generic message
      message = 'Failed with status code: $statusCode';
    }

    if (statusCode == 401) {
      return Exception('Authentication failed. Please log in again.');
    } else if (statusCode == 403) {
      return Exception(
          'You do not have permission to access this resource. Only students who took this quiz can view their results.');
    } else if (statusCode == 404) {
      return Exception(
          'Quiz results not found. You may not have taken this quiz yet.');
    } else if (statusCode >= 500) {
      return Exception('Server error. Please try again later.');
    } else {
      return Exception('Error: $message ($statusCode)');
    }
  }

  static Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/verify-token'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_valid'];
      } else {
        return false;
      }
    } catch (e) {
      dev.log('Failed to verify token: $e');
      return false;
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
      dev.log(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load lesson');
    }
  }

  // دالة لجلب الدروس
  static Future<List<Map<String, dynamic>>> getLessons(
      int languageId, int chapterNumber, String token) async {
    try {
      final url = Uri.parse('$baseUrl/lessons/$chapterNumber');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
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
    final url =
        Uri.parse('$baseUrl/courses/$courseId'); // ✅ Correct API endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // ✅ Parse JSON response
    } else {
      throw Exception('Failed to load course: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getChaptersByCourseId(
      int courseId) async {
    final url =
        Uri.parse('$baseUrl/chapters/course/$courseId'); // ✅ New Endpoint
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
    final url = Uri.parse('$baseUrl/chapters'); // ✅ No course_id in the URL
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load chapters: ${response.statusCode}');
    }
  }

  Future<List<Tag>> getTags() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/problems/tags'));
      dev.log(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((e) => Tag.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load tags');
      }
    } catch (e) {
      dev.log('Error: $e');
      throw Exception('Failed to load tags');
    }
  }

  Future<List<ProblemModel>> getProblemsByTag(int tagId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/problems/tags/$tagId/problems'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProblemModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load problems');
    }
  }

  /// Specialized method to get quiz results for a specific quiz
  Future<List<Map<String, dynamic>>> fetchQuizResults(
      int quizId, String token) async {
    dev.log('Fetching quiz results for quiz ID: $quizId');
    final url = Uri.parse('${ApiService.baseUrl}/quizzes/$quizId/results');
    dev.log('token: $token');
    try {
      dev.log('Making request to: $url with token');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dev.log('Quiz results response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> resultList = jsonDecode(response.body);
        dev.log('Received quiz results: ${resultList.length} entries');
        return resultList.map((item) => item as Map<String, dynamic>).toList();
      } else if (response.statusCode == 403) {
        // Log more details about the 403 error
        dev.log('Permission denied (403) response: ${response.body}');
        // Try alternative endpoint for student-specific results
        dev.log('Permission denied (403), trying student-specific endpoint');
        return await _fetchStudentQuizResults(quizId, token);
      } else if (response.statusCode == 404) {
        dev.log('Quiz results not found (404)');
        throw Exception(
            'Quiz results not found. You may not have taken this quiz yet.');
      } else if (response.statusCode == 401) {
        dev.log('Authentication failed (401)');
        throw Exception('Authentication failed. Please log in again.');
      } else {
        dev.log('Request failed with status: ${response.statusCode}');
        dev.log('Response body: ${response.body}');
        throw Exception('Failed to load quiz results: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      dev.log('Error fetching quiz results: $e');
      throw Exception('Failed to load quiz results: $e');
    }
  }

  /// Try alternative endpoint for student-specific quiz results
  Future<List<Map<String, dynamic>>> _fetchStudentQuizResults(
      int quizId, String token) async {
    final url = Uri.parse('${ApiService.baseUrl}/quizzes/$quizId/my-results');

    dev.log('Trying student-specific endpoint: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dev.log(
          'Student-specific results response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> resultList = jsonDecode(response.body);
        dev.log(
            'Received student-specific results: ${resultList.length} entries');
        return resultList.map((item) => item as Map<String, dynamic>).toList();
      } else if (response.statusCode == 404) {
        dev.log('Student has not taken this quiz yet (404)');
        // Return empty list instead of throwing exception
        // This makes the UI show "No results found" instead of an error
        return [];
      } else if (response.statusCode == 403) {
        dev.log('Permission denied for student endpoint too (403)');
        return []; // Return empty list instead of throwing exception
      } else {
        dev.log(
            'Failed to load results from student endpoint: ${response.statusCode}');
        return []; // Return empty list to show "No results" UI
      }
    } catch (e) {
      dev.log('Error in student-specific endpoint: $e');
      return []; // Return empty list to show "No results" UI
    }
  }

  /// Fetch a single quiz result for the current student
  /// This uses the singular 'my-result' endpoint introduced in API v8001
  Future<Map<String, dynamic>?> fetchMyQuizResult(
      int quizId, String token) async {
    final url = Uri.parse('${ApiService.baseUrl}/quizzes/$quizId/my-result');

    dev.log('Fetching single quiz result from: $url');
    dev.log(
        'Using auth token: ${token.substring(0, min(10, token.length))}...');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dev.log('My quiz result response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        dev.log('Received single quiz result: $result');
        return result as Map<String, dynamic>;
      } else {
        dev.log('Error response body: ${response.body}');

        if (response.statusCode == 404) {
          dev.log('Student has not taken this quiz yet (404)');
          return null;
        } else if (response.statusCode == 403) {
          dev.log('Permission denied for my-result endpoint (403)');
          throw Exception(
              'You do not have permission to view this quiz result');
        } else if (response.statusCode == 401) {
          dev.log('Authentication failed (401)');
          throw Exception('Authentication failed. Please log in again.');
        } else {
          dev.log('Failed to load quiz result: ${response.statusCode}');
          dev.log('Response body: ${response.body}');
          throw Exception('Failed to load quiz result: ${response.statusCode}');
        }
      }
    } catch (e) {
      dev.log('Error fetching quiz result: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to load quiz result: $e');
    }
  }

  /// Fetch all attempts for a specific quiz by the current user
  /// This uses the /quizzes/{quiz_id}/attempts endpoint
  Future<List<Map<String, dynamic>>> fetchQuizAttempts(
      int quizId, String token) async {
    final url = Uri.parse('${ApiService.baseUrl}/quizzes/$quizId/attempts');

    dev.log('Fetching quiz attempts from: $url');
    dev.log(
        'Using auth token: ${token.substring(0, min(10, token.length))}...');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dev.log('Quiz attempts response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> attempts = jsonDecode(response.body);
        dev.log('Received ${attempts.length} quiz attempts');
        return attempts
            .map((attempt) => attempt as Map<String, dynamic>)
            .toList();
      } else {
        dev.log('Error response body: ${response.body}');

        if (response.statusCode == 404) {
          dev.log('No attempts found for this quiz (404)');
          return [];
        } else if (response.statusCode == 403) {
          dev.log('Permission denied for attempts endpoint (403)');
          throw Exception(
              'You do not have permission to view these quiz attempts');
        } else if (response.statusCode == 401) {
          dev.log('Authentication failed (401)');
          throw Exception('Authentication failed. Please log in again.');
        } else {
          dev.log('Failed to load quiz attempts: ${response.statusCode}');
          dev.log('Response body: ${response.body}');
          throw Exception(
              'Failed to load quiz attempts: ${response.statusCode}');
        }
      }
    } catch (e) {
      dev.log('Error fetching quiz attempts: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to load quiz attempts: $e');
    }
  }
}
