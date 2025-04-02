import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learn_programming/presentation/cubit/problem/problem/image_cubit.dart';
import 'package:learn_programming/presentation/screens/problem/peoblem/result/error_screen.dart';
import 'package:learn_programming/presentation/screens/problem/peoblem/result/success_screen.dart';

class ProblemDetailScreen extends StatefulWidget {
  const ProblemDetailScreen({super.key});

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  late int id;
  late String title;
  late String description;
  final TextEditingController _solutionController = TextEditingController();

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
    super.dispose();
  }

  void _submitSolution() async {
    final solution = _solutionController.text.trim();

    if (solution.isNotEmpty) {
      final cubit = ImageCubit();
      final result = await cubit.checkCodeWithGemini(solution);
      log(result.toString());
      if (result == true) {
        // Navigate to success screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  SuccessScreen( message: result.toString(),),
          ),
        );
      } else {
        // Navigate to error screen with error message
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ErrorScreen(
              errorMessage: 'Error: $result',
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ Solution field cannot be empty. Please enter your solution.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ImageCubit(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Problem Detail',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.blue.shade800,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 16),
              _buildDescriptionCard(),
              const SizedBox(height: 32),
              BlocConsumer<ImageCubit, ImageState>(
                listener: (context, state) {
                  if (state is ImageUploaded) {
                    _solutionController.text = state.response;
                  }
                },
                builder: (context, state) {
                  return Column(
                    children: [
                      _buildSolutionTextField(),
                      const SizedBox(height: 20),
                      if (state is ImagePicked) _buildPickedImage(state),
                      if (state is ImageUploading) _buildUploadingIndicator(),
                      const SizedBox(height: 20),
                      _buildImagePickerButtons(),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Text(description,
          style: const TextStyle(
              fontSize: 18, color: Colors.black87, height: 1.5)),
    );
  }

  Widget _buildSolutionTextField() {
    return TextField(
      controller: _solutionController,
      maxLines: null,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Your Solution',
        labelStyle: const TextStyle(color: Colors.black),
        hintText: 'Write your solution or use AI...',
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPickedImage(ImagePicked state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            Image.file(File(state.image.path), height: 150, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: CircularProgressIndicator(color: Colors.blue),
    );
  }

  Widget _buildImagePickerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(
          icon: Icons.image,
          label: 'Gallery',
          onTap: () =>
              context.read<ImageCubit>().pickImage(ImageSource.gallery),
        ),
        _buildButton(
          icon: Icons.camera,
          label: 'Camera',
          onTap: () => context.read<ImageCubit>().pickImage(ImageSource.camera),
        ),
      ],
    );
  }

  Widget _buildButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.blue),
      label: Text(label, style: const TextStyle(color: Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.blue, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitSolution,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Submit Solution',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
