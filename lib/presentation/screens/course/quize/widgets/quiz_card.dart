import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizCard extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final int index;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription = quiz['description'] != null &&
        quiz['description'].toString().isNotEmpty;
    final isCompleted = quiz['completed'] ?? false;
    final score = quiz['score'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToQuiz(context, quiz),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, quiz, isCompleted, score),
              if (hasDescription) ...[
                const SizedBox(height: 16),
                Text(
                  quiz['description'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildQuizInfo(context, quiz),
              const SizedBox(height: 20),
              _buildActionButton(context, isCompleted),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildHeader(
    BuildContext context,
    Map<String, dynamic> quiz,
    bool isCompleted,
    dynamic score,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.quiz_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz['title'],
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (score != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Score: ${score.toStringAsFixed(1)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Completed',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuizInfo(BuildContext context, Map<String, dynamic> quiz) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildInfoChip(
            context,
            Icons.stars_rounded,
            'Total Marks',
            quiz['total_marks'].toString(),
            Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            context,
            Icons.timer_outlined,
            'Time Limit',
            '${quiz['time_limit']} mins',
            Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            context,
            Icons.question_answer_outlined,
            'Questions',
            quiz['questions'].length.toString(),
            Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _navigateToQuiz(context, quiz),
        icon: Icon(
          isCompleted ? Icons.refresh_rounded : Icons.play_arrow_rounded,
        ),
        label: Text(isCompleted ? 'Retake Quiz' : 'Start Quiz'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor:
              isCompleted ? theme.colorScheme.secondaryContainer : null,
          foregroundColor:
              isCompleted ? theme.colorScheme.onSecondaryContainer : null,
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToQuiz(BuildContext context, Map<String, dynamic> quiz) {
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
