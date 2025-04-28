/* --- Begin lib\presentation\screens\course\chapter_screen.dart --- */
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../cubit/course/course_cubit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChapterScreen extends StatelessWidget {
  final int courseId;

  const ChapterScreen({required this.courseId, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => CourseCubit()..fetchCourseById(courseId),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: BlocBuilder<CourseCubit, CourseState>(
          builder: (context, state) {
            if (state is CourseLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              );
            } else if (state is CourseError) {
              return _buildErrorState(context, state.message);
            } else if (state is SpecificCourseLoaded) {
              final course = state.course;
              final chapters = state.chapters;
              final bool allCompleted = chapters.isNotEmpty &&
                  chapters.every((c) => c['completed'] ?? true);

              return Scaffold(
                backgroundColor: Colors.transparent,
                body: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(context, course),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDescription(context, course),
                            const SizedBox(height: 24),
                            _buildStats(context, chapters),
                            const SizedBox(height: 24),
                            Divider(color: theme.dividerColor.withOpacity(0.1)),
                            const SizedBox(height: 24),
                            _buildChapterList(context, chapters),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                persistentFooterButtons: [
                  _buildFinalExamButton(context, courseId, allCompleted)
                ],
                persistentFooterAlignment: AlignmentDirectional.center,
              );
            }
            return Center(
              child: Text(
                'Loading course details...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> course) {
    final theme = Theme.of(context);

    return SliverAppBar.large(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          course['title'] ?? 'Course Details',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'courseImage-${course['id']}',
              child: Image.network(
                course['image_url'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.primary.withOpacity(0.3),
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, Map<String, dynamic> course) {
    final theme = Theme.of(context);

    return Text(
      course['description'] ?? 'No description available for this course.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.8),
        height: 1.6,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .moveX(begin: -30, end: 0, duration: 600.ms);
  }

  Widget _buildStats(
      BuildContext context, List<Map<String, dynamic>> chapters) {
    final theme = Theme.of(context);
    final completedCount =
        chapters.where((c) => c['completed'] ?? false).length;
    final totalChapters = chapters.length;
    final progress = totalChapters > 0 ? completedCount / totalChapters : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $totalChapters chapters completed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Icon(
                Icons.auto_stories,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildChapterList(
      BuildContext context, List<Map<String, dynamic>> chapters) {
    final theme = Theme.of(context);

    if (chapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No chapters available yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.library_books_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Course Content',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            return _buildChapterCard(context, chapters[index], index + 1)
                .animate(delay: Duration(milliseconds: 100 * index))
                .fadeIn(duration: 600.ms)
                .moveX(begin: 30, end: 0, duration: 600.ms);
          },
        ),
      ],
    );
  }

  Widget _buildChapterCard(
      BuildContext context, Map<String, dynamic> chapter, int chapterNumber) {
    final theme = Theme.of(context);
    final bool isCompleted = chapter['completed'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          log('Chapter ID: ${chapter['id']}');
          Navigator.pushNamed(
            context,
            '/lessons',
            arguments: {
              'languageId': courseId,
              'chapterNumber': chapter['id'],
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    '$chapterNumber',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isCompleted
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter['title'] ?? 'Unnamed Chapter',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (chapter['duration'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${chapter['duration']} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isCompleted ? Icons.check_circle : Icons.play_circle_outline,
                color: isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.4),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalExamButton(
      BuildContext context, int courseId, bool allCompleted) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        onPressed: allCompleted
            ? () {
                Navigator.pushNamed(context, '/exam', arguments: courseId);
              }
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: theme.colorScheme.primary,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(
          allCompleted ? Icons.quiz : Icons.lock_outline,
          size: 20,
        ),
        label: Text(
          allCompleted ? 'Start Final Exam' : 'Complete All Chapters to Unlock',
          style: theme.textTheme.titleMedium?.copyWith(
            color: allCompleted
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  context.read<CourseCubit>().fetchCourseById(courseId),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scaleXY(begin: 0.8, end: 1.0, duration: 600.ms);
  }
}
/* --- End lib\presentation\screens\course\chapter_screen.dart --- */