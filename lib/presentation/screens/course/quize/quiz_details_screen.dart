import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../cubit/quiz/quiz_details_cubit.dart';

class QuizDetailsScreen extends StatefulWidget {
  final int lessonId;

  const QuizDetailsScreen({super.key, required this.lessonId});

  @override
  State<QuizDetailsScreen> createState() => _QuizDetailsScreenState();
}

class _QuizDetailsScreenState extends State<QuizDetailsScreen> {
  late ScrollController _scrollController;
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >= 200 && !_showFloatingButton) {
      setState(() => _showFloatingButton = true);
    } else if (_scrollController.offset < 200 && _showFloatingButton) {
      setState(() => _showFloatingButton = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) =>
          QuizDetailsCubit(ApiService())..fetchQuizzes(widget.lessonId),
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar.large(
              expandedHeight: 200,
              pinned: true,
              title: Text(
                'Quiz Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: CustomPaint(
                          painter: PatternPainter(),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -50,
                      bottom: -20,
                      child: Icon(
                        Icons.quiz_rounded,
                        size: 180,
                        color: theme.colorScheme.onPrimary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: BlocBuilder<QuizDetailsCubit, QuizDetailsState>(
            builder: (context, state) {
              if (state is QuizDetailsLoading) {
                return _buildLoadingState(context);
              } else if (state is QuizDetailsError) {
                return _buildErrorState(context, state.message);
              } else if (state is QuizDetailsLoaded) {
                final quizzes = state.quizzes;
                if (quizzes.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildQuizList(context, quizzes);
              } else {
                return _buildEmptyState(context);
              }
            },
          ),
        ),
        floatingActionButton: _showFloatingButton
            ? FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(Icons.keyboard_arrow_up),
              ).animate().scale()
            : null,
      ),
    );
  }

  Widget _buildQuizList(
      BuildContext context, List<Map<String, dynamic>> quizzes) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildQuizStats(context, quizzes),
              const SizedBox(height: 24),
              ...List.generate(
                quizzes.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: QuizCard(quiz: quizzes[index], index: index),
                ),
              ),
              const SizedBox(height: 80), // Bottom padding
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizStats(
      BuildContext context, List<Map<String, dynamic>> quizzes) {
    final theme = Theme.of(context);
    final totalQuizzes = quizzes.length;
    final completedQuizzes =
        quizzes.where((q) => q['completed'] == true).length;

    // Calculate average score properly
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

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading quizzes...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                context.read<QuizDetailsCubit>().fetchQuizzes(widget.lessonId);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 600.ms,
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No Quizzes Available',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no quizzes available for this lesson yet.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).moveY(begin: 30, end: 0),
    );
  }
}

class QuizCard extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final int index;

  const QuizCard({super.key, required this.quiz, required this.index});

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
        onTap: () => navigateToQuiz(context, quiz),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.quiz_rounded,
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
              ),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.stars_rounded,
                      'Total Marks',
                      quiz['total_marks'].toString(),
                      theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      context,
                      Icons.timer_outlined,
                      'Time Limit',
                      '${quiz['time_limit']} mins',
                      theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      context,
                      Icons.question_answer_outlined,
                      'Questions',
                      quiz['questions'].length.toString(),
                      theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => navigateToQuiz(context, quiz),
                  icon: Icon(
                    isCompleted
                        ? Icons.refresh_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(isCompleted ? 'Retake Quiz' : 'Start Quiz'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isCompleted
                        ? theme.colorScheme.secondaryContainer
                        : null,
                    foregroundColor: isCompleted
                        ? theme.colorScheme.onSecondaryContainer
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.2, end: 0);
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

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(i, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
