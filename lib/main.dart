import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:learn_programming/domain/repositories/auth_repository_impl.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/cubit/auth_cubit.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/screens/sign_up_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(MyApp());
}

Future<void> setupDependencies() async {
  final authRepository = AuthRepositoryImpl();
  GetIt.I.registerSingleton<AuthRepository>(authRepository);
  GetIt.I.registerFactory(() => AuthCubit(GetIt.I<AuthRepository>()));

  // تحميل الـ token عند بدء التطبيق
  final token = await authRepository.getToken();
  log('Initial token: $token');
  if (token != null) {
    final isValid = await authRepository.validateToken(token);
    if (isValid) 
    {
      log('Token is valid');
      GetIt.I.registerSingleton<String>(token, instanceName: 'token');
    } else {
      log('Token is not invalid');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learn Programming',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: GetIt.I.isRegistered<String>(instanceName: 'token') ? '/home' : '/login',
      routes: {
        '/login': (context) => BlocProvider(
              create: (context) => GetIt.I<AuthCubit>(),
              child: LoginScreen(),
            ),
        '/sign-up': (context) => BlocProvider(
              create: (context) => GetIt.I<AuthCubit>(),
              child: SignUpScreen(),
            ),
        '/home': (context) => BlocProvider(
              create: (context) => GetIt.I<AuthCubit>(),
              child: HomeScreen(),
            ),
        '/reset-password': (context) => ResetPasswordScreen(),
      },
    );
  }
}