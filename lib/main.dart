// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learn_programming/data/datasources/values.dart';
import 'package:learn_programming/presentation/cubit/problem/problem/problem_cubit.dart';
import 'package:learn_programming/presentation/theme/app_theme.dart';
import 'package:learn_programming/presentation/cubit/theme/theme_cubit.dart';
import 'package:learn_programming/test.dart';
import 'package:learn_programming/utils/auth_service.dart';
// Remove the imports causing issues
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:device_preview/device_preview.dart';
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
import 'presentation/screens/error_screen.dart';

// Custom BLoC observer for better debugging
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('${bloc.runtimeType} $event');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType}: $change');
  }
}

void main() async {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception} ${details.stack}');
  };

  // Catch async errors
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set BLoC observer
  Bloc.observer = AppBlocObserver();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize auth service
  final authService = AuthService();
  await authService.init();

  await _setupDependencies(prefs);

  // Run the app without DevicePreview which was causing issues
  runApp(const MyApp());
}

Future<void> _setupDependencies(SharedPreferences prefs) async {
  // Register SharedPreferences
  GetIt.I.registerSingleton<SharedPreferences>(prefs);

  // Register API Service
  final apiService = ApiService();
  GetIt.I.registerSingleton<ApiService>(apiService);

  // Register Repositories
  final authRepository = AuthRepositoryImpl();
  GetIt.I.registerSingleton<AuthRepository>(authRepository);

  // Register Cubits
  GetIt.I.registerFactory(() => AuthCubit(GetIt.I<AuthRepository>()));
  GetIt.I.registerFactory(() => ThemeCubit(GetIt.I<SharedPreferences>()));
  GetIt.I.registerFactory(() => LessonCubit(GetIt.I<ApiService>()));
  GetIt.I.registerFactory(() => QuizSubmissionCubit());
  GetIt.I.registerFactory(() => QuizResultCubit(GetIt.I<ApiService>()));
  GetIt.I.registerFactory(() => TagsCubit(GetIt.I<ApiService>()));
  GetIt.I.registerFactory(() => ProblemCubit(GetIt.I<ApiService>()));
  GetIt.I.registerFactory(() => ImageCubit());

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
        BlocProvider<LessonCubit>(create: (_) => GetIt.I<LessonCubit>()),
        BlocProvider<QuizSubmissionCubit>(
            create: (_) => GetIt.I<QuizSubmissionCubit>()),
        BlocProvider<QuizResultCubit>(
            create: (_) => GetIt.I<QuizResultCubit>()),
        BlocProvider<TagsCubit>(create: (_) => GetIt.I<TagsCubit>()),
        BlocProvider<ProblemCubit>(create: (_) => GetIt.I<ProblemCubit>()),
        BlocProvider<ImageCubit>(create: (_) => GetIt.I<ImageCubit>()),
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
            onGenerateRoute: _generateRoute,
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (context) => ErrorScreen(
                errorMessage: 'Page not found: ${settings.name}',
              ),
            ),
            // Remove localization and device preview
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

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Handle deep linking here by parsing the settings.name

    // Normal route handling
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/sign-up':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/reset-password':
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/courses':
        return MaterialPageRoute(builder: (_) => const CourseScreen());
      case '/chapter':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('courseId')) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              errorMessage: 'Invalid course data',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ChapterScreen(courseId: args['courseId']),
        );
      case '/lessons':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('languageId') ||
            !args.containsKey('chapterNumber')) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              errorMessage: 'Invalid lesson data',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => LessonScreen(
            languageId: args['languageId'] as int,
            chapterNumber: args['chapterNumber'] as int,
          ),
        );
      case '/view-lesson':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('lessonId')) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              errorMessage: 'Invalid lesson ID',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ViewLessonScreen(lessonId: args['lessonId']),
        );
      case '/quiz-details':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('lessonId')) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              errorMessage: 'Invalid quiz data',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => QuizDetailsScreen(lessonId: args['lessonId']),
        );
      case '/quiz-submission':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('quizId') ||
            !args.containsKey('questions')) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              errorMessage: 'Invalid quiz submission data',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => QuizSubmissionScreen(
            quizId: args['quizId'],
            questions: List<Map<String, dynamic>>.from(args['questions']),
            timeLimit: args['timeLimit'],
          ),
        );
      case '/quizResult':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('quizId') ||
            !args.containsKey('token')) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              errorMessage: 'Invalid quiz result data',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quizId: args['quizId'],
            token: args['token'],
            numberOfQuestions: args['numberOfQuestions'],
          ),
        );
      case '/tags':
        return MaterialPageRoute(builder: (_) => const TagsScreen());
      case '/problems':
        final tagId = settings.arguments as int?;
        if (tagId == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorScreen(
              errorMessage: 'Invalid tag ID',
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => ProblemScreen(tagId: tagId));
      case '/problem_detail':
        return MaterialPageRoute(builder: (_) => const ProblemDetailScreen());
      case '/ocr':
        return MaterialPageRoute(builder: (_) => const GeminiScreen());
      default:
        return null;
    }
  }
}
