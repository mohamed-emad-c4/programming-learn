// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:learn_programming/domain/repositories/auth_repository_impl.dart';
import 'package:learn_programming/presentation/screens/course/lesson/lessons_screen.dart';
import 'package:learn_programming/presentation/screens/course/quize/quiz_submission_screen%20.dart';
import 'presentation/screens/course/basics_csrnnn.dart';
import 'presentation/screens/course/course_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/cubit/auth_cubit.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/screens/course/quize/quiz_details_screen.dart';
import 'presentation/screens/course/quize/quiz_result_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/auth/sign_up_screen.dart';
import 'presentation/screens/settings_screen.dart'; // Added import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(MyApp());
}

Future<void> setupDependencies() async {
  final authRepository = AuthRepositoryImpl();
  GetIt.I.registerSingleton<AuthRepository>(authRepository);
  GetIt.I.registerFactory(() => AuthCubit(GetIt.I<AuthRepository>()));

  final token = await authRepository.getToken();
  if (token != null) {
    final isValid = await authRepository.validateToken(token);
    if (isValid) {
      GetIt.I.registerSingleton<String>(token, instanceName: 'token');
    } else {
      await authRepository.clearToken(); // Clear invalid token
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<AuthCubit>(), // Provide AuthCubit
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Learn Programming',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: GetIt.I.isRegistered<String>(instanceName: 'token')
            ? '/home'
            : '/login',
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
          '/settings': (context) => SettingsScreen(),
          '/course-detail': (context) => CourseDetailScreen(courseId: 14),
          '/courses': (context) => CourseScreen(),
          '/lessons': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments as Map<String, int>;
            return LessonsScreen(
              languageId: args['languageId']!,
              chapterNumber: args['chapterNumber']!,
            );
          },
          '/quizDetails': (context) => const QuizDetailsScreen(lessonId: 1),
          '/quizSubmission': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return QuizSubmissionScreen(
              quizId: args['quizId'],
              questions: args['questions'],

            );
          },
          '/quiz': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return QuizSubmissionScreen(
              quizId: args['quizId'],
              questions: args['questions'],
            );
          },
          '/quizResult': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return QuizResultScreen(
              quizId: args['quizId'],
              token: args['token'],
              numberOfQuestions: args['numberOfQuestions'],
            );
          },
        },
      ),
    );
  }
}