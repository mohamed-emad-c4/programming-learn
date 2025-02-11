import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/course_cubit.dart';
import 'lesson/lesson_screen.dart';

class ChapterScreen extends StatelessWidget {
  final int courseId;

  const ChapterScreen({required this.courseId, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseCubit()..fetchCourseById(courseId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الدورة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
          elevation: 4,
        ),
        body: BlocBuilder<CourseCubit, CourseState>(
          builder: (context, state) {
            if (state is CourseLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CourseError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<CourseCubit>().fetchCourseById(courseId),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (state is SpecificCourseLoaded) {
              final course = state.course;
              final chapters = state.chapters;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Course Image with Fallback
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(course['image_url'] ?? ''),
                          fit: BoxFit.cover,
                          onError: (_, __) =>
                              const AssetImage('assets/images/fallback.jpg'),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          course['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Course Description
                          Text(
                            course['description'] ?? 'لا يوجد وصف',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(height: 20),

                          const Divider(),

                          // ✅ Chapters List
                          const Text(
                            '📚 الفصول',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: chapters.length,
                            itemBuilder: (context, index) {
                              final chapter = chapters[index];
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    child: Text(
                                      '${chapter['order_number']}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    chapter['title'],
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                  ),
                                  subtitle: Text(
                                    chapter['content'] ?? 'لا يوجد محتوى',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LessonScreen(
                                            chapterId: chapter[
                                                'id']), // Replace 1 with the actual chapter ID
                                      ),
                                    );
                                    // TODO: Navigate to lessons screen
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('لا توجد بيانات متاحة.'));
          },
        ),
      ),
    );
  }
}
