import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:math' as math; // For gradient rotation

class SuccessScreen extends StatefulWidget {
  final String message; // Add a message field

  const SuccessScreen(
      {super.key,
      required this.message}); // Accept the message in the constructor

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    log('Success screen initialized with message: ${widget.message}');

    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Bouncy effect for futuristic feel

    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut), // Fade in early
      ),
      
    );

    // Start the animation automatically when the screen loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define our futuristic blue theme colors
    const Color primaryBlue = Color.fromARGB(255, 50, 161, 13); // Deep blue
    const Color accentBlue =
        Color.fromARGB(255, 0, 154, 54); // Brighter accent blue
    const Color lightBlue = Color(0xFFBBDEFB); // Light background tint
    const Color darkBlueText =
        Color(0xFF0A3A80); // Slightly darker than primary for text contrast
    const Color gradientStart = Color.fromARGB(255, 0, 111, 46);
    const Color gradientEnd =
        Color(0xFF1976D2); // Slightly lighter shade for gradient

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allow body gradient to go behind app bar
      appBar: AppBar(
        title: FadeTransition(
          opacity: _opacityAnimation,
          child: const Text(
            'Success',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 1.2, // Add some spacing for modern look
            ),
          ),
        ),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // No shadow for a cleaner look
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        // Apply a gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.1, 0.9], // Control gradient distribution
            transform:
                GradientRotation(math.pi / 4), // Rotate gradient slightly
          ),
        ),
        child: SafeArea(
          // Ensure content is not obscured by notches/system UI
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated success icon container
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                            .withOpacity(0.9), // Semi-transparent white
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons
                            .check_rounded, // Use a rounded check for modern feel
                        size: screenWidth * 0.25, // Responsive size
                        color: accentBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05), // Responsive spacing

                  // Success message with fade-in
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Text(
                      widget.message??'back and try again', // Display the custom message
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.06, // Responsive font size
                        fontWeight: FontWeight.w600, // Slightly lighter bold
                        color: Colors.white, // White text on gradient
                        letterSpacing: 0.5,
                        shadows: [
                          // Subtle text shadow for depth
                          Shadow(
                            blurRadius: 10.0,
                            color: primaryBlue.withOpacity(0.5),
                            offset: const Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06), // Responsive spacing

                  // Back button with enhanced styling
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20), // Modern arrow
                      label: const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 12), // Adjust padding
                        child: Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold, // Bold for action
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: darkBlueText, // Text/Icon color
                        backgroundColor: Colors.white, // Button background
                        padding: const EdgeInsets.symmetric(
                            horizontal: 35, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // More rounded corners
                        ),
                        elevation: 8, // Enhanced elevation
                        shadowColor:
                            primaryBlue.withOpacity(0.6), // Stronger shadow
                      ),
                      onPressed: () {
                        // Optional: Add a slight delay before popping for animation feel
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        });
                      },
                    ),
                  ),
                  const Spacer(), // Pushes content slightly up if needed
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
