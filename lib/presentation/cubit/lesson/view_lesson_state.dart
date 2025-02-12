part of 'view_lesson_cubit.dart';

abstract class ViewLessonState {}

class ViewLessonInitial extends ViewLessonState {}

class ViewLessonLoading extends ViewLessonState {}

class ViewLessonLoaded extends ViewLessonState {
  final Map<String, dynamic> lesson;

  ViewLessonLoaded(this.lesson);
}

class ViewLessonError extends ViewLessonState {
  final String message;

  ViewLessonError(this.message);
}
