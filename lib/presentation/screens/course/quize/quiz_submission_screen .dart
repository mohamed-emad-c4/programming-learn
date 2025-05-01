import 'dart:developer' as dev;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../../../data/datasources/api_service.dart';
import '../../../../domain/repositories/auth_repository_impl.dart';
import '../../../../utils/auth_service.dart';
import '../../../cubit/quiz/quiz_submission_cubit.dart';

class QuizSubmissionScreen extends StatefulWidget {
  final int quizId;
  final List<Map<String, dynamic>> questions;
  final int? timeLimit; // Time limit in minutes, null for unlimited

  const QuizSubmissionScreen({
    super.key,
    required this.quizId,
    required this.questions,
    this.timeLimit,
  });

  @override
  _QuizSubmissionScreenState createState() => _QuizSubmissionScreenState();
}

class _QuizSubmissionScreenState extends State<QuizSubmissionScreen>
    with TickerProviderStateMixin {
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _bookmarkedQuestions = {};
  late QuizSubmissionCubit quizSubmissionCubit;
  late AnimationController _fadeController;
  Timer? _timer;
  int _remainingSeconds = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showConfirmDialog = false;
  late final List<GlobalKey> _questionKeys;
  bool _isTimeAlmostUp = false;

  @override
  void initState() {
    super.initState();
    quizSubmissionCubit = QuizSubmissionCubit();
    _questionKeys = List.generate(
      widget.questions.length,
      (index) => GlobalKey(),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Check authentication status
    _checkAuthStatus();

    if (widget.timeLimit != null) {
      _remainingSeconds = widget.timeLimit! * 60;
      _startTimer();
    }
  }

  /// Check if user is authenticated
  Future<void> _checkAuthStatus() async {
    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();

    if (!isAuthenticated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'You need to log in to submit quizzes',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Log In',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ),
      );
    }
  }

  /// Load token from SharedPreferences if not already in GetIt
  Future<void> _preloadToken() async {
    const tokenKey = 'auth_token'; // Must match the key in the cubit

    // Check if token is already in GetIt
    if (GetIt.I.isRegistered<String>(instanceName: 'token')) {
      dev.log('Token already registered in GetIt');
      return;
    }

    try {
      // Try to load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      if (token != null && token.isNotEmpty) {
        dev.log('Found token in SharedPreferences, registering in GetIt');
        GetIt.I.registerSingleton<String>(token, instanceName: 'token');
      } else {
        // Try to load from AuthRepository as fallback
        final authRepo = AuthRepositoryImpl();
        final repoToken = await authRepo.getToken();

        if (repoToken != null) {
          dev.log('Found token in AuthRepository, registering in GetIt');
          GetIt.I.registerSingleton<String>(repoToken, instanceName: 'token');

          // Save to SharedPreferences for future use
          await prefs.setString(tokenKey, repoToken);
        } else {
          dev.log('No token found in any storage');
        }
      }
    } catch (e) {
      dev.log('Error preloading token: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds <= 300 && !_isTimeAlmostUp) {
            // 5 minutes warning
            _isTimeAlmostUp = true;
            _showTimeWarning();
          }
        } else {
          _timer?.cancel();
          submitAnswers(autoSubmit: true);
        }
      });
    });
  }

  void _showTimeWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.timer, color: Colors.white),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '5 minutes remaining!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showSubmitConfirmation() {
    final unansweredCount = widget.questions.length - _selectedAnswers.length;
    setState(() => _showConfirmDialog = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSubmitConfirmation(unansweredCount),
    ).then((value) => setState(() => _showConfirmDialog = false));
  }

  void submitAnswers({bool autoSubmit = false}) {
    if (autoSubmit) {
      dev.log('autoSubmit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.timer_off, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Time\'s up! Quiz submitted automatically.',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }

    // Convert to the expected format with specific question_id and selected_option fields
    final answers = _selectedAnswers.entries
        .map((entry) => {
              "question_id": entry.key,
              "selected_option": entry.value,
            })
        .toList();

    dev.log('Submitting answers: $answers');

    try {
      // Ensure auth service is initialized and token is preloaded before submission
      _preloadToken().then((_) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting quiz...'),
              ],
            ),
          ),
        );

        // Submit quiz
        quizSubmissionCubit.submitQuiz(widget.quizId, answers);
      });
    } catch (e) {
      dev.log('Error during quiz submission: $e');
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar(
        'An error occurred. Please try again.',
        isAuthError: e.toString().toLowerCase().contains('auth') ||
            e.toString().toLowerCase().contains('token'),
      );
    }
  }

  void _showErrorSnackBar(String message, {bool isAuthError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isAuthError ? Icons.lock : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.fixed,
        action: isAuthError
            ? SnackBarAction(
                label: 'Log In',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              )
            : null,
      ),
    );
  }

  /// Build error widget for authentication issues
  Widget _buildAuthErrorWidget({
    required String message,
    required VoidCallback onLogin,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.security,
            size: 48,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication Error',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onRetry != null) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Log In'),
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(
        begin: 0.2, end: 0, duration: const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Quiz?'),
            content: const Text('Your progress will be lost if you leave now.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: BlocProvider(
          create: (context) => quizSubmissionCubit,
          child: BlocListener<QuizSubmissionCubit, QuizSubmissionState>(
            listener: (context, state) {
              // Close loading dialog
              if (Navigator.of(context).canPop() &&
                  ModalRoute.of(context)?.settings.name != '/login') {
                Navigator.of(context).pop();
              }

              if (state is QuizSubmissionSuccess) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            state.message,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.fixed,
                  ),
                );

                // Return to quiz list with results
                Navigator.of(context).pushReplacementNamed(
                  '/quiz_result',
                  arguments: {
                    'quizId': widget.quizId,
                    'data': state.data,
                    'token': quizSubmissionCubit.token,
                    'numberOfQuestions': widget.questions.length,
                  },
                );
              } else if (state is QuizSubmissionError) {
                // Show error dialog instead of just a snackbar
                if (state.isAuthError) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      content: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildAuthErrorWidget(
                          message: state.message,
                          onLogin: () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          onRetry: () {
                            Navigator.of(context).pop();
                            submitAnswers();
                          },
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                  );
                } else {
                  _showErrorSnackBar(state.message);
                }
              }
            },
            child: Column(
              children: [
                _buildAppBar(context),
                if (widget.timeLimit != null) _buildTimer(context),
                _buildProgressIndicator(context),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemCount: widget.questions.length,
                    itemBuilder: (context, index) =>
                        _buildQuestionPage(context, index),
                  ),
                ),
                _buildBottomNavigation(context),
              ],
            ),
          ),
        ),
        floatingActionButton: !_showConfirmDialog
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentPage < widget.questions.length)
                    FloatingActionButton.small(
                      heroTag: 'bookmark_fab_quiz_submission',
                      onPressed: () {
                        setState(() {
                          final questionId =
                              widget.questions[_currentPage]['id'];
                          if (_bookmarkedQuestions.contains(questionId)) {
                            _bookmarkedQuestions.remove(questionId);
                          } else {
                            _bookmarkedQuestions.add(questionId);
                          }
                        });
                      },
                      child: Icon(
                        _bookmarkedQuestions
                                .contains(widget.questions[_currentPage]['id'])
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                      ),
                    ).animate().scale(delay: 200.ms),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'submit_fab_quiz_submission',
                    onPressed: _showSubmitConfirmation,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Submit Quiz'),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz in Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedAnswers.length} of ${widget.questions.length} questions answered',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showQuestionsList(context),
            icon: const Icon(Icons.list_rounded),
            tooltip: 'Questions List',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _selectedAnswers.length / widget.questions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  'Question ${_currentPage + 1} of ${widget.questions.length}',
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(BuildContext context, int index) {
    final theme = Theme.of(context);
    final question = widget.questions[index];

    return SingleChildScrollView(
      key: _questionKeys[index],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                question['question_text'],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            question['options'].length,
            (optionIndex) => _buildOptionItem(
              context,
              question,
              optionIndex,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildOptionItem(
    BuildContext context,
    Map<String, dynamic> question,
    int optionIndex,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedAnswers[question['id']] == optionIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () =>
            setState(() => _selectedAnswers[question['id']] = optionIndex),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question['options'][optionIndex],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(target: isSelected ? 1 : 0)
        .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02))
        .tint(color: theme.colorScheme.primary.withOpacity(0.1));
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            FilledButton.tonalIcon(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            )
          else
            const SizedBox.shrink(),
          if (_currentPage < widget.questions.length - 1)
            FilledButton.icon(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
        ],
      ),
    );
  }

  Widget _buildTimer(BuildContext context) {
    final theme = Theme.of(context);
    final isLowTime = _remainingSeconds <= 300; // 5 minutes or less

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isLowTime ? theme.colorScheme.error.withOpacity(0.1) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            color:
                isLowTime ? theme.colorScheme.error : theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Time Remaining: ${_formatTime(_remainingSeconds)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isLowTime
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate(target: isLowTime ? 1 : 0).shimmer(
          duration: const Duration(milliseconds: 1000),
          color: theme.colorScheme.error.withOpacity(0.5),
        );
  }

  Widget _buildSubmitConfirmation(int unansweredCount) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            unansweredCount > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            size: 48,
            color: unansweredCount > 0
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            unansweredCount > 0
                ? 'You have unanswered questions'
                : 'Ready to submit?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unansweredCount > 0
                ? 'You have $unansweredCount unanswered ${unansweredCount == 1 ? 'question' : 'questions'}. Do you want to submit anyway?'
                : 'You have answered all questions. Are you sure you want to submit your answers?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Review'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    submitAnswers();
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms);
  }

  void _showQuestionsList(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Questions Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    final bookmarkedIndex = widget.questions.indexWhere(
                      (q) => _bookmarkedQuestions.contains(q['id']),
                    );
                    if (bookmarkedIndex != -1) {
                      Navigator.pop(context);
                      _pageController.animateToPage(
                        bookmarkedIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  icon: const Icon(Icons.bookmark, size: 18),
                  label: const Text(
                    'Bookmarked',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    widget.questions.length,
                    (index) => Stack(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _selectedAnswers.containsKey(
                                      widget.questions[index]['id'])
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedAnswers.containsKey(
                                        widget.questions[index]['id'])
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline
                                        .withOpacity(0.2),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: _selectedAnswers.containsKey(
                                          widget.questions[index]['id'])
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_bookmarkedQuestions
                            .contains(widget.questions[index]['id']))
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bookmark,
                                size: 12,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 400.ms),
    );
  }
}
