import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/course_cubit.dart';

class ChapterScreen extends StatelessWidget {
  final int courseId;

  const ChapterScreen({required this.courseId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseCubit()..fetchCourseById(courseId),
      child: Scaffold(
        appBar: AppBar(title: Text('تفاصيل الدورة')),
        body: BlocBuilder<CourseCubit, CourseState>(
          builder: (context, state) {
            if (state is CourseLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is CourseError) {
              return Center(child: Text(state.message, style: TextStyle(color: Colors.red)));
            } else if (state is SpecificCourseLoaded) {
              final course = state.course;
              final chapters = state.chapters;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Course Image
                    if (course['image_url'] != null)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(course['image_url']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Course Info
                          Text(
                            course['name'],
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          SizedBox(height: 8),
                          Text(
                            course['description'] ?? 'لا يوجد وصف',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 16),

                          Divider(),

                          // ✅ Chapters List
                          Text(
                            'الفصول',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: chapters.length,
                            itemBuilder: (context, index) {
                              final chapter = chapters[index];
                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    chapter['title'],
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(chapter['content']),
                                  leading: CircleAvatar(
                                    child: Text('${chapter['order_number']}'),
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                  onTap: () {
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

            return Center(child: Text('لا توجد بيانات متاحة.'));
          },
        ),
      ),
    );
  }
}
