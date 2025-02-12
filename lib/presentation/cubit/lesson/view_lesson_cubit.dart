import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_programming/data/datasources/api_service.dart';

part 'view_lesson_state.dart';

class ViewLessonCubit extends Cubit<ViewLessonState> {
  final ApiService apiService;

  ViewLessonCubit(this.apiService) : super(ViewLessonInitial());

  Future<void> fetchLesson(int lessonId) async {
    try {
      emit(ViewLessonLoading());
      final lesson = await apiService.fetchLesson(lessonId);
      emit(ViewLessonLoaded(lesson));
    } catch (error) {
      emit(ViewLessonError(error.toString()));
    }
  }
}
