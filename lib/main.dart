// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learn_programming/data/datasources/values.dart';
import 'package:learn_programming/presentation/cubit/problem/problem/problem_cubit.dart';
import 'package:learn_programming/presentation/theme/app_theme.dart';
import 'package:learn_programming/presentation/cubit/theme/theme_cubit.dart';
import 'package:learn_programming/test.dart';
// Domain
import 'data/datasources/api_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/auth_repository_impl.dart';
// Cubit
import 'presentation/cubit/auth/auth_cubit.dart';
// Screens
import 'presentation/cubit/lesson/lesson_cubit.dart';
import 'presentation/cubit/problem/problem/image_cubit.dart';
import 'presentation/cubit/problem/tag/tags_cubit.dart';
import 'presentation/cubit/quiz/quiz_result_cubit.dart';
import 'presentation/cubit/quiz/quiz_submission_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/sign_up_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/course/quize/quiz_submission_screen .dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/problem/peoblem/problem_detail_screen.dart';
import 'presentation/screens/problem/peoblem/problem_screen.dart';
import 'presentation/screens/problem/tag/tags_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/course/course_screen.dart';
import 'presentation/screens/course/chapter_screen.dart'; // Ensure this file contains the ChapterScreen class
import 'presentation/screens/course/lesson/lesson_screen.dart';
import 'presentation/screens/course/lesson/view_lesson_screen.dart';
import 'presentation/screens/course/quize/quiz_details_screen.dart';
import 'presentation/screens/course/quize/quiz_result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  await _setupDependencies(prefs);

  runApp(const MyApp());
}

Future<void> _setupDependencies(SharedPreferences prefs) async {
  // Register SharedPreferences
  GetIt.I.registerSingleton<SharedPreferences>(prefs);

  // Register Repositories
  final authRepository = AuthRepositoryImpl();
  GetIt.I.registerSingleton<AuthRepository>(authRepository);

  // Register Cubits
  GetIt.I.registerFactory(() => AuthCubit(GetIt.I<AuthRepository>()));
  GetIt.I.registerFactory(() => ThemeCubit(GetIt.I<SharedPreferences>()));

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
        BlocProvider<ThemeCubit>(create: (_) => GetIt.I<ThemeCubit>()),
        BlocProvider<LessonCubit>(
          create: (context) => LessonCubit(ApiService()),
        ),
        BlocProvider<QuizSubmissionCubit>(
          create: (context) => QuizSubmissionCubit(),
        ),
        BlocProvider<QuizResultCubit>(
            create: (context) => QuizResultCubit(ApiService())),
        BlocProvider<TagsCubit>(create: (context) => TagsCubit(ApiService())),
        BlocProvider<ProblemCubit>(
            create: (context) => ProblemCubit(ApiService())),
        BlocProvider<ImageCubit>(create: (context) => ImageCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Learn Programming',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(themeState),
            initialRoute: GetIt.I.isRegistered<String>(instanceName: 'token')
                ? '/home'
                : '/login',
            routes: _buildRoutes(),
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(ThemeState state) {
    switch (state) {
      case ThemeState.light:
        return ThemeMode.light;
      case ThemeState.dark:
        return ThemeMode.dark;
      case ThemeState.system:
        return ThemeMode.system;
    }
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/login': (context) => const LoginScreen(),
      '/sign-up': (context) => const SignUpScreen(),
      '/home': (context) => const HomeScreen(),
      '/reset-password': (context) => const ResetPasswordScreen(),
      '/settings': (context) => const SettingsScreen(),
      '/courses': (context) => const CourseScreen(),
      '/chapter': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ChapterScreen(courseId: args['courseId']);
      },
      '/lessons': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return LessonScreen(
          languageId: args['languageId'] as int,
          chapterNumber: args['chapterNumber'] as int,
        );
      },
      '/view-lesson': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ViewLessonScreen(lessonId: args['lessonId']);
      },
      '/quiz-details': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return QuizDetailsScreen(lessonId: args['lessonId']);
      },
      '/quiz-submission': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return QuizSubmissionScreen(
          quizId: args['quizId'],
          questions: List<Map<String, dynamic>>.from(args['questions']),
        );
      },
      '/quizResult': (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return QuizResultScreen(
          quizId: args['quizId'],
          token: args['token'],
          numberOfQuestions: args['numberOfQuestions'],
        );
      },
      '/tags': (context) => const TagsScreen(),
      '/problems': (context) => ProblemScreen(
          tagId: ModalRoute.of(context)!.settings.arguments as int),
      '/problem_detail': (context) => const ProblemDetailScreen(),
      '/ocr': (context) => const GeminiScreen(),
    };
  }
}
