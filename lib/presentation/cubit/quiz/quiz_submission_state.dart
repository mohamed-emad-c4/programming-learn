part of 'quiz_submission_cubit.dart';

abstract class QuizSubmissionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QuizSubmissionInitial extends QuizSubmissionState {}

class QuizSubmissionLoading extends QuizSubmissionState {}

class QuizSubmissionSuccess extends QuizSubmissionState {}

class QuizSubmissionError extends QuizSubmissionState {
  final String message;

  QuizSubmissionError(this.message);

  @override
  List<Object?> get props => [message];
}
