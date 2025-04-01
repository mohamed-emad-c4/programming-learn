/* --- Begin lib\presentation\screens\course\chapter_screen.dart --- */
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../cubit/course/course_cubit.dart';

class ChapterScreen extends StatelessWidget {
  final int courseId;

  const ChapterScreen({required this.courseId, super.key});

  @override
  Widget build(BuildContext context) {
    // Define consistent theme colors (can be moved to a theme file later)
    final Color primaryColor = Colors.blue.shade800;
    final Color accentColor = Colors.deepPurpleAccent;
    final Color cardBackgroundColor = Colors.blueGrey[50]!;
    final Color cardTextColor = Colors.blueGrey[800]!;
    final Color completedColor = Colors.green.shade600;
    final Color pendingColor = Colors.blueGrey;

    return BlocProvider(
      create: (context) => CourseCubit()..fetchCourseById(courseId),
      child: Scaffold(
        // Use Scaffold background color for consistency
        backgroundColor: Colors.grey[100],
        body: BlocBuilder<CourseCubit, CourseState>(
          builder: (context, state) {
            if (state is CourseLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CourseError) {
              return _buildErrorState(context, state.message, primaryColor);
            } else if (state is SpecificCourseLoaded) {
              final course = state.course;
              final chapters = state.chapters;
              // Calculate completion state here to pass to the persistent footer button
              final bool allCompleted = chapters.isNotEmpty &&
                  chapters.every((c) => c['completed'] ?? true);

              return Scaffold(
                // Nested Scaffold to easily use persistentFooterButtons with CustomScrollView
                // Make the inner Scaffold transparent so the outer one's background shows
                backgroundColor: Colors.transparent,
                body: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(context, course, primaryColor),
                    SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDescription(context, course),
                                const SizedBox(height: 20),
                                Divider(color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                _buildChapterList(
                                  context,
                                  chapters,
                                  accentColor,
                                  cardBackgroundColor,
                                  cardTextColor,
                                  completedColor,
                                  pendingColor,
                                ),
                                // Space at the bottom to ensure content doesn't hide behind the button initially
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // --- Persistent Footer Button ---
                // This button stays fixed at the bottom, regardless of scrolling
                persistentFooterButtons: [
                  _buildFinalExamButton(
                      context, courseId, allCompleted, completedColor)
                ],
                // Center the button if needed, or adjust padding within _buildFinalExamButton
                persistentFooterAlignment: AlignmentDirectional.center,
              );
            }
            // Fallback for unhandled states or initial state
            return Center(
                child: Text(
              'Loading course details...',
              style: GoogleFonts.poppins(color: Colors.grey),
            ));
          },
        ),
      ),
    );
  }

  // ✅ Enhanced Sliver App Bar
  Widget _buildSliverAppBar(
      BuildContext context, Map<String, dynamic> course, Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true, // Allows stretching on overscroll
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          course['title'] ?? 'Course Details', // Use course title if available
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsetsDirectional.only(
            start: 72, bottom: 16), // Adjust padding
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'courseImage-${course['id']}',
              child: FadeInImage.assetNetwork(
                placeholder:
                    'assets/images/fallback.jpg', // Ensure this asset exists
                image: course['image_url'] ?? '',
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  // Fallback in case the network image fails
                  return Image.asset('assets/images/fallback.jpg',
                      fit: BoxFit.cover);
                },
              ),
            ),
            // Add a gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: primaryColor, // Use primary theme color
      iconTheme: const IconThemeData(
          color: Colors.white), // Ensure back button is visible
    );
  }

  // ✅ Enhanced Course Description
  Widget _buildDescription(BuildContext context, Map<String, dynamic> course) {
    return Text(
      course['description'] ?? 'No description available for this course.',
      style: GoogleFonts.roboto(
        // Or Poppins for consistency
        fontSize: 16,
        color: Colors.black87, // Good contrast
        height: 1.5, // Improved line spacing
      ),
    );
  }

  // ✅ Enhanced Chapter List UI
  Widget _buildChapterList(
      BuildContext context,
      List<Map<String, dynamic>> chapters,
      Color accentColor,
      Color cardBackgroundColor,
      Color cardTextColor,
      Color completedColor,
      Color pendingColor) {
    if (chapters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Text(
            'No chapters found for this course yet.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📚 Chapters',
          style: GoogleFonts.poppins(
            // Consistent font
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: accentColor, // Use accent theme color
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true, // Important inside Column/SliverList
          physics:
              const NeverScrollableScrollPhysics(), // Scrolling handled by CustomScrollView
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            return _buildChapterCard(
              context,
              chapters[index],
              index + 1, // Pass chapter number for display
              cardBackgroundColor,
              cardTextColor,
              completedColor,
              pendingColor,
            );
          },
        ),
      ],
    );
  }

  // ✅ Enhanced Chapter Card UI
  Widget _buildChapterCard(
      BuildContext context,
      Map<String, dynamic> chapter,
      int chapterNumber,
      Color cardBackgroundColor,
      Color cardTextColor,
      Color completedColor,
      Color pendingColor) {
    final bool isCompleted =
        chapter['completed'] ?? true; // Default to true if not specified

    return Card(
      // Using Card for elevation and shape
      margin:
          const EdgeInsets.symmetric(vertical: 6.0), // Reduced vertical margin
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: cardBackgroundColor, // Use defined card color
      child: InkWell(
        // InkWell provides ripple effect on tap
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.pushNamed(context, '/lessons', arguments: {
            'languageId': courseId, // Ensure courseId is accessible here
            'chapterNumber': chapter['id'], // Use chapter ID from data
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Chapter Number Circle
              CircleAvatar(
                radius: 16,
                backgroundColor: isCompleted
                    ? completedColor
                    : pendingColor.withOpacity(0.7),
                child: Text(
                  '$chapterNumber',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 16),
              // Chapter Title and Status Icon
              Expanded(
                child: Text(
                  chapter['title'] ?? 'Unnamed Chapter',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600, // Semi-bold
                    color: cardTextColor, // Use defined text color
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Completion Status Icon
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked, // More distinct icons
                color: isCompleted ? completedColor : pendingColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Always Visible Final Exam Button (Conditionally Enabled)
  Widget _buildFinalExamButton(BuildContext context, int courseId,
      bool allCompleted, Color completedColor) {
    return Padding(
      // Padding ensures it doesn't touch screen edges
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        width: double.infinity, // Make button take full width
        child: ElevatedButton.icon(
          icon: Icon(allCompleted ? Icons.quiz : Icons.lock_outline,
              size: 20), // Change icon based on state
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: allCompleted
                ? completedColor
                : Colors.grey.shade400, // Change color based on state
            foregroundColor: Colors.white, // Text/icon color
            textStyle:
                GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)), // Match card shape
            elevation: 3, // Add slight elevation
          ),
          // Disable button by setting onPressed to null if not all completed
          onPressed: allCompleted
              ? () {
                  Navigator.pushNamed(context, '/exam', arguments: courseId);
                }
              : null, // THIS DISABLES THE BUTTON
          label: Text(allCompleted
              ? 'Start Final Exam'
              : 'Complete Chapters to Unlock'), // Change text based on state
        ),
      ),
    );
  }

  // ✅ Enhanced Error State UI
  Widget _buildErrorState(
      BuildContext context, String message, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong.',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.roboto(fontSize: 15, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // Use primary color
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onPressed: () =>
                  context.read<CourseCubit>().fetchCourseById(courseId),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
/* --- End lib\presentation\screens\course\chapter_screen.dart --- */