import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

import '../../data/datasources/api_service.dart';

class QuizResultScreen extends StatefulWidget {
  final int quizId;
  final String token;

  const QuizResultScreen({Key? key, required this.quizId, required this.token}) : super(key: key);

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late Future<List<Map<String, dynamic>>> _quizResult;
ApiService apiService = ApiService();

  Future<List<Map<String, dynamic>>> fetchQuizResult(int quizId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/quizzes/$quizId/results'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _quizResult.then((value) => value.reversed.toList()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No result available.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              } else {
                final results = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * 0.05,
                            vertical: constraints.maxHeight * 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'Quiz Result',
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              ),
                              const Divider(height: 20, thickness: 1.5),
                              _buildResultRow(
                                'Quiz number:',
                                result['quiz_id'].toString(),
                                constraints,
                              ),
                              
                              _buildResultRow(
                                'Score:',
                                result['score'].toString(),
                                constraints,
                                isScore: true,
                              ),
                              _buildResultRow(
                                'Submitted At:',
                                formatDateTime(result['submitted_at']),
                                constraints,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildResultRow(String title, String value, BoxConstraints constraints,
      {bool isScore = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontSize: constraints.maxWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: constraints.maxWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: isScore ? Colors.green : Colors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
