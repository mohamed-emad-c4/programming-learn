import '../../../../data/models/problem_model.dart';

abstract class ProblemState {}

class ProblemInitial extends ProblemState {}

class ProblemLoading extends ProblemState {}

class ProblemLoaded extends ProblemState {
  final List<ProblemModel> problems;
  ProblemLoaded(this.problems);
}

class ProblemError extends ProblemState {
  final String message;
  ProblemError(this.message);
}
