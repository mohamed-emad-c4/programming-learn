/* --- Begin lib\presentation\screens\course\lesson\lesson_screen.dart --- */
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learn_programming/presentation/cubit/lesson/lesson_cubit.dart'; // Ensure correct path
import 'package:learn_programming/presentation/cubit/lesson/lesson_state.dart'; // Ensure correct path
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LessonScreen extends StatefulWidget {
  final int languageId;
  final int chapterNumber;
  final String? chapterTitle;

  const LessonScreen({
    super.key,
    required this.languageId,
    required this.chapterNumber,
    this.chapterTitle,
  });

  @override
  _LessonScreenState createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  // --- Define Your Custom Colors ---
  // These will override or supplement theme colors where needed
  final Color primaryColor = Colors.blue.shade800;
  final Color accentColor = Colors.deepPurpleAccent;
  final Color cardBackgroundColor =
      Colors.blueGrey[50]!; // Specific card background
  final Color cardTextColor =
      Colors.blueGrey[800]!; // Specific text color for cards
  final Color completedColor =
      Colors.green.shade600; // Keep for potential future use
  final Color pendingColor = Colors.blueGrey; // Keep for potential future use
  // --- End Custom Colors ---

  // Track scroll position for effects
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    // Fetch lessons only if not already loading/loaded to avoid redundant calls
    // Ensure LessonCubit is provided above this widget in the tree
    final currentState = context.read<LessonCubit>().state;
    if (currentState is LessonInitial || currentState is LessonError) {
      context.read<LessonCubit>().fetchLessons(widget.chapterNumber);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _scrollProgress = _scrollController.offset /
            _scrollController.position.maxScrollExtent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: Text(
              widget.chapterTitle ?? 'Chapter ${widget.chapterNumber} Lessons',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: Stack(
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
                // Add subtle pattern overlay
                Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: PatternPainter(),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt_rounded),
                          SizedBox(width: 8),
                          Text('All'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text('Completed'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_border_rounded),
                          SizedBox(width: 8),
                          Text('Bookmarked'),
                        ],
                      ),
                    ),
                  ],
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: theme.textTheme.bodyMedium,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLessonList(context, filter: 'all'),
            _buildLessonList(context, filter: 'completed'),
            _buildLessonList(context, filter: 'bookmarked'),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
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
        .moveY(begin: 50, end: 0, duration: 300.ms, delay: 500.ms);
  }

  IconData _getFloatingActionButtonIcon() {
    switch (_selectedTabIndex) {
      case 0:
        return Icons.search_rounded;
      case 1:
        return Icons.play_circle_outline_rounded;
      case 2:
        return Icons.bookmark_add_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  String _getFloatingActionButtonLabel() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Find Lesson';
      case 1:
        return 'Continue Next';
      case 2:
        return 'Add Bookmark';
      default:
        return 'Find Lesson';
    }
  }

  Widget _buildLessonList(BuildContext context, {required String filter}) {
    return BlocBuilder<LessonCubit, LessonState>(
      builder: (context, state) {
        if (state is LessonLoading) {
          return _buildShimmerLoading(context);
        } else if (state is LessonLoaded) {
          final lessons = _filterLessons(state.lessons, filter);
          if (lessons.isEmpty) {
            return _buildEmptyState(context, filter: filter);
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<LessonCubit>().fetchLessons(widget.chapterNumber);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(context, lessons.length),
                      const SizedBox(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lessons.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildLessonCard(context, lessons[index], index),
                      ),
                      // Add bottom padding for FAB
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          );
        } else if (state is LessonError) {
          return _buildErrorState(context, state.message);
        }
        return _buildEmptyState(context, message: "Loading...");
      },
    );
  }

  List<Map<String, dynamic>> _filterLessons(
      List<Map<String, dynamic>> lessons, String filter) {
    switch (filter) {
      case 'completed':
        return lessons.where((lesson) => lesson['completed'] == true).toList();
      case 'bookmarked':
        return lessons.where((lesson) => lesson['bookmarked'] == true).toList();
      default:
        return lessons;
    }
  }

  Widget _buildHeader(BuildContext context, int lessonCount) {
    final theme = Theme.of(context);
    const completedCount = 3; // TODO: Get actual completed count from state

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
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Course Content',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$lessonCount Lessons',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completedCount / lessonCount,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completedCount of $lessonCount lessons completed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).moveY(begin: 30, end: 0);
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 150,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Lesson cards shimmer
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 200,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: 100 * index))
                  .shimmer(duration: 1200.ms, delay: 400.ms)
                  .fadeIn(duration: 600.ms);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(
      BuildContext context, Map<String, dynamic> lesson, int index) {
    final theme = Theme.of(context);
    final lessonId = lesson['lesson_id'];
    final title = lesson['title']?.toString() ?? 'Unnamed Lesson';
    final isCompleted = lesson['completed'] ?? false;

    String contentPreview = 'View lesson details';
    dynamic contentData = lesson['content'];
    if (contentData is Map && contentData['text'] is String) {
      contentPreview = (contentData['text'] as String).split('\n').first.trim();
    } else if (contentData is String) {
      contentPreview = contentData.split('\n').first.trim();
    }
    contentPreview = contentPreview.replaceAll(RegExp(r'[#*`>]'), '').trim();
    contentPreview =
        contentPreview.isEmpty ? 'View lesson details' : contentPreview;
    const maxLength = 80;
    if (contentPreview.length > maxLength) {
      contentPreview = '${contentPreview.substring(0, maxLength)}...';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (lessonId != null) {
            Navigator.pushNamed(
              context,
              '/view-lesson',
              arguments: {'lessonId': lessonId},
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Missing lesson identifier.',
                  style: TextStyle(color: theme.colorScheme.onError),
                ),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: Stack(
          children: [
            if (isCompleted)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isCompleted
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onPrimaryContainer,
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
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (contentPreview != 'View lesson details') ...[
                              const SizedBox(height: 4),
                              Text(
                                contentPreview,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate(
      effects: [
        FadeEffect(duration: 400.ms, delay: (100 * index).ms),
        SlideEffect(
          begin: const Offset(0.2, 0),
          end: const Offset(0, 0),
          duration: 400.ms,
          delay: (100 * index).ms,
        ),
      ],
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
              'Oops! Something Went Wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
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
                context.read<LessonCubit>().fetchLessons(widget.chapterNumber);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
        );
  }

  Widget _buildEmptyState(BuildContext context,
      {String? filter, String message = "No lessons available yet."}) {
    final theme = Theme.of(context);
    IconData icon;
    String title;
    String description;

    switch (filter) {
      case 'completed':
        icon = Icons.check_circle_outline;
        title = 'No Completed Lessons';
        description = 'Start learning and complete lessons to see them here.';
        break;
      case 'bookmarked':
        icon = Icons.bookmark_border_rounded;
        title = 'No Bookmarked Lessons';
        description = 'Bookmark lessons to quickly access them later.';
        break;
      default:
        icon = Icons.school_outlined;
        title = 'Nothing Here Yet';
        description = message;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).moveY(begin: 30, end: 0);
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
/* --- End lib\presentation\screens\course\lesson\lesson_screen.dart --- */