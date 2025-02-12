import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:learn_programming/data/datasources/api_service.dart';

part 'quiz_result_state.dart';

class QuizResultCubit extends Cubit<QuizResultState> {
  final ApiService apiService;

  QuizResultCubit(this.apiService) : super(QuizResultInitial());

  Future<void> fetchQuizResult(int quizId, String token) async {
    try {
      emit(QuizResultLoading());
      final response = await apiService.getData('/quizzes/$quizId/results', token);
      final List<Map<String, dynamic>> resultList = 
          (response as List).map((item) => item as Map<String, dynamic>).toList();
      emit(QuizResultLoaded(resultList));
    } catch (e) {
      emit(QuizResultError(e.toString()));
    }
  }
}
