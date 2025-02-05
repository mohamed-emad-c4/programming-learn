import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learn_programming/presentation/screens/quiz_details_screen.dart';
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ViewLessonScreen extends StatefulWidget {
  final int lessonId;

  const ViewLessonScreen({Key? key, required this.lessonId}) : super(key: key);

  @override
  _ViewLessonScreenState createState() => _ViewLessonScreenState();
}

class _ViewLessonScreenState extends State<ViewLessonScreen> {
  late Future<Map<String, dynamic>> _lesson;

  Future<Map<String, dynamic>> fetchLesson(int lessonId) async {
    final response = await http.get(
      Uri.parse('http://192.168.1.2:8000/api/lessons/details/$lessonId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load lesson');
    }
  }

  void navigateToQuiz() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizDetailsScreen(lessonId: widget.lessonId),
        ));
  }

  void navigateToPreviousLesson(int previousLessonId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ViewLessonScreen(lessonId: previousLessonId),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _lesson = fetchLesson(widget.lessonId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Details'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _lesson,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No lesson data available.'));
          } else {
            final lesson = snapshot.data!;
            final content = lesson['content'] as Map<String, dynamic>?;
            final previousLessonId =
                lesson['order_number'] > 1 ? lesson['order_number'] - 1 : null;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 5,
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (lesson['video_url'] != null)
                              YoutubePlayer(
                                controller: YoutubePlayerController(
                                  initialVideoId: YoutubePlayer.convertUrlToId(
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
                                return entry.key.contains('subtitle')
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.5,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (previousLessonId != null)
                          ElevatedButton(
                            onPressed: () =>
                                navigateToPreviousLesson(previousLessonId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text('Previous Lesson'),
                          ),
                        ElevatedButton(
                          onPressed: navigateToQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Go to Quiz'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
