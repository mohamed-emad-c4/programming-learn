// lib/presentation/screens/problem/problem/problem_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class ProblemDetailScreen extends StatefulWidget {
  const ProblemDetailScreen({Key? key}) : super(key: key);

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen>
    with SingleTickerProviderStateMixin {
  late int id;
  late String title;
  late String description;
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _newLanguageController = TextEditingController();
  bool isSubmitting = false;
  bool isValidSolution = true;

  String? selectedLanguage;
  List<String> programmingLanguages = [
    'C++',
    'Java',
    'Python',
    'JavaScript',
    'Dart',
    'Add New Language'
  ];

  // File and Image Variables
  File? _selectedImage;
  File? _selectedFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    id = args['id'];
    title = args['title'];
    description = args['description'];
  }

  @override
  void dispose() {
    _solutionController.dispose();
    _newLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Problem Detail',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Solution TextField
              TextField(
                controller: _solutionController,
                maxLines: null,
                onChanged: (value) {
                  setState(() {
                    isValidSolution = value.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Your Solution',
                  hintText: 'Write your solution here...',
                  errorText:
                      isValidSolution ? null : 'Solution cannot be empty',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () {
                          if (_solutionController.text.trim().isEmpty) {
                            setState(() {
                              isValidSolution = false;
                            });
                          } else {
                            setState(() {
                              isSubmitting = true;
                            });

                            // Simulating submission delay
                            Future.delayed(const Duration(seconds: 2), () {
                              setState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Solution Submitted!'),
                                ),
                              );
                            });
                          }
                        },
                  child: isSubmitting
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Attempt Button for Camera and File
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showAttemptOptions();
                  },
                  child: const Text(
                    'Attempt',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show Bottom Sheet for Camera and File Picker
  void _showAttemptOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Open Camera'),
              onTap: () async {
                Navigator.pop(context);
              
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Select File'),
              onTap: () async {
                Navigator.pop(context);
              
              },
            ),
          ],
        ),
      ),
    );
  }
}
