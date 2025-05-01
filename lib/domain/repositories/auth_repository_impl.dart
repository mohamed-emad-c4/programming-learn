import 'dart:developer';
import 'dart:io';
import 'dart:async';

import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/api_service.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  // Standardize token keys
  static const String TOKEN_KEY = 'access_token';
  static const String LEGACY_TOKEN_KEY = 'auth_token';

  @override
  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      log('AuthRepository: Attempting to login user: $username');
      log('AuthRepository: Using API base URL: ${ApiService.baseUrl}');

      try {
        final response = await ApiService.login(
          username: username,
          password: password,
        );

        final token = response['access_token'];
        if (token == null || token.isEmpty) {
          log('AuthRepository: Empty or null token received');
          throw Exception('Invalid token received from server');
        }

        log('AuthRepository: Login successful, token received');
        await saveToken(token); // حفظ الـ token
        return token;
      } on SocketException catch (e) {
        log('AuthRepository: SocketException during login: $e');
        throw Exception(
            'Network connection error. Please check your internet connection: ${e.message}');
      } on ClientException catch (e) {
        log('AuthRepository: ClientException during login: $e');
        throw Exception('Network error: ${e.message}');
      } on FormatException catch (e) {
        log('AuthRepository: FormatException during login: $e');
        throw Exception(
            'Server returned invalid data. Please try again later.');
      } on TimeoutException catch (e) {
        log('AuthRepository: TimeoutException during login: $e');
        throw Exception('Connection timed out. Please try again.');
      }
    } catch (e) {
      log('AuthRepository: Login failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
    await prefs.setString(
        LEGACY_TOKEN_KEY, token); // Also save with legacy key for compatibility
    log('Token saved: $token'); // طباعة الـ token للتأكد من حفظه
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Try primary key first
    String? token = prefs.getString(TOKEN_KEY);

    // If primary key doesn't have a token, try legacy key
    if (token == null || token.isEmpty) {
      token = prefs.getString(LEGACY_TOKEN_KEY);

      // If found in legacy, migrate it to the primary key
      if (token != null && token.isNotEmpty) {
        log('Token found in legacy storage, migrating to primary key');
        await prefs.setString(TOKEN_KEY, token);
      }
    }

    log('Token retrieved: $token'); // طباعة الـ token للتأكد من تحميله
    return token;
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(LEGACY_TOKEN_KEY); // Clear both keys
    log('Token cleared'); // طباعة رسالة تأكيد
  }

  @override
  Future<void> register({
    required String name,
    required String nickname,
    required String country,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await ApiService.register(
        name: name,
        nickname: nickname,
        country: country,
        email: email,
        password: password,
        role: role,
      );
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  @override
  Future<void> signUp(
    String name,
    String username,
    String country,
    String email,
    String password,
  ) async {
    // تنفيذ عملية تسجيل الحساب (مثل استدعاء API)
    await Future.delayed(
        const Duration(seconds: 2)); // محاكاة لعملية غير متزامنة
    if (email.isNotEmpty && password.isNotEmpty) {
      return;
    } else {
      throw Exception('فشل تسجيل الحساب: بيانات غير صحيحة');
    }
  }

// lib/domain/repositories/auth_repository_impl.dart
  @override
  Future<bool> validateToken(String token) async {
    try {
      return await ApiService.verifyToken(token); // استخدام الدالة الجديدة
    } on Exception catch (e) {
      log('فشل في التحقق من صحة الـ token: $e');
      return false;
    }
  }
}
