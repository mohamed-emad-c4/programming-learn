// lib/presentation/screens/fundamentals_screen.dart
import 'package:flutter/material.dart';
import 'package:learn_programming/presentation/screens/essonsScreen.dart';
import '../../data/datasources/api_service.dart';

class FundamentalsScreen extends StatelessWidget {
  final int languageId;

  const FundamentalsScreen({required this.languageId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أساسيات الكمبيوتر'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.getChapters(languageId), // جلب الفصول
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
            return Center(child: Text('لا توجد بيانات متاحة'));
          } else {
            final chapters = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return _buildChapterCard(
                  chapterNumber: chapter['chapter_number'],
                  chapterName: chapter['chapter_name'],
                  onTap: () {
                    // الانتقال إلى شاشة الدروس
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonsScreen(
                          languageId: languageId,
                          chapterNumber: chapter['chapter_number'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildChapterCard({
    required int chapterNumber,
    required String chapterName,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الفصل $chapterNumber: $chapterName',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}