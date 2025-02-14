import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../../data/models/problem_model.dart';
import 'problem_state.dart';

class ProblemCubit extends Cubit<ProblemState> {
  final ApiService apiService;
  ProblemCubit(this.apiService) : super(ProblemInitial());

  Future<void> fetchProblemsByTag(int tagId) async {
    emit(ProblemLoading());
    try {
      final problems = await apiService.getProblemsByTag(tagId);
      print('Fetched Problems: $problems');
      emit(ProblemLoaded(problems));
    } catch (e) {
      print('Error: $e');
      emit(ProblemError('Failed to load problems'));
    }
  }
}
