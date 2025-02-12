import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_programming/data/datasources/api_service.dart';

import '../../../cubit/quiz/quiz_result_cubit.dart';

class QuizResultScreen extends StatefulWidget {
  final int quizId;
  final String token;
  final int numberOfQuestions;

  const QuizResultScreen({
    super.key,
    required this.quizId,
    required this.token,
    required this.numberOfQuestions,
  });

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QuizResultCubit>().fetchQuizResult(widget.quizId, widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: Colors.teal,
      ),
      body: BlocBuilder<QuizResultCubit, QuizResultState>(
        builder: (context, state) {
          if (state is QuizResultLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is QuizResultLoaded) {
            final results = state.results;
            if (results.isEmpty) {
              return const Center(child: Text('No results found.'));
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final score = int.parse(result['score'].toString());
                final percentage = (score / widget.numberOfQuestions) * 100;
                final isPassed = percentage >= 80;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPassed ? Colors.green : Colors.red,
                      child: Icon(
                        isPassed ? Icons.thumb_up : Icons.thumb_down,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Score: $score / ${widget.numberOfQuestions}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green : Colors.red,
                      ),
                    ),
                    subtitle: Text(
                      'Submitted At: ${result['submitted_at']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Chip(
                      label: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: isPassed ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            );
          } else if (state is QuizResultError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 80),
                  const SizedBox(height: 10),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<QuizResultCubit>().fetchQuizResult(widget.quizId, widget.token);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No Data'));
          }
        },
      ),
    );
  }
}
