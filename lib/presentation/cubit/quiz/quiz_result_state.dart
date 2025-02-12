part of 'quiz_result_cubit.dart';

abstract class QuizResultState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QuizResultInitial extends QuizResultState {}

class QuizResultLoading extends QuizResultState {}

class QuizResultLoaded extends QuizResultState {
  final List<Map<String, dynamic>> results;
  QuizResultLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class QuizResultError extends QuizResultState {
  final String message;
  QuizResultError(this.message);

  @override
  List<Object?> get props => [message];
}
