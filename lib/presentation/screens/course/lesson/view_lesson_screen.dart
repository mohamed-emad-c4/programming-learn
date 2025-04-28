import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_programming/data/datasources/api_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:markdown/markdown.dart' as md; // ✅ Import markdown package
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'; // ✅ Use flutter_widget_from_html
import 'package:flutter_animate/flutter_animate.dart';

import '../../../cubit/lesson/view_lesson_cubit.dart';

class ViewLessonScreen extends StatefulWidget {
  final int lessonId;
  const ViewLessonScreen({super.key, required this.lessonId});

  @override
  State<ViewLessonScreen> createState() => _ViewLessonScreenState();
}

class _ViewLessonScreenState extends State<ViewLessonScreen> {
  late TextEditingController _editingController;
  late ScrollController _scrollController;
  bool _showToTopButton = false;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >= 400 && !_showToTopButton) {
      setState(() => _showToTopButton = true);
    } else if (_scrollController.offset < 400 && _showToTopButton) {
      setState(() => _showToTopButton = false);
    }
  }

  @override
  void dispose() {
    _editingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) =>
          ViewLessonCubit(ApiService())..fetchLesson(widget.lessonId),
      child: Scaffold(
        body: BlocBuilder<ViewLessonCubit, ViewLessonState>(
          builder: (context, state) {
            if (state is ViewLessonLoading) {
              return _buildLoadingState();
            } else if (state is ViewLessonError) {
              return _buildErrorState(state.message);
            } else if (state is ViewLessonLoaded) {
              final lesson = state.lesson;
              final content = lesson['content'] as Map<String, dynamic>?;
              _editingController.text =
                  content?['text'] ?? 'No content available';

              return NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar.large(
                    expandedHeight: 200,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        lesson['title'] ?? 'Lesson Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Container(
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
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.1,
                                child: CustomPaint(
                                  painter: PatternPainter(),
                                ),
                              ),
                            ),
                            if (lesson['difficulty'] != null)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Chip(
                                  label: Text(
                                    lesson['difficulty']
                                        .toString()
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                body: _buildLessonContent(context, lesson, content),
              );
            } else {
              return const Center(child: Text('No lesson data available.'));
            }
          },
        ),
        floatingActionButton: _buildFloatingButtons(),
      ),
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
            'Loading lesson content...',
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
                context.read<ViewLessonCubit>().fetchLesson(widget.lessonId);
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

  Widget _buildLessonContent(BuildContext context, Map<String, dynamic> lesson,
      Map<String, dynamic>? content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson['video_url'] != null) ...[
            _buildVideoSection(lesson['video_url']),
            const SizedBox(height: 24),
          ],
          _buildContentSection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVideoSection(String videoUrl) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: YoutubePlayer(
          controller: YoutubePlayerController(
            initialVideoId: YoutubePlayer.convertUrlToId(videoUrl)!,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              showLiveFullscreenButton: false,
            ),
          ),
          showVideoProgressIndicator: true,
          progressColors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
            bufferedColor: Colors.red,
            backgroundColor: Colors.grey,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildContentSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Lesson Content',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            HtmlWidget(
              md.markdownToHtml(_editingController.text),
              textStyle: theme.textTheme.bodyMedium,
              customStylesBuilder: (element) {
                if (element.localName == 'code') {
                  return {
                    'background':
                        theme.colorScheme.surfaceContainerHighest.toString(),
                    'color': theme.colorScheme.primary.toString(),
                    'padding': '4px 8px',
                    'border-radius': '4px',
                    'font-family': 'monospace',
                    'font-size': '14px',
                    'border': '1px solid ${theme.colorScheme.outline}',
                  };
                }
                if (element.localName == 'h1' ||
                    element.localName == 'h2' ||
                    element.localName == 'h3') {
                  return {
                    'color': theme.colorScheme.primary.toString(),
                    'font-weight': 'bold',
                    'margin': '16px 0 8px 0',
                  };
                }
                if (element.localName == 'a') {
                  return {
                    'color': theme.colorScheme.primary.toString(),
                    'text-decoration': 'none',
                  };
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3, end: 0);
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_showToTopButton)
          FloatingActionButton(
            heroTag: 'topBtn',
            mini: true,
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            child: const Icon(Icons.keyboard_arrow_up),
          ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: 'quizBtn',
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/quiz-details',
              arguments: {'lessonId': widget.lessonId},
            );
          },
          icon: const Icon(Icons.quiz),
          label: const Text('Take Quiz'),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
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
