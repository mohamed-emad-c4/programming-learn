import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Import intl package
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
    context
        .read<QuizResultCubit>()
        .fetchQuizResult(widget.quizId, widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white)),
        backgroundColor: Colors.blueAccent, // Added gradient effect
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

                // Parse the date
                final submittedAt = DateTime.parse(result['submitted_at']);
                final formattedDate =
                    DateFormat('yy:MM:dd-HH:mm:ss a').format(submittedAt);

                return AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 600), // Smoother transition
                  curve: Curves.easeInOut,
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPassed ? Colors.green : Colors.red,
                      child: Icon(
                        isPassed ? Icons.thumb_up : Icons.thumb_down,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      'Score: $score / ${widget.numberOfQuestions}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green : Colors.red,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Submitted At: $formattedDate', // Use the formatted date here
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    trailing: Chip(
                      label: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: isPassed ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                  const Icon(Icons.error, color: Colors.red, size: 100),
                  const SizedBox(height: 15),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<QuizResultCubit>()
                          .fetchQuizResult(widget.quizId, widget.token);
                    },
                    icon: const Icon(Icons.refresh, size: 30),
                    label: const Text('Retry', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 25),
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
