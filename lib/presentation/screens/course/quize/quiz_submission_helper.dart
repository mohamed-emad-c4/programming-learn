import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../utils/logger.dart';
import '../../../cubit/quiz/quiz_submission_cubit.dart';

/// Helper class for managing quiz submission state and logic
class QuizSubmissionHelper {
  final AppLogger logger = AppLogger(tag: 'QuizSubmission');
  final BuildContext context;
  final int quizId;

  QuizSubmissionHelper({
    required this.context,
    required this.quizId,
  });

  /// Submit quiz answers
  Future<void> submitQuiz(Map<int, int> selectedAnswers) async {
    logger.i('Preparing to submit quiz $quizId');
    logger.d('Selected answers: $selectedAnswers');

    if (selectedAnswers.isEmpty) {
      logger.w('No answers selected, showing warning');
      _showWarningDialog(
        'No answers selected',
        'Please select at least one answer before submitting.',
      );
      return;
    }

    // Convert to the expected format - each answer in separate object in the array
    final answers = selectedAnswers.entries
        .map((entry) => {
              "question_id": entry.key,
              "selected_option": entry.value,
            })
        .toList();

    logger.d('Formatted answers for API: $answers');

    try {
      // Get cubit from context
      final cubit = BlocProvider.of<QuizSubmissionCubit>(context);

      // Show loading dialog
      _showLoadingDialog();

      // Submit quiz
      await cubit.submitQuiz(quizId, answers);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      logger.i('Quiz submission completed');
    } catch (e, stackTrace) {
      logger.e('Error submitting quiz', e, stackTrace);

      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Show error dialog
        _showErrorDialog('Submission failed', 'Please try again later.');
      }
    }
  }

  /// Show a confirmation dialog before submitting
  Future<bool> confirmSubmission(int totalQuestions, int answeredCount) async {
    logger.d(
        'Showing confirmation dialog. Answered: $answeredCount/$totalQuestions');

    if (!context.mounted) return false;

    final unansweredCount = totalQuestions - answeredCount;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(unansweredCount > 0
                ? 'You have unanswered questions'
                : 'Ready to submit?'),
            content: Text(
              unansweredCount > 0
                  ? 'You have $unansweredCount unanswered ${unansweredCount == 1 ? 'question' : 'questions'}. Do you want to submit anyway?'
                  : 'You have answered all questions. Are you sure you want to submit your answers?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show a loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Submitting quiz...'),
          ],
        ),
      ),
    );
  }

  /// Show a warning dialog
  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show an error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
