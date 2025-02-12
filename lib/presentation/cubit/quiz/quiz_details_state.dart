part of 'quiz_details_cubit.dart';

abstract class QuizDetailsState extends Equatable {
  @override
  List<Object> get props => [];
}

class QuizDetailsInitial extends QuizDetailsState {}

class QuizDetailsLoading extends QuizDetailsState {}

class QuizDetailsLoaded extends QuizDetailsState {
  final List<Map<String, dynamic>> quizzes;
  QuizDetailsLoaded(this.quizzes);

  @override
  List<Object> get props => [quizzes];
}

class QuizDetailsError extends QuizDetailsState {
  final String message;
  QuizDetailsError(this.message);

  @override
  List<Object> get props => [message];
}
