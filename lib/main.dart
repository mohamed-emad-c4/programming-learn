// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// Domain
import 'data/datasources/api_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/auth_repository_impl.dart';

// Cubit
import 'presentation/cubit/auth/auth_cubit.dart';

// Screens
import 'presentation/cubit/lesson/lesson_cubit.dart';
import 'presentation/cubit/quiz/quiz_result_cubit.dart';
import 'presentation/cubit/quiz/quiz_submission_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/sign_up_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/course/quize/quiz_submission_screen .dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/course/course_screen.dart';
import 'presentation/screens/course/chapter_screen.dart';
import 'presentation/screens/course/lesson/lesson_screen.dart';
import 'presentation/screens/course/lesson/view_lesson_screen.dart';
import 'presentation/screens/course/quize/quiz_details_screen.dart';
import 'presentation/screens/course/quize/quiz_result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDependencies();
  runApp(const MyApp());
}

Future<void> _setupDependencies() async {
  // Register Repositories
  final authRepository = AuthRepositoryImpl();
  GetIt.I.registerSingleton<AuthRepository>(authRepository);

  // Register Cubits
  GetIt.I.registerFactory(() => AuthCubit(GetIt.I<AuthRepository>()));

  // Check Token
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => GetIt.I<AuthCubit>()),
         BlocProvider<LessonCubit>(
          create: (context) => LessonCubit(ApiService()),
        ),
         BlocProvider<QuizSubmissionCubit>(
          create: (context) => QuizSubmissionCubit(
          ),
        ),
         BlocProvider<QuizResultCubit>(create: (context) => QuizResultCubit(ApiService())),
      ],
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
        routes: _buildRoutes(),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/login': (context) => LoginScreen(),
      '/sign-up': (context) => SignUpScreen(),
      '/home': (context) => HomeScreen(),
      '/reset-password': (context) => ResetPasswordScreen(),
      '/settings': (context) => SettingsScreen(),
      '/courses': (context) => CourseScreen(),
      '/chapter': (context) => ChapterScreen(courseId: 14),
      '/lessons': (context) {
        final args = ModalRoute.of(context)!.settings.arguments
            as Map<String, dynamic>;
        return LessonScreen(
          languageId: args['languageId'] as int,
          chapterNumber: args['chapterNumber'] as int,
        );
      },
       '/view-lesson': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return ViewLessonScreen(lessonId: args['lessonId']);
    },
      '/quiz-details': (context) {
        final args = ModalRoute.of(context)!.settings.arguments
            as Map<String, dynamic>;
        return QuizDetailsScreen(lessonId: args['lessonId']);
      },
      '/quiz-submission': (context) {
        final args = ModalRoute.of(context)!.settings.arguments
            as Map<String, dynamic>;
        return QuizSubmissionScreen(
          quizId: args['quizId'],
          questions: List<Map<String, dynamic>>.from(args['questions']),
        );
      },
      '/quizResult': (context) {
        final args = ModalRoute.of(context)!.settings.arguments
            as Map<String, dynamic>;
        return QuizResultScreen(
          quizId: args['quizId'],
          token: args['token'],
          numberOfQuestions: args['numberOfQuestions'],
        );
      },
    };
  }
}
