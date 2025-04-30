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
      emit(AuthSuccess());
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
      final token = await authRepository.login(
        username: username,
        password: password,
      );
      log('Token after login: $token'); // طباعة الـ token
      
      emit(AuthSuccess(token: token)); // إرسال الـ token مع الحالة
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
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