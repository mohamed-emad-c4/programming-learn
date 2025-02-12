import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/datasources/api_service.dart';
import '../../../domain/repositories/auth_repository_impl.dart';

part 'quiz_submission_state.dart';
class QuizSubmissionCubit extends Cubit<QuizSubmissionState> {
  String token = ''; // Store the token here

  QuizSubmissionCubit() : super(QuizSubmissionInitial());

  Future<void> submitQuiz(int quizId, List<Map<String, dynamic>> answers) async {
    emit(QuizSubmissionLoading());
    try {
      final authRepository = AuthRepositoryImpl();
      token = await authRepository.getToken() ?? ''; // Save the token

      final response = await ApiService.submitQuiz(quizId, answers, token);

      if (response.statusCode == 200) {
        emit(QuizSubmissionSuccess());
      } else {
        emit(QuizSubmissionError('Failed to submit quiz.'));
      }
    } catch (e) {
      emit(QuizSubmissionError('An error occurred.'));
    }
  }
}
