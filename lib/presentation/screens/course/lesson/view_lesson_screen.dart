import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_programming/data/datasources/api_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../cubit/lesson/view_lesson_cubit.dart';

class ViewLessonScreen extends StatelessWidget {
  final int lessonId;

  const ViewLessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ViewLessonCubit(ApiService())..fetchLesson(lessonId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lesson Details'),
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 0,
        ),
        body: BlocBuilder<ViewLessonCubit, ViewLessonState>(
          builder: (context, state) {
            if (state is ViewLessonLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ViewLessonError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                ),
              );
            } else if (state is ViewLessonLoaded) {
              final lesson = state.lesson;
              final content = lesson['content'] as Map<String, dynamic>?;
              final previousLessonId = lesson['order_number'] > 1
                  ? lesson['order_number'] - 1
                  : null;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson['title'],
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (lesson['video_url'] != null)
                                  YoutubePlayer(
                                    controller: YoutubePlayerController(
                                      initialVideoId:
                                          YoutubePlayer.convertUrlToId(
                                              lesson['video_url'])!,
                                      flags: const YoutubePlayerFlags(
                                        autoPlay: false,
                                        mute: false,
                                      ),
                                    ),
                                    showVideoProgressIndicator: true,
                                  ),
                                const SizedBox(height: 10),
                                if (content != null)
                                  ...content.entries.map((entry) {
                                    return AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 700),
                                      opacity: 1.0,
                                      child: entry.key.contains('subtitle')
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Text(
                                                entry.value,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Text(
                                                entry.value,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  height: 1.5,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (previousLessonId != null)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/view-lesson',
                                    arguments: {'lessonId': previousLessonId},
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Previous Lesson'),
                              ),
                            ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/quiz-details',
                                  arguments: {'lessonId': lessonId},
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.quiz),
                              label: const Text('Go to Quiz'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: Text('No lesson data available.'));
            }
          },
        ),
      ),
    );
  }
}
