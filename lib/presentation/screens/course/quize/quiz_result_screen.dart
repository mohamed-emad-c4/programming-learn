import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:learn_programming/data/datasources/api_service.dart';
import 'package:learn_programming/utils/auth_service.dart';
import '../../../cubit/quiz/quiz_result_cubit.dart';

class QuizResultScreen extends StatefulWidget {
  final int quizId;
  final String? token;
  final int numberOfQuestions;
  final Map<String, dynamic>? data;

  const QuizResultScreen({
    super.key,
    required this.quizId,
    this.token,
    required this.numberOfQuestions,
    this.data,
  });

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _token;
  bool _hasError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int _maxRetries = 2;
  bool _isPermissionError = false;
  bool _isNotFoundError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    // First try initializing the auth service if needed
    try {
      await _authService.init();
    } catch (e) {
      log('Error initializing auth service: $e');
    }

    await _resolveToken();
  }

  Future<void> _resolveToken() async {
    try {
      // First try using the token from navigation arguments
      if (widget.token != null && widget.token!.isNotEmpty) {
        log('Using token from quiz submission: ${widget.token!.substring(0, min(10, widget.token!.length))}...');
        _token = widget.token;

        // Save this token to ensure it's available in all storage mechanisms
        await _authService.saveExternalToken(_token!);
      } else {
        // Fall back to auth service
        log('No token from quiz submission, trying auth service');
        _token = await _authService.getToken();
      }

      // Check if we have a valid token
      if (_token == null || _token!.isEmpty) {
        log('No valid token resolved, showing login prompt');
        _setError(
            'Authentication required. Please log in to view quiz results.');
        _showLoginPrompt();
      } else {
        // We have a token, fetch the results
        log('Found valid token, fetching quiz results for quiz ID: ${widget.quizId}');
        _fetchQuizResults();
      }
    } catch (e) {
      log('Error resolving token: $e');
      _setError('Error retrieving authentication: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String message,
      {bool isPermissionError = false, bool isNotFoundError = false}) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
        _isLoading = false;
        _isPermissionError = isPermissionError;
        _isNotFoundError = isNotFoundError;
      });
    }
  }

  Future<void> _fetchQuizResults() async {
    if (_token == null) {
      _setError('No authentication token available');
      return;
    }

    try {
      // Use the BLoC to fetch results
      if (mounted) {
        // Try to fetch quiz attempts using the new endpoint
        context
            .read<QuizResultCubit>()
            .fetchQuizAttempts(widget.quizId, _token);
      }
    } catch (e) {
      log('Error starting quiz result fetch: $e');
      _setError('Failed to retrieve quiz results: $e');
    }
  }

  Future<void> _retryFetch() async {
    if (_retryCount >= _maxRetries) {
      // If we've exceeded max retries, force a token refresh
      log('Maximum retry attempts reached, forcing token refresh');
      _token = null;
      await _resolveToken();
      _retryCount = 0;
    } else {
      _retryCount++;
      log('Retry attempt $_retryCount of $_maxRetries');
      setState(() => _isLoading = true);
      await _fetchQuizResults();
      setState(() => _isLoading = false);
    }
  }

  void _showLoginPrompt() {
    if (!mounted) return;

    // Wrap in future.delayed to avoid showing dialog during build
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Authentication Required'),
          content: const Text(
            'You need to log in to view quiz results. Your quiz has been submitted, but you need to authenticate to see the results.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Go Back'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.quiz, size: 20, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  'Quiz Results',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              'Quiz #${widget.quizId}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _retryFetch,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              _showInfoDialog();
            },
            tooltip: 'About Results',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading quiz results...'),
                  const SizedBox(height: 8),
                  Text(
                    'Retrieving data for Quiz #${widget.quizId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _hasError
              ? _buildErrorView()
              : BlocConsumer<QuizResultCubit, QuizResultState>(
                  listener: (context, state) {
                    if (state is QuizResultError) {
                      final message = state.message.toLowerCase();
                      if (message.contains('auth') ||
                          message.contains('log in') ||
                          message.contains('unauthorized') ||
                          message.contains('401')) {
                        _setError(state.message);
                        _showLoginPrompt();
                      } else if (message.contains('permission') ||
                          message.contains('access denied') ||
                          message.contains('403')) {
                        _setError(state.message, isPermissionError: true);
                      } else if (message.contains('not found') ||
                          message.contains('not taken') ||
                          message.contains('404')) {
                        _setError(state.message, isNotFoundError: true);
                      } else {
                        _setError(state.message);
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is QuizResultLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading quiz results...'),
                          ],
                        ),
                      );
                    } else if (state is QuizResultLoaded) {
                      return _buildResultsView(state.results);
                    } else if (state is SingleQuizResultLoaded) {
                      // Convert the single result to a list format for display
                      return _buildResultsView([state.result]);
                    } else if (state is QuizAttemptsLoaded) {
                      // Use the new attempts view for the attempts endpoint
                      return _buildAttemptsView(state.attempts);
                    } else if (state is QuizResultError) {
                      return _buildErrorView();
                    } else {
                      return const Center(child: Text('No Data Available'));
                    }
                  },
                ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Quiz Results'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Understanding Your Results',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('• Results show all your quiz attempts'),
            Text('• Passing score is 70% or higher'),
            Text('• Green items indicate passed attempts'),
            Text('• Red items indicate failed attempts'),
            SizedBox(height: 16),
            Text(
              'Tips:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('• Refresh to see most recent attempts'),
            Text('• You can retake a quiz multiple times'),
            Text('• Review lessons before retaking failed quizzes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    if (_isPermissionError) {
      return _buildPermissionErrorView();
    } else if (_isNotFoundError) {
      return _buildNotFoundErrorView();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 80),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _retryFetch,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_outlined, color: Colors.blue, size: 80),
          const SizedBox(height: 20),
          const Text(
            'No Quiz Results Found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Why am I seeing this?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• You haven\'t taken this quiz yet'),
                Text('• The quiz submission is still being processed'),
                Text('• You might need to refresh your session'),
                Text('• There could be a delay in the result calculation')
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () {
                  // Navigate to take the quiz
                  Navigator.of(context).pop();
                  _navigateToQuizDetails();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Take Quiz'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToQuizDetails() {
    // Try to get the lesson ID from navigation arguments if available
    final lessonId = ModalRoute.of(context)?.settings.arguments is Map
        ? (ModalRoute.of(context)?.settings.arguments as Map)['lessonId']
        : null;

    if (lessonId != null) {
      Navigator.pushReplacementNamed(
        context,
        '/quiz-details',
        arguments: {'lessonId': lessonId},
      );
    } else {
      // If lesson ID is not available, just go to courses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not determine which quiz to take. Redirecting to courses.'),
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to courses after a brief delay
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/courses');
      });
    }
  }

  Widget _buildPermissionErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_encryption_gmailerrorred,
              color: Colors.orange, size: 80),
          const SizedBox(height: 20),
          const Text(
            'Permission Denied',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This could happen for the following reasons:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• You are not the student who took this quiz'),
                Text('• You need to be logged in with a student account'),
                Text('• Your account does not have the right permissions'),
                Text('• You may need to take the quiz first')
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Change Account'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 80),
            const SizedBox(height: 20),
            const Text(
              'No Quiz Results Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This could be because:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• You haven\'t taken this quiz yet'),
                  Text('• You don\'t have access to view these results'),
                  Text('• The quiz submission is still being processed'),
                  Text('• Your account doesn\'t have sufficient permissions'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _retryFetch,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Navigate to take the quiz
                Navigator.of(context).pop();
                _navigateToQuizDetails();
              },
              icon: const Icon(Icons.quiz),
              label: const Text('Take This Quiz'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Your Quiz Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You have completed this quiz ${results.length} ${results.length == 1 ? 'time' : 'times'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    'Best Score',
                    _calculateBestScore(results),
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                  _buildStat(
                    'Last Score',
                    _calculateLastScore(results),
                    Icons.access_time,
                    Colors.white,
                  ),
                  _buildStat(
                    'Attempts',
                    '${results.length}',
                    Icons.repeat,
                    Colors.greenAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              // Extract fields from the API response format
              final score = int.parse(result['score'].toString());
              final percentage = (score / widget.numberOfQuestions) * 100;
              final isPassed = percentage >= 70;

              // Parse the date
              final submittedAt = DateTime.parse(result['submitted_at']);
              final formattedDate =
                  DateFormat('yyyy-MM-dd HH:mm').format(submittedAt);

              // Check for additional data fields that might be present
              final hasDuration = result.containsKey('duration_seconds');
              final hasCorrectAnswers = result.containsKey('correct_answers');
              final hasWrongAnswers = result.containsKey('wrong_answers');
              final hasAttempts = result.containsKey('attempts');

              return Hero(
                tag: 'result_${result['quiz_id']}_$index',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    left: 15 + (index % 2 == 0 ? 0 : 5),
                    right: 15 + (index % 2 == 0 ? 5 : 0),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: isPassed
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // Show a detailed view when tapped
                        _showResultDetails(
                            result, formattedDate, percentage, isPassed, score);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isPassed
                                              ? [
                                                  Colors.green.shade400,
                                                  Colors.green.shade600
                                                ]
                                              : [
                                                  Colors.red.shade400,
                                                  Colors.red.shade600
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${results.length - index}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Attempt ${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Submitted: $formattedDate',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPassed
                                          ? [
                                              Colors.green.shade400,
                                              Colors.green.shade600
                                            ]
                                          : [
                                              Colors.red.shade400,
                                              Colors.red.shade600
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Score',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$score/${widget.numberOfQuestions}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isPassed
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Result',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isPassed ? 'Passed' : 'Failed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isPassed
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Show any additional data fields if present
                            if (hasDuration ||
                                hasCorrectAnswers ||
                                hasWrongAnswers ||
                                hasAttempts)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Additional Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Display any available additional information in a grid layout
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      if (hasDuration)
                                        _buildDetailItem(
                                          Icons.timer,
                                          'Duration',
                                          _formatDuration(
                                              result['duration_seconds']),
                                          Colors.blue.shade50,
                                        ),
                                      if (hasCorrectAnswers)
                                        _buildDetailItem(
                                          Icons.check_circle,
                                          'Correct',
                                          '${result['correct_answers']}',
                                          Colors.green.shade50,
                                        ),
                                      if (hasWrongAnswers)
                                        _buildDetailItem(
                                          Icons.cancel,
                                          'Wrong',
                                          '${result['wrong_answers']}',
                                          Colors.red.shade50,
                                        ),
                                      if (hasAttempts)
                                        _buildDetailItem(
                                          Icons.replay,
                                          'Attempts',
                                          '${result['attempts']}',
                                          Colors.purple.shade50,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToQuizDetails();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Take Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to show detailed result information
  void _showResultDetails(Map<String, dynamic> result, String formattedDate,
      double percentage, bool isPassed, int score) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPassed
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Result Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isPassed ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPassed ? 'Congratulations!' : 'Almost there!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPassed
                        ? 'You have successfully passed this quiz.'
                        : 'Keep practicing to improve your score.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDetailRow('Quiz ID', '#${result['quiz_id']}'),
                  _buildDetailRow('Submitted', formattedDate),
                  _buildDetailRow(
                      'Score', '$score/${widget.numberOfQuestions}'),
                  _buildDetailRow(
                      'Percentage', '${percentage.toStringAsFixed(1)}%'),
                  _buildDetailRow('Status', isPassed ? 'Passed' : 'Failed'),
                  if (result.containsKey('duration_seconds'))
                    _buildDetailRow('Duration',
                        _formatDuration(result['duration_seconds'])),
                  if (result.containsKey('correct_answers'))
                    _buildDetailRow(
                        'Correct Answers', '${result['correct_answers']}'),
                  if (result.containsKey('wrong_answers'))
                    _buildDetailRow(
                        'Wrong Answers', '${result['wrong_answers']}'),
                  if (result.containsKey('attempts'))
                    _buildDetailRow('Attempts', '${result['attempts']}'),
                  const SizedBox(height: 20),
                  const Text(
                    'Tips for Improvement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._getTipsBasedOnScore(percentage).map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pop();
                          _navigateToQuizDetails();
                        },
                        icon: const Icon(Icons.replay),
                        label: const Text('Retake Quiz'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  // Create a detail row for the result details modal
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Get tips based on score percentage
  List<String> _getTipsBasedOnScore(double percentage) {
    if (percentage >= 90) {
      return [
        'Excellent work! Consider exploring more advanced topics.',
        'Share your knowledge with others who are learning.',
        'Try to understand the concepts even deeper.',
      ];
    } else if (percentage >= 80) {
      return [
        'Great job! Review the questions you missed to solidify your understanding.',
        'Try to explain the concepts to someone else to reinforce your learning.',
        'Consider applying these concepts in a small project.',
      ];
    } else if (percentage >= 70) {
      return [
        'Good work! You\'ve passed but there\'s room for improvement.',
        'Focus on the topics related to the questions you missed.',
        'Try making flashcards for concepts you find challenging.',
      ];
    } else if (percentage >= 50) {
      return [
        'You\'re on the right track. Review the lesson materials again.',
        'Take notes while studying to help with retention.',
        'Try breaking down complex topics into smaller parts.',
        'Consider watching tutorial videos on the topics you struggled with.',
      ];
    } else {
      return [
        'Don\'t give up! Everyone learns at their own pace.',
        'Go back to the lesson and focus on the foundational concepts.',
        'Consider asking for help in the community forums.',
        'Try a different learning approach, like hands-on exercises.',
        'Break your study sessions into smaller, more frequent segments.',
      ];
    }
  }

  // Build a statistic item for the header
  Widget _buildStat(
      String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white24,
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Calculate the best score from results
  String _calculateBestScore(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return '0%';

    double bestPercentage = 0;
    for (final result in results) {
      final score = int.parse(result['score'].toString());
      final percentage = (score / widget.numberOfQuestions) * 100;
      if (percentage > bestPercentage) {
        bestPercentage = percentage;
      }
    }

    return '${bestPercentage.toStringAsFixed(0)}%';
  }

  // Get the most recent score
  String _calculateLastScore(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return '0%';

    // Assuming results are sorted with most recent first
    final score = int.parse(results.first['score'].toString());
    final percentage = (score / widget.numberOfQuestions) * 100;

    return '${percentage.toStringAsFixed(0)}%';
  }

  // Helper widget to display detailed information items with background color
  Widget _buildDetailItem(IconData icon, String label, String value,
      [Color? backgroundColor]) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format duration in seconds to a readable format
  String _formatDuration(dynamic seconds) {
    if (seconds == null) return 'N/A';

    final duration = Duration(seconds: int.parse(seconds.toString()));
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '$minutes min ${remainingSeconds > 0 ? '$remainingSeconds sec' : ''}';
    } else {
      return '$remainingSeconds sec';
    }
  }

  /// Build the quiz attempts view
  Widget _buildAttemptsView(List<Map<String, dynamic>> attempts) {
    if (attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 80),
            const SizedBox(height: 20),
            const Text(
              'No Quiz Attempts Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You haven\'t taken this quiz yet',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToQuizDetails();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Take Quiz'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz: ${attempts.first['quiz_title']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Showing all your attempts for this quiz',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: attempts.length,
            itemBuilder: (context, index) {
              final attempt = attempts[index];

              // Extract fields from the API response format
              final id = attempt['id'];
              final score = int.tryParse(attempt['score'].toString()) ?? 0;
              final totalMarks =
                  int.tryParse(attempt['total_marks'].toString()) ?? 1;
              final percentage = (score / totalMarks) * 100;
              final isPassed = percentage >= 70;

              // Parse the date
              final submittedAt = DateTime.parse(attempt['submitted_at']);
              final formattedDate =
                  DateFormat('yyyy-MM-dd HH:mm').format(submittedAt);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Add details view if needed
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isPassed
                                            ? [
                                                Colors.green.shade400,
                                                Colors.green.shade600
                                              ]
                                            : [
                                                Colors.red.shade400,
                                                Colors.red.shade600
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${attempts.length - index}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attempt ${attempts.length - index}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isPassed
                                        ? [
                                            Colors.green.shade400,
                                            Colors.green.shade600
                                          ]
                                        : [
                                            Colors.red.shade400,
                                            Colors.red.shade600
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPassed
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width:
                                      (MediaQuery.of(context).size.width - 62) *
                                          (score / totalMarks),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPassed
                                          ? [
                                              Colors.green.shade400,
                                              Colors.green.shade600
                                            ]
                                          : [
                                              Colors.red.shade400,
                                              Colors.red.shade600
                                            ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildQuizStat(
                                'Score',
                                '$score/$totalMarks',
                                Icons.trending_up,
                                isPassed ? Colors.green : Colors.red,
                              ),
                              _buildQuizStat(
                                'Result',
                                isPassed ? 'Passed' : 'Failed',
                                isPassed ? Icons.check_circle : Icons.cancel,
                                isPassed ? Colors.green : Colors.red,
                              ),
                              if (attempt.containsKey('duration_seconds'))
                                _buildQuizStat(
                                  'Time',
                                  _formatDuration(attempt['duration_seconds']),
                                  Icons.timer,
                                  Colors.blue,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper widget for quiz stats display
  Widget _buildQuizStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Helper function to avoid the 'min' import issue
int min(int a, int b) => a < b ? a : b;
