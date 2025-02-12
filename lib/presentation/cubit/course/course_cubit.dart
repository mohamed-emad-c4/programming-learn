import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/datasources/api_service.dart';

part 'course_state.dart';

class CourseCubit extends Cubit<CourseState> {
  CourseCubit() : super(CourseInitial());

  Future<void> fetchCourses() async {
    emit(CourseLoading());
    try {
      final courses = await ApiService.getCourses();
      emit(CourseLoaded(courses));
    } catch (e) {
      emit(CourseError("❌ Failed to load courses: $e"));
    }
  }

  // ✅ Updated to include chapters
  Future<void> fetchCourseById(int courseId) async {
    emit(CourseLoading());
    try {
      final course = await ApiService.getCourseById(courseId);
      final chapters = await ApiService.getChaptersByCourseId(courseId); // Fetch chapters
      emit(SpecificCourseLoaded(course, chapters)); // Emit with chapters
    } catch (e) {
      emit(CourseError("❌ Failed to load course: $e"));
    }
  }

  Future<void> fetchChapters(int courseId) async {
    emit(CourseLoading());
    try {
      final chapters = await ApiService.getChapters(courseId);
      emit(ChaptersLoaded(chapters));
    } catch (e) {
      emit(CourseError("❌ Failed to load chapters: $e"));
    }
  }

  Future<void> fetchAllChapters() async {
    emit(CourseLoading());
    try {
      final chapters = await ApiService.getAllChapters();
      emit(ChaptersLoaded(chapters));
    } catch (e) {
      emit(CourseError('❌ Failed to load chapters: $e'));
    }
  }

  Future<void> fetchChaptersByCourseId(int courseId) async {
    emit(CourseLoading());
    try {
      final chapters = await ApiService.getChaptersByCourseId(courseId);
      emit(ChaptersLoaded(chapters));
    } catch (e) {
      emit(CourseError('❌ Failed to load chapters: $e'));
    }
  }

  Future<void> fetchCourseAndChapters(int courseId) async {
    emit(CourseLoading());
    try {
      final course = await ApiService.getCourseById(courseId);
      final chapters = await ApiService.getChaptersByCourseId(courseId);
      emit(CourseAndChaptersLoaded(course, chapters));
    } catch (e) {
      emit(CourseError('❌ Failed to load data: $e'));
    }
  }
}
