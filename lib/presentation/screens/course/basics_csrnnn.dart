import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/course_cubit.dart';

class CourseDetailScreen extends StatelessWidget {
  final int courseId;

  CourseDetailScreen({this.courseId = 14});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseCubit()..fetchCourseAndChapters(courseId),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('تفاصيل الدورة', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<CourseCubit>().fetchCourseAndChapters(courseId),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (state is CourseAndChaptersLoaded) {
              final course = state.course;
              final chapters = state.chapters;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCourseBanner(course),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCourseInfo(course),
                          const SizedBox(height: 20),
                          const Text(
                            '📚 الفصول',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 10),
                          _buildChapterList(chapters),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('لم يتم العثور على بيانات الدورة.'));
          },
        ),
      ),
    );
  }

  // ✅ Course Banner with Image
  Widget _buildCourseBanner(Map<String, dynamic> course) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(course['image_url'] ?? ''),
          fit: BoxFit.cover,
          onError: (_, __) => const AssetImage('assets/images/fallback.jpg'),
        ),
      ),
      child: Container(
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black54, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Text(
          course['name'],
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  // ✅ Course Information Section
  Widget _buildCourseInfo(Map<String, dynamic> course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.description, course['description'] ?? 'لا يوجد وصف'),
        _infoRow(Icons.category, course['category'] ?? 'غير مصنف'),
        _infoRow(Icons.language, course['language'] ?? 'غير محدد'),
        _infoRow(Icons.star, course['level'] ?? 'غير محدد'),
        _infoRow(Icons.check_circle, course['status'] == 'active' ? 'نشط' : 'غير نشط'),
      ],
    );
  }

  Widget _infoRow(IconData icon, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Chapters List with Expandable Cards
  Widget _buildChapterList(List<Map<String, dynamic>> chapters) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return _buildChapterCard(chapter);
      },
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            '${chapter['order_number']}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          chapter['title'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              chapter['content'] ?? 'لا يوجد محتوى',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}