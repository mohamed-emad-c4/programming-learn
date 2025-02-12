import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../cubit/quiz/quiz_details_cubit.dart';

class QuizDetailsScreen extends StatelessWidget {
  final int lessonId;

  const QuizDetailsScreen({Key? key, required this.lessonId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuizDetailsCubit(ApiService())..fetchQuizzes(lessonId),
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: const Text('Quiz Details'),
          backgroundColor: Colors.teal,
          centerTitle: true,
        ),
        body: BlocBuilder<QuizDetailsCubit, QuizDetailsState>(
          builder: (context, state) {
            if (state is QuizDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is QuizDetailsError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is QuizDetailsLoaded) {
              final quizzes = state.quizzes;
              return ListView.builder(
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: QuizCard(quiz: quiz),
                    ),
                  );
                },
              );
            } else {
              return const Center(child: Text('No quizzes available.'));
            }
          },
        ),
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  final Map<String, dynamic> quiz;

  const QuizCard({Key? key, required this.quiz}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
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
                onPressed: () => navigateToQuiz(context, quiz),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
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

  void navigateToQuiz(BuildContext context, Map<String, dynamic> quiz) {
    Navigator.pushNamed(
      context,
      '/quiz-submission',
      arguments: {
        'quizId': quiz['id'],
        'questions': List<Map<String, dynamic>>.from(quiz['questions']),
      },
    );
  }
}
