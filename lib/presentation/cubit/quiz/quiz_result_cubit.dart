import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:learn_programming/data/datasources/api_service.dart';
import 'package:learn_programming/utils/auth_service.dart';

part 'quiz_result_state.dart';

class QuizResultCubit extends Cubit<QuizResultState> {
  final ApiService apiService;
  final AuthService _authService = AuthService();

  QuizResultCubit(this.apiService) : super(QuizResultInitial());

  Future<void> fetchQuizResult(int quizId, String? token) async {
    try {
      emit(QuizResultLoading());

      // Debug logs
      log('QuizResultCubit: fetching results for quiz $quizId');
      log('QuizResultCubit: token length: ${token?.length ?? 0}');

      if (token == null || token.isEmpty) {
        log('QuizResultCubit: No token provided!');
        emit(QuizResultError(
            'Authentication required. Please log in and try again.'));
        return;
      }

      // Validate token before making the API call
      final isValid = await _validateToken(token);
      if (!isValid) {
        log('QuizResultCubit: Invalid token detected');
        emit(QuizResultError('Your session has expired. Please log in again.'));
        return;
      }

      // Use the new dedicated method for fetching quiz results
      log('QuizResultCubit: Using dedicated fetchQuizResults method');
      final resultList = await apiService.fetchQuizResults(quizId, token);

      log('QuizResultCubit: received response with ${resultList.length} results');

      // Check if the results list is empty
      if (resultList.isEmpty) {
        log('QuizResultCubit: Results list is empty');
        // We still emit QuizResultLoaded with empty list, but log this for debugging
        // This allows the UI to show the empty state instead of error state
        log('QuizResultCubit: Showing empty results UI (not error)');
      }

      emit(QuizResultLoaded(resultList));
    } catch (e) {
      log('QuizResultCubit: Error fetching quiz results: $e');

      // Provide more specific error messages
      final errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('401') || errorMsg.contains('unauthorized')) {
        emit(QuizResultError('Your session has expired. Please log in again.'));
      } else if (errorMsg.contains('403') || errorMsg.contains('permission')) {
        emit(QuizResultError(
            'You do not have permission to view these quiz results. This may be because you need to be the student who took the quiz, or you need to log in with a different account.'));
      } else if (errorMsg.contains('500')) {
        emit(QuizResultError(
            'The server encountered an error. Please try again later.'));
      } else if (errorMsg.contains('timeout')) {
        emit(QuizResultError(
            'Connection timeout. Please check your internet connection.'));
      } else if (errorMsg.contains('not found') ||
          errorMsg.contains('404') ||
          errorMsg.contains('not taken') ||
          errorMsg.contains('have not taken')) {
        emit(QuizResultError(
            'Quiz results not found. You may not have taken this quiz yet.'));
      } else {
        // Use the original error message
        emit(QuizResultError(e.toString()));
      }
    }
  }

  /// Fetch a single quiz result for the current user
  /// This uses the new /my-result endpoint
  Future<void> fetchMyQuizResult(int quizId, String? token) async {
    try {
      emit(QuizResultLoading());

      // Debug logs
      log('QuizResultCubit: fetching single result for quiz $quizId');
      log('QuizResultCubit: token length: ${token?.length ?? 0}');

      if (token == null || token.isEmpty) {
        log('QuizResultCubit: No token provided!');
        emit(QuizResultError(
            'Authentication required. Please log in and try again.'));
        return;
      }

      // Validate token before making the API call
      final isValid = await _validateToken(token);
      if (!isValid) {
        log('QuizResultCubit: Invalid token detected');
        emit(QuizResultError('Your session has expired. Please log in again.'));
        return;
      }

      // Use the new method for fetching a single quiz result
      log('QuizResultCubit: Using fetchMyQuizResult method');
      try {
        final result = await apiService.fetchMyQuizResult(quizId, token);

        if (result == null) {
          log('QuizResultCubit: Result is null - user may not have taken this quiz');

          // Try falling back to the legacy endpoint
          log('QuizResultCubit: Falling back to legacy endpoint');
          _fallbackToLegacyEndpoint(quizId, token);
          return;
        }

        log('QuizResultCubit: received single quiz result');
        emit(SingleQuizResultLoaded(result));
      } catch (e) {
        // If we get a 404 from the new endpoint, try the old one
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('not found') || errorMsg.contains('404')) {
          log('QuizResultCubit: New endpoint returned 404, trying legacy endpoint');
          _fallbackToLegacyEndpoint(quizId, token);
        } else if (errorMsg.contains('connection refused') ||
            errorMsg.contains('network is unreachable') ||
            errorMsg.contains('failed host lookup') ||
            errorMsg.contains('socket') ||
            errorMsg.contains('connection failed')) {
          log('QuizResultCubit: Network connection error: $e');
          emit(QuizResultError(
              'Cannot connect to the server. Please check your internet connection and try again.'));
        } else {
          rethrow; // Let the outer catch handle other errors
        }
      }
    } catch (e) {
      log('QuizResultCubit: Error fetching quiz result: $e');

      // Provide more specific error messages
      final errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('401') || errorMsg.contains('unauthorized')) {
        emit(QuizResultError('Your session has expired. Please log in again.'));
      } else if (errorMsg.contains('403') || errorMsg.contains('permission')) {
        emit(QuizResultError(
            'You do not have permission to view this quiz result.'));
      } else if (errorMsg.contains('500')) {
        emit(QuizResultError(
            'The server encountered an error. Please try again later.'));
      } else if (errorMsg.contains('timeout')) {
        emit(QuizResultError(
            'Connection timeout. Please check your internet connection.'));
      } else if (errorMsg.contains('not found') ||
          errorMsg.contains('404') ||
          errorMsg.contains('not taken') ||
          errorMsg.contains('have not taken')) {
        emit(QuizResultError('You have not taken this quiz yet.'));
      } else if (errorMsg.contains('connection refused') ||
          errorMsg.contains('network is unreachable') ||
          errorMsg.contains('failed host lookup') ||
          errorMsg.contains('socket') ||
          errorMsg.contains('connection failed')) {
        emit(QuizResultError(
            'Cannot connect to the server. Please check your internet connection and try again.'));
      } else {
        // Use the original error message
        emit(QuizResultError(e.toString()));
      }
    }
  }

  /// Private method to fall back to the legacy endpoint if the new one fails
  Future<void> _fallbackToLegacyEndpoint(int quizId, String token) async {
    try {
      log('QuizResultCubit: Trying legacy endpoint as fallback');
      final resultList = await apiService.fetchQuizResults(quizId, token);

      if (resultList.isEmpty) {
        log('QuizResultCubit: Legacy endpoint returned empty results');
        emit(QuizResultError('You have not taken this quiz yet.'));
      } else {
        log('QuizResultCubit: Successfully fetched results from legacy endpoint');
        emit(QuizResultLoaded(resultList));
      }
    } catch (e) {
      log('QuizResultCubit: Error in legacy fallback: $e');
      emit(QuizResultError('You have not taken this quiz yet.'));
    }
  }

  /// Fetch all attempts for a quiz by the current user
  Future<void> fetchQuizAttempts(int quizId, String? token) async {
    try {
      emit(QuizResultLoading());

      log('QuizResultCubit: fetching attempts for quiz $quizId');

      if (token == null || token.isEmpty) {
        log('QuizResultCubit: No token provided for fetching attempts!');
        emit(QuizResultError(
            'Authentication required. Please log in and try again.'));
        return;
      }

      // Validate token before making the API call
      final isValid = await _validateToken(token);
      if (!isValid) {
        log('QuizResultCubit: Invalid token detected');
        emit(QuizResultError('Your session has expired. Please log in again.'));
        return;
      }

      try {
        final attempts = await apiService.fetchQuizAttempts(quizId, token);

        if (attempts.isEmpty) {
          log('QuizResultCubit: No attempts found for this quiz');
          emit(QuizResultError('You have not taken this quiz yet.'));
          return;
        }

        log('QuizResultCubit: Successfully fetched ${attempts.length} attempts');
        emit(QuizAttemptsLoaded(attempts));
      } catch (e) {
        // Check for connection issues
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('connection refused') ||
            errorMsg.contains('network is unreachable') ||
            errorMsg.contains('failed host lookup') ||
            errorMsg.contains('socket') ||
            errorMsg.contains('connection failed')) {
          log('QuizResultCubit: Network connection error: $e');
          emit(QuizResultError(
              'Cannot connect to the server. Please check your internet connection and try again.'));
        } else {
          rethrow;
        }
      }
    } catch (e) {
      log('QuizResultCubit: Error fetching quiz attempts: $e');

      // Provide more specific error messages
      final errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('401') || errorMsg.contains('unauthorized')) {
        emit(QuizResultError('Your session has expired. Please log in again.'));
      } else if (errorMsg.contains('403') || errorMsg.contains('permission')) {
        emit(QuizResultError(
            'You do not have permission to view these quiz attempts.'));
      } else if (errorMsg.contains('500')) {
        emit(QuizResultError(
            'The server encountered an error. Please try again later.'));
      } else if (errorMsg.contains('timeout')) {
        emit(QuizResultError(
            'Connection timeout. Please check your internet connection.'));
      } else if (errorMsg.contains('not found') ||
          errorMsg.contains('404') ||
          errorMsg.contains('not taken')) {
        emit(QuizResultError('You have not taken this quiz yet.'));
      } else {
        // Use the original error message
        emit(QuizResultError(e.toString()));
      }
    }
  }

  /// Validate the token before making API calls
  Future<bool> _validateToken(String token) async {
    try {
      return await _authService.isAuthenticated();
    } catch (e) {
      log('QuizResultCubit: Error validating token: $e');
      return false;
    }
  }
}
