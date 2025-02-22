import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learn_programming/data/datasources/values.dart';

class GeminiScreen extends StatefulWidget {
  const GeminiScreen({super.key});

  @override
  _GeminiScreenState createState() => _GeminiScreenState();
}

class _GeminiScreenState extends State<GeminiScreen> {
  final String _response = ''; // To store the response from Gemini
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = image;
    });
  }

  Future<void> sendToGemini() async {
    if (_imageFile == null) return;

    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );

    final prompt = 'ocr this image';
    final Uint8List imageBytes = await _imageFile!.readAsBytes();
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpg', imageBytes),
      ])
    ];

    final response = await model.generateContent(content);
    print(response.text);

    log(response.text.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage, // Call the function to pick an image
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendToGemini, // Call the function to send to Gemini
              child: const Text('Send to Gemini'),
            ),
            const SizedBox(height: 20),
            Text(_response), // Display the response from Gemini
          ],
        ),
      ),
    );
  }
}
