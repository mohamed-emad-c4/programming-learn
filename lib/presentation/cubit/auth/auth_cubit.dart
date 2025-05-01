import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit(this.authRepository) : super(AuthInitial());

  Future<void> register({
    required String name,
    required String nickname,
    required String country,
    required String email,
    required String password,
    required String role,
  }) async {
    emit(AuthLoading());
    try {
      await authRepository.register(
        name: name,
        nickname: nickname,
        country: country,
        email: email,
        password: password,
        role: role,
      );
      emit(const AuthSuccess());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      log('AuthCubit: Attempting login for username: $username');
      final token = await authRepository.login(
        username: username,
        password: password,
      );
      log('AuthCubit: Token after login: $token'); // طباعة الـ token

      emit(AuthSuccess(token: token)); // إرسال الـ token مع الحالة
    } catch (e) {
      log('AuthCubit: Login error: $e');

      // Check for specific network errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('connection refused') ||
          errorStr.contains('network is unreachable') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection failed')) {
        emit(const AuthFailure(
            error:
                'Cannot connect to the server. Please check your internet connection and try again.'));
      } else if (errorStr.contains('timeout')) {
        emit(const AuthFailure(
            error:
                'Connection timeout. Please check your internet connection.'));
      } else if (errorStr.contains('unauthorized') ||
          errorStr.contains('401')) {
        emit(const AuthFailure(
            error: 'Login failed: Invalid username or password.'));
      } else {
        emit(AuthFailure(error: e.toString()));
      }
    }
  }

  Future<void> logout() async {
    emit(AuthInitial()); // إعادة الحالة إلى الحالة الأولية
  }

// lib/presentation/cubit/auth_cubit.dart
// lib/presentation/cubit/auth_cubit.dart
  Future<void> checkTokenValidity() async {
    final token = await authRepository.getToken();
    if (token != null) {
      final isValid = await authRepository.validateToken(token);
      if (!isValid) {
        await authRepository.clearToken();
        emit(AuthInitial()); // إعادة التوجيه إلى شاشة تسجيل الدخول
      }
    }
  }
}
