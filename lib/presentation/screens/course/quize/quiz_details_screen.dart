import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';

import '../../../../data/datasources/api_service.dart';
import 'quiz_submission_screen .dart';

class QuizDetailsScreen extends StatefulWidget {
  final int lessonId;

  const QuizDetailsScreen({Key? key, required this.lessonId}) : super(key: key);

  @override
  _QuizDetailsScreenState createState() => _QuizDetailsScreenState();
}

class _QuizDetailsScreenState extends State<QuizDetailsScreen> {
  late Future<List<Map<String, dynamic>>> _quizzes;
ApiService apiService = ApiService();

  Future<List<Map<String, dynamic>>> fetchQuizzes(int lessonId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/quizzes/by-lesson/$lessonId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load quizzes');
    }
  }

  @override
  void initState() {
    super.initState();
    _quizzes = fetchQuizzes(widget.lessonId);
  }

  void navigateToQuiz(Map<String, dynamic> quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSubmissionScreen(
          
          quizId: quiz['id'],
          questions: List<Map<String, dynamic>>.from(quiz['questions']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Quiz Details'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 4,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _quizzes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No quizzes available.'));
          } else {
            final quizzes = snapshot.data!;
            return ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 200 * index),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: MediaQuery.of(context).size.height * 0.05),
                    child: Card(
                      color: Colors.white,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz['title'],
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              quiz['description'] ?? 'No description available.',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _infoCard('Total Marks', quiz['total_marks'].toString()),
                                _infoCard('Time Limit', '${quiz['time_limit']} mins'),
                                _infoCard('Questions', quiz['questions'].length.toString()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed: () => navigateToQuiz(quiz),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                ),
                                child: const Text(
                                  'Start Quiz',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
