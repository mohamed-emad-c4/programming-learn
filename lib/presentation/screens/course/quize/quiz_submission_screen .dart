import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../../domain/repositories/auth_repository_impl.dart';
import '../../../cubit/quiz/quiz_submission_cubit.dart';

class QuizSubmissionScreen extends StatefulWidget {
  final int quizId;
  final List<Map<String, dynamic>> questions;

  const QuizSubmissionScreen(
      {super.key, required this.quizId, required this.questions});

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
        title: const Text('Answer Quiz',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blue[800], // Blue color for the app bar
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: widget.questions.length,
            itemBuilder: (context, index) {
              final question = widget.questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6, // Slightly increased elevation for better shadow
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
                          color: Colors.blue, // Blue color for question text
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(
                            question['options'].length,
                            (optionIndex) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAnswers[question['id']] =
                                      optionIndex;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: _selectedAnswers[question['id']] ==
                                          optionIndex
                                      ? Colors.blue[100]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedAnswers[question['id']] ==
                                            optionIndex
                                        ? Colors.blue
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedAnswers[question['id']] ==
                                              optionIndex
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: _selectedAnswers[question['id']] ==
                                              optionIndex
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        question['options'][optionIndex],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
        backgroundColor: Colors.blue[800], // Blue color for the floating button
        label: const Text(
          'Submit Answers',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        icon: const Icon(Icons.send, color: Colors.white),
      ),
    );
  }
}
