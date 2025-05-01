import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/datasources/api_service.dart';
import '../../../utils/auth_service.dart';
import '../../../domain/repositories/auth_repository_impl.dart';

// States
abstract class QuizSubmissionState {}

class QuizSubmissionInitial extends QuizSubmissionState {}

class QuizSubmissionLoading extends QuizSubmissionState {}

class QuizSubmissionSuccess extends QuizSubmissionState {
  final String message;
  final Map<String, dynamic> data;

  QuizSubmissionSuccess({
    this.message = 'Quiz submitted successfully',
    this.data = const {},
  });
}

class QuizSubmissionError extends QuizSubmissionState {
  final String message;
  final bool isAuthError;

  QuizSubmissionError({
    this.message = 'Failed to submit quiz',
    this.isAuthError = false,
  });
}

class QuizSubmissionCubit extends Cubit<QuizSubmissionState> {
  final ApiService _apiService;
  final AuthService _authService = AuthService();
  final AuthRepositoryImpl _authRepo = AuthRepositoryImpl();
  String? token;
  int? _lastSubmittedQuizId;
  List<Map<String, dynamic>>? _lastSubmittedAnswers;

  QuizSubmissionCubit([ApiService? apiService])
      : _apiService = apiService ?? GetIt.I<ApiService>(),
        super(QuizSubmissionInitial());

  Future<void> submitQuiz(
      int quizId, List<Map<String, dynamic>> answers) async {
    try {
      emit(QuizSubmissionLoading());
      _lastSubmittedQuizId = quizId;
      _lastSubmittedAnswers = answers;

      // Initialize auth service if needed
      await _authService.init();

      // Get token with multiple strategies
      token = await _getTokenWithFallbacks();

      if (token == null || token!.isEmpty) {
        log('No authentication token available');
        emit(QuizSubmissionError(
            message:
                'You need to be logged in to submit the quiz. Please log in and try again.',
            isAuthError: true));
        return;
      }

      // Log submission data for debugging
      log('Submitting quiz: Quiz ID: $quizId');
      log('Answers count: ${answers.length}');
      log('First few answers: ${answers.take(2).toList()}');
      log('Using token: ${token!.substring(0, min(10, token!.length))}...');

      // Call API service to submit quiz
      final result = await _apiService.submitQuiz(
        quizId: quizId,
        answers: answers,
        token: token,
      );

      log('Quiz submission result: $result');

      if (result['success'] == true) {
        // Store submission token if returned
        if (result.containsKey('submission_token') &&
            result['submission_token'] != null &&
            result['submission_token'].toString().isNotEmpty) {
          token = result['submission_token'];
          log('Received new submission token: ${token!.substring(0, min(10, token!.length))}...');

          // Save this token to ensure it's available across the app
          await _saveTokenEverywhere(token!);
        } else if (token != null) {
          // Make sure the current token is properly saved
          await _saveTokenEverywhere(token!);
        }

        emit(QuizSubmissionSuccess(
          message: result['message'] ?? 'Quiz submitted successfully',
          data: result['data'] ?? {},
        ));
      } else {
        // Check for 401 or auth errors
        final resultMessage = result['message']?.toString().toLowerCase() ?? '';
        final isAuthError = resultMessage.contains('auth') ||
            resultMessage.contains('login') ||
            resultMessage.contains('401') ||
            resultMessage.contains('unauthorized');

        if (isAuthError) {
          log('Authentication error detected: $resultMessage');
          // Try to refresh token
          final tokenRefreshed = await _refreshToken();

          // If token refreshed, try submission again
          if (tokenRefreshed && token != null && token!.isNotEmpty) {
            log('Token refreshed, retrying quiz submission');
            // Retry submission with the new token
            return submitQuiz(quizId, answers);
          } else {
            emit(QuizSubmissionError(
                message: 'Authentication failed. Please log in again.',
                isAuthError: true));
          }
        } else {
          emit(QuizSubmissionError(
            message: result['message'] ?? 'Failed to submit quiz',
          ));
        }
      }
    } catch (e, stackTrace) {
      log('Error submitting quiz: $e');
      log(stackTrace.toString());

      final errorMsg = e.toString();
      final isAuthError = errorMsg.toLowerCase().contains('auth') ||
          errorMsg.toLowerCase().contains('token') ||
          errorMsg.toLowerCase().contains('unauthorized');

      emit(QuizSubmissionError(message: 'Error: $e', isAuthError: isAuthError));
    }
  }

  /// Try to get token from all possible sources
  Future<String?> _getTokenWithFallbacks() async {
    log('Attempting to get token from all possible sources');

    // Source 1: Try AuthService first (comprehensive token search)
    String? token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      log('Token found via AuthService');
      return token;
    }

    // Source 2: Try direct repository access
    token = await _authRepo.getToken();
    if (token != null && token.isNotEmpty) {
      log('Token found via AuthRepository');
      // Ensure it's saved in AuthService
      await _authService.saveExternalToken(token);
      return token;
    }

    // Source 3: Try direct GetIt access
    if (GetIt.I.isRegistered<String>(instanceName: 'token')) {
      token = GetIt.I<String>(instanceName: 'token');
      log('Token found in GetIt');
      // Ensure it's saved in AuthService
      await _authService.saveExternalToken(token);
      return token;
    }

    // Source 4: Try direct SharedPreferences access (checking all possible keys)
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('access_token') ??
        prefs.getString('auth_token') ??
        prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      log('Token found in SharedPreferences with direct access');
      // Ensure it's saved in AuthService
      await _authService.saveExternalToken(token);
      return token;
    }

    log('No token found in any storage');
    return null;
  }

  /// Save token to all storage mechanisms
  Future<void> _saveTokenEverywhere(String token) async {
    try {
      log('Saving token to all storage mechanisms');

      // Save via AuthService (which saves to multiple places)
      await _authService.saveExternalToken(token);

      // Also save directly to repository for good measure
      await _authRepo.saveToken(token);

      // Direct save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('auth_token', token);

      // Register in GetIt
      try {
        if (GetIt.I.isRegistered<String>(instanceName: 'token')) {
          GetIt.I.unregister<String>(instanceName: 'token');
        }
        GetIt.I.registerSingleton<String>(token, instanceName: 'token');
      } catch (e) {
        log('Error updating GetIt token: $e');
      }

      log('Token saved to all storage mechanisms');
    } catch (e) {
      log('Error saving token everywhere: $e');
    }
  }

  /// Try to refresh the token
  Future<bool> _refreshToken() async {
    try {
      log('Attempting to refresh token');

      // First try to load token again from all sources
      token = await _getTokenWithFallbacks();

      if (token != null && token!.isNotEmpty) {
        log('Token refreshed: ${token!.substring(0, min(10, token!.length))}...');
        return true;
      }

      // If that fails, token likely expired - user needs to login again
      log('Token refresh failed - user needs to log in again');
      return false;
    } catch (e) {
      log('Error refreshing token: $e');
      return false;
    }
  }

  /// Get the last submitted quiz ID
  int? getLastSubmittedQuizId() {
    return _lastSubmittedQuizId;
  }

  /// Retry last submission with potentially refreshed token
  Future<void> retryLastSubmission() async {
    if (_lastSubmittedQuizId != null && _lastSubmittedAnswers != null) {
      log('Retrying last quiz submission');
      await submitQuiz(_lastSubmittedQuizId!, _lastSubmittedAnswers!);
    } else {
      emit(QuizSubmissionError(
        message: 'No previous submission to retry',
      ));
    }
  }
}

// Helper function to avoid the 'min' import issue
int min(int a, int b) => a < b ? a : b;
