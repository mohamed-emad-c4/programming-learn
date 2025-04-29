import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizStatsCard extends StatelessWidget {
  final List<Map<String, dynamic>> quizzes;

  const QuizStatsCard({
    super.key,
    required this.quizzes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalQuizzes = quizzes.length;
    final completedQuizzes =
        quizzes.where((q) => q['completed'] == true).length;

    final scores = quizzes
        .where((q) => q['score'] != null)
        .map((q) => q['score'] as num)
        .toList();
    final averageScore = scores.isNotEmpty
        ? scores.reduce((a, b) => a + b) / scores.length
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                Icons.assignment_turned_in_rounded,
                '$completedQuizzes/$totalQuizzes',
                'Completed',
              ),
              _buildStatItem(
                context,
                Icons.stars_rounded,
                averageScore?.toStringAsFixed(1) ?? '-',
                'Avg. Score',
              ),
              _buildStatItem(
                context,
                Icons.timeline_rounded,
                '${((completedQuizzes / totalQuizzes) * 100).toStringAsFixed(0)}%',
                'Progress',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completedQuizzes / totalQuizzes,
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.secondary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
        );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.secondary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
