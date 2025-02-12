import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../../domain/repositories/auth_repository_impl.dart';
import '../../../cubit/quiz/quiz_submission_cubit.dart';

class QuizSubmissionScreen extends StatefulWidget {
  final int quizId;
  final List<Map<String, dynamic>> questions;

  QuizSubmissionScreen({super.key, required this.quizId, required this.questions});

  @override
  _QuizSubmissionScreenState createState() => _QuizSubmissionScreenState();
}

class _QuizSubmissionScreenState extends State<QuizSubmissionScreen> {
  final Map<int, int> _selectedAnswers = {};
  late QuizSubmissionCubit quizSubmissionCubit;

  @override
  void initState() {
    super.initState();
    quizSubmissionCubit = QuizSubmissionCubit();
  }

  void submitAnswers() {
    final List<Map<String, dynamic>> answers = _selectedAnswers.entries
        .map((entry) => {
              "question_id": entry.key,
              "selected_option": entry.value,
            })
        .toList();
    log(answers.toString());
    quizSubmissionCubit.submitQuiz(widget.quizId, answers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Quiz'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: BlocProvider(
        create: (context) => quizSubmissionCubit,
        child: BlocListener<QuizSubmissionCubit, QuizSubmissionState>(
          listener: (context, state) {
            if (state is QuizSubmissionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quiz submitted successfully!')),
              );

              Navigator.pushReplacementNamed(
                context,
                '/quizResult',
                arguments: {
                  'quizId': widget.quizId,
                  "numberOfQuestions": widget.questions.length,
                  'token': quizSubmissionCubit.token,
                },
              );
            } else if (state is QuizSubmissionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: ListView.builder(
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
        ),
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
