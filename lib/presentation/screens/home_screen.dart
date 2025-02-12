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
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildGridSection(context),
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
          child:  SettingsScreen(),
        ),
      ),
    );
  }

  Widget _buildGridSection(BuildContext context) {
    final items = [
      {
        'icon': Icons.computer,
        'title': 'أساسيات الكمبيوتر',
        'description': 'تعلم أساسيات الهاردوير والسوفتوير.',
        'route': '/course-detail'
      },
      {
        'icon': Icons.code,
        'title': 'لغة البرمجة',
        'description': 'تعلم بايثون، جافا، وغيرها.',
        'route': '/courses'
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'تعلم المهارات',
        'description': 'طور التفكير النقدي والإبداع.',
        'route': '/skills'
      },
      {
        'icon': Icons.bug_report,
        'title': 'حل المشكلات',
        'description': 'تدرب على بناء المنطق والخوارزميات.',
        'route': '/problem-solving'
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
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
          onTap: () => Navigator.pushNamed(context, item['route'] as String),
          delay: 200 * (index + 1),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: Colors.blue.withOpacity(0.1),
        highlightColor: Colors.blue.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: delay.ms);
  }
}
