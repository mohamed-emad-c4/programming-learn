import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../cubit/quiz/quiz_details_cubit.dart';
import 'widgets/quiz_card.dart';
import 'widgets/quiz_stats_card.dart';
import 'widgets/pattern_painter.dart';

class QuizDetailsScreen extends StatefulWidget {
  final int lessonId;

  const QuizDetailsScreen({super.key, required this.lessonId});

  @override
  State<QuizDetailsScreen> createState() => _QuizDetailsScreenState();
}

class _QuizDetailsScreenState extends State<QuizDetailsScreen> {
  late ScrollController _scrollController;
  bool _showFloatingButton = false;
  int _selectedTabIndex = 0;

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
    return BlocProvider(
      create: (context) =>
          QuizDetailsCubit(ApiService())..fetchQuizzes(widget.lessonId),
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildAppBar(context),
          ],
          body: BlocBuilder<QuizDetailsCubit, QuizDetailsState>(
            builder: (context, state) {
              if (state is QuizDetailsLoading) {
                return _buildLoadingState();
              } else if (state is QuizDetailsError) {
                return _buildErrorState(state.message);
              } else if (state is QuizDetailsLoaded) {
                return _buildContent(state.quizzes);
              }
              return _buildEmptyState();
            },
          ),
        ),
        floatingActionButton:
            _showFloatingButton ? _buildFloatingActionButton() : null,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar.large(
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
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> quizzes) {
    if (quizzes.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              QuizStatsCard(quizzes: quizzes),
              const SizedBox(height: 24),
              ...List.generate(
                quizzes.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: QuizCard(quiz: quizzes[index], index: index),
                ),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
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

  Widget _buildErrorState(String message) {
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

  Widget _buildEmptyState() {
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

  Widget _buildFloatingActionButton() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_selectedTabIndex < 3)
            Positioned(
              bottom: 56,
              right: 0,
              child: FloatingActionButton.small(
                heroTag: 'bookmark_fab_quiz_details',
                onPressed: () {
                  setState(() {
                    _selectedTabIndex = (_selectedTabIndex + 1) % 3;
                  });
                },
                child: Icon(
                  _selectedTabIndex == 0
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
              ).animate().scale(delay: 200.ms),
            ),
          FloatingActionButton.extended(
            heroTag: 'main_fab_quiz_details',
            onPressed: () {
              // TODO: Implement quick navigation or lesson filtering
            },
            icon: Icon(_getFloatingActionButtonIcon()),
            label: Text(_getFloatingActionButtonLabel()),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 500.ms)
              .moveY(begin: 50, end: 0, duration: 300.ms, delay: 500.ms),
        ],
      ),
    );
  }

  IconData _getFloatingActionButtonIcon() {
    switch (_selectedTabIndex) {
      case 0:
        return Icons.play_arrow_rounded;
      case 1:
        return Icons.refresh_rounded;
      case 2:
        return Icons.bookmark_add_rounded;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  String _getFloatingActionButtonLabel() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Start Quiz';
      case 1:
        return 'Retry Quiz';
      case 2:
        return 'Bookmark Quiz';
      default:
        return 'Start Quiz';
    }
  }
}
