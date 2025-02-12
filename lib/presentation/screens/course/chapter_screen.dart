import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/values.dart';
import '../../cubit/course_cubit.dart';

class ChapterScreen extends StatelessWidget {
  final int courseId;

  const ChapterScreen({required this.courseId, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseCubit()..fetchCourseById(courseId),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // ✅ 1. تحسين AppBar ليكون SliverAppBar
            SliverAppBar(
              expandedHeight: 250.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'تفاصيل الدورة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: BlocBuilder<CourseCubit, CourseState>(
                  builder: (context, state) {
                    if (state is SpecificCourseLoaded) {
                      final course = state.course;
                      return Hero(
                        tag: 'courseImage-${course['id']}',
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/fallback.jpg',
                          image: course['image_url'] ?? '',
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return Image.asset(
                      'assets/images/fallback.jpg',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              backgroundColor: Colors.blueAccent,
            ),

            SliverList(
              delegate: SliverChildListDelegate(
                [
                  BlocBuilder<CourseCubit, CourseState>(
                    builder: (context, state) {
                      if (state is CourseLoading) {
                        return const Center(
                            child: CircularProgressIndicator());
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
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<CourseCubit>()
                                    .fetchCourseById(courseId),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        );
                      } else if (state is SpecificCourseLoaded) {
                        final course = state.course;
                        final chapters = state.chapters;

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✅ 4. تحسين ألوان النصوص والخطوط
                              Text(
                                course['description'] ?? 'لا يوجد وصف',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const Text(
                                '📚 الفصول',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // ✅ 3. تحسين بطاقات الفصول
                              ListView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: chapters.length,
                                itemBuilder: (context, index) {
                                  final chapter = chapters[index];
                                  return _buildChapterCard(
                                      context, chapter);
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return const Center(
                          child: Text('لا توجد بيانات متاحة.'));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ تحسين تصميم بطاقات الفصول
  Widget _buildChapterCard(
      BuildContext context, Map<String, dynamic> chapter) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.shade100,
          child: Text(
            '${chapter['order_number']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          chapter['title'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            chapter['content'] ?? 'لا يوجد محتوى',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/lessons',
            arguments: {
              'languageId': current_course_Id,
              'chapterNumber': chapter['id'],
            },
          );
        },
      ),
    );
  }
}
