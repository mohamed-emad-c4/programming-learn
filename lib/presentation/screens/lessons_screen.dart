// lib/presentation/screens/lessons_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/api_service.dart';

class LessonsScreen extends StatelessWidget {
  final int languageId;
  final int chapterNumber;

  const LessonsScreen({
    required this.languageId,
    required this.chapterNumber,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الدروس'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getLessons(languageId, chapterNumber, GetIt.I.get<String>(instanceName: 'token')), // جلب الدروس
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد دروس متاحة'));
          } else {
            final lessons = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return _buildLessonCard(
                  title: lesson['title'],
                  content: lesson['content'],
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildLessonCard({
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              content,
              style: TextStyle(fontSize: 14.0, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}