import 'dart:developer';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../data/datasources/values.dart';

part 'image_state.dart';

class ImageCubit extends Cubit<ImageState> {
  final ImagePicker _picker = ImagePicker();

  ImageCubit() : super(ImageInitial());

  Future<void> pickImage(ImageSource source) async {
    try {
      emit(ImageUploading());
      final XFile? image = await _picker.pickImage(source: source);

      if (image != null) {
        emit(ImagePicked(image));
        await sendToGemini(image);
      } else {
        emit(ImageError('No image selected'));
      }
    } catch (e) {
      emit(ImageError('Error picking image: $e'));
    }
  }

  Future<void> sendToGemini(XFile imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );

      final prompt = 'Extract text from this image';
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final extractedText = response.text ?? 'No response from AI';

      log(extractedText);
      emit(ImageUploaded(extractedText));
    } catch (e) {
      emit(ImageError('Error processing image: $e'));
    }
  }

  Future<dynamic> checkCodeWithGemini(String code) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );

      final prompt = """
        Analyze the following code and check if it contains any errors.
        - If the code is correct, respond with: `true`
        - If there are errors, provide a detailed explanation using Markdown format dont send all code.

        ```
        $code
        ```
      """;

      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text?.trim() ?? '';

      if (result.toLowerCase() == 'true') {
        return true;
      } else {
        return result; // Return Markdown-formatted error message
      }
    } catch (e) {
      return 'Error checking code: $e';
    }
  }
}
