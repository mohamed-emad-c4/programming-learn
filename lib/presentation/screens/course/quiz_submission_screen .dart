import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../data/datasources/api_service.dart';
import '../../../domain/repositories/auth_repository_impl.dart';
import 'quiz_result_screen.dart';

class QuizSubmissionScreen extends StatefulWidget {
  final int quizId;
  final List<Map<String, dynamic>> questions;

  QuizSubmissionScreen(
      {super.key, required this.quizId, required this.questions});
  late String token;

  @override
  _QuizSubmissionScreenState createState() => _QuizSubmissionScreenState();
}

class _QuizSubmissionScreenState extends State<QuizSubmissionScreen> {
  final Map<int, int> _selectedAnswers = {};
  ApiService apiService = ApiService();

  Future<void> submitAnswers() async {
    final authRepository = AuthRepositoryImpl();
    final token = await authRepository.getToken() ?? '';
    final List<Map<String, dynamic>> answers = _selectedAnswers.entries
        .map((entry) => {
              "question_id": entry.key,
              "selected_option": entry.value,
            })
        .toList();
    log(answers.toString());

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/quizzes/${widget.quizId}/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"answers": answers}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz submitted successfully!')),
      );

      final resultResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/quizzes/${widget.quizId}/results'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resultResponse.statusCode == 200) {
        final List<dynamic> resultList = jsonDecode(resultResponse.body);
        if (resultList.isNotEmpty) {
          final result = resultList.first as Map<String, dynamic>;
          Navigator.pushReplacementNamed(
            context,
            '/quizResult',
            arguments: {
              'quizId': result['quiz_id'],
              'token': token,
              "numberOfQuestions": widget.questions.length
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No result available.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch quiz result.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit quiz.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Quiz'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final question = widget.questions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${question['question_text']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(
                    question['options'].length,
                    (optionIndex) => RadioListTile<int>(
                      title: Text(question['options'][optionIndex]),
                      value: optionIndex,
                      groupValue: _selectedAnswers[question['id']],
                      onChanged: (value) {
                        setState(() {
                          _selectedAnswers[question['id']] = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitAnswers,
        backgroundColor: Colors.teal,
        label: const Text(
          'Submit Answers',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.send),
      ),
    );
  }
}
