part of 'course_cubit.dart';

abstract class CourseState extends Equatable {
  @override
  List<Object> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final List<Map<String, dynamic>> courses;
  CourseLoaded(this.courses);

  @override
  List<Object> get props => [courses];
}

class ChaptersLoaded extends CourseState {
  final List<Map<String, dynamic>> chapters;
  ChaptersLoaded(this.chapters);

  @override
  List<Object> get props => [chapters];
}

class CourseAndChaptersLoaded extends CourseState {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> chapters;

  CourseAndChaptersLoaded(this.course, this.chapters);

  @override
  List<Object> get props => [course, chapters];
}

// ✅ Updated to include chapters
class SpecificCourseLoaded extends CourseState {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> chapters; // Added chapters

  SpecificCourseLoaded(this.course, this.chapters); // Updated constructor

  @override
  List<Object> get props => [course, chapters];
}

class CourseError extends CourseState {
  final String message;
  CourseError(this.message);

  @override
  List<Object> get props => [message];
}
