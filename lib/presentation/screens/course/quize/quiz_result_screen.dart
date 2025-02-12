import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../data/datasources/values.dart';
import '../lesson/lesson_screen.dart';
import '../../../../data/datasources/api_service.dart';

class QuizResultScreen extends StatefulWidget {
  final int quizId;
  final String token;
  final int numberOfQuestions;
  const QuizResultScreen({
    super.key,
    required this.quizId,
    required this.token,
    required this.numberOfQuestions,
  });

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late Future<List<Map<String, dynamic>>> _quizResult;
  ApiService apiService = ApiService();
  bool _isFilterVisible = false;
  final String _filterOption = 'All';
  bool _isDarkMode = false;
  String _selectedSortOption = 'Date';

  Future<List<Map<String, dynamic>>> fetchQuizResult(int quizId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/quizzes/$quizId/results'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> resultList = jsonDecode(response.body);
      return resultList.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load quiz result');
    }
  }

  @override
  void initState() {
    super.initState();
    _quizResult = fetchQuizResult(widget.quizId);
  }

  String formatDateTime(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    return DateFormat('yyyy MMM d HH:mm:ss').format(parsedDate);
  }

  List<Map<String, dynamic>> _sortResults(List<Map<String, dynamic>> results) {
    if (_selectedSortOption == 'Score') {
      results.sort((a, b) => int.parse(b['score'].toString())
          .compareTo(int.parse(a['score'].toString())));
    } else if (_selectedSortOption == 'Date') {
      results.sort((a, b) => DateTime.parse(b['submitted_at'])
          .compareTo(DateTime.parse(a['submitted_at'])));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz Results',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(_isFilterVisible ? Icons.close : Icons.filter_list),
            onPressed: () {
              setState(() {
                _isFilterVisible = !_isFilterVisible;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedSortOption = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'Date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'Score',
                child: Text('Sort by Score'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
      
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future:
            _quizResult.then((value) => _sortResults(value.reversed.toList())),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: _isDarkMode ? Colors.white : Colors.teal,
                strokeWidth: 4,
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorContent(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyContent();
          } else {
            final results = _filterResults(snapshot.data!);
            return Column(
              children: [
                Expanded(child: _buildResultsList(results)),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  List<Map<String, dynamic>> _filterResults(
      List<Map<String, dynamic>> results) {
    return results.where((result) {
      final score = int.parse(result['score'].toString());
      return _filterOption == 'All' ||
          (_filterOption == 'High' && score >= 80) ||
          (_filterOption == 'Low' && score < 80);
    }).toList();
  }

  Widget _buildResultsList(List<Map<String, dynamic>> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : Colors.teal.shade100,
            width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quiz Result ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.teal,
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: int.parse(result['score'].toString()) >= 80
                      ? Colors.green
                      : Colors.orange,
                  size: 24,
                ),
              ],
            ),
            const Divider(color: Colors.teal, thickness: 1, height: 20),
            _buildResultRow('Score:', result['score'].toString(),
                isScore: true),
            _buildResultRow(
                'Submitted At:', formatDateTime(result['submitted_at'])),
            _buildFeedbackSection(result['score'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'An error occurred: $error',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: _isDarkMode ? Colors.white : Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _quizResult = fetchQuizResult(widget.quizId);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.teal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No results available.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String title, String value, {bool isScore = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isScore
                    ? Colors.green
                    : (_isDarkMode ? Colors.white : Colors.teal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(String score) {
    final double scoreValue = double.parse(score);
    final String message = 0.5 >= (scoreValue / widget.numberOfQuestions)
        ? 'Great job! You scored ${(scoreValue / widget.numberOfQuestions) * 100}%. Keep up the good work!'
        : 'You scored ${(scoreValue / widget.numberOfQuestions) * 100}%. Don’t worry, practice makes perfect!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Feedback:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.teal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
              fontSize: 14, color: _isDarkMode ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Your Thoughts'),
                content: TextField(
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                      hintText: 'Enter your feedback here...'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Feedback submitted: ')),
                      );
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.teal,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('comment', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.teal,
        boxShadow: [
          BoxShadow(
            color:
                _isDarkMode ? Colors.grey[700]! : Colors.teal.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
              context, '/lessons', ModalRoute.withName('/chapter'),
              arguments: {
              'languageId': current_course_Id,
               'chapterNumber': current_chapter_Id}); // Replace with your desired route,
              
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Return to Lessons',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreData {
  final String label;
  final int score;

  ScoreData(this.label, this.score);
}
