import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_programming/presentation/screens/course/chapter_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../../cubit/course/course_cubit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => CourseCubit()..fetchCourses(),
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: Text(
                'Courses',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: theme.colorScheme.primary,
              expandedHeight: 200,
              floating: true,
              pinned: true,
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
                    Positioned(
                      right: -50,
                      top: -20,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer
                              .withOpacity(0.3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -60,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color:
                                  theme.colorScheme.onPrimary.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 4),
                          Text(
                            'What would you like to learn today?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          )
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 600.ms)
                              .slideX(begin: -0.2, end: 0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<CourseCubit, CourseState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CourseCubit>().fetchCourses();
                    },
                    child: _buildCourseList(state, context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(CourseState state, BuildContext context) {
    if (state is CourseLoading) {
      return _buildShimmerLoading();
    } else if (state is CourseError) {
      return _buildErrorState(context, state);
    } else if (state is CourseLoaded) {
      if (state.courses.isEmpty) {
        return _buildEmptyState(context);
      }
      return _buildCourseGrid(state);
    }
    return const Center(child: Text('An unexpected error occurred.'));
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: theme.colorScheme.surface,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: double.infinity,
                          color: theme.colorScheme.surface,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseGrid(CourseLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.70,
        ),
        itemCount: state.courses.length,
        itemBuilder: (context, index) {
          final course = state.courses[index];
          return _buildCourseCard(context, course, index);
        },
      ),
    );
  }

  Widget _buildCourseCard(
      BuildContext context, Map<String, dynamic> course, int index) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          log('Course ID: ${course['id']}');
          Navigator.pushNamed(
            context,
            '/chapter',
            arguments: {'courseId': course['id']},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'course-${course['id']}',
                    child: Image.network(
                      course['image_url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.school_outlined,
                            size: 40,
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
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      course['name'] ?? 'Untitled Course',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        course['description'] ?? 'No description available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          height: 1.3,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 24,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTag(
                              context,
                              Icons.category_outlined,
                              course['category'] ?? 'General',
                            ),
                            const SizedBox(width: 6),
                            _buildTag(
                              context,
                              Icons.translate_outlined,
                              course['language'] ?? 'Any',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOut)
        .scaleXY(begin: 0.96, end: 1, duration: 800.ms, curve: Curves.easeOut);
  }

  Widget _buildTag(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, CourseError state) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<CourseCubit>().fetchCourses(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No courses available yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
