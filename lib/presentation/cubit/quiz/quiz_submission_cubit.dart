import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/datasources/api_service.dart';
import '../../../utils/auth_service.dart';

// States
abstract class QuizSubmissionState {}

class QuizSubmissionInitial extends QuizSubmissionState {}

class QuizSubmissionLoading extends QuizSubmissionState {}

class QuizSubmissionSuccess extends QuizSubmissionState {
  final String message;
  QuizSubmissionSuccess({this.message = 'Quiz submitted successfully'});
}

class QuizSubmissionError extends QuizSubmissionState {
  final String message;
  QuizSubmissionError({this.message = 'Failed to submit quiz'});
}

class QuizSubmissionCubit extends Cubit<QuizSubmissionState> {
  final ApiService _apiService;
  final AuthService _authService = AuthService();
  String? token;

  QuizSubmissionCubit([ApiService? apiService])
      : _apiService = apiService ?? GetIt.I<ApiService>(),
        super(QuizSubmissionInitial());

  Future<void> submitQuiz(
      int quizId, List<Map<String, dynamic>> answers) async {
    try {
      emit(QuizSubmissionLoading());

      // Get token from auth service
      token = await _authService.getToken();

      if (token == null || token!.isEmpty) {
        log('No authentication token available');
        emit(QuizSubmissionError(
            message:
                'You need to be logged in to submit the quiz. Please log in and try again.'));
        return;
      }

      // Log submission data for debugging
      log('Submitting quiz: Quiz ID: $quizId');
      log('Answers: $answers');
      log('Using token: ${token!.substring(0, 10)}...');

      // Call API service to submit quiz
      final result = await _apiService.submitQuiz(
        quizId: quizId,
        answers: answers,
        token: token,
      );

      log('Quiz submission result: $result');

      if (result['success'] == true) {
        // Store submission token if returned
        if (result.containsKey('submission_token')) {
          token = result['submission_token'];
          log('Received submission token: $token');
        }

        emit(QuizSubmissionSuccess(
          message: result['message'] ?? 'Quiz submitted successfully',
        ));
      } else {
        // Check for 401 or auth errors
        if (result['message']?.toString().toLowerCase().contains('auth') ==
            true) {
          // Try to refresh token
          await _refreshToken();

          // If we have a token now, tell user to retry
          if (token != null && token!.isNotEmpty) {
            emit(QuizSubmissionError(
                message: 'Authentication refreshed. Please try again.'));
          } else {
            emit(QuizSubmissionError(
                message: 'Authentication failed. Please log in again.'));
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
      emit(QuizSubmissionError(message: 'Error: $e'));
    }
  }

  /// Try to refresh the token
  Future<bool> _refreshToken() async {
    try {
      // First try to load token again using auth service
      token = await _authService.getToken();

      if (token != null && token!.isNotEmpty) {
        log('Token refreshed from auth service');
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
}
