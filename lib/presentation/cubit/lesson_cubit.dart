import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../../../data/datasources/api_service.dart';
import 'lesson_state.dart';

class LessonCubit extends Cubit<LessonState> {
  final ApiService apiService;

  LessonCubit(this.apiService) : super(LessonInitial());

  void fetchLessons(int chapterNumber) async {
    try {
      emit(LessonLoading());
      final lessons = await apiService.fetchLessons(chapterNumber);
      emit(LessonLoaded(lessons));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }
}
