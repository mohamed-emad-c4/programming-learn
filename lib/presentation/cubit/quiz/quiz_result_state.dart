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

// New state for single quiz result
class SingleQuizResultLoaded extends QuizResultState {
  final Map<String, dynamic> result;
  SingleQuizResultLoaded(this.result);

  @override
  List<Object?> get props => [result];
}

// New state for quiz attempts
class QuizAttemptsLoaded extends QuizResultState {
  final List<Map<String, dynamic>> attempts;
  QuizAttemptsLoaded(this.attempts);

  @override
  List<Object?> get props => [attempts];
}

class QuizResultError extends QuizResultState {
  final String message;
  QuizResultError(this.message);

  @override
  List<Object?> get props => [message];
}
