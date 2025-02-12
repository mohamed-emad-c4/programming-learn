import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/datasources/api_service.dart';

part 'quiz_details_state.dart';

class QuizDetailsCubit extends Cubit<QuizDetailsState> {
  final ApiService apiService;
  QuizDetailsCubit(this.apiService) : super(QuizDetailsInitial());

  Future<void> fetchQuizzes(int lessonId) async {
    emit(QuizDetailsLoading());
    try {
      final quizzes = await apiService.fetchQuizzesByLesson(lessonId);
      emit(QuizDetailsLoaded(quizzes));
    } catch (e) {
      emit(QuizDetailsError(e.toString()));
    }
  }
}
