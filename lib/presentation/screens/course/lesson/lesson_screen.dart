/* --- Begin lib\presentation\screens\course\lesson\lesson_screen.dart --- */
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learn_programming/presentation/cubit/lesson/lesson_cubit.dart'; // Ensure correct path
import 'package:learn_programming/presentation/cubit/lesson/lesson_state.dart'; // Ensure correct path
import 'package:shimmer/shimmer.dart';

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

class _LessonScreenState extends State<LessonScreen> {
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

  @override
  void initState() {
    super.initState();
    // Fetch lessons only if not already loading/loaded to avoid redundant calls
    // Ensure LessonCubit is provided above this widget in the tree
    final currentState = context.read<LessonCubit>().state;
    if (currentState is LessonInitial || currentState is LessonError) {
      context.read<LessonCubit>().fetchLessons(widget.chapterNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme, which should be the light theme configured in MaterialApp
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme; // Use derived scheme for consistency
    final textTheme = theme.textTheme;

    final String appBarTitle =
        widget.chapterTitle != null && widget.chapterTitle!.isNotEmpty
            ? widget.chapterTitle!
            : 'Chapter ${widget.chapterNumber} Lessons';

    return Scaffold(
      // AppBar uses theme settings (primaryColor background, white foreground) from MaterialApp
      appBar: AppBar(
        title: Text(appBarTitle), // Styling handled by AppBarTheme
        // Optional: Explicitly set if needed, but theme is preferred
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      // Use a clean background, derived from theme or a light grey
      backgroundColor:
          Colors.grey[100], // Or colorScheme.surface for theme consistency
      body: BlocBuilder<LessonCubit, LessonState>(
        builder: (context, state) {
          if (state is LessonLoading) {
            return _buildShimmerLoading(context);
          } else if (state is LessonLoaded) {
            final lessons = state.lessons;
            if (lessons.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return _buildLessonCard(context, lesson, index, theme);
              },
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12.0),
            );
          } else if (state is LessonError) {
            return _buildErrorState(context, state.message, theme);
          } else {
            return _buildEmptyState(context, message: "Loading...");
          }
        },
      ),
    );
  }

  // --- UI Building Helper Widgets ---

  Widget _buildShimmerLoading(BuildContext context) {
    // Shimmer for light mode only
    final baseColor = Colors.grey[200]!;
    final highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 12.0),
        itemBuilder: (context, index) {
          // Mimic the card structure accurately
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            decoration: BoxDecoration(
              color: Colors.white, // Shimmer base needs a solid color
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.white),
                      const SizedBox(height: 8),
                      Container(
                          height: 12,
                          width: MediaQuery.of(context).size.width * 0.5,
                          color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 18, height: 18, color: Colors.white),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Map<String, dynamic> lesson,
      int index, ThemeData theme) {
    final colorScheme = theme.colorScheme; // Use for theme-consistent elements
    final textTheme = theme.textTheme;

    final lessonId = lesson['lesson_id'];
    final title = lesson['title']?.toString() ?? 'Unnamed Lesson';

    // Simplified Content Preview Logic (adjust as needed)
    String contentPreview = 'View lesson details';
    dynamic contentData = lesson['content'];
    if (contentData is Map && contentData['text'] is String) {
      contentPreview = (contentData['text'] as String).split('\n').first.trim();
    } else if (contentData is String) {
      contentPreview = contentData.split('\n').first.trim();
    }
    contentPreview = contentPreview
        .replaceAll(RegExp(r'[#*`>]'), '')
        .trim(); // Basic cleanup
    contentPreview =
        contentPreview.isEmpty ? 'View lesson details' : contentPreview;
    const maxLength = 80;
    if (contentPreview.length > maxLength) {
      contentPreview = '${contentPreview.substring(0, maxLength)}...';
    }

    return Card(
      // Use the specific background color provided by the user
      color: cardBackgroundColor,
      // Use theme's card shape and elevation (or define explicitly)
      shape: theme.cardTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: theme.cardTheme.elevation ?? 1.5,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0), // Match card shape
        onTap: () {
          if (lessonId != null) {
            Navigator.pushNamed(context, '/view-lesson',
                arguments: {'lessonId': lessonId});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Error: Missing lesson identifier.')),
            );
          }
        },
        child: Hero(
          tag: "lesson_${lessonId ?? UniqueKey()}", // Ensure unique tag
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Leading Circle: Use primary color variations
                  CircleAvatar(
                    radius: 20,
                    // Use a lighter shade of primary or accent for background
                    backgroundColor: primaryColor.withOpacity(0.1),
                    // Use primary color for the text
                    foregroundColor: primaryColor,
                    child: Text(
                      "${index + 1}",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Center Text: Use the specific card text color
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                // Use the specific card text color
                                color: cardTextColor,
                              ) ??
                              GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: cardTextColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contentPreview != 'View lesson details') ...[
                          const SizedBox(height: 4),
                          Text(
                            contentPreview,
                            style: textTheme.bodyMedium?.copyWith(
                                  // Use the specific card text color, maybe slightly lighter
                                  color: cardTextColor.withOpacity(0.7),
                                ) ??
                                GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: cardTextColor.withOpacity(0.7)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Trailing Icon: Use the primary color for action
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, String message, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red[400], size: 60), // Standard error color
            const SizedBox(height: 20),
            Text(
              'Oops! Something Went Wrong',
              style: textTheme.headlineSmall
                  ?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Button uses primaryColor via FilledButtonTheme in MaterialApp
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              // style: FilledButton.styleFrom(backgroundColor: primaryColor), // Explicit override if theme fails
              onPressed: () {
                context.read<LessonCubit>().fetchLessons(widget.chapterNumber);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context,
      {String message = "No lessons available yet."}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use accent or a neutral color for the icon
            Icon(Icons.school_outlined,
                color: accentColor.withOpacity(0.5), size: 60),
            const SizedBox(height: 20),
            Text(
              'Nothing Here Yet',
              style: textTheme.headlineSmall
                  ?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
/* --- End lib\presentation\screens\course\lesson\lesson_screen.dart --- */