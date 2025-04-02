import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_programming/data/datasources/api_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:markdown/markdown.dart' as md; // ✅ Import markdown package
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'; // ✅ Use flutter_widget_from_html

import '../../../cubit/lesson/view_lesson_cubit.dart';

class ViewLessonScreen extends StatefulWidget {
  final int lessonId;
  const ViewLessonScreen({super.key, required this.lessonId});

  @override
  State<ViewLessonScreen> createState() => _ViewLessonScreenState();
}

class _ViewLessonScreenState extends State<ViewLessonScreen> {
  late TextEditingController _editingController;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController();
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ViewLessonCubit(ApiService())..fetchLesson(widget.lessonId),
      child: Scaffold(
        appBar: _buildAppBar(),
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

              return _buildLessonContent(context, lesson, content);
            } else {
              return const Center(child: Text('No lesson data available.'));
            }
          },
        ),
        floatingActionButton: _buildQuizButton(context),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Lesson Details',
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
      ),
      centerTitle: true,
      backgroundColor: Colors.blueAccent,
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.blueAccent,
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Text(
        'Error: $message',
        style: const TextStyle(color: Colors.red, fontSize: 18),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context, Map<String, dynamic> lesson,
      Map<String, dynamic>? content) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLessonCard(lesson, context),
            const SizedBox(height: 20),
            _buildMarkdownContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 6,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              if (lesson['video_url'] != null)
                _buildVideoPlayer(lesson['video_url']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: YoutubePlayer.convertUrlToId(videoUrl)!,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        ),
        showVideoProgressIndicator: true,
        progressColors: ProgressBarColors(
          playedColor: Colors.blueAccent,
          handleColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
      
            ),
            child: HtmlWidget(
              // Parse the markdown content into HTML
              md.markdownToHtml(
                  _editingController.text), // ✅ Convert Markdown to HTML
              textStyle: Theme.of(context).textTheme.bodyMedium,
              customStylesBuilder: (element) {
                if (element.localName == 'code') {
                  return {
                    'background': '#333333', // خلفية سوداء بس مش قوي
                    'color': '#FFA500', // لون النص برتقالي
                    'padding': '2px',
                    'borderRadius': '1px',
                    'fontFamily': 'monospace',
                    'fontSize': '12px',
                    'border': '1px solid #44475a', // حدود خفيفة
                  };
                }
                return {};
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuizButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/quiz-details',
          arguments: {'lessonId': widget.lessonId},
        );
      },
      backgroundColor: Colors.green,
      icon: const Icon(Icons.quiz, color: Colors.white),
      label: const Text('Go to Quiz', style: TextStyle(color: Colors.white)),
    );
  }
}
