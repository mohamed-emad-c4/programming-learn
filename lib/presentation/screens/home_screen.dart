// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cubit/auth/auth_cubit.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkTokenValidity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Learning Hub',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  'What would you like to learn today?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildGridSection(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: SettingsScreen(),
        ),
      ),
    ).then((_) => setState(() {})); // Refresh when returning from settings
  }

  Widget _buildGridSection(BuildContext context) {
    final items = [
      {
        'icon': Icons.computer,
        'title': 'Computer Basics',
        'description': 'Learn hardware and software fundamentals',
        'route': '/course-detail',
        'color': Colors.indigo,
      },
      {
        'icon': Icons.code,
        'title': 'Programming',
        'description': 'Python, Java, C++ and more',
        'route': '/courses',
        'color': Colors.teal,
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Skill Development',
        'description': 'Enhance critical thinking',
        'route': '/ocr',
        'color': Colors.orange,
      },
      {
        'icon': Icons.bug_report,
        'title': 'Problem Solving',
        'description': 'Practice algorithms',
        'route': '/tags',
        'color': Colors.pink,
      },
      {
        'icon': Icons.data_object,
        'title': 'Data Structures',
        'description': 'Master core concepts',
        'route': '/data-structures',
        'color': Colors.purple,
      },
      {
        'icon': Icons.security,
        'title': 'Cyber Security',
        'description': 'Learn protection techniques',
        'route': '/security',
        'color': Colors.blue,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCard(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          description: item['description'] as String,
          color: item['color'] as Color,
          onTap: () => Navigator.pushNamed(context, item['route'] as String),
          delay: 100 * (index + 1),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.05),
                color.withOpacity(0.15),
              ],
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: delay.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: delay.ms);
  }
}
