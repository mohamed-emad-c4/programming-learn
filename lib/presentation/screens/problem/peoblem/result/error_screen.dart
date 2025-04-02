import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math' as math; // For gradient rotation

class ErrorScreen extends StatefulWidget {
  final String errorMessage;
  final VoidCallback? onRetry; // Callback for a retry action

  const ErrorScreen({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Slightly faster fade-in
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define futuristic blue theme colors (consistent with SuccessScreen)
    const Color primaryBlue = Color(0xFF0D47A1); // Deep blue
    const Color accentBlue = Color(0xFF42A5F5); // Brighter accent blue
    // Define specific error colors within the blue theme context
    const Color errorColor = Color(0xFFD32F2F); // A standard Material error red
    const Color errorAccent =
        Color.fromARGB(255, 36, 0, 4); // Light tint for background/border

    // Gradient for background
    const Color gradientStart =
        Color.fromARGB(255, 108, 18, 0); // Darker start for error feel
    const Color gradientEnd =
        Color.fromARGB(255, 0, 60, 112); // Slightly brighter end

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool hasRetryAction = widget.onRetry != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: FadeTransition(
          opacity: _opacityAnimation,
          child: Text(
            hasRetryAction ? 'Action Failed' : 'Error Occurred',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close), // Use close instead of back arrow
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Container(
        // Apply a gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            transform:
                GradientRotation(math.pi / 6), // Slightly different rotation
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Error Icon with subtle background
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: errorAccent
                            .withOpacity(0.8), // Error tint background
                        boxShadow: [
                          BoxShadow(
                            color: errorColor.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons
                            .warning_amber_rounded, // A suitable error/warning icon
                        color: errorColor, // Use the defined error color
                        size: screenWidth * 0.18, // Responsive size
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Main Error Title
                    Text(
                      "Oops! Something went wrong.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.055, // Responsive font size
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Error Message Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.3, // Responsive max height
                      ),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.1), // Darker, subtle bg
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: errorAccent.withOpacity(0.5), // Subtle border
                          width: 1.5,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: widget.errorMessage,
                          selectable: true, // Allow text selection
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(Theme.of(context))
                                  .copyWith(
                            p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255)
                                          .withOpacity(0.9), // Brighter text
                                  fontSize: 15,
                                  height: 1.4, // Improve line spacing
                                ),
                            code: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: const Color.fromARGB(255, 255, 143,
                                      6), // Use error accent for code
                                  backgroundColor:
                                      const Color.fromARGB(255, 0, 0, 0)
                                          .withOpacity(0.7),
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                            h1: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.bold,
                                ),
                            // Add styles for other markdown elements as needed
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Action Button (Retry or Go Back)
                    ElevatedButton.icon(
                      icon: Icon(
                        hasRetryAction
                            ? Icons.refresh_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: hasRetryAction
                            ? errorColor
                            : primaryBlue, // Icon color matches text
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          hasRetryAction ? "Try Again" : "Go Back",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: hasRetryAction
                                ? errorColor
                                : primaryBlue, // Text color
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: hasRetryAction
                            ? errorColor
                            : primaryBlue, // Ripple color
                        backgroundColor: Colors.white, // Button background
                        padding: const EdgeInsets.symmetric(
                            horizontal: 35, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: hasRetryAction
                            ? errorColor.withOpacity(0.5)
                            : primaryBlue
                                .withOpacity(0.6), // Shadow matches context
                      ),
                      onPressed: () {
                        if (hasRetryAction) {
                          widget.onRetry!(); // Execute the retry callback
                        } else {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // Just go back
                          }
                        }
                      },
                    ),
                    const Spacer(), // Pushes content slightly up
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
