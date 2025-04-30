// import 'dart:async';
// import 'package:flutter/material.dart';

// class QuizSubmissionScreen extends StatefulWidget {
//   final int quizId;
//   final List<Map<String, dynamic>> questions;
//   final int? timeLimit; // Time limit in minutes, null for unlimited

//   const QuizSubmissionScreen({
//     Key? key,
//     required this.quizId,
//     required this.questions,
//     this.timeLimit,
//   }) : super(key: key);

//   @override
//   State<QuizSubmissionScreen> createState() => _QuizSubmissionScreenState();
// }

// class _QuizSubmissionScreenState extends State<QuizSubmissionScreen> {
//   bool _questionLoading = true;
//   bool _isSubmitting = false;
//   Timer? _timer;
//   int _remainingSeconds = 0;
//   final Map<int, int> _selectedAnswers = {};
//   final Set<int> _bookmarkedQuestions = {};
//   int _currentPage = 0;
//   final PageController _pageController = PageController();

//   @override
//   void initState() {
//     super.initState();
//     // Initialize timer if timeLimit is provided
//     if (widget.timeLimit != null) {
//       _remainingSeconds = widget.timeLimit! * 60;
//       _startTimer();
//     }

//     // Simulate loading questions
//     Future.delayed(const Duration(seconds: 1), () {
//       setState(() {
//         _questionLoading = false;
//       });
//     });
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_remainingSeconds > 0) {
//           _remainingSeconds--;
//         } else {
//           _timer?.cancel();
//           // Auto-submit when time is up
//           _submitQuiz(true);
//         }
//       });
//     });
//   }

//   void _submitQuiz(bool autoSubmit) {
//     setState(() {
//       _isSubmitting = true;
//     });

//     // Simulate API call
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         Navigator.of(context).pop();
//         // Show result or navigate to results page
//       }
//     });
//   }

//   String _formatTime(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Quiz'),
//         actions: [
//           if (widget.timeLimit != null)
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: Text(
//                   _formatTime(_remainingSeconds),
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: _questionLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Quiz progress
//                 LinearProgressIndicator(
//                   value: _currentPage / (widget.questions.length - 1),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Text(
//                     'Question ${_currentPage + 1} of ${widget.questions.length}',
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                 ),
//                 // Question content
//                 Expanded(
//                   child: PageView.builder(
//                     controller: _pageController,
//                     onPageChanged: (page) {
//                       setState(() {
//                         _currentPage = page;
//                       });
//                     },
//                     itemCount: widget.questions.length,
//                     itemBuilder: (context, index) {
//                       // Replace with actual question UI
//                       return Center(
//                         child: Text(
//                           'Question ${index + 1} Content Here',
//                           style: Theme.of(context).textTheme.headlineSmall,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 // Navigation controls
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       if (_currentPage > 0)
//                         ElevatedButton(
//                           onPressed: () {
//                             _pageController.previousPage(
//                               duration: const Duration(milliseconds: 300),
//                               curve: Curves.easeInOut,
//                             );
//                           },
//                           child: const Text('Previous'),
//                         )
//                       else
//                         const SizedBox(),
//                       if (_currentPage < widget.questions.length - 1)
//                         ElevatedButton(
//                           onPressed: () {
//                             _pageController.nextPage(
//                               duration: const Duration(milliseconds: 300),
//                               curve: Curves.easeInOut,
//                             );
//                           },
//                           child: const Text('Next'),
//                         )
//                       else
//                         const SizedBox(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//       floatingActionButton: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           FloatingActionButton.small(
//             heroTag: 'bookmark_fab_quiz_submission',
//             onPressed: () {
//               setState(() {
//                 final questionId = widget.questions[_currentPage]['id'];
//                 if (_bookmarkedQuestions.contains(questionId)) {
//                   _bookmarkedQuestions.remove(questionId);
//                 } else {
//                   _bookmarkedQuestions.add(questionId);
//                 }
//               });
//             },
//             child: Icon(
//               _bookmarkedQuestions
//                       .contains(widget.questions[_currentPage]['id'])
//                   ? Icons.bookmark
//                   : Icons.bookmark_border,
//             ),
//           ),
//           const SizedBox(height: 8),
//           FloatingActionButton.extended(
//             heroTag: 'submit_fab_quiz_submission',
//             onPressed: () => _submitQuiz(false),
//             icon: const Icon(Icons.check_circle_outline),
//             label: const Text('Submit Quiz'),
//           ),
//         ],
//       ),
//     );
//   }
// }
