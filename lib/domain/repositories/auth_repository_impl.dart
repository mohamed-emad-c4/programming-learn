import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/api_service.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override  @override
Future<String> login({
  required String username,
  required String password,
}) async {
  try {
    final response = await ApiService.login(
      username: username,
      password: password,
    );
    final token = response['access_token']; // استخراج الـ token
    await saveToken(token); // حفظ الـ token
    return token;
  } catch (e) {
    throw Exception('فشل في تسجيل الدخول: $e');
  }
}
@override
Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', token);
  log('Token saved: $token'); // طباعة الـ token للتأكد من حفظه
}

@override
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  log('Token retrieved: $token'); // طباعة الـ token للتأكد من تحميله
  return token;
}
@override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
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
    await Future.delayed(Duration(seconds: 2)); // محاكاة لعملية غير متزامنة
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